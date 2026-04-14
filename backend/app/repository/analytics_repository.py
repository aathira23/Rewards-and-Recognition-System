from typing import Optional, List
from datetime import date

from sqlalchemy import text
from sqlalchemy.orm import Session

from app.models.recognition_feed import RecognitionFeed
from app.models.redemptions import Redemption
from app.models.wallets import Wallet
from app.models.wallet_funding import WalletFunding
from app.models.points_conversion import PointsConversion
from app.models.points_ledger import PointsLedger
from app.models.points_batches import PointsBatch
from app.utils.enums import WalletType
from app.utils.query_loader import QueryLoader


class AnalyticsRepository:
    def __init__(self, db: Session):
        self.db = db
        loader = QueryLoader()
        self.wallet_q = loader.get_queries(Wallet)
        self.funding_q = loader.get_queries(WalletFunding)
        self.conversion_q = loader.get_queries(PointsConversion)
        self.ledger_q = loader.get_queries(PointsLedger)
        self.batch_q = loader.get_queries(PointsBatch)
        self.feed_q = loader.get_queries(RecognitionFeed)
        self.redemption_q = loader.get_queries(Redemption)

    # ── Helpers ──────────────────────────────────────────────────────────────

    def _exec(self, sql: str, params: dict):
        return self.db.execute(text(sql), params).mappings().fetchall()

    def _scalar(self, sql: str, params: dict):
        return self.db.execute(text(sql), params).scalar()

    # ── Recognition queries ──────────────────────────────────────────────────

    def get_recognitions(
        self,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
        receiver_ids: Optional[List[int]] = None,
    ) -> List:
        clauses, params = [], {}
        if from_date:
            clauses.append("created_at >= :from_date")
            params["from_date"] = from_date
        if to_date:
            clauses.append("created_at <= :to_date")
            params["to_date"] = to_date
        if receiver_ids is not None:
            clauses.append("receiver_id IN :receiver_ids")
            params["receiver_ids"] = tuple(receiver_ids) if receiver_ids else (0,)
        where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
        sql = f"SELECT * FROM recognition_feed {where} ORDER BY created_at DESC"
        return self._exec(sql, params)

    def get_points_for_recognition(
        self, source_type: str, source_id: int, receiver_id: int
    ) -> Optional[int]:
        sql = (
            "SELECT pl.points FROM points_ledger pl "
            "JOIN wallets w ON pl.target_wallet_id = w.id "
            "WHERE pl.reference_type = :source_type "
            "  AND pl.reference_id = :source_id "
            "  AND pl.transaction_type = 'CREDIT' "
            "  AND w.user_id = :receiver_id "
            "LIMIT 1"
        )
        return self._scalar(sql, {"source_type": source_type, "source_id": source_id, "receiver_id": receiver_id})

    # ── Redemption queries ─────────────────────────────────────────────────-─

    def get_redemptions(
        self, from_date: Optional[date] = None, to_date: Optional[date] = None
    ) -> List:
        clauses, params = [], {}
        if from_date:
            clauses.append("r.created_at >= :from_date")
            params["from_date"] = from_date
        if to_date:
            clauses.append("r.created_at <= :to_date")
            params["to_date"] = to_date
        where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
        sql = (
            "SELECT r.*, rw.name AS reward_name, rw.points_required AS reward_points "
            "FROM redemptions r JOIN rewards rw ON r.reward_id = rw.id "
            f"{where} ORDER BY r.created_at DESC"
        )
        return self._exec(sql, params)

    # ── Wallet utilization ───────────────────────────────────────────────────

    def get_manager_wallet(self, user_id: int):
        return (
            self.db.execute(
                self.wallet_q.GET_BY_USER_AND_TYPE,
                {"user_id": user_id, "wallet_type": WalletType.MANAGER.value},
            )
            .mappings()
            .fetchone()
        )

    def get_total_funding(self, wallet_id: int) -> int:
        return int(
            self.db.execute(self.funding_q.SUM_FUNDING, {"wallet_id": wallet_id}).scalar() or 0
        )

    # ── Payroll ──────────────────────────────────────────────────────────────

    def get_approved_conversions(self, year: int, month: int) -> List:
        return (
            self.db.execute(
                self.conversion_q.GET_APPROVED_FOR_PAYROLL,
                {"year": year, "month": month},
            )
            .mappings()
            .fetchall()
        )

    # ── Dashboard metrics ────────────────────────────────────────────────────

    def count_recognitions(
        self,
        user_ids: Optional[List[int]],
        from_date: Optional[date],
        to_date: Optional[date],
    ) -> int:
        clauses, params = [], {}
        if user_ids is not None:
            clauses.append("receiver_id IN :user_ids")
            params["user_ids"] = tuple(user_ids) if user_ids else (0,)
        if from_date:
            clauses.append("created_at >= :from_date")
            params["from_date"] = from_date
        if to_date:
            clauses.append("created_at <= :to_date")
            params["to_date"] = to_date
        where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
        sql = f"SELECT COUNT(id) FROM recognition_feed {where}"
        return int(self._scalar(sql, params) or 0)

    def sum_points_distributed(
        self,
        user_ids: Optional[List[int]],
        from_date: Optional[date],
        to_date: Optional[date],
    ) -> int:
        clauses = ["w.wallet_type = :wallet_type", "pl.transaction_type = 'CREDIT'"]
        params: dict = {"wallet_type": WalletType.EMPLOYEE.value}
        if user_ids is not None:
            clauses.append("w.user_id IN :user_ids")
            params["user_ids"] = tuple(user_ids) if user_ids else (0,)
        if from_date:
            clauses.append("pl.created_at >= :from_date")
            params["from_date"] = from_date
        if to_date:
            clauses.append("pl.created_at <= :to_date")
            params["to_date"] = to_date
        where = "WHERE " + " AND ".join(clauses)
        sql = (
            "SELECT SUM(pl.points) FROM points_ledger pl "
            f"JOIN wallets w ON pl.target_wallet_id = w.id {where}"
        )
        return int(self._scalar(sql, params) or 0)

    # ── Trends and rankings ──────────────────────────────────────────────────

    def get_recognition_trends(
        self, user_ids: Optional[List[int]], from_date: Optional[date], to_date: Optional[date]
    ) -> List:
        clauses, params = [], {}
        if user_ids is not None:
            clauses.append("receiver_id IN :user_ids")
            params["user_ids"] = tuple(user_ids) if user_ids else (0,)
        if from_date:
            clauses.append("created_at >= :from_date")
            params["from_date"] = from_date
        if to_date:
            clauses.append("created_at <= :to_date")
            params["to_date"] = to_date
        where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
        sql = (
            "SELECT DATE(created_at) AS date, COUNT(id) AS count "
            f"FROM recognition_feed {where} "
            "GROUP BY DATE(created_at) ORDER BY date"
        )
        return self._exec(sql, params)

    def get_top_recognizers(self, user_ids: Optional[List[int]], limit: int = 5) -> List:
        clauses, params = [], {"lim": limit}
        if user_ids is not None:
            clauses.append("actor_id IN :user_ids")
            params["user_ids"] = tuple(user_ids) if user_ids else (0,)
        where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
        sql = (
            f"SELECT actor_id, COUNT(id) AS count FROM recognition_feed {where} "
            "GROUP BY actor_id ORDER BY count DESC LIMIT :lim"
        )
        return self._exec(sql, params)

    def get_top_recognized(self, user_ids: Optional[List[int]], limit: int = 5) -> List:
        clauses, params = [], {"lim": limit}
        if user_ids is not None:
            clauses.append("receiver_id IN :user_ids")
            params["user_ids"] = tuple(user_ids) if user_ids else (0,)
        where = ("WHERE " + " AND ".join(clauses)) if clauses else ""
        sql = (
            f"SELECT receiver_id, COUNT(id) AS count FROM recognition_feed {where} "
            "GROUP BY receiver_id ORDER BY count DESC LIMIT :lim"
        )
        return self._exec(sql, params)

    def get_active_user_count(self, user_ids: Optional[List[int]]) -> int:
        clauses_r, clauses_s, params = [], [], {}
        if user_ids is not None:
            uids = tuple(user_ids) if user_ids else (0,)
            clauses_r.append("receiver_id IN :user_ids")
            clauses_s.append("actor_id IN :user_ids")
            params["user_ids"] = uids
        where_r = ("WHERE " + " AND ".join(clauses_r)) if clauses_r else ""
        where_s = ("WHERE " + " AND ".join(clauses_s)) if clauses_s else ""
        sql = (
            f"SELECT COUNT(DISTINCT uid) FROM ("
            f"  SELECT receiver_id AS uid FROM recognition_feed {where_r} "
            f"  UNION SELECT actor_id AS uid FROM recognition_feed {where_s}"
            f") AS combined"
        )
        return int(self._scalar(sql, params) or 0)

    def count_recognitions_for_users(
        self,
        user_ids: List[int],
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
    ) -> int:
        clauses = ["receiver_id IN :user_ids"]
        params: dict = {"user_ids": tuple(user_ids) if user_ids else (0,)}
        if from_date:
            clauses.append("created_at >= :from_date")
            params["from_date"] = from_date
        if to_date:
            clauses.append("created_at <= :to_date")
            params["to_date"] = to_date
        where = "WHERE " + " AND ".join(clauses)
        sql = f"SELECT COUNT(id) FROM recognition_feed {where}"
        return int(self._scalar(sql, params) or 0)

    def sum_points_for_users(
        self,
        user_ids: List[int],
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
    ) -> int:
        clauses = [
            "w.user_id IN :user_ids",
            "w.wallet_type = :wallet_type",
            "pl.transaction_type = 'CREDIT'",
        ]
        params: dict = {
            "user_ids": tuple(user_ids) if user_ids else (0,),
            "wallet_type": WalletType.EMPLOYEE.value,
        }
        if from_date:
            clauses.append("pl.created_at >= :from_date")
            params["from_date"] = from_date
        if to_date:
            clauses.append("pl.created_at <= :to_date")
            params["to_date"] = to_date
        where = "WHERE " + " AND ".join(clauses)
        sql = (
            "SELECT SUM(pl.points) FROM points_ledger pl "
            f"JOIN wallets w ON pl.target_wallet_id = w.id {where}"
        )
        return int(self._scalar(sql, params) or 0)

    # ── Expiry forecast ──────────────────────────────────────────────────────

    def get_expiry_forecast(self, target_date: date) -> List:
        return (
            self.db.execute(self.batch_q.GET_EXPIRY_FORECAST, {"target_date": target_date})
            .mappings()
            .fetchall()
        )
