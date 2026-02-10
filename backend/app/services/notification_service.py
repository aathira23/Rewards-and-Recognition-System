"""
Notification service - Business logic for notifications.
"""
from sqlalchemy.orm import Session
from typing import List, Optional


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
    ):
        """Create a notification for a user."""
        # TODO: Implement create notification
        # 1. Create notification record
        # 2. Optionally send email (integrate with email service)
        pass
    
    def get_user_notifications(
        self,
        user_id: int,
        unread_only: bool = False,
        skip: int = 0,
        limit: int = 20
    ):
        """Get notifications for a user."""
        # TODO: Implement get notifications
        pass
    
    def mark_as_read(self, notification_id: int, user_id: int):
        """Mark a notification as read."""
        # TODO: Implement mark as read
        # Verify notification belongs to user
        pass
    
    def mark_all_as_read(self, user_id: int):
        """Mark all notifications as read for a user."""
        # TODO: Implement mark all as read
        pass
    
    def send_email_notification(self, user_id: int, subject: str, body: str):
        """Send email notification (integration point)."""
        # TODO: Implement email sending
        # Integrate with email service (SMTP, SendGrid, etc.)
        pass
