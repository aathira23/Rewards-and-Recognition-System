"""
Points Conversion schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional
from decimal import Decimal
from pydantic import BaseModel


class PointsConversionBase(BaseModel):
    """Base points conversion schema."""
    points_converted: int
    conversion_type: str


class PointsConversionCreate(PointsConversionBase):
    """Schema for creating a points conversion request."""
    pass


class PointsConversionResponse(PointsConversionBase):
    """Schema for points conversion response."""
    id: int
    user_id: int
    cash_amount: Decimal
    status: str
    requested_at: datetime
    approved_by: Optional[int]
    approved_at: Optional[datetime]

    class Config:
        from_attributes = True


class PointsConversionActionRequest(BaseModel):
    """Schema for approving/rejecting conversion."""
    action: str  # APPROVE, REJECT
    comments: Optional[str] = None
