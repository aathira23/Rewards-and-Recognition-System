from typing import Optional, List, Tuple
from datetime import date

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
from app.utils.enums import WalletType
from app.utils.query_loader import QueryLoader


class PointsRepository:
    def __init__(self, db: Session):
        self.db = db
        loader = QueryLoader()
        self.wallet_q = loader.get_queries(Wallet)
        self.ledger_q = loader.get_queries(PointsLedger)
        self.batch_q = loader.get_queries(PointsBatch)
        self.conversion_q = loader.get_queries(PointsConversion)
        self.redemption_q = loader.get_queries(Redemption)
        self.ecard_q = loader.get_queries(ECard)
        self.award_q = loader.get_queries(Award)
        self.award_type_q = loader.get_queries(AwardType)
        self.badge_q = loader.get_queries(Badge)
        self.reward_q = loader.get_queries(Reward)
        self.notif_q = loader.get_queries(Notification)

    # ── Wallet ───────────────────────────────────────────────────────────────

    def get_employee_wallet(self, user_id: int):
        return (
            self.db.execute(
                self.wallet_q.GET_BY_USER_AND_TYPE,
                {"user_id": user_id, "wallet_type": WalletType.EMPLOYEE.value},
            )
            .mappings()
            .fetchone()
        )

    def create_employee_wallet(self, user_id: int):
        result = self.db.execute(
            self.wallet_q.CREATE,
            {"user_id": user_id, "wallet_type": WalletType.EMPLOYEE.value, "balance": 0},
        )
        self.db.commit()
        return self.db.execute(self.wallet_q.GET_BY_ID, {"id": result.lastrowid}).mappings().fetchone()

    def get_manager_wallet(self, user_id: int):
        return (
            self.db.execute(
                self.wallet_q.GET_BY_USER_AND_TYPE,
                {"user_id": user_id, "wallet_type": WalletType.MANAGER.value},
            )
            .mappings()
            .fetchone()
        )

    # ── Points Balance ───────────────────────────────────────────────────────

    def get_available_balance(self, user_id: int) -> int:
        return int(
            self.db.execute(
                self.batch_q.GET_AVAILABLE_BALANCE, {"user_id": user_id}
            ).scalar()
            or 0
        )

    # ── Points Batches ───────────────────────────────────────────────────────

    def create_batch(
        self, user_id: int, points: int, source_type: str, source_id: int, expiry_date: date
    ):
        result = self.db.execute(
            self.batch_q.CREATE,
            {
                "user_id": user_id,
                "points": points,
                "remaining_points": points,
                "source_type": source_type,
                "source_id": source_id,
                "expiry_date": expiry_date,
            },
        )
        return self.db.execute(self.batch_q.GET_BY_ID, {"id": result.lastrowid}).mappings().fetchone()

    def get_fifo_batches(self, user_id: int) -> List:
        return (
            self.db.execute(self.batch_q.GET_FIFO_BATCHES, {"user_id": user_id})
            .mappings()
            .fetchall()
        )

    def get_expired_batches(self, user_id: int) -> List:
        return (
            self.db.execute(self.batch_q.GET_EXPIRED_BATCHES, {"user_id": user_id})
            .mappings()
            .fetchall()
        )

    def get_expired_batches_paginated(
        self, user_id: int, skip: int, limit: int
    ) -> Tuple[int, List]:
        total = self.db.execute(
            self.batch_q.GET_EXPIRED_BATCHES_COUNT, {"user_id": user_id}
        ).scalar()
        rows = (
            self.db.execute(
                self.batch_q.GET_EXPIRED_BATCHES_PAGINATED,
                {"user_id": user_id, "limit": limit, "skip": skip},
            )
            .mappings()
            .fetchall()
        )
        return total, list(rows)

    def get_upcoming_expiry_batches(self, cutoff: date) -> List:
        return (
            self.db.execute(self.batch_q.GET_UPCOMING_EXPIRY, {"cutoff": cutoff})
            .mappings()
            .fetchall()
        )

    def get_all_expired_unprocessed(self) -> List:
        return self.db.execute(self.batch_q.GET_ALL_EXPIRED_UNPROCESSED).mappings().fetchall()

    # ── Ledger ───────────────────────────────────────────────────────────────

    def add_ledger_entry(
        self,
        points: int,
        transaction_type: str,
        reference_type: str,
        reference_id: int,
        *,
        source_wallet_id: Optional[int] = None,
        target_wallet_id: Optional[int] = None,
    ):
        result = self.db.execute(
            self.ledger_q.CREATE,
            {
                "source_wallet_id": source_wallet_id,
                "target_wallet_id": target_wallet_id,
                "points": points,
                "transaction_type": transaction_type,
                "reference_type": reference_type,
                "reference_id": reference_id,
            },
        )
        return self.db.execute(self.ledger_q.GET_BY_ID, {"id": result.lastrowid}).mappings().fetchone()

    def get_total_credits(self, wallet_id: int) -> int:
        return int(
            self.db.execute(
                self.ledger_q.SUM_CREDITS_FOR_WALLET, {"wallet_id": wallet_id}
            ).scalar()
            or 0
        )

    def get_month_credits(self, first_day: date) -> int:
        return int(
            self.db.execute(
                self.ledger_q.SUM_CREDITS_SINCE, {"since": first_day}
            ).scalar()
            or 0
        )

    def get_monthly_earned_for_user(self, wallet_id: int, first_day: date) -> int:
        return int(
            self.db.execute(
                self.ledger_q.SUM_MONTHLY_EARNED,
                {"wallet_id": wallet_id, "since": first_day},
            ).scalar()
            or 0
        )

    def get_ledger_query(self, wallet_id: int) -> List:
        return (
            self.db.execute(self.ledger_q.GET_BY_WALLET, {"wallet_id": wallet_id})
            .mappings()
            .fetchall()
        )

    # ── Aggregates ───────────────────────────────────────────────────────────

    def get_total_redeemed(self, user_id: int) -> int:
        return int(
            self.db.execute(
                self.redemption_q.SUM_REDEEMED_BY_USER, {"user_id": user_id}
            ).scalar()
            or 0
        )

    def get_total_converted(self, user_id: int) -> int:
        return int(
            self.db.execute(
                self.conversion_q.SUM_APPROVED_CONVERTED, {"user_id": user_id}
            ).scalar()
            or 0
        )

    def get_pending_conversion_count(self, user_id: int) -> int:
        return int(
            self.db.execute(
                self.conversion_q.COUNT_PENDING, {"user_id": user_id}
            ).scalar()
            or 0
        )

    def get_pending_conversion_points(self, user_id: int) -> int:
        return int(
            self.db.execute(
                self.conversion_q.SUM_PENDING_POINTS, {"user_id": user_id}
            ).scalar()
            or 0
        )

    def get_expiring_points(self, user_id: int, on_date: date) -> int:
        return int(
            self.db.execute(
                self.batch_q.GET_EXPIRING_POINTS_ON_DATE,
                {"user_id": user_id, "on_date": on_date},
            ).scalar()
            or 0
        )

    def get_expiring_points_range(self, user_id: int, after: date, until: date) -> int:
        return int(
            self.db.execute(
                self.batch_q.GET_EXPIRING_POINTS_IN_RANGE,
                {"user_id": user_id, "after": after, "until": until},
            ).scalar()
            or 0
        )

    # ── Pending conversions for history ──────────────────────────────────────

    def get_pending_conversions_paginated(
        self, user_id: int, skip: int, limit: int
    ) -> Tuple[int, List]:
        total = self.db.execute(
            self.conversion_q.GET_PENDING_BY_USER_PAGINATED_COUNT, {"user_id": user_id}
        ).scalar()
        rows = (
            self.db.execute(
                self.conversion_q.GET_PENDING_BY_USER_PAGINATED,
                {"user_id": user_id, "limit": limit, "skip": skip},
            )
            .mappings()
            .fetchall()
        )
        return total, list(rows)

    def get_pending_conversions_all(self, user_id: int) -> List:
        return (
            self.db.execute(
                self.conversion_q.GET_PENDING_BY_USER, {"user_id": user_id}
            )
            .mappings()
            .fetchall()
        )

    # ── Enrichment lookups ───────────────────────────────────────────────────

    def get_ecard(self, ecard_id: int):
        return self.db.execute(self.ecard_q.GET_BY_ID, {"id": ecard_id}).mappings().fetchone()

    def get_badge(self, badge_id: int):
        return self.db.execute(self.badge_q.GET_BY_ID, {"id": badge_id}).mappings().fetchone()

    def get_reward(self, reward_id: int):
        return self.db.execute(self.reward_q.GET_BY_ID, {"id": reward_id}).mappings().fetchone()

    def get_redemption(self, redemption_id: int):
        return self.db.execute(self.redemption_q.GET_BY_ID, {"id": redemption_id}).mappings().fetchone()

    def get_award(self, award_id: int):
        return self.db.execute(self.award_q.GET_BY_ID, {"id": award_id}).mappings().fetchone()

    def get_award_type(self, award_type_id: int):
        return self.db.execute(self.award_type_q.GET_BY_ID, {"id": award_type_id}).mappings().fetchone()

    def get_conversion(self, conversion_id: int):
        return self.db.execute(self.conversion_q.GET_BY_ID, {"id": conversion_id}).mappings().fetchone()

    # ── Expiry forecast ──────────────────────────────────────────────────────

    def get_expiry_forecast(self, target_date: date) -> List:
        return (
            self.db.execute(self.batch_q.GET_EXPIRY_FORECAST, {"target_date": target_date})
            .mappings()
            .fetchall()
        )

    # ── Transaction helpers ──────────────────────────────────────────────────

    def commit(self) -> None:
        self.db.commit()

    def refresh(self, obj) -> None:
        pass  # not needed with raw SQL

    def add(self, obj) -> None:
        pass  # batch inserts done via execute() in each create_* method

    def notification_exists(self, source_type: str, source_id: int) -> bool:
        row = (
            self.db.execute(
                self.notif_q.FIND_BY_SOURCE,
                {"source_type": source_type, "source_id": source_id},
            )
            .mappings()
            .fetchone()
        )
        return row is not None

