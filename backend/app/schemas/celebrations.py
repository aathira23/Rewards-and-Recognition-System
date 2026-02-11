"""
Celebration schemas for request/response validation.
"""
from datetime import datetime
from pydantic import BaseModel


class CelebrationBase(BaseModel):
    """Base celebration schema."""
    celebration_type: str
    year: int
    points_awarded: int


class CelebrationResponse(CelebrationBase):
    """Schema for celebration response."""
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True


class CelebrationRetryRequest(BaseModel):
    """Schema for retrying a failed celebration."""
    celebration_id: int
