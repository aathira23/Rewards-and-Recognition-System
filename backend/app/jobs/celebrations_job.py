"""
Celebrations job - Automated birthday and anniversary recognition.
"""
from datetime import date
from sqlalchemy.orm import Session

from app.core.database import SessionLocal


def process_celebrations():
    """
    Background job to process daily celebrations.

    Should be run daily (e.g., via cron or scheduler).
    Processes birthdays and work anniversaries for the current date.
    """
    db = SessionLocal()
    try:
        today = date.today()

        # Process birthdays
        process_birthdays(db, today)

        # Process work anniversaries
        process_anniversaries(db, today)

        db.commit()
    except Exception as e:
        db.rollback()
        # TODO: Log error
        print(f"Error processing celebrations: {e}")
    finally:
        db.close()


def process_birthdays(db: Session, today: date):
    """Process birthday celebrations for today."""
    # TODO: Implement birthday processing
    # 1. Query users with birth_date matching today (day and month)
    # 2. Check if celebration already exists for this year
    # 3. Get points value from policy
    # 4. Award points
    # 5. Create celebration record
    # 6. Create recognition feed entry
    # 7. Send notification
    pass


def process_anniversaries(db: Session, today: date):
    """Process work anniversary celebrations for today."""
    # TODO: Implement anniversary processing
    # 1. Query users with date_of_joining matching today (day and month)
    # 2. Calculate years of service
    # 3. Check if celebration already exists for this year
    # 4. Get points value from policy
    # 5. Award points
    # 6. Create celebration record
    # 7. Create recognition feed entry
    # 8. Send notification
    pass


if __name__ == "__main__":
    # For manual execution or testing
    process_celebrations()
