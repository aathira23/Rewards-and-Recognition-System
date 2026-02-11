from app.core.database import SessionLocal
from app.models.ecards import ECard
from sqlalchemy.orm import joinedload
import sys

def test_query():
    db = SessionLocal()
    try:
        print("Querying ECard with ID 1...")
        ecard = db.query(ECard).options(
            joinedload(ECard.sender),
            joinedload(ECard.receiver),
            joinedload(ECard.badge)
        ).filter(ECard.id == 1).first()
        print(f"Result: {ecard}")
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    test_query()
