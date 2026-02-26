from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.notifications import Notification


class NotificationService:
    """Service for managing notifications."""

    def __init__(self, db: Session):
        self.db = db

    def create_notification(
        self,
        user_id: int,
        message: str,
        source_type: str,
        source_id: int
    ) -> Notification:
        """Create a notification for a user."""
        notification = Notification(
            user_id=user_id,
            message=message,
            source_type=source_type,
            source_id=source_id
        )
        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)
        return notification

    def get_user_notifications(
        self,
        user_id: int,
        unread_only: bool = False,
        page: int = 1,
        per_page: int = 20
    ):
        """Get notifications for a user. Returns (total, items)."""
        from app.utils.constants import clamp_pagination
        page, per_page, skip = clamp_pagination(page, per_page)
        query = self.db.query(Notification).filter(Notification.user_id == user_id)
        
        if unread_only:
            query = query.filter(Notification.is_read == False)

        total = query.count()
        items = query.order_by(Notification.created_at.desc()).offset(skip).limit(per_page).all()
        return total, items

    def get_unread_count(self, user_id: int) -> int:
        """Get count of unread notifications."""
        return self.db.query(Notification).filter(
            Notification.user_id == user_id,
            Notification.is_read == False
        ).count()

    def mark_as_read(self, notification_id: int, user_id: int) -> bool:
        """Mark a notification as read."""
        notification = self.db.query(Notification).filter(
            Notification.id == notification_id,
            Notification.user_id == user_id
        ).first()
        
        if not notification:
            return False
            
        notification.is_read = True
        self.db.commit()
        return True

    def mark_all_as_read(self, user_id: int):
        """Mark all notifications as read for a user."""
        self.db.query(Notification).filter(
            Notification.user_id == user_id,
            Notification.is_read == False
        ).update({"is_read": True}, synchronize_session=False)
        self.db.commit()

    def send_email_notification(self, user_id: int, subject: str, body: str):
        """Send email notification (integration point)."""
        # Placeholder for email service integration
        pass
    def send_expiry_reminders(self, days_before: int = 7) -> int:
        """Send notifications to users whose points are expiring soon."""
        from app.models.points_batches import PointsBatch
        from sqlalchemy import func
        from datetime import date, timedelta

        expiry_target = date.today() + timedelta(days=days_before)
        
        # 1. Find all batches expiring on the target date
        expiring_batches = self.db.query(
            PointsBatch.user_id,
            func.sum(PointsBatch.remaining_points).label('total_expiring')
        ).filter(
            PointsBatch.expiry_date == expiry_target,
            PointsBatch.remaining_points > 0
        ).group_by(PointsBatch.user_id).all()

        count = 0
        for batch in expiring_batches:
            msg = f"Friendly Reminder: {int(batch.total_expiring)} of your points will expire on {expiry_target.strftime('%d %b %Y')}. Don't forget to spend them!"
            
            # 2. Avoid duplicate notifications for the same day
            existing = self.db.query(Notification).filter(
                Notification.user_id == batch.user_id,
                Notification.source_type == "EXPIRY_REMINDER",
                Notification.message.like(f"%{expiry_target.strftime('%d %b %Y')}%")
            ).first()

            if not existing:
                self.create_notification(
                    user_id=batch.user_id,
                    message=msg,
                    source_type="EXPIRY_REMINDER",
                    source_id=0
                )
                count += 1
        
        return count
