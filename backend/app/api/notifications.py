"""
Notifications API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user_id, get_current_user
from app.schemas.notifications import NotificationResponse

from app.utils.response import success

from app.services.notification_service import NotificationService
from app.utils.response import success, client_error

router = APIRouter()


@router.get("/", response_model=List[NotificationResponse])
def get_notifications(
    skip: int = 0,
    limit: int = 20,
    unread_only: bool = False,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get list of user notifications."""
    service = NotificationService(db)
    notifications = service.get_user_notifications(
        user_id=current_user_id,
        unread_only=unread_only,
        skip=skip,
        limit=limit
    )
    
    data = [NotificationResponse.model_validate(n) for n in notifications]
    return success(data=data, message="Notifications retrieved")


@router.get("/unread-count")
def get_unread_count(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get count of unread notifications."""
    service = NotificationService(db)
    count = service.get_unread_count(current_user_id)
    return success(data={"unread_count": count}, message="Unread count retrieved")


@router.post("/{notification_id}/read")
def mark_notification_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Mark a specific notification as read."""
    service = NotificationService(db)
    updated = service.mark_as_read(notification_id, current_user_id)
    if not updated:
        return client_error(message="Notification not found or access denied", status_code=404)
        
    return success(message="Notification marked as read")


@router.post("/read-all")
def mark_all_read(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Mark all unread notifications as read."""
    service = NotificationService(db)
    service.mark_all_as_read(current_user_id)
    return success(message="All notifications marked as read")
@router.post("/send-expiry-reminders")
def send_expiry_reminders(
    days_before: int = 7,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Trigger expiry reminder notifications (Admin/HR only)."""
    if current_user.role != "HR":
        return client_error(message="Access denied. Only HR can trigger reminders.", status_code=403)

    service = NotificationService(db)
    sent_count = service.send_expiry_reminders(days_before=days_before)
    return success(data={"sent_count": sent_count}, message=f"Successfully sent {sent_count} expiry reminders.")
