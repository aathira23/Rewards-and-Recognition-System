from typing import Optional, Tuple, List

from sqlalchemy.orm import Session

from app.models.celebrations import Celebration
from app.models.points_policy import PointsPolicy
from app.utils.query_loader import QueryLoader


class CelebrationRepository:
    def __init__(self, db: Session):
        self.db = db
        loader = QueryLoader()
        self.q = loader.get_queries(Celebration)
        self.policy_q = loader.get_queries(PointsPolicy)

    def get_celebration(
        self, user_id: int, celebration_type: str, year: int
    ) -> Optional[object]:
        return (
            self.db.execute(
                self.q.GET_BY_USER_TYPE_YEAR,
                {"user_id": user_id, "celebration_type": celebration_type, "year": year},
            )
            .mappings()
            .fetchone()
        )

    def create_celebration(
        self, user_id: int, celebration_type: str, year: int, points: int
    ):
        result = self.db.execute(
            self.q.CREATE,
            {
                "user_id": user_id,
                "celebration_type": celebration_type,
                "year": year,
                "points_awarded": points,
            },
        )
        return (
            self.db.execute(self.q.GET_BY_ID, {"id": result.lastrowid})
            .mappings()
            .fetchone()
        )

    def get_history_paginated(self, skip: int, limit: int) -> Tuple[int, List]:
        total = self.db.execute(self.q.GET_HISTORY_COUNT).scalar()
        items = (
            self.db.execute(self.q.GET_HISTORY, {"limit": limit, "skip": skip})
            .mappings()
            .fetchall()
        )
        return total, list(items)

    def get_policy_points(self, event_key: str) -> Optional[int]:
        row = (
            self.db.execute(
                self.policy_q.GET_CELEBRATION_POLICY, {"event_key": event_key}
            )
            .mappings()
            .fetchone()
        )
        return row["points"] if row else None

    def commit(self) -> None:
        self.db.commit()
