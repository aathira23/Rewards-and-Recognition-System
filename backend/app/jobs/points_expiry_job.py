"""
Points expiry job - Expire old points batches.
"""
from datetime import date
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.models.points_batches import PointsBatch
from app.models.points_ledger import PointsLedger
from app.models.notifications import Notification
from app.services.points_service import PointsService
from app.utils.enums import TransactionType, ReferenceType


def expire_points():
    """
    Background job to expire old points batches.

    Should be run daily (e.g., via cron or scheduler).
    Finds batches past their expiry date and deducts remaining points.
    """
    db = SessionLocal()
    try:
        today = date.today()
        print(f"--- Processing points expiry for {today} ---")

        # Find expired batches with remaining points
        expired_batches = db.query(PointsBatch).filter(
            PointsBatch.expiry_date < today,
            PointsBatch.remaining_points > 0
        ).all()

        if not expired_batches:
            print("No expired batches found today.")
            return

        for batch in expired_batches:
            process_expired_batch(db, batch)

        db.commit()
        print(f"--- Expired {len(expired_batches)} points batches ---")

    except Exception as e:
        db.rollback()
        print(f"Error expiring points: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()


def process_expired_batch(db: Session, batch: PointsBatch):
    """Process a single expired points batch."""
    print(f"Expiring batch {batch.id} for User {batch.user_id}: {batch.remaining_points} points")
    
    points_service = PointsService(db)
    
    # 1. Get user's employee wallet
    wallet = points_service.get_employee_wallet(batch.user_id)
    
    points_to_expire = batch.remaining_points

    # 2. Deduct remaining_points from wallet balance
    wallet.balance -= points_to_expire
    if wallet.balance < 0:
        wallet.balance = 0 # Safety net
    
    # 3. Create ledger entry for expiry
    ledger = PointsLedger(
        source_wallet_id=wallet.id,
        points=points_to_expire,
        transaction_type=TransactionType.DEBIT.value,
        reference_type=ReferenceType.EXPIRY.value,
        reference_id=batch.id
    )
    db.add(ledger)

    # 4. Set batch.remaining_points to 0
    batch.remaining_points = 0

    # 5. Create notification
    notification = Notification(
        user_id=batch.user_id,
        message=f"Alert: {points_to_expire} points have expired from your account.",
        source_type=ReferenceType.EXPIRY.value,
        source_id=batch.id
    )
    db.add(notification)


if __name__ == "__main__":
    # For manual execution or testing
    expire_points()
