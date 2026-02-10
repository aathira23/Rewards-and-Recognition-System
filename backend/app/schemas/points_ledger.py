"""
Points Ledger schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class PointsLedgerBase(BaseModel):
    """Base points ledger schema."""
    points: int
    transaction_type: str
    reference_type: str
    reference_id: int


class PointsLedgerResponse(PointsLedgerBase):
    """Schema for points ledger response."""
    id: int
    source_wallet_id: Optional[int]
    target_wallet_id: Optional[int]
    created_at: datetime
    
    class Config:
        from_attributes = True
