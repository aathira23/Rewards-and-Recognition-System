from typing import Optional, List
from sqlalchemy.orm import Session
from datetime import datetime

from app.models.wallets import Wallet
from app.models.wallet_funding import WalletFunding
from app.models.points_ledger import PointsLedger
from app.models.users import User
from app.models.notifications import Notification
from app.utils.enums import WalletType, TransactionType, ReferenceType, UserRole
from app.services.points_service import PointsService
from app.services.recognition_service import RecognitionService


class WalletsService:
    """Service for managing wallets and budget allocation."""

    def __init__(self, db: Session):
        self.db = db
        self.points_service = PointsService(db)
        self.recognition_service = RecognitionService(db)

    def get_or_create_wallet(self, user_id: int, wallet_type: WalletType) -> Wallet:
        """Get or create a wallet for a user."""
        wallet = self.db.query(Wallet).filter(
            Wallet.user_id == user_id,
            Wallet.wallet_type == wallet_type.value
        ).first()

        if not wallet:
            wallet = Wallet(
                user_id=user_id,
                wallet_type=wallet_type.value,
                balance=0
            )
            self.db.add(wallet)
            self.db.commit()
            self.db.refresh(wallet)
        
        return wallet

    def get_manager_wallet(self, user_id: int) -> Optional[Wallet]:
        """Get manager wallet for a user."""
        return self.db.query(Wallet).filter(
            Wallet.user_id == user_id,
            Wallet.wallet_type == WalletType.MANAGER.value
        ).first()

    def allocate_budget(self, manager_id: int, points: int, allocated_by: int) -> WalletFunding:
        """Allocate budget to manager wallet (HR only)."""
        # 1. Verify the target user is actually a manager or dept head
        target_user = self.db.query(User).filter(User.id == manager_id).first()
        if not target_user:
            raise ValueError(f"User with ID {manager_id} not found")
        
        if target_user.role not in ["MANAGER", "DEPT_HEAD", "HR"]:
            raise ValueError(f"Cannot allocate manager budget to user with role {target_user.role}. Only MANAGER, DEPT_HEAD, or HR roles can receive budget allocations.")
        
        # 2. Get or create manager wallet
        wallet = self.get_or_create_wallet(manager_id, WalletType.MANAGER)

        # 3. Create wallet funding record
        funding = WalletFunding(
            manager_wallet_id=wallet.id,
            funded_by=allocated_by,
            points=points
        )
        self.db.add(funding)

        # 4. Update wallet balance
        wallet.balance += points

        # 5. Create ledger entry
        ledger = PointsLedger(
            target_wallet_id=wallet.id,
            points=points,
            transaction_type=TransactionType.CREDIT.value,
            reference_type="BUDGET_ALLOCATION",
            reference_id=0 # Funding id will be available after commit
        )
        self.db.add(ledger)
        
        self.db.commit()
        self.db.refresh(funding)
        
        # Update ledger with funding ID
        ledger.reference_id = funding.id
        self.db.commit()

        # 6. Notify manager
        notification = Notification(
            user_id=manager_id,
            message=f"You have been allocated {points} points in your manager budget.",
            source_type="BUDGET",
            source_id=funding.id
        )
        self.db.add(notification)
        self.db.commit()

        return funding

    def manager_reward_employee(self, manager_id: int, employee_id: int, points: int, reason: str):
        """Manager rewards employee from their wallet."""
        # 1. Get manager wallet
        manager_wallet = self.get_manager_wallet(manager_id)
        if not manager_wallet:
            raise ValueError("Manager wallet not found.")

        # 2. Verify manager has sufficient balance
        if manager_wallet.balance < points:
            raise ValueError(f"Insufficient budget. Available: {manager_wallet.balance}, Requested: {points}")

        # 3. Deduct from manager wallet
        manager_wallet.balance -= points

        # 4. Award points to employee (creates PointsBatch and EMPLOYEE wallet if needed)
        # Note: PointsService.award_points currently doesn't track source_wallet_id in ledger perfectly for transfers
        # We will manually handle ledger for the debit side and let award_points handle credit+batch
        
        # We'll use a transaction
        batch = self.points_service.award_points(
            user_id=employee_id,
            points=points,
            source_type=ReferenceType.MANAGER_REWARD.value,
            source_id=manager_id # Using manager_id as source_id for now
        )

        # Find the ledger entry created by award_points and update its source_wallet_id
        ledger_credit = self.db.query(PointsLedger).filter(
            PointsLedger.target_wallet_id != None,
            PointsLedger.reference_type == ReferenceType.MANAGER_REWARD.value,
            PointsLedger.points == points
        ).order_by(PointsLedger.created_at.desc()).first()
        
        if ledger_credit:
            ledger_credit.source_wallet_id = manager_wallet.id
        
        # Create a DEBIT entry for manager
        ledger_debit = PointsLedger(
            source_wallet_id=manager_wallet.id,
            target_wallet_id=None, # or employee wallet? usually target is empty for debit but here it's a transfer
            points=points,
            transaction_type=TransactionType.DEBIT.value,
            reference_type=ReferenceType.MANAGER_REWARD.value,
            reference_id=employee_id
        )
        self.db.add(ledger_debit)

        # 5. Create recognition feed entry
        self.recognition_service.create_feed_entry(
            actor_id=manager_id,
            receiver_id=employee_id,
            source_type=ReferenceType.MANAGER_REWARD.value,
            source_id=manager_id,
            message=reason
        )

        # 6. Create notification for employee
        notification = Notification(
            user_id=employee_id,
            message=f"You have received {points} points from your manager. Reason: {reason}",
            source_type=ReferenceType.MANAGER_REWARD.value,
            source_id=batch.id
        )
        self.db.add(notification)

        self.db.commit()
        return batch

    def get_wallet_balance(self, user_id: int, wallet_type: str = "EMPLOYEE") -> int:
        """Get wallet balance for a user."""
        wallet = self.db.query(Wallet).filter(
            Wallet.user_id == user_id,
            Wallet.wallet_type == wallet_type
        ).first()
        return wallet.balance if wallet else 0

    def bulk_allocate_budget(
        self,
        points: int,
        allocated_by: int,
        department_id: Optional[int] = None,
        user_ids: Optional[List[int]] = None,
        role_filter: Optional[str] = None
    ) -> int:
        """Bulk allocate budget to multiple managers."""
        query = self.db.query(User)
        
        if user_ids:
            query = query.filter(User.id.in_(user_ids))
        elif department_id:
            query = query.filter(User.department_id == department_id)
            # When filtering by department, we usually only want to fund managers
            if not role_filter:
                query = query.filter(User.role.in_([UserRole.MANAGER.value, UserRole.DEPT_HEAD.value]))
        
        if role_filter:
            query = query.filter(User.role == role_filter)

        managers = query.all()
        count = 0
        for manager in managers:
            # We reuse the existing single allocation logic
            # Note: This will do a commit per manager, which is safer for partial failures
            # but slower. For bulk of ~100s it's fine.
            self.allocate_budget(manager.id, points, allocated_by)
            count += 1
            
        return count
