from sqlalchemy.orm import Session
from sqlalchemy import extract, or_, and_
from datetime import date, timedelta
from typing import List, Dict, Any
from app.models.users import User
from app.models.celebrations import Celebration

class CelebrationService:
    def __init__(self, db: Session):
        self.db = db

    def get_upcoming_celebrations(self, days: int = 7) -> List[Dict[str, Any]]:
        """Get users with birthdays or anniversaries in the next N days."""
        today = date.today()
        upcoming = []
        
        # Check for next N days
        for i in range(days + 1):
            target_date = today + timedelta(days=i)
            
            # Birthdays
            birthday_users = self.db.query(User).filter(
                extract('month', User.birth_date) == target_date.month,
                extract('day', User.birth_date) == target_date.day
            ).all()
            
            for user in birthday_users:
                upcoming.append({
                    "user_id": user.id,
                    "user_name": user.name,
                    "celebration_type": "BIRTHDAY",
                    "date": target_date.strftime("%Y-%m-%d"),
                    "year": target_date.year,
                    "points_awarded": 0 # Placeholder as it hasn't happened yet
                })
                
            # Anniversaries
            anniversary_users = self.db.query(User).filter(
                extract('month', User.date_of_joining) == target_date.month,
                extract('day', User.date_of_joining) == target_date.day
            ).all()
            
            for user in anniversary_users:
                years = target_date.year - user.date_of_joining.year
                if years > 0:
                    upcoming.append({
                        "user_id": user.id,
                        "user_name": user.name,
                        "celebration_type": "ANNIVERSARY",
                        "date": target_date.strftime("%Y-%m-%d"),
                        "year": target_date.year,
                        "years_of_service": years,
                        "points_awarded": 0
                    })
                    
        return upcoming

    def get_celebration_history(self, skip: int = 0, limit: int = 20) -> List[Celebration]:
        """Get list of past celebration awards."""
        return self.db.query(Celebration).order_by(Celebration.created_at.desc()).offset(skip).limit(limit).all()
