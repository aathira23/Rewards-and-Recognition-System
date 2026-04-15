"""
ECard schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional, Literal
from pydantic import BaseModel, field_validator


PERSONA_TYPES = ("PERSONAL", "DEPARTMENT")


class ECardBase(BaseModel):
    """Base ecard schema."""
    badge_id: int
    message: Optional[str] = None


class ECardCreate(ECardBase):
    """Schema for creating an ecard."""
    receiver_id: int
    persona_type: Literal["PERSONAL", "DEPARTMENT"] = "PERSONAL"
    persona_label: Optional[str] = None

    @field_validator("persona_type")
    @classmethod
    def normalise_persona_type(cls, v: str) -> str:
        return v.upper()


class UserShortResponse(BaseModel):
    """Minimal user info for nested objects."""
    id: int
    name: str
    department_name: Optional[str] = None

    class Config:
        from_attributes = True

class ECardResponse(ECardBase):
    """Schema for ecard response."""
    id: int
    sender_id: int
    receiver_id: int
    points_awarded: int
    persona_type: str = "PERSONAL"
    persona_label: Optional[str] = None
    created_at: datetime

    sender: Optional[UserShortResponse] = None
    receiver: Optional[UserShortResponse] = None
    badge: Optional["BadgeResponse"] = None

    class Config:
        from_attributes = True

from app.schemas.badges import BadgeResponse
ECardResponse.model_rebuild()
