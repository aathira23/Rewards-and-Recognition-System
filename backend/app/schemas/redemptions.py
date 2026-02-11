"""
Redemption schemas for request/response validation.
"""
from datetime import datetime
from pydantic import BaseModel


class RedemptionBase(BaseModel):
    """Base redemption schema."""
    reward_id: int


class RedemptionCreate(RedemptionBase):
    """Schema for creating a redemption."""
    pass


class RedemptionResponse(RedemptionBase):
    """Schema for redemption response."""
    id: int
    user_id: int
    points_used: int
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
