from typing import Optional, Tuple, List

from sqlalchemy.orm import Session

from app.models.notifications import Notification
from app.models.points_batches import PointsBatch
from app.utils.query_loader import QueryLoader


class NotificationRepository:
    def __init__(self, db: Session):
        self.db = db
        loader = QueryLoader()
        self.q = loader.get_queries(Notification)
        self.batch_q = loader.get_queries(PointsBatch)

    # ── helpers ──────────────────────────────────────────────────────────────

    def _fetch_by_id(self, new_id: int):
        return self.db.execute(self.q.GET_BY_ID, {"id": new_id}).mappings().fetchone()

    # ── public API ───────────────────────────────────────────────────────────

    def create(
        self, user_id: int, message: str, source_type: str, source_id: int
    ):
        result = self.db.execute(
            self.q.CREATE,
            {
                "user_id": user_id,
                "message": message,
                "source_type": source_type,
                "source_id": source_id,
            },
        )
        self.db.commit()
        return self._fetch_by_id(result.lastrowid)

    def get_by_user_paginated(
        self, user_id: int, unread_only: bool, skip: int, limit: int
    ) -> Tuple[int, List]:
        count_q = (
            self.q.COUNT_BY_USER_UNREAD if unread_only else self.q.COUNT_BY_USER
        )
        data_q = (
            self.q.GET_BY_USER_UNREAD_PAGINATED
            if unread_only
            else self.q.GET_BY_USER_PAGINATED
        )
        total = self.db.execute(count_q, {"user_id": user_id}).scalar()
        items = (
            self.db.execute(data_q, {"user_id": user_id, "limit": limit, "skip": skip})
            .mappings()
            .fetchall()
        )
        return total, list(items)

    def get_unread_count(self, user_id: int) -> int:
        return (
            self.db.execute(self.q.COUNT_BY_USER_UNREAD, {"user_id": user_id}).scalar()
            or 0
        )

    def mark_read(self, notification_id: int, user_id: int) -> bool:
        result = self.db.execute(
            self.q.MARK_READ, {"id": notification_id, "user_id": user_id}
        )
        self.db.commit()
        return result.rowcount > 0

    def mark_all_read(self, user_id: int) -> None:
        self.db.execute(self.q.MARK_ALL_READ, {"user_id": user_id})
        self.db.commit()

    def find_by_source(self, source_type: str, source_id: int) -> Optional[object]:
        return (
            self.db.execute(
                self.q.FIND_BY_SOURCE,
                {"source_type": source_type, "source_id": source_id},
            )
            .mappings()
            .fetchone()
        )

    def find_by_user_source_message_like(
        self, user_id: int, source_type: str, message_pattern: str
    ) -> Optional[object]:
        return (
            self.db.execute(
                self.q.FIND_BY_USER_SOURCE_LIKE,
                {
                    "user_id": user_id,
                    "source_type": source_type,
                    "pattern": message_pattern,
                },
            )
            .mappings()
            .fetchone()
        )

    def get_expiring_batches_grouped(self, expiry_date, min_points: int = 0):
        return (
            self.db.execute(
                self.batch_q.GET_GROUPED_EXPIRING_ON,
                {"expiry_date": expiry_date, "min_points": min_points},
            )
            .mappings()
            .fetchall()
        )

