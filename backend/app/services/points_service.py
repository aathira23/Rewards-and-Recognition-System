"""
Points service - Business logic for points management.
"""
from sqlalchemy.orm import Session
from typing import List, Optional
from decimal import Decimal


class PointsService:
    """Service for managing points, ledger, and conversions."""
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_user_balance(self, user_id: int) -> int:
        """Get total available points for a user."""
        # TODO: Implement balance calculation
        # Sum all points_batches.remaining_points for user
        pass
    
    def get_points_history(self, user_id: int, skip: int = 0, limit: int = 20):
        """Get points transaction history."""
        # TODO: Implement history retrieval from points_ledger
        pass
    
    def award_points(
        self,
        user_id: int,
        points: int,
        source_type: str,
        source_id: int,
        expiry_days: int = 365
    ):
        """Award points to a user and create batch."""
        # TODO: Implement points awarding logic
        # 1. Create points batch with expiry
        # 2. Update wallet balance
        # 3. Create ledger entry
        pass
    
    def deduct_points(self, user_id: int, points: int, reference_type: str, reference_id: int):
        """Deduct points from user using FIFO."""
        # TODO: Implement FIFO deduction logic
        # 1. Get batches ordered by expiry_date
        # 2. Deduct from oldest first
        # 3. Update remaining_points
        # 4. Create ledger entry
        pass
    
    def create_conversion_request(
        self,
        user_id: int,
        points: int,
        conversion_type: str
    ):
        """Create a points-to-cash conversion request."""
        # TODO: Implement conversion request logic
        # 1. Verify user has sufficient points
        # 2. Calculate cash amount based on policy
        # 3. Create conversion record
        # 4. Reserve points (or deduct immediately)
        pass
    
    def approve_conversion(self, conversion_id: int, approver_id: int):
        """Approve a conversion request."""
        # TODO: Implement approval logic
        # 1. Update conversion status
        # 2. Deduct points if not already done
        # 3. Create notification
        pass
    
    def reject_conversion(self, conversion_id: int, approver_id: int, reason: str):
        """Reject a conversion request."""
        # TODO: Implement rejection logic
        pass
    
    def expire_points(self):
        """Background job to expire old points batches."""
        # TODO: Implement expiry logic
        # 1. Find batches past expiry_date
        # 2. Deduct remaining_points from wallet
        # 3. Update batch remaining_points to 0
        pass
