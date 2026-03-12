from typing import Optional, List, Tuple

from sqlalchemy.orm import Session

from app.models.notifications import Notification


class NotificationRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, user_id: int, message: str, source_type: str, source_id: int) -> Notification:
        notification = Notification(
            user_id=user_id,
            message=message,
            source_type=source_type,
            source_id=source_id,
        )
        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)
        return notification

    def get_by_user_paginated(
        self, user_id: int, unread_only: bool, skip: int, limit: int
    ) -> Tuple[int, List[Notification]]:
        query = self.db.query(Notification).filter(Notification.user_id == user_id)
        if unread_only:
            query = query.filter(Notification.is_read == False)
        total = query.count()
        items = query.order_by(Notification.created_at.desc()).offset(skip).limit(limit).all()
        return total, items

    def get_unread_count(self, user_id: int) -> int:
        return self.db.query(Notification).filter(
            Notification.user_id == user_id,
            Notification.is_read == False,
        ).count()

    def mark_read(self, notification_id: int, user_id: int) -> bool:
        notification = self.db.query(Notification).filter(
            Notification.id == notification_id,
            Notification.user_id == user_id,
        ).first()
        if not notification:
            return False
        notification.is_read = True
        self.db.commit()
        return True

    def mark_all_read(self, user_id: int) -> None:
        self.db.query(Notification).filter(
            Notification.user_id == user_id,
            Notification.is_read == False,
        ).update({"is_read": True}, synchronize_session=False)
        self.db.commit()

    def add_raw(self, notification: Notification) -> None:
        """Add a notification without commit (for batch operations)."""
        self.db.add(notification)

    def find_by_source(self, source_type: str, source_id: int) -> Optional[Notification]:
        return self.db.query(Notification).filter(
            Notification.source_type == source_type,
            Notification.source_id == source_id,
        ).first()

    def find_by_user_source_message_like(
        self, user_id: int, source_type: str, message_pattern: str
    ) -> Optional[Notification]:
        return self.db.query(Notification).filter(
            Notification.user_id == user_id,
            Notification.source_type == source_type,
            Notification.message.like(message_pattern),
        ).first()

    def get_expiring_batches_grouped(self, expiry_date, min_points: int = 0):
        """Get expiring point batches grouped by user for reminder notifications."""
        from sqlalchemy import func
        from app.models.points_batches import PointsBatch

        return self.db.query(
            PointsBatch.user_id,
            func.sum(PointsBatch.remaining_points).label("total_expiring"),
        ).filter(
            PointsBatch.expiry_date == expiry_date,
            PointsBatch.remaining_points > min_points,
        ).group_by(PointsBatch.user_id).all()
