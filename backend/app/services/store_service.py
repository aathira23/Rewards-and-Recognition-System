"""
Store service - Business logic for reward catalog and redemptions.
"""
from __future__ import annotations

from typing import Any, List, Optional
from sqlalchemy.orm import Session
from datetime import datetime

from app.services.points_service import PointsService
from app.services.notification_service import NotificationService
from app.utils.enums import RedemptionStatus, ConversionStatus, ReferenceType
from app.repository.store_repository import StoreRepository


class StoreService:
    """Service for managing the rewards catalog and redemptions."""

    def __init__(self, db: Session, token: Optional[str] = None):
        self.db = db
        self.repository = StoreRepository(db)
        self.points_service = PointsService(db)
        self.notification_service = NotificationService(db, token=token)

    def get_catalog(self, page: int = 1, per_page: int = 20, include_inactive: bool = False):
        """Get rewards from the catalog, paginated. Returns (total, items).

        For the employee-facing catalog (include_inactive=False) rewards with
        stock_quantity == 0 are excluded as well as inactive ones.
        When include_inactive=True (HR config view) every reward is returned.
        """
        from app.utils.constants import clamp_pagination
        page, per_page, skip = clamp_pagination(page, per_page)
        return self.repository.get_catalog_paginated(skip, per_page, include_inactive)

    def get_reward_by_id(self, reward_id: int):
        """Get a specific reward by ID."""
        return self.repository.get_reward_by_id(reward_id)

    def create_reward(self, reward_data: Any):
        """Create a new reward item in the store."""
        return self.repository.create_reward(reward_data.model_dump())

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

        return self.repository.save_reward(reward)

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
                self.repository.save_reward(reward)
                raise ValueError("This reward is out of stock.")

        # Check balance accounting for points locked in pending conversions
        current_balance = self.points_service.get_user_balance(user_id)
        pending_points = self.points_service.get_pending_conversion_points(user_id)
        available = current_balance - pending_points
        if available < reward.points_required:
            raise ValueError(
                f"Insufficient points. Available: {available} "
                f"({pending_points} points are reserved for a pending conversion request)."
            )

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
        redemption = self.repository.create_redemption(
            user_id=user_id,
            reward_id=reward.id,
            points_used=reward.points_required,
            status=RedemptionStatus.FULFILLED.value,
        )

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

        # 0. Block if user already has a pending conversion request
        if self.repository.has_pending_conversion(user_id):
            raise ValueError(
                "You already have a pending conversion request. "
                "Please wait for it to be approved or rejected before submitting a new one."
            )

        # 1. Check balance (minus points already locked in pending conversions)
        current_balance = self.points_service.get_user_balance(user_id)
        pending_points = self.points_service.get_pending_conversion_points(user_id)
        available = current_balance - pending_points
        if available < points:
            raise ValueError(f"Insufficient points. Available: {available}, Requested: {points}")

        # 2. Create conversion record (PENDING)
        conversion = self.repository.create_conversion(
            user_id=user_id,
            points=points,
            cash_amount=cash_amount,
            conversion_type=conversion_type,
            status=ConversionStatus.PENDING.value,
        )

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

    def get_redemption_history(self, user_id: int):
        """Get all standard redemptions for a user."""
        return self.repository.get_redemptions_by_user(user_id)

    def get_conversion_history(self, user_id: int):
        """Get all conversion requests for a user."""
        return self.repository.get_conversions_by_user(user_id)

    def get_all_conversion_history(self):
        """Get all conversion requests (HR/admin view)."""
        return self.repository.get_all_conversions()

    def get_pending_conversions(self):
        """Get all pending conversion requests (Admin)."""
        return self.repository.get_pending_conversions()

    def approve_conversion(self, conversion_id: int, approver_id: int):
        """Approve a conversion request and deduct points."""
        conversion = self.repository.get_conversion_by_id(conversion_id)
        if not conversion:
            raise ValueError("Conversion request not found.")

        if conversion.status != ConversionStatus.PENDING.value:
            raise ValueError("Only pending requests can be approved.")

        # Re-validate that user still has enough points before deducting
        current_balance = self.points_service.get_user_balance(conversion.user_id)
        if current_balance < conversion.points_converted:
            raise ValueError(
                f"Cannot approve: user's balance ({current_balance}) is less than "
                f"the requested conversion ({conversion.points_converted} points)."
            )

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

        self.repository.save_conversion(conversion)

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

    def reject_conversion(self, conversion_id: int, approver_id: int):
        """Reject a conversion request."""
        conversion = self.repository.get_conversion_by_id(conversion_id)
        if not conversion:
            raise ValueError("Conversion request not found.")

        conversion.status = ConversionStatus.REJECTED.value
        conversion.approved_by = approver_id
        conversion.approved_at = datetime.now()

        self.repository.save_conversion(conversion)

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

    def get_policies(self, include_inactive: bool = False):
        """Get all points and conversion rules. If not include_inactive, returns only active."""
        return self.repository.get_policies(include_inactive)

    def create_policy(self, policy_data: Any):
        """Create a new point policy, deactivating any existing duplicate first.

        Duplicate identity:
          - CONVERSION rules  → same recognition_type + conversion_reward_type
          - All other rules   → same recognition_type + event_key (None or value)
        """
        data = policy_data.model_dump()
        rec_type = data.get("recognition_type")
        event_key = data.get("event_key")
        conv_reward_type = data.get("conversion_reward_type")

        duplicates = self.repository.find_duplicate_policies(
            recognition_type=rec_type,
            event_key=event_key,
            conversion_reward_type=conv_reward_type,
        )

        if duplicates:
            # Update the existing record instead of creating a new one
            policy = duplicates[0]
            for key, value in data.items():
                if key != "id":
                    setattr(policy, key, value)
            policy.is_active = True
            return self.repository.save_policy(policy)
        else:
            return self.repository.create_policy(data)

    def update_policy(self, policy_id: int, policy_data: Any):
        """Update an existing policy."""
        policy = self.repository.get_policy_by_id(policy_id)
        if not policy:
            raise ValueError("Policy not found.")

        update_data = policy_data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(policy, key, value)

        return self.repository.save_policy(policy)
