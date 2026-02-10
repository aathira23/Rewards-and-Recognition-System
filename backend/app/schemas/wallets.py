"""
Wallet schemas for request/response validation.
"""
from datetime import datetime
from pydantic import BaseModel


class WalletBase(BaseModel):
    """Base wallet schema."""
    wallet_type: str
    balance: int = 0


class WalletResponse(WalletBase):
    """Schema for wallet response."""
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class WalletAllocateRequest(BaseModel):
    """Schema for allocating budget to manager wallet."""
    manager_id: int
    points: int


class WalletRewardRequest(BaseModel):
    """Schema for manager rewarding employee."""
    employee_id: int
    points: int
    reason: str
