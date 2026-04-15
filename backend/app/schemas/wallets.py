"""
Wallet schemas for request/response validation.
"""
from typing import Optional, List
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
    total_allocated: Optional[int] = None
    total_rewarded: Optional[int] = None

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


class WalletRewardResponse(BaseModel):
    batch_id: int | None
    employee_id: int
    points: int
    manager_wallet_balance: int | None


class BulkBudgetAllocationRequest(BaseModel):
    """Schema for bulk budget allocation by HR."""
    points: int
    department_id: Optional[int] = None
    user_ids: Optional[List[int]] = None
    role_filter: Optional[str] = None
