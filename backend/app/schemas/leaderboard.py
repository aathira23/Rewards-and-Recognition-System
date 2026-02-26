from pydantic import BaseModel
from typing import List, Optional

class LeaderboardEntry(BaseModel):
    user_id: int
    name: str
    department_name: Optional[str] = None
    rank: int
    score: int  # Points or Count
    recognitions_received: int

class LeaderboardResponse(BaseModel):
    period: str
    metric: str
    entries: List[LeaderboardEntry]
