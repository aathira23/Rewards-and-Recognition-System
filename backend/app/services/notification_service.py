from sqlalchemy.orm import Session
from typing import Optional
from app.models.notifications import Notification
from app.jobs.email_worker import enqueue_email
from app.repository.notification_repository import NotificationRepository


# Map in-app source_type → EmailEventType for auto-dispatch.
_SOURCE_TO_EMAIL_EVENT: dict = {}  # populated lazily to avoid circular imports


def _get_source_email_map() -> dict:
    """Lazy-load the mapping from source_type to EmailEventType."""
    global _SOURCE_TO_EMAIL_EVENT
    if not _SOURCE_TO_EMAIL_EVENT:
        from app.utils.enums import EmailEventType
        _SOURCE_TO_EMAIL_EVENT = {
            "ECARD": EmailEventType.RECOGNITION_RECEIVED,
            "AWARD": None,           # handled explicitly – approved/rejected differ
            "REDEMPTION": EmailEventType.REDEMPTION_CONFIRMED,
            "CONVERSION": None,      # handled explicitly
            "EXPIRY_REMINDER": EmailEventType.POINTS_EXPIRY_REMINDER,
            "CELEBRATION": EmailEventType.CELEBRATION_REMINDER,
        }
    return _SOURCE_TO_EMAIL_EVENT


class NotificationService:
    """Service for managing notifications."""

    def __init__(self, db: Session, token: Optional[str] = None):
        self.db = db
        self._token = token
        self.repository = NotificationRepository(db)

    def create_notification(
        self,
        user_id: int,
        message: str,
        source_type: str,
        source_id: int,
        *,
        email_event_type: str | None = None,
        email_context: dict | None = None,
    ) -> Notification:
        """Create an in-app notification and optionally enqueue an email."""
        notification = self.repository.create(user_id, message, source_type, source_id)

        # --- Auto-dispatch email (best-effort, non-blocking) ---
        evt = email_event_type
        if evt is None:
            evt = _get_source_email_map().get(source_type)
        if evt is not None:
            ctx = email_context or {}
            enqueue_email(
                event_type=evt,
                recipient_user_id=user_id,
                context=ctx,
                token=self._token,
            )

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
        return self.repository.get_by_user_paginated(user_id, unread_only, skip, per_page)

    def get_unread_count(self, user_id: int) -> int:
        """Get count of unread notifications."""
        return self.repository.get_unread_count(user_id)

    def mark_as_read(self, notification_id: int, user_id: int) -> bool:
        """Mark a notification as read."""
        return self.repository.mark_read(notification_id, user_id)

    def mark_all_as_read(self, user_id: int):
        """Mark all notifications as read for a user."""
        self.repository.mark_all_read(user_id)

    def send_email_notification(self, user_id: int, subject: str, body: str):
        """Send email notification via background worker."""
        from app.utils.enums import EmailEventType
        enqueue_email(
            event_type=EmailEventType.HR_CRITICAL,
            recipient_user_id=user_id,
            context={"short_reason": subject, "detailed_message": body},
            token=self._token,
        )

    def send_expiry_reminders(self, days_before: int = 7) -> int:
        """Send notifications to users whose points are expiring soon."""
        from datetime import date, timedelta

        expiry_target = date.today() + timedelta(days=days_before)

        expiring_batches = self.repository.get_expiring_batches_grouped(expiry_target)

        count = 0
        for batch in expiring_batches:
            msg = f"Friendly Reminder: {int(batch.total_expiring)} of your points will expire on {expiry_target.strftime('%d %b %Y')}. Don't forget to spend them!"

            existing = self.repository.find_by_user_source_message_like(
                batch.user_id, "EXPIRY_REMINDER", f"%{expiry_target.strftime('%d %b %Y')}%"
            )

            if not existing:
                self.create_notification(
                    user_id=batch.user_id,
                    message=msg,
                    source_type="EXPIRY_REMINDER",
                    source_id=0,
                    email_context={
                        "points": int(batch.total_expiring),
                        "expiry_date": expiry_target.strftime('%d %b %Y'),
                        "catalog_url": "",
                        "days_left": days_before,
                    },
                )
                count += 1

        return count
