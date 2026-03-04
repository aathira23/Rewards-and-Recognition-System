"""
Notifications API endpoints.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user_id, get_current_user
from app.schemas.notifications import NotificationResponse

from app.utils.response import success, client_error, paginated_success
from app.utils.constants import (
    DEFAULT_PAGE_SIZE, SUCCESS_NOTIFICATIONS_RETRIEVED, SUCCESS_UNREAD_COUNT_RETRIEVED,
    SUCCESS_ALL_NOTIFICATIONS_MARKED_READ, ERROR_NOTIFICATION_NOT_FOUND,
    SUCCESS_NOTIFICATION_MARKED_READ, ERROR_INVALID_MARK_READ_PARAMS,
    ERROR_ONLY_HR_TRIGGER_REMINDERS, SUCCESS_EXPIRY_REMINDERS_SENT
)

from app.services.notification_service import NotificationService

router = APIRouter()


@router.get("/")
def get_notifications(
    page: int = 1,
    per_page: int = DEFAULT_PAGE_SIZE,
    unread_only: bool = False,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get list of user notifications."""
    service = NotificationService(db)
    total, notifications = service.get_user_notifications(
        user_id=current_user_id,
        unread_only=unread_only,
        page=page,
        per_page=per_page
    )

    data = [NotificationResponse.model_validate(n) for n in notifications]
    return paginated_success(
        items=data,
        total=total,
        page=page,
        per_page=per_page,
        message=SUCCESS_NOTIFICATIONS_RETRIEVED,
    )


@router.get("/unread-count")
def get_unread_count(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get count of unread notifications."""
    service = NotificationService(db)
    count = service.get_unread_count(current_user_id)
    return success(data={"unread_count": count}, message=SUCCESS_UNREAD_COUNT_RETRIEVED)


@router.post("/mark-read")
def mark_notifications_read(
    notification_id: int = None,
    mark_all: bool = False,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Mark notification(s) as read. Provide notification_id for single, or mark_all=true for all."""
    service = NotificationService(db)

    if mark_all:
        service.mark_all_as_read(current_user_id)
        return success(message=SUCCESS_ALL_NOTIFICATIONS_MARKED_READ)
    elif notification_id:
        updated = service.mark_as_read(notification_id, current_user_id)
        if not updated:
            return client_error(message=ERROR_NOTIFICATION_NOT_FOUND, status_code=404)
        return success(message=SUCCESS_NOTIFICATION_MARKED_READ)
    else:
        return client_error(message=ERROR_INVALID_MARK_READ_PARAMS, status_code=400)
@router.post("/send-expiry-reminders")
def send_expiry_reminders(
    days_before: int = 7,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Trigger expiry reminder notifications (Admin/HR only)."""
    if current_user.role != "HR":
        return client_error(message=ERROR_ONLY_HR_TRIGGER_REMINDERS, status_code=403)

    service = NotificationService(db)
    sent_count = service.send_expiry_reminders(days_before=days_before)
    return success(data={"sent_count": sent_count}, message=SUCCESS_EXPIRY_REMINDERS_SENT.format(sent_count))
