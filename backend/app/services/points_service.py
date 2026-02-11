from typing import Any, Dict, List, Optional, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import or_, desc, func

from app.models.wallets import Wallet
from app.models.points_ledger import PointsLedger
from app.models.points_conversion import PointsConversion
from app.models.ecards import ECard
from app.models.awards import Award
from app.models.redemptions import Redemption
from app.models.users import User
from app.models.badges import Badge
from app.models.award_types import AwardType
from app.models.rewards import Reward
from app.models.points_batches import PointsBatch
from app.utils.enums import TransactionType, ReferenceType
from datetime import date


def get_employee_wallet(db: Session, user_id: int) -> Optional[Wallet]:
    return db.query(Wallet).filter(Wallet.user_id == user_id, Wallet.wallet_type == "EMPLOYEE").first()


def get_aggregates(db: Session, user_id: int) -> Dict[str, int]:
    """Compute total earned, total redeemed, and pending conversion count."""
    wallet = get_employee_wallet(db, user_id)
    if not wallet:
        return {"balance": 0, "total_earned": 0, "total_redeemed": 0, "pending_count": 0}
    
    balance = int(wallet.balance or 0)
    
    # Total earned: sum of credits to user's wallet
    earned = db.query(func.sum(PointsLedger.points)).filter(
        PointsLedger.transaction_type == TransactionType.CREDIT.value,
        PointsLedger.target_wallet_id == wallet.id
    ).scalar() or 0
    
    # Total redeemed: sum of redemptions.points_used or debits with REDEMPTION reference
    redeemed = db.query(func.sum(Redemption.points_used)).filter(
        Redemption.user_id == user_id
    ).scalar() or 0
    
    # Pending count: conversion requests with PENDING status
    pending_count = db.query(func.count(PointsConversion.id)).filter(
        PointsConversion.user_id == user_id,
        PointsConversion.status == "PENDING"
    ).scalar() or 0
    
    return {
        "balance": balance,
        "total_earned": int(earned),
        "total_redeemed": int(redeemed),
        "pending_count": int(pending_count),
    }


def _enrich_description(db: Session, row: PointsLedger) -> Tuple[str, str]:
    """Return (description, type_badge) for a ledger entry by joining related tables."""
    ref_type = row.reference_type
    ref_id = row.reference_id
    
    if not ref_type:
        return "Points transaction", "Other"
    
    ref_upper = ref_type.upper()
    
    # ECARD
    if ref_upper == ReferenceType.ECARD.value:
        ecard = db.query(ECard).filter(ECard.id == ref_id).first()
        if ecard:
            sender = db.query(User).filter(User.id == ecard.sender_id).first()
            badge = db.query(Badge).filter(Badge.id == ecard.badge_id).first()
            sender_name = sender.name if sender else "Unknown"
            badge_title = badge.title if badge else "Badge"
            desc = f"'{badge_title}' Appreciation\nFrom: {sender_name}"
            return desc, "Earned"
        return "eCard Appreciation", "Earned"
    
    # AWARD
    elif ref_upper == ReferenceType.AWARD.value:
        award = db.query(Award).filter(Award.id == ref_id).first()
        if award:
            award_type = db.query(AwardType).filter(AwardType.id == award.award_type_id).first()
            award_name = award_type.name if award_type else "Award"
            desc = f"{award_name}"
            return desc, "Earned"
        return "Award", "Earned"
    
    # REDEMPTION
    elif ref_upper == ReferenceType.REDEMPTION.value:
        redemption = db.query(Redemption).filter(Redemption.id == ref_id).first()
        if redemption:
            reward = db.query(Reward).filter(Reward.id == redemption.reward_id).first()
            reward_title = reward.title if reward else "Reward"
            desc = f"{reward_title} Redemption\nOrder ID: ALR-{redemption.id}"
            return desc, "Redeemed"
        return "Reward Redemption", "Redeemed"
    
    # CONVERSION
    elif ref_upper == ReferenceType.CONVERSION.value:
        conversion = db.query(PointsConversion).filter(PointsConversion.id == ref_id).first()
        if conversion:
            desc = f"Points Conversion - {conversion.conversion_type}\nRequest ID: {conversion.id}"
            return desc, "Pending" if conversion.status == "PENDING" else "Redeemed"
        return "Points Conversion", "Pending"
    
    # CELEBRATION (birthday, anniversary)
    elif ref_upper == ReferenceType.CELEBRATION.value:
        return "Celebration Bonus", "Earned"
    
    # MANAGER_REWARD
    elif ref_upper == ReferenceType.MANAGER_REWARD.value:
        return "Manager Reward", "Earned"
    
    # EXPIRY
    elif ref_upper == "EXPIRY":
        return "Points Expired", "Expired"
    
    # fallback
    return f"{ref_type} #{ref_id}", "Other"


