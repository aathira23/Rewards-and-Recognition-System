from typing import Optional, List, Dict, Any, Tuple
from datetime import date, datetime

from sqlalchemy import func, or_, desc
from sqlalchemy.orm import Session

from app.models.wallets import Wallet
from app.models.points_ledger import PointsLedger
from app.models.points_batches import PointsBatch
from app.models.points_conversion import PointsConversion
from app.models.redemptions import Redemption
from app.models.ecards import ECard
from app.models.awards import Award
from app.models.award_types import AwardType
from app.models.badges import Badge
from app.models.rewards import Reward
from app.models.notifications import Notification
from app.utils.enums import TransactionType, WalletType


class PointsRepository:
    def __init__(self, db: Session):
        self.db = db

    # --- Wallet ---
    def get_employee_wallet(self, user_id: int) -> Optional[Wallet]:
        return self.db.query(Wallet).filter(
            Wallet.user_id == user_id,
            Wallet.wallet_type == WalletType.EMPLOYEE.value,
        ).first()

    def create_employee_wallet(self, user_id: int) -> Wallet:
        wallet = Wallet(user_id=user_id, wallet_type=WalletType.EMPLOYEE.value, balance=0)
        self.db.add(wallet)
        self.db.commit()
        self.db.refresh(wallet)
        return wallet

    def get_manager_wallet(self, user_id: int) -> Optional[Wallet]:
        return self.db.query(Wallet).filter(
            Wallet.user_id == user_id,
            Wallet.wallet_type == WalletType.MANAGER.value,
        ).first()

    # --- Points Balance ---
    def get_available_balance(self, user_id: int) -> int:
        today = date.today()
        total = self.db.query(func.sum(PointsBatch.remaining_points)).filter(
            PointsBatch.user_id == user_id,
            PointsBatch.expiry_date >= today,
            PointsBatch.remaining_points > 0,
        ).scalar() or 0
        return int(total)

    # --- Points Batches ---
    def create_batch(
        self, user_id: int, points: int, source_type: str, source_id: int, expiry_date: date
    ) -> PointsBatch:
        batch = PointsBatch(
            user_id=user_id,
            points=points,
            remaining_points=points,
            source_type=source_type,
            source_id=source_id,
            expiry_date=expiry_date,
        )
        self.db.add(batch)
        return batch

    def get_fifo_batches(self, user_id: int) -> List[PointsBatch]:
        today = date.today()
        return self.db.query(PointsBatch).filter(
            PointsBatch.user_id == user_id,
            PointsBatch.expiry_date >= today,
            PointsBatch.remaining_points > 0,
        ).order_by(PointsBatch.expiry_date.asc()).all()

    def get_expired_batches(self, user_id: int) -> List[PointsBatch]:
        today = date.today()
        return self.db.query(PointsBatch).filter(
            PointsBatch.user_id == user_id,
            PointsBatch.expiry_date < today,
            PointsBatch.remaining_points > 0,
        ).all()

    def get_expired_batches_paginated(
        self, user_id: int, skip: int, limit: int
    ) -> Tuple[int, List[PointsBatch]]:
        today = date.today()
        query = self.db.query(PointsBatch).filter(
            PointsBatch.user_id == user_id,
            PointsBatch.expiry_date < today,
            PointsBatch.remaining_points > 0,
        )
        total = query.count()
        rows = query.order_by(desc(PointsBatch.expiry_date)).offset(skip).limit(limit).all()
        return total, rows

    def get_upcoming_expiry_batches(self, cutoff: date) -> List[PointsBatch]:
        today = date.today()
        return self.db.query(PointsBatch).filter(
            PointsBatch.expiry_date > today,
            PointsBatch.expiry_date <= cutoff,
            PointsBatch.remaining_points > 0,
        ).all()

    def get_all_expired_unprocessed(self) -> List[PointsBatch]:
        today = date.today()
        return self.db.query(PointsBatch).filter(
            PointsBatch.expiry_date < today,
            PointsBatch.remaining_points > 0,
        ).all()

    # --- Ledger ---
    def add_ledger_entry(
        self,
        points: int,
        transaction_type: str,
        reference_type: str,
        reference_id: int,
        *,
        source_wallet_id: Optional[int] = None,
        target_wallet_id: Optional[int] = None,
    ) -> PointsLedger:
        ledger = PointsLedger(
            source_wallet_id=source_wallet_id,
            target_wallet_id=target_wallet_id,
            points=points,
            transaction_type=transaction_type,
            reference_type=reference_type,
            reference_id=reference_id,
        )
        self.db.add(ledger)
        return ledger

    def get_total_credits(self, wallet_id: int) -> int:
        return self.db.query(func.sum(PointsLedger.points)).filter(
            PointsLedger.transaction_type == TransactionType.CREDIT.value,
            PointsLedger.target_wallet_id == wallet_id,
        ).scalar() or 0

    def get_month_credits(self, first_day: date) -> int:
        return self.db.query(func.sum(PointsLedger.points)).filter(
            PointsLedger.transaction_type == TransactionType.CREDIT.value,
            PointsLedger.created_at >= first_day,
        ).scalar() or 0

    def get_monthly_earned_for_user(self, wallet_id: int, first_day: date) -> int:
        """Total CREDIT points earned by a specific wallet in the current calendar month."""
        return self.db.query(func.sum(PointsLedger.points)).filter(
            PointsLedger.transaction_type == TransactionType.CREDIT.value,
            PointsLedger.target_wallet_id == wallet_id,
            PointsLedger.created_at >= first_day,
        ).scalar() or 0

    def get_ledger_query(self, wallet_id: int):
        return self.db.query(PointsLedger).filter(
            or_(
                PointsLedger.source_wallet_id == wallet_id,
                PointsLedger.target_wallet_id == wallet_id,
            )
        )

    # --- Aggregates ---
    def get_total_redeemed(self, user_id: int) -> int:
        return self.db.query(func.sum(Redemption.points_used)).filter(
            Redemption.user_id == user_id,
        ).scalar() or 0

    def get_total_converted(self, user_id: int) -> int:
        return self.db.query(func.sum(PointsConversion.points_converted)).filter(
            PointsConversion.user_id == user_id,
            PointsConversion.status.in_(["APPROVED", "PAID"]),
        ).scalar() or 0

    def get_pending_conversion_count(self, user_id: int) -> int:
        return self.db.query(func.count(PointsConversion.id)).filter(
            PointsConversion.user_id == user_id,
            PointsConversion.status == "PENDING",
        ).scalar() or 0

    def get_pending_conversion_points(self, user_id: int) -> int:
        """Return total points locked in PENDING conversion requests."""
        return self.db.query(func.sum(PointsConversion.points_converted)).filter(
            PointsConversion.user_id == user_id,
            PointsConversion.status == "PENDING",
        ).scalar() or 0

    def get_expiring_points(self, user_id: int, on_date: date) -> int:
        return self.db.query(func.sum(PointsBatch.remaining_points)).filter(
            PointsBatch.user_id == user_id,
            PointsBatch.remaining_points > 0,
            PointsBatch.expiry_date == on_date,
        ).scalar() or 0

    def get_expiring_points_range(self, user_id: int, after: date, until: date) -> int:
        return self.db.query(func.sum(PointsBatch.remaining_points)).filter(
            PointsBatch.user_id == user_id,
            PointsBatch.remaining_points > 0,
            PointsBatch.expiry_date > after,
            PointsBatch.expiry_date <= until,
        ).scalar() or 0

    # --- Pending conversions for history ---
    def get_pending_conversions_paginated(
        self, user_id: int, skip: int, limit: int
    ) -> Tuple[int, List[PointsConversion]]:
        query = self.db.query(PointsConversion).filter(
            PointsConversion.user_id == user_id,
            PointsConversion.status == "PENDING",
        )
        total = query.count()
        rows = query.order_by(desc(PointsConversion.requested_at)).offset(skip).limit(limit).all()
        return total, rows

    def get_pending_conversions_all(self, user_id: int) -> List[PointsConversion]:
        return self.db.query(PointsConversion).filter(
            PointsConversion.user_id == user_id,
            PointsConversion.status == "PENDING",
        ).order_by(desc(PointsConversion.requested_at)).all()

    # --- Enrichment lookups ---
    def get_ecard(self, ecard_id: int) -> Optional[ECard]:
        return self.db.query(ECard).filter(ECard.id == ecard_id).first()

    def get_badge(self, badge_id: int) -> Optional[Badge]:
        return self.db.query(Badge).filter(Badge.id == badge_id).first()

    def get_reward(self, reward_id: int) -> Optional[Reward]:
        return self.db.query(Reward).filter(Reward.id == reward_id).first()

    def get_redemption(self, redemption_id: int) -> Optional[Redemption]:
        return self.db.query(Redemption).filter(Redemption.id == redemption_id).first()

    def get_award(self, award_id: int) -> Optional[Award]:
        return self.db.query(Award).filter(Award.id == award_id).first()

    def get_award_type(self, award_type_id: int) -> Optional[AwardType]:
        return self.db.query(AwardType).filter(AwardType.id == award_type_id).first()

    def get_conversion(self, conversion_id: int) -> Optional[PointsConversion]:
        return self.db.query(PointsConversion).filter(PointsConversion.id == conversion_id).first()

    # --- Expiry forecast ---
    def get_expiry_forecast(self, target_date: date):
        today = date.today()
        return self.db.query(
            PointsBatch.expiry_date,
            func.sum(PointsBatch.remaining_points).label("total_points"),
            func.count(PointsBatch.user_id.distinct()).label("user_count"),
        ).filter(
            PointsBatch.remaining_points > 0,
            PointsBatch.expiry_date <= target_date,
            PointsBatch.expiry_date >= today,
        ).group_by(PointsBatch.expiry_date).order_by(PointsBatch.expiry_date).all()

    # --- Transaction helpers ---
    def commit(self) -> None:
        self.db.commit()

    def refresh(self, obj) -> None:
        self.db.refresh(obj)

    def add(self, obj) -> None:
        self.db.add(obj)

    def notification_exists(self, source_type: str, source_id: int) -> bool:
        return self.db.query(Notification).filter(
            Notification.source_type == source_type,
            Notification.source_id == source_id,
        ).first() is not None
