from typing import Optional, List
from sqlalchemy.orm import Session

from app.models.wallets import Wallet
from app.models.wallet_funding import WalletFunding
from app.models.notifications import Notification
from app.utils.enums import WalletType, TransactionType, ReferenceType, UserRole
from app.services.points_service import PointsService
from app.services.recognition_service import RecognitionService
from app.repository.wallets_repository import WalletsRepository


class WalletsService:
    """Service for managing wallets and budget allocation."""

    def __init__(self, db: Session, token: Optional[str] = None):
        self.db = db
        self._token = token
        self.repository = WalletsRepository(db)
        self.points_service = PointsService(db)
        self.recognition_service = RecognitionService(db)

    def get_or_create_wallet(self, user_id: int, wallet_type: WalletType) -> Wallet:
        """Get or create a wallet for a user."""
        return self.repository.get_or_create_wallet(user_id, wallet_type)

    def get_manager_wallet(self, user_id: int) -> Optional[Wallet]:
        """Get manager wallet for a user."""
        return self.repository.get_wallet(user_id, WalletType.MANAGER.value)

    def allocate_budget(self, manager_id: int, points: int, allocated_by: int) -> WalletFunding:
        """Allocate budget to manager wallet (HR only)."""
        # 1. Verify the target user is actually a manager or dept head
        target_user = self.repository.get_user_by_id(manager_id)
        if not target_user:
            raise ValueError(f"User with ID {manager_id} not found")

        if target_user.role not in ["MANAGER", "DEPT_HEAD", "HR"]:
            raise ValueError(f"Cannot allocate manager budget to user with role {target_user.role}. Only MANAGER, DEPT_HEAD, or HR roles can receive budget allocations.")

        # 2. Get or create manager wallet
        wallet = self.get_or_create_wallet(manager_id, WalletType.MANAGER)

        # 3. Create wallet funding record
        funding = self.repository.create_funding(wallet.id, allocated_by, points)

        # 4. Update wallet balance
        wallet.balance += points

        # 5. Create ledger entry
        ledger = self.repository.add_ledger_entry(
            points=points,
            transaction_type=TransactionType.CREDIT.value,
            reference_type="BUDGET_ALLOCATION",
            reference_id=0,
            target_wallet_id=wallet.id,
        )

        self.repository.commit()
        self.repository.refresh(funding)

        # Update ledger with funding ID
        ledger.reference_id = funding.id
        self.repository.commit()

        # 6. Notify manager
        notification = Notification(
            user_id=manager_id,
            message=f"You have been allocated {points} points in your manager budget.",
            source_type="BUDGET",
            source_id=funding.id
        )
        self.db.add(notification)
        self.repository.commit()

        return funding

    def manager_reward_employee(self, manager_id: int, employee_id: int, points: int, reason: str):
        """Manager rewards employee from their wallet."""
        # 0. Validate permission/hierarchy
        manager = self.repository.get_user_by_id(manager_id)
        employee = self.repository.get_user_by_id(employee_id)

        if not manager or not employee:
            raise ValueError("Manager or Employee not found.")

        if manager.role == UserRole.MANAGER.value:
            if employee.manager_id != manager.id:
                raise ValueError("Managers can only reward their direct reports.")
        elif manager.role == UserRole.DEPT_HEAD.value:
            if employee.department_id != manager.department_id:
                raise ValueError("Department Heads can only reward employees within their department.")
        # HR/Admin can reward anyone

        # 1. Get manager wallet
        manager_wallet = self.get_manager_wallet(manager_id)
        if not manager_wallet:
            raise ValueError("Manager wallet not found.")
        # 2. Delegate awarding to PointsService which will centrally deduct manager budget
        batch = self.points_service.award_points(
            user_id=employee_id,
            points=points,
            source_type=ReferenceType.MANAGER_REWARD.value,
            source_id=manager_id # Using manager_id as source_id so PointsService can deduct manager wallet
        )

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

        self.repository.commit()
        return batch

    def get_wallet_balance(self, user_id: int, wallet_type: str = "EMPLOYEE") -> int:
        """Get wallet balance for a user."""
        wallet = self.repository.get_wallet(user_id, wallet_type)
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
        managers = self.repository.get_users_by_role_and_department(
            department_id=department_id,
            user_ids=user_ids,
            role_filter=role_filter,
            default_roles=[UserRole.MANAGER.value, UserRole.DEPT_HEAD.value],
        )
        count = 0
        for manager in managers:
            # We reuse the existing single allocation logic
            # Note: This will do a commit per manager, which is safer for partial failures
            # but slower. For bulk of ~100s it's fine.
            self.allocate_budget(manager.id, points, allocated_by)
            count += 1

        return count
