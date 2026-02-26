"""
Badge schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class BadgeBase(BaseModel):
    """Base badge schema."""
    name: str
    description: Optional[str] = None
    icon_url: Optional[str] = None
    points: Optional[int] = None
    is_active: bool = True


class BadgeCreate(BadgeBase):
    """Schema for creating a badge."""
    pass


class BadgeUpdate(BaseModel):
    """Schema for updating a badge."""
    name: Optional[str] = None
    description: Optional[str] = None
    icon_url: Optional[str] = None
    points: Optional[int] = None
    is_active: Optional[bool] = None


class BadgeResponse(BadgeBase):
    """Schema for badge response."""
    id: int
    created_at: datetime

    class Config:
        from_attributes = True
