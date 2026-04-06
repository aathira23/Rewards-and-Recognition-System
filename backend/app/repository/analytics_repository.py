from typing import Optional, List, Dict, Any
from datetime import date

from sqlalchemy import func, extract
from sqlalchemy.orm import Session

from app.models.recognition_feed import RecognitionFeed
from app.models.redemptions import Redemption
from app.models.rewards import Reward
from app.models.wallets import Wallet
from app.models.wallet_funding import WalletFunding
from app.models.points_conversion import PointsConversion
from app.models.points_ledger import PointsLedger
from app.models.points_batches import PointsBatch
from app.utils.enums import WalletType, ConversionStatus


class AnalyticsRepository:
    def __init__(self, db: Session):
        self.db = db

    # --- Recognition queries ---
    def get_recognitions(
        self,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
        receiver_ids: Optional[List[int]] = None,
    ) -> List[RecognitionFeed]:
        query = self.db.query(RecognitionFeed)
        if from_date:
            query = query.filter(RecognitionFeed.created_at >= from_date)
        if to_date:
            query = query.filter(RecognitionFeed.created_at <= to_date)
        if receiver_ids is not None:
            query = query.filter(RecognitionFeed.receiver_id.in_(receiver_ids))
        return query.order_by(RecognitionFeed.created_at.desc()).all()

    def get_points_for_recognition(
        self, source_type: str, source_id: int, receiver_id: int
    ) -> Optional[int]:
        row = self.db.query(PointsLedger.points).join(
            Wallet, PointsLedger.target_wallet_id == Wallet.id
        ).filter(
            PointsLedger.reference_type == source_type,
            PointsLedger.reference_id == source_id,
            PointsLedger.transaction_type == "CREDIT",
            Wallet.user_id == receiver_id,
        ).first()
        return row[0] if row else None

    # --- Redemption queries ---
    def get_redemptions(
        self, from_date: Optional[date] = None, to_date: Optional[date] = None
    ) -> List[Redemption]:
        query = self.db.query(Redemption).join(Reward)
        if from_date:
            query = query.filter(Redemption.created_at >= from_date)
        if to_date:
            query = query.filter(Redemption.created_at <= to_date)
        return query.order_by(Redemption.created_at.desc()).all()

    # --- Wallet utilization ---
    def get_manager_wallet(self, user_id: int) -> Optional[Wallet]:
        return self.db.query(Wallet).filter(
            Wallet.user_id == user_id,
            Wallet.wallet_type == WalletType.MANAGER.value,
        ).first()

    def get_total_funding(self, wallet_id: int) -> int:
        return self.db.query(func.sum(WalletFunding.points)).filter(
            WalletFunding.manager_wallet_id == wallet_id,
        ).scalar() or 0

    # --- Payroll ---
    def get_approved_conversions(self, year: int, month: int) -> List[PointsConversion]:
        return self.db.query(PointsConversion).filter(
            PointsConversion.status == ConversionStatus.APPROVED.value,
            extract("year", PointsConversion.approved_at) == year,
            extract("month", PointsConversion.approved_at) == month,
        ).all()

    # --- Dashboard metrics ---
    def count_recognitions(
        self,
        user_ids: Optional[List[int]],
        from_date: Optional[date],
        to_date: Optional[date],
    ) -> int:
        return self.db.query(func.count(RecognitionFeed.id)).filter(
            RecognitionFeed.receiver_id.in_(user_ids) if user_ids is not None else True,
            RecognitionFeed.created_at >= from_date if from_date else True,
            RecognitionFeed.created_at <= to_date if to_date else True,
        ).scalar() or 0

    def sum_points_distributed(
        self,
        user_ids: Optional[List[int]],
        from_date: Optional[date],
        to_date: Optional[date],
    ) -> int:
        return self.db.query(func.sum(PointsLedger.points)).join(
            Wallet, PointsLedger.target_wallet_id == Wallet.id
        ).filter(
            Wallet.user_id.in_(user_ids) if user_ids is not None else True,
            Wallet.wallet_type == WalletType.EMPLOYEE.value,
            PointsLedger.transaction_type == "CREDIT",
            PointsLedger.created_at >= from_date if from_date else True,
            PointsLedger.created_at <= to_date if to_date else True,
        ).scalar() or 0

    # --- Trends and rankings ---
    def get_recognition_trends(
        self, user_ids: Optional[List[int]], from_date: Optional[date], to_date: Optional[date]
    ):
        query = self.db.query(
            func.date(RecognitionFeed.created_at).label("date"),
            func.count(RecognitionFeed.id).label("count"),
        )
        if user_ids is not None:
            query = query.filter(RecognitionFeed.receiver_id.in_(user_ids))
        if from_date:
            query = query.filter(RecognitionFeed.created_at >= from_date)
        if to_date:
            query = query.filter(RecognitionFeed.created_at <= to_date)
        return query.group_by(func.date(RecognitionFeed.created_at)).order_by("date").all()

    def get_top_recognizers(self, user_ids: Optional[List[int]], limit: int = 5):
        """Return (actor_id, count) – names resolved by caller via User Service."""
        query = self.db.query(
            RecognitionFeed.actor_id,
            func.count(RecognitionFeed.id).label("count"),
        )
        if user_ids is not None:
            query = query.filter(RecognitionFeed.actor_id.in_(user_ids))
        return query.group_by(RecognitionFeed.actor_id).order_by(func.count(RecognitionFeed.id).desc()).limit(limit).all()

    def get_top_recognized(self, user_ids: Optional[List[int]], limit: int = 5):
        """Return (receiver_id, count) – names resolved by caller via User Service."""
        query = self.db.query(
            RecognitionFeed.receiver_id,
            func.count(RecognitionFeed.id).label("count"),
        )
        if user_ids is not None:
            query = query.filter(RecognitionFeed.receiver_id.in_(user_ids))
        return query.group_by(RecognitionFeed.receiver_id).order_by(func.count(RecognitionFeed.id).desc()).limit(limit).all()

    def get_active_user_count(self, user_ids: Optional[List[int]]) -> int:
        query_received = self.db.query(RecognitionFeed.receiver_id.label("uid"))
        query_sent = self.db.query(RecognitionFeed.actor_id.label("uid"))
        if user_ids is not None:
            query_received = query_received.filter(RecognitionFeed.receiver_id.in_(user_ids))
            query_sent = query_sent.filter(RecognitionFeed.actor_id.in_(user_ids))
        return query_received.union(query_sent).distinct().count()

    def count_recognitions_for_users(
        self,
        user_ids: List[int],
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
    ) -> int:
        query = self.db.query(func.count(RecognitionFeed.id)).filter(
            RecognitionFeed.receiver_id.in_(user_ids),
        )
        if from_date:
            query = query.filter(RecognitionFeed.created_at >= from_date)
        if to_date:
            query = query.filter(RecognitionFeed.created_at <= to_date)
        return query.scalar() or 0

    def sum_points_for_users(
        self,
        user_ids: List[int],
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
    ) -> int:
        query = self.db.query(func.sum(PointsLedger.points)).join(
            Wallet, PointsLedger.target_wallet_id == Wallet.id
        ).filter(
            Wallet.user_id.in_(user_ids),
            Wallet.wallet_type == WalletType.EMPLOYEE.value,
            PointsLedger.transaction_type == "CREDIT",
        )
        if from_date:
            query = query.filter(PointsLedger.created_at >= from_date)
        if to_date:
            query = query.filter(PointsLedger.created_at <= to_date)
        return query.scalar() or 0

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
