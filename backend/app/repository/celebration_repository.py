from typing import Optional, List, Tuple
from datetime import date

from sqlalchemy import func, extract
from sqlalchemy.orm import Session

from app.models.celebrations import Celebration
from app.models.points_policy import PointsPolicy
from app.models.users import User


class CelebrationRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_users_by_date_field(self, field: str, month: int, day: int) -> List[User]:
        """Get users whose birth_date or date_of_joining matches the given month/day."""
        col = getattr(User, field)
        return self.db.query(User).filter(
            extract("month", col) == month,
            extract("day", col) == day,
        ).all()

    def get_celebration(
        self, user_id: int, celebration_type: str, year: int
    ) -> Optional[Celebration]:
        return self.db.query(Celebration).filter(
            Celebration.user_id == user_id,
            Celebration.celebration_type == celebration_type,
            Celebration.year == year,
        ).first()

    def create_celebration(
        self, user_id: int, celebration_type: str, year: int, points: int
    ) -> Celebration:
        celebration = Celebration(
            user_id=user_id,
            celebration_type=celebration_type,
            year=year,
            points_awarded=points,
        )
        self.db.add(celebration)
        self.db.flush()
        return celebration

    def get_history_paginated(self, skip: int, limit: int) -> Tuple[int, List[Celebration]]:
        query = self.db.query(Celebration).order_by(Celebration.created_at.desc())
        total = query.count()
        items = query.offset(skip).limit(limit).all()
        return total, items

    def get_policy_points(self, event_key: str) -> Optional[int]:
        policy = self.db.query(PointsPolicy).filter(
            PointsPolicy.recognition_type == "CELEBRATION",
            PointsPolicy.event_key == event_key,
            PointsPolicy.is_active == True,
        ).first()
        return policy.points if policy else None

    def commit(self) -> None:
        self.db.commit()
