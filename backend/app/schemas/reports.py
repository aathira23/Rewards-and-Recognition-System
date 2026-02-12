"""
Report schemas for request/response validation.
"""
from datetime import date, datetime
from typing import List, Optional, Any
from pydantic import BaseModel


class ReportBase(BaseModel):
    """Base report schema."""
    report_type: str
    generated_at: datetime = datetime.now()


class RecognitionReportRow(BaseModel):
    id: int
    actor_name: str
    receiver_name: str
    source_type: str
    points: int
    message: Optional[str] = None
    created_at: datetime


class RedemptionReportRow(BaseModel):
    id: int
    user_name: str
    reward_name: str
    points_used: int
    status: str
    created_at: datetime


class WalletUtilizationRow(BaseModel):
    manager_name: str
    total_allocated: int
    total_spent: int
    remaining_balance: int


class PayrollReportRow(BaseModel):
    user_name: str
    employee_id: Optional[str] = None
    points_converted: int
    cash_amount: float
    status: str
    approved_at: Optional[datetime] = None


class ExpiryForecastRow(BaseModel):
    expiry_date: date
    total_points: int
    user_count: int


class ReportResponse(ReportBase):
    """Generic report response."""
    data: List[Any]
    summary: Optional[dict] = None
