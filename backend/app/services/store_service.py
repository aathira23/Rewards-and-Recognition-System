"""
Store service - Business logic for reward catalog and redemptions.
"""
from typing import Any, List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import or_
from datetime import datetime

from app.models.rewards import Reward
from app.models.redemptions import Redemption
from app.models.points_conversion import PointsConversion
from app.services.points_service import PointsService
from app.services.notification_service import NotificationService
from app.utils.enums import RedemptionStatus, ConversionStatus, ReferenceType


class StoreService:
    """Service for managing the rewards catalog and redemptions."""

    def __init__(self, db: Session):
        self.db = db
        self.points_service = PointsService(db)
        self.notification_service = NotificationService(db)

    def get_catalog(self, page: int = 1, per_page: int = 20, include_inactive: bool = False):
        """Get rewards from the catalog, paginated. Returns (total, items).

        For the employee-facing catalog (include_inactive=False) rewards with
        stock_quantity == 0 are excluded as well as inactive ones.
        When include_inactive=True (HR config view) every reward is returned.
        """
        from app.utils.constants import clamp_pagination
        page, per_page, skip = clamp_pagination(page, per_page)
        query = self.db.query(Reward)
        if not include_inactive:
            query = query.filter(
                Reward.is_active == True,
                # hide rewards that are fully out of stock from employees
                or_(Reward.stock_quantity == None, Reward.stock_quantity > 0),
            )
        total = query.count()
        items = query.offset(skip).limit(per_page).all()
        return total, items

    def get_reward_by_id(self, reward_id: int) -> Optional[Reward]:
        """Get a specific reward by ID."""
        return self.db.query(Reward).filter(Reward.id == reward_id).first()

    def create_reward(self, reward_data: Any) -> Reward:
        """Create a new reward item in the store."""
        reward = Reward(**reward_data.model_dump())
        self.db.add(reward)
        self.db.commit()
        self.db.refresh(reward)
        return reward

    def update_reward(self, reward_id: int, reward_data: Any) -> Reward:
        """Update an existing reward item."""
        reward = self.get_reward_by_id(reward_id)
        if not reward:
            raise ValueError("Reward not found.")

        update_data = reward_data.model_dump(exclude_unset=True)

        for key, value in update_data.items():
            setattr(reward, key, value)

        # HR controls is_active manually — stock hitting 0 does NOT auto-deactivate.
        # 0-stock rewards are simply hidden from the employee catalog by the query filter.

        self.db.commit()
        self.db.refresh(reward)
        return reward

    def redeem_reward(self, user_id: int, reward_id: int) -> Redemption:
        """Instant redemption for Merch or Vouchers."""
        reward = self.get_reward_by_id(reward_id)
        if not reward:
            raise ValueError("Reward not found.")

        if not reward.is_active:
            raise ValueError("This reward is no longer available.")

        # Check stock availability
        if reward.stock_quantity is not None:
            if reward.stock_quantity <= 0:
                # Auto-deactivate if stock is 0
                reward.is_active = False
                self.db.commit()
                raise ValueError("This reward is out of stock.")

        # 1. Deduct points via FIFO
        self.points_service.deduct_points(
            user_id=user_id,
            points=reward.points_required,
            reference_type=ReferenceType.REDEMPTION.value,
            reference_id=0  # Placeholder, will update after creating redemption
        )

        # 2. Decrease stock if applicable
        if reward.stock_quantity is not None:
            reward.stock_quantity -= 1
            # Auto-deactivate if stock reaches 0
            if reward.stock_quantity <= 0:
                reward.is_active = False

        # 3. Create redemption record
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

        # 4. Notify user
        remaining_balance = self.points_service.get_user_balance(user_id)
        self.notification_service.create_notification(
            user_id=user_id,
            message=f"Redemption successful! You redeemed '{reward.name}' for {reward.points_required} points.",
            source_type=ReferenceType.REDEMPTION.value,
            source_id=redemption.id,
            email_context={
                "reward_name": reward.name,
                "points_used": reward.points_required,
                "remaining_balance": remaining_balance,
                "redemption_id": redemption.id,
                "redemption_date": str(redemption.created_at),
            },
        )

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

        # 3. Notify HR/Admin (Optional, but let's notify the user that request is received)
        self.notification_service.create_notification(
            user_id=user_id,
            message=f"Your request to convert {points} points to cash ({cash_amount}) has been submitted and is pending approval.",
            source_type=ReferenceType.CONVERSION.value,
            source_id=conversion.id,
            email_event_type="CONVERSION_SUBMITTED",
            email_context={
                "points": points,
                "cash_amount": cash_amount,
                "details_url": "",
            },
        )

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

    def get_all_conversion_history(self) -> List[PointsConversion]:
        """Get all conversion requests (HR/admin view)."""
        return self.db.query(PointsConversion).order_by(PointsConversion.requested_at.desc()).all()

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

        # 3. Notify User
        self.notification_service.create_notification(
            user_id=conversion.user_id,
            message=f"Your points conversion request for {conversion.points_converted} points has been approved.",
            source_type=ReferenceType.CONVERSION.value,
            source_id=conversion.id,
            email_event_type="CONVERSION_APPROVED",
            email_context={
                "item_type": "Points Conversion",
                "status": "Approved",
                "approver_name": "HR",
                "comment": "",
                "points_amount": conversion.points_converted,
                "details_url": "",
            },
        )

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
        self.db.refresh(conversion)

        # Notify User
        self.notification_service.create_notification(
            user_id=conversion.user_id,
            message=f"Your points conversion request for {conversion.points_converted} points has been rejected.",
            source_type=ReferenceType.CONVERSION.value,
            source_id=conversion.id,
            email_event_type="CONVERSION_REJECTED",
            email_context={
                "item_type": "Points Conversion",
                "status": "Rejected",
                "approver_name": "HR",
                "comment": "",
                "points_amount": conversion.points_converted,
                "details_url": "",
            },
        )

        return conversion

    def get_policies(self) -> List[Any]:
        """Get all active points and conversion rules."""
        from app.models.points_policy import PointsPolicy
        return self.db.query(PointsPolicy).filter(PointsPolicy.is_active == True).all()

    def create_policy(self, policy_data: Any) -> Any:
        """Create a new point policy, deactivating any existing duplicate first.

        Duplicate identity:
          - CONVERSION rules  → same recognition_type + conversion_reward_type
          - All other rules   → same recognition_type + event_key (None or value)
        """
        from app.models.points_policy import PointsPolicy

        data = policy_data.model_dump()
        rec_type = data.get("recognition_type")

        if rec_type == "CONVERSION":
            conv_reward_type = data.get("conversion_reward_type")
            duplicates = self.db.query(PointsPolicy).filter(
                PointsPolicy.recognition_type == rec_type,
                PointsPolicy.conversion_reward_type == conv_reward_type,
                PointsPolicy.is_active == True,
            ).all()
        else:
            event_key = data.get("event_key")
            query = self.db.query(PointsPolicy).filter(
                PointsPolicy.recognition_type == rec_type,
                PointsPolicy.is_active == True,
            )
            if event_key:
                query = query.filter(PointsPolicy.event_key == event_key)
            else:
                query = query.filter(PointsPolicy.event_key == None)
            duplicates = query.all()

        for old in duplicates:
            old.is_active = False

        policy = PointsPolicy(**data)
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
