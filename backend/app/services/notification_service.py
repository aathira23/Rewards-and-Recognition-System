from sqlalchemy.orm import Session
from app.models.notifications import Notification
from app.jobs.email_worker import enqueue_email


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

    def __init__(self, db: Session):
        self.db = db

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
        """Create an in-app notification and optionally enqueue an email.

        Parameters
        ----------
        email_event_type : str | None
            Explicit ``EmailEventType`` value.  When *None* the method
            attempts an automatic lookup via ``_SOURCE_TO_EMAIL_EVENT``.
        email_context : dict | None
            Extra Jinja2 context passed to the email template.
        """
        notification = Notification(
            user_id=user_id,
            message=message,
            source_type=source_type,
            source_id=source_id
        )
        self.db.add(notification)
        self.db.commit()
        self.db.refresh(notification)

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
        """Send email notification via background worker."""
        from app.utils.enums import EmailEventType
        enqueue_email(
            event_type=EmailEventType.HR_CRITICAL,
            recipient_user_id=user_id,
            context={"short_reason": subject, "detailed_message": body},
        )
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