def _map_ledger_row(db: Session, row: PointsLedger, wallet_id: int) -> Dict[str, Any]:
    """Map PointsLedger row to dashboard entry with enriched description."""
    # Determine sign and category
    if row.transaction_type == TransactionType.CREDIT.value and row.target_wallet_id == wallet_id:
        points = int(row.points)
        category = "received"
    elif row.transaction_type == TransactionType.DEBIT.value and row.source_wallet_id == wallet_id:
        points = -int(row.points)
        category = "expired" if row.reference_type and row.reference_type.upper() == "EXPIRY" else "spent"
    else:
        points = int(row.points) if row.target_wallet_id == wallet_id else -int(row.points)
        category = "received" if points > 0 else "spent"
    
    description, type_badge = _enrich_description(db, row)
    
    return {
        "id": row.id,
        "date": row.created_at.strftime("%d/%m/%Y") if row.created_at else "",
        "description": description,
        "type": type_badge,
        "points": f"+{points}" if points > 0 else str(points),
    }


def fetch_ledger_history(
    db: Session,
    user_id: int,
    category: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    page: int = 1,
    per_page: int = 20,
) -> Tuple[int, List[Dict[str, Any]]]:
    """Return total count and list of ledger entries for the user's wallet, filtered and paginated."""
    wallet = get_employee_wallet(db, user_id)
    if not wallet:
        return 0, []

    q = db.query(PointsLedger).filter(
        or_(PointsLedger.source_wallet_id == wallet.id, PointsLedger.target_wallet_id == wallet.id)
    )

    if start_date:
        q = q.filter(PointsLedger.created_at >= start_date)
    if end_date:
        q = q.filter(PointsLedger.created_at <= end_date)

    # category filters
    # Exclude ledger rows created by expiry job; expired items will be sourced from PointsBatch
    q = q.filter(or_(PointsLedger.reference_type == None, ~PointsLedger.reference_type.ilike("%EXPIRY%")))

    if category:
        cat = category.lower()
        if cat == "received":
            q = q.filter(PointsLedger.transaction_type == TransactionType.CREDIT.value, PointsLedger.target_wallet_id == wallet.id)
        elif cat == "spent":
            q = q.filter(PointsLedger.transaction_type == TransactionType.DEBIT.value, PointsLedger.source_wallet_id == wallet.id)
        elif cat == "expired":
            # When user requests expired category, return batches that have expired (source of truth)
            today = date.today()
            batch_q = db.query(PointsBatch).filter(
                PointsBatch.user_id == user_id,
                PointsBatch.expiry_date <= today,
                PointsBatch.remaining_points > 0,
            )
            total_batches = batch_q.count()
            batch_rows = batch_q.order_by(desc(PointsBatch.expiry_date)).offset((page - 1) * per_page).limit(per_page).all()
            batch_items = [
                {
                    "id": f"batch-{b.id}",
                    "date": b.expiry_date.strftime("%d/%m/%Y") if b.expiry_date else "",
                    "description": f"Points Expired - {b.source_type}\nBatch ID: {b.id}",
                    "type": "Expired",
                    "points": f"-{int(b.remaining_points)}",
                }
                for b in batch_rows
            ]
            return total_batches, batch_items
        # pending handled separately (see below)

    total = q.count()
    rows = q.order_by(desc(PointsLedger.created_at)).offset((page - 1) * per_page).limit(per_page).all()

    items = [_map_ledger_row(db, r, wallet.id) for r in rows]

    # include pending conversion requests as separate entries when requested
    # For the overall feed (no category) we also merge expired batch items so the UI shows expiries
    if category is None:
        today = date.today()
        expired_q = db.query(PointsBatch).filter(
            PointsBatch.user_id == user_id,
            PointsBatch.expiry_date <= today,
            PointsBatch.remaining_points > 0,
        ).order_by(desc(PointsBatch.expiry_date))
        expired_rows = expired_q.all()
        expired_items = [
            {
                "id": f"batch-{b.id}",
                "date": b.expiry_date.strftime("%d/%m/%Y") if b.expiry_date else "",
                "description": f"Points Expired - {b.source_type}\nBatch ID: {b.id}",
                "type": "Expired",
                "points": f"-{int(b.remaining_points)}",
            }
            for b in expired_rows
        ]
        # prepend expired items so they appear at the top
        items = expired_items + items
        total += len(expired_items)

    if category is None or category.lower() == "pending":
        pending_q = db.query(PointsConversion).filter(PointsConversion.user_id == user_id, PointsConversion.status == "PENDING")
        pending_rows = pending_q.order_by(desc(PointsConversion.requested_at)).all()
        pending_items = [
            {
                "id": f"conv-{p.id}",
                "date": p.requested_at.strftime("%d/%m/%Y") if p.requested_at else "",
                "description": f"Points Conversion - {p.conversion_type}\nRequest ID: {p.id}",
                "type": "Pending",
                "points": f"-{int(p.points_converted)}",
            }
            for p in pending_rows
        ]
        # merge pending items at the top
        items = pending_items + items
        total += len(pending_items)

    return total, items
"""
Points service - Business logic for points management.
"""
from sqlalchemy.orm import Session


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
