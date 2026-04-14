from typing import Optional, List, Tuple
from datetime import datetime

from sqlalchemy.orm import Session

from app.models.rewards import Reward
from app.models.redemptions import Redemption
from app.models.points_conversion import PointsConversion
from app.models.points_policy import PointsPolicy
from app.utils.enums import ConversionStatus
from app.utils.query_loader import QueryLoader


class StoreRepository:
    def __init__(self, db: Session):
        self.db = db
        loader = QueryLoader()
        self.reward_q = loader.get_queries(Reward)
        self.redemption_q = loader.get_queries(Redemption)
        self.conversion_q = loader.get_queries(PointsConversion)
        self.policy_q = loader.get_queries(PointsPolicy)

    # ── Rewards / Catalog ────────────────────────────────────────────────────

    def get_catalog_paginated(
        self, skip: int, limit: int, include_inactive: bool = False
    ) -> Tuple[int, List]:
        count_q = self.reward_q.GET_CATALOG_COUNT_ALL if include_inactive else self.reward_q.GET_CATALOG_COUNT
        data_q = self.reward_q.GET_CATALOG_ALL if include_inactive else self.reward_q.GET_CATALOG
        total = self.db.execute(count_q).scalar()
        items = self.db.execute(data_q, {"limit": limit, "skip": skip}).mappings().fetchall()
        return total, list(items)

    def get_reward_by_id(self, reward_id: int):
        return self.db.execute(self.reward_q.GET_BY_ID, {"id": reward_id}).mappings().fetchone()

    def create_reward(self, data: dict):
        result = self.db.execute(self.reward_q.CREATE, data)
        self.db.commit()
        return self.db.execute(self.reward_q.GET_BY_ID, {"id": result.lastrowid}).mappings().fetchone()

    def save_reward(self, reward_id: int, **kwargs):
        self.db.execute(self.reward_q.UPDATE, {"id": reward_id, **kwargs})
        self.db.commit()
        return self.db.execute(self.reward_q.GET_BY_ID, {"id": reward_id}).mappings().fetchone()

    # ── Redemptions ──────────────────────────────────────────────────────────

    def create_redemption(
        self, user_id: int, reward_id: int, points_used: int, status: str
    ):
        result = self.db.execute(
            self.redemption_q.CREATE,
            {"user_id": user_id, "reward_id": reward_id, "points_used": points_used, "status": status},
        )
        self.db.commit()
        return self.db.execute(self.redemption_q.GET_BY_ID, {"id": result.lastrowid}).mappings().fetchone()

    def get_redemptions_by_user(self, user_id: int) -> List:
        return (
            self.db.execute(self.redemption_q.GET_BY_USER, {"user_id": user_id})
            .mappings()
            .fetchall()
        )

    # ── Conversions ──────────────────────────────────────────────────────────

    def create_conversion(
        self,
        user_id: int,
        points: int,
        cash_amount: float,
        conversion_type: str,
        status: str,
    ):
        result = self.db.execute(
            self.conversion_q.CREATE,
            {
                "user_id": user_id,
                "points_converted": points,
                "cash_amount": cash_amount,
                "conversion_type": conversion_type,
                "status": status,
            },
        )
        self.db.commit()
        return (
            self.db.execute(self.conversion_q.GET_BY_ID, {"id": result.lastrowid})
            .mappings()
            .fetchone()
        )

    def get_conversion_by_id(self, conversion_id: int):
        return (
            self.db.execute(self.conversion_q.GET_BY_ID, {"id": conversion_id})
            .mappings()
            .fetchone()
        )

    def get_conversions_by_user(self, user_id: int) -> List:
        return (
            self.db.execute(self.conversion_q.GET_BY_USER, {"user_id": user_id})
            .mappings()
            .fetchall()
        )

    def get_all_conversions(self) -> List:
        return self.db.execute(self.conversion_q.GET_ALL).mappings().fetchall()

    def get_pending_conversions(self) -> List:
        return self.db.execute(self.conversion_q.GET_PENDING).mappings().fetchall()

    def has_pending_conversion(self, user_id: int) -> bool:
        cnt = self.db.execute(
            self.conversion_q.HAS_PENDING, {"user_id": user_id}
        ).scalar()
        return (cnt or 0) > 0

    def save_conversion(self, conversion_id: int, status: str, approved_by: Optional[int] = None, approved_at: Optional[datetime] = None):
        self.db.execute(
            self.conversion_q.UPDATE_STATUS,
            {"id": conversion_id, "status": status, "approved_by": approved_by, "approved_at": approved_at},
        )
        self.db.commit()
        return self.db.execute(self.conversion_q.GET_BY_ID, {"id": conversion_id}).mappings().fetchone()

    # ── Policies ─────────────────────────────────────────────────────────────

    def get_policies(self, include_inactive: bool = False) -> List:
        q = self.policy_q.GET_ALL if include_inactive else self.policy_q.GET_ACTIVE
        return self.db.execute(q).mappings().fetchall()

    def get_policy_by_id(self, policy_id: int):
        return (
            self.db.execute(self.policy_q.GET_BY_ID, {"id": policy_id})
            .mappings()
            .fetchone()
        )

    def find_duplicate_policies(
        self,
        recognition_type: str,
        event_key: Optional[str] = None,
        conversion_reward_type: Optional[str] = None,
    ) -> List:
        if recognition_type == "CONVERSION":
            return (
                self.db.execute(
                    self.policy_q.FIND_DUPLICATES_CONVERSION,
                    {"conversion_reward_type": conversion_reward_type},
                )
                .mappings()
                .fetchall()
            )
        if event_key:
            return (
                self.db.execute(
                    self.policy_q.FIND_DUPLICATES_WITH_EVENT_KEY,
                    {"recognition_type": recognition_type, "event_key": event_key},
                )
                .mappings()
                .fetchall()
            )
        return (
            self.db.execute(
                self.policy_q.FIND_DUPLICATES_NO_EVENT_KEY,
                {"recognition_type": recognition_type},
            )
            .mappings()
            .fetchall()
        )

    def create_policy(self, data: dict):
        result = self.db.execute(self.policy_q.CREATE, data)
        self.db.commit()
        return self.db.execute(self.policy_q.GET_BY_ID, {"id": result.lastrowid}).mappings().fetchone()

    def save_policy(self, policy_id: int, **kwargs):
        self.db.execute(self.policy_q.UPDATE, {"id": policy_id, **kwargs})
        self.db.commit()
        return self.db.execute(self.policy_q.GET_BY_ID, {"id": policy_id}).mappings().fetchone()



