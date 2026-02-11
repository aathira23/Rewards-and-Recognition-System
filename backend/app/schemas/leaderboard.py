from pydantic import BaseModel
from typing import List, Optional

class LeaderboardEntry(BaseModel):
    user_id: int
    name: str
    email: str
    department: Optional[str] = None
    profile_picture: Optional[str] = None
    rank: int
    score: int  # Points or Count
    recognitions_received: int

class LeaderboardResponse(BaseModel):
    period: str
    metric: str
    entries: List[LeaderboardEntry]
