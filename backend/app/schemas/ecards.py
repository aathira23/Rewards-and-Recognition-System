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


class UserShortResponse(BaseModel):
    id: int
    name: str

    class Config:
        from_attributes = True

class ECardResponse(ECardBase):
    """Schema for ecard response."""
    id: int
    sender_id: int
    receiver_id: int
    points_awarded: int
    created_at: datetime
    
    sender: Optional[UserShortResponse] = None
    receiver: Optional[UserShortResponse] = None
    badge: Optional["BadgeResponse"] = None

    class Config:
        from_attributes = True

from app.schemas.badges import BadgeResponse
ECardResponse.model_rebuild()
