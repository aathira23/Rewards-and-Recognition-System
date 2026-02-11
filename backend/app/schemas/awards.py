"""
Award schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class AwardBase(BaseModel):
    """Base award schema."""
    award_type_id: int


class AwardNominationCreate(AwardBase):
    """Schema for creating an award nomination."""
    nominee_id: int
    justification: Optional[str] = None


class AwardResponse(AwardBase):
    """Schema for award response."""
    id: int
    nominee_id: int
    nominator_id: int
    status: str
    points_awarded: Optional[int]
    created_at: datetime

    class Config:
        from_attributes = True


class AwardActionRequest(BaseModel):
    """Schema for approving/rejecting award."""
    action: str  # APPROVE, REJECT
    comments: Optional[str] = None
