"""
Wallet Funding schemas for request/response validation.
"""
from datetime import datetime
from pydantic import BaseModel


class WalletFundingBase(BaseModel):
    """Base wallet funding schema."""
    manager_wallet_id: int
    points: int


class WalletFundingResponse(WalletFundingBase):
    """Schema for wallet funding response."""
    id: int
    funded_by: int
    created_at: datetime
    
    class Config:
        from_attributes = True
