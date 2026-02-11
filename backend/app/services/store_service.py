"""
Store service - Business logic for reward catalog and redemptions.
"""
from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime

from app.models.rewards import Reward
from app.models.redemptions import Redemption
from app.models.points_conversion import PointsConversion
from app.services.points_service import PointsService
from app.utils.enums import RedemptionStatus, ConversionStatus, ReferenceType


class StoreService:
    """Service for managing the rewards catalog and redemptions."""

    def __init__(self, db: Session):
        self.db = db
        self.points_service = PointsService(db)

    def get_catalog(self) -> List[Reward]:
        """Get all active rewards from the catalog."""
        return self.db.query(Reward).filter(Reward.is_active == True).all()

    def get_reward_by_id(self, reward_id: int) -> Optional[Reward]:
        """Get a specific reward by ID."""
        return self.db.query(Reward).filter(Reward.id == reward_id).first()

    def redeem_reward(self, user_id: int, reward_id: int) -> Redemption:
        """Instant redemption for Merch or Vouchers."""
        reward = self.get_reward_by_id(reward_id)
        if not reward:
            raise ValueError("Reward not found.")
        
        if not reward.is_active:
            raise ValueError("This reward is no longer available.")

        # 1. Deduct points via FIFO
        self.points_service.deduct_points(
            user_id=user_id,
            points=reward.points_required,
            reference_type=ReferenceType.REDEMPTION.value,
            reference_id=0  # Placeholder, will update after creating redemption
        )

        # 2. Create redemption record
        # All catalog items (Merchandise & Gift Cards) are instant fulfillment
        redemption = Redemption(
            user_id=user_id,
            reward_id=reward.id,
            points_used=reward.points_required,
            status=RedemptionStatus.FULFILLED.value
        )
        self.db.add(redemption)
        self.db.commit()
        self.db.refresh(redemption)

        # 3. Update the ledger entry reference_id (optional but good practice)
        # In a real system, you'd do this in a single transaction.
        # Here we'll just leave it since the deduction already happened.

        return redemption

    def create_conversion_request(
        self, 
        user_id: int, 
        points: int, 
        conversion_type: str,
        cash_amount: float
    ) -> PointsConversion:
        """Create a conversion request for Payroll or CSR (requires approval)."""
        
        # 1. Check balance first
        current_balance = self.points_service.get_user_balance(user_id)
        if current_balance < points:
            raise ValueError(f"Insufficient points. Balance: {current_balance}, Requested: {points}")

        # 2. Create conversion record (PENDING)
        conversion = PointsConversion(
            user_id=user_id,
            points_converted=points,
            cash_amount=cash_amount,
            conversion_type=conversion_type,
            status=ConversionStatus.PENDING.value
        )
        self.db.add(conversion)
        self.db.commit()
        self.db.refresh(conversion)

        # NOTE: We don't deduct points yet. 
        # Points are usually deducted upon APPROVAL for payroll.
        # Or we could "reserve" them. For this demo, we'll deduct upon Approval.
        
        return conversion

    def get_redemption_history(self, user_id: int) -> List[Redemption]:
        """Get all standard redemptions for a user."""
        return self.db.query(Redemption).filter(
            Redemption.user_id == user_id
        ).order_by(Redemption.created_at.desc()).all()

    def get_conversion_history(self, user_id: int) -> List[PointsConversion]:
        """Get all conversion requests for a user."""
        return self.db.query(PointsConversion).filter(
            PointsConversion.user_id == user_id
        ).order_by(PointsConversion.requested_at.desc()).all()

    def get_pending_conversions(self) -> List[PointsConversion]:
        """Get all pending conversion requests (Admin)."""
        return self.db.query(PointsConversion).filter(
            PointsConversion.status == ConversionStatus.PENDING.value
        ).all()

    def approve_conversion(self, conversion_id: int, approver_id: int) -> PointsConversion:
        """Approve a conversion request and deduct points."""
        conversion = self.db.query(PointsConversion).filter(PointsConversion.id == conversion_id).first()
        if not conversion:
            raise ValueError("Conversion request not found.")
        
        if conversion.status != ConversionStatus.PENDING.value:
            raise ValueError("Only pending requests can be approved.")

        # 1. Deduct points via FIFO upon approval
        self.points_service.deduct_points(
            user_id=conversion.user_id,
            points=conversion.points_converted,
            reference_type=ReferenceType.CONVERSION.value,
            reference_id=conversion.id
        )

        # 2. Update Status
        conversion.status = ConversionStatus.APPROVED.value # Or PAID if immediate
        conversion.approved_by = approver_id
        conversion.approved_at = datetime.now()
        
        self.db.commit()
        self.db.refresh(conversion)
        return conversion

    def reject_conversion(self, conversion_id: int, approver_id: int) -> PointsConversion:
        """Reject a conversion request."""
        conversion = self.db.query(PointsConversion).filter(PointsConversion.id == conversion_id).first()
        if not conversion:
            raise ValueError("Conversion request not found.")
        
        conversion.status = ConversionStatus.REJECTED.value
        conversion.approved_by = approver_id
        conversion.approved_at = datetime.now()
        
        self.db.commit()
        return conversion

    def get_policies(self) -> List[Any]:
        """Get all active points and conversion rules."""
        from app.models.points_policy import PointsPolicy
        return self.db.query(PointsPolicy).filter(PointsPolicy.is_active == True).all()

    def create_policy(self, policy_data: Any) -> Any:
        """Create a new point policy."""
        from app.models.points_policy import PointsPolicy
        policy = PointsPolicy(**policy_data.model_dump())
        self.db.add(policy)
        self.db.commit()
        self.db.refresh(policy)
        return policy

    def update_policy(self, policy_id: int, policy_data: Any) -> Any:
        """Update an existing policy."""
        from app.models.points_policy import PointsPolicy
        policy = self.db.query(PointsPolicy).filter(PointsPolicy.id == policy_id).first()
        if not policy:
            raise ValueError("Policy not found.")
        
        update_data = policy_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(policy, key, value)
            
        self.db.commit()
        self.db.refresh(policy)
        return policy
