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

    def process_today_celebrations(self) -> Dict[str, int]:
        """Process today's birthdays and anniversaries - award points and create notifications."""
        from app.services.points_service import PointsService
        from app.services.notification_service import NotificationService
        from app.utils.enums import ReferenceType
        
        points_service = PointsService(self.db)
        notification_service = NotificationService(self.db)
        
        today = date.today()
        birthday_count = 0
        anniversary_count = 0
        
        # Process Birthdays
        birthday_users = self.db.query(User).filter(
            extract('month', User.birth_date) == today.month,
            extract('day', User.birth_date) == today.day
        ).all()
        
        for user in birthday_users:
            # Check if already processed today
            existing = self.db.query(Celebration).filter(
                Celebration.user_id == user.id,
                Celebration.celebration_type == "BIRTHDAY",
                extract('year', Celebration.created_at) == today.year,
                extract('month', Celebration.created_at) == today.month,
                extract('day', Celebration.created_at) == today.day
            ).first()
            
            if not existing:
                # Award birthday points (e.g., 500 points)
                points_service.award_points(
                    user_id=user.id,
                    points=500,
                    source_type=ReferenceType.CELEBRATION.value,
                    source_id=0
                )
                
                # Create celebration record
                celebration = Celebration(
                    user_id=user.id,
                    celebration_type="BIRTHDAY",
                    points_awarded=500
                )
                self.db.add(celebration)
                
                # Send notification
                notification_service.create_notification(
                    user_id=user.id,
                    message=f"🎉 Happy Birthday! You've been awarded 500 points to celebrate your special day!",
                    source_type="CELEBRATION",
                    source_id=0
                )
                birthday_count += 1
        
        # Process Anniversaries
        anniversary_users = self.db.query(User).filter(
            extract('month', User.date_of_joining) == today.month,
            extract('day', User.date_of_joining) == today.day
        ).all()
        
        for user in anniversary_users:
            years = today.year - user.date_of_joining.year
            if years > 0:  # Must be at least 1 year
                # Check if already processed
                existing = self.db.query(Celebration).filter(
                    Celebration.user_id == user.id,
                    Celebration.celebration_type == "ANNIVERSARY",
                    extract('year', Celebration.created_at) == today.year,
                    extract('month', Celebration.created_at) == today.month,
                    extract('day', Celebration.created_at) == today.day
                ).first()
                
                if not existing:
                    # Award points based on years (e.g., 1000 * years)
                    points = 1000 * years
                    points_service.award_points(
                        user_id=user.id,
                        points=points,
                        source_type=ReferenceType.CELEBRATION.value,
                        source_id=0
                    )
                    
                    # Create celebration record
                    celebration = Celebration(
                        user_id=user.id,
                        celebration_type="ANNIVERSARY",
                        points_awarded=points
                    )
                    self.db.add(celebration)
                    
                    # Send notification
                    notification_service.create_notification(
                        user_id=user.id,
                        message=f"🎊 Congratulations on {years} year{'s' if years > 1 else ''} with us! You've been awarded {points} points!",
                        source_type="CELEBRATION",
                        source_id=0
                    )
                    anniversary_count += 1
        
        self.db.commit()
        return {"birthdays": birthday_count, "anniversaries": anniversary_count}
