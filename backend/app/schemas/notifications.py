"""
Notification schemas for request/response validation.
"""
from datetime import datetime
from pydantic import BaseModel


class NotificationBase(BaseModel):
    """Base notification schema."""
    message: str
    source_type: str
    source_id: int


class NotificationResponse(NotificationBase):
    """Schema for notification response."""
    id: int
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True
