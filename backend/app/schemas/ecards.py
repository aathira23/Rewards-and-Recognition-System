"""
ECard schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class ECardBase(BaseModel):
    """Base ecard schema."""
    badge_id: int
    message: Optional[str] = None


class ECardCreate(ECardBase):
    """Schema for creating an ecard."""
    receiver_id: int


class ECardResponse(ECardBase):
    """Schema for ecard response."""
    id: int
    sender_id: int
    points_awarded: int
    created_at: datetime

    class Config:
        from_attributes = True
