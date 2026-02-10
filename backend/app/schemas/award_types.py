"""
Award Type schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class AwardTypeBase(BaseModel):
    """Base award type schema."""
    award_key: str
    name: str
    description: Optional[str] = None
    points: int
    frequency: str
    eligibility_rule: str
    is_active: bool = True


class AwardTypeCreate(AwardTypeBase):
    """Schema for creating an award type."""
    pass


class AwardTypeUpdate(BaseModel):
    """Schema for updating an award type."""
    name: Optional[str] = None
    description: Optional[str] = None
    points: Optional[int] = None
    frequency: Optional[str] = None
    eligibility_rule: Optional[str] = None
    is_active: Optional[bool] = None


class AwardTypeResponse(AwardTypeBase):
    """Schema for award type response."""
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True
