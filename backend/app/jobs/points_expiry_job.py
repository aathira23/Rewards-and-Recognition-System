"""
Points expiry job - Expire old points batches.
"""
from datetime import date
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.models.points_batches import PointsBatch


def expire_points():
    """
    Background job to expire old points batches.

    Should be run daily (e.g., via cron or scheduler).
    Finds batches past their expiry date and deducts remaining points.
    """
    db = SessionLocal()
    try:
        today = date.today()

        # Find expired batches with remaining points
        expired_batches = db.query(PointsBatch).filter(
            PointsBatch.expiry_date < today,
            PointsBatch.remaining_points > 0
        ).all()

        for batch in expired_batches:
            process_expired_batch(db, batch)

        db.commit()
        print(f"Expired {len(expired_batches)} points batches")

    except Exception as e:
        db.rollback()
        # TODO: Log error
        print(f"Error expiring points: {e}")
    finally:
        db.close()


def process_expired_batch(db: Session, batch: PointsBatch):
    """Process a single expired points batch."""
    # TODO: Implement expiry processing
    # 1. Get user's employee wallet
    # 2. Deduct remaining_points from wallet balance
    # 3. Set batch.remaining_points to 0
    # 4. Create ledger entry for expiry
    # 5. Optionally create notification
    pass


if __name__ == "__main__":
    # For manual execution or testing
    expire_points()
