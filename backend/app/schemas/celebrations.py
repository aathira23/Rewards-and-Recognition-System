from datetime import datetime
from pydantic import BaseModel
from typing import Optional

class CelebrationBase(BaseModel):
    user_id: int
    celebration_type: str  # BIRTHDAY, ANNIVERSARY
    year: int
    points_awarded: int

class CelebrationCreate(CelebrationBase):
    pass

class CelebrationResponse(CelebrationBase):
    id: Optional[int] = None
    user_id: Optional[int] = None
    created_at: Optional[datetime] = None
    user_name: Optional[str] = None
    date: Optional[str] = None
    years_of_service: Optional[int] = None

    class Config:
        from_attributes = True
