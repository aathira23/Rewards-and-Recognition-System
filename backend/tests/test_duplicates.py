import os
import sys
from sqlalchemy.orm import Session
from sqlalchemy import text

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.core.database import SessionLocal
from app.services.recognition_service import RecognitionService
from app.services.awards_service import AwardsService
from app.models.users import User
from app.utils.enums import UserRole
from fastapi import HTTPException


def cleanup(db: Session, badge_name=None, award_type_id=None, user_emails=None, award_ids=None):
    if badge_name:
        db.execute(text("DELETE FROM badges WHERE lower(name)=lower(:name)"), {"name": badge_name})
    if award_ids:
        ids = ",".join(map(str, award_ids))
        db.execute(text(f"DELETE FROM award_approvals WHERE award_id IN ({ids})"))
        db.execute(text(f"DELETE FROM points_ledger WHERE reference_id IN ({ids}) AND reference_type = 'AWARD'"))
        db.execute(text(f"DELETE FROM points_batches WHERE source_id IN ({ids}) AND source_type = 'AWARD'"))
        db.execute(text(f"DELETE FROM awards WHERE id IN ({ids})"))
    if award_type_id:
        db.execute(text("DELETE FROM award_types WHERE id = :id"), {"id": award_type_id})
    if user_emails:
        db.execute(text("DELETE FROM users WHERE email IN :emails"), {"emails": tuple(user_emails)})
    db.commit()


def test_duplicate_badge_creation():
    db = SessionLocal()
    service = RecognitionService(db)
    name = "DupBadgeTest"
    try:
        # Ensure clean state
        cleanup(db, badge_name=name)

        badge = service.create_badge(name=name, description="desc", icon_url=None)
        assert badge.name == name

        # Creating again should raise ValueError
        try:
            service.create_badge(name=name, description="desc", icon_url=None)
            assert False, "Expected ValueError for duplicate badge"
        except ValueError:
            pass
    finally:
        cleanup(db, badge_name=name)
        db.close()


def test_duplicate_award_nomination():
    db = SessionLocal()
    service = AwardsService(db)
    users = []
    award_type_id = None
    award_ids = []
    try:
        # Create minimal users
        nominator = db.query(User).filter(User.email == 'dup_nom@example.com').first()
        if not nominator:
            nominator = User(name='Nominator', email='dup_nom@example.com', password='x', role=UserRole.EMPLOYEE.value)
            db.add(nominator)
            db.commit()
            db.refresh(nominator)
        nominee = db.query(User).filter(User.email == 'dup_nominee@example.com').first()
        if not nominee:
            nominee = User(name='Nominee', email='dup_nominee@example.com', password='x', role=UserRole.EMPLOYEE.value)
            db.add(nominee)
            db.commit()
            db.refresh(nominee)

        # Create award type
        award_type = service.create_award_type(
            award_key="DUP_TEST_KEY",
            name="Dup Nom Test",
            points=100,
            frequency="ADHOC",
            eligibility_rule="PEER"
        )
        award_type_id = award_type.id

        # First nomination should succeed
        award = service.nominate_for_award(nominator_id=nominator.id, nominee_id=nominee.id, award_type_id=award_type_id)
        award_ids.append(award.id)

        # Second nomination (same nominee & award type) should raise HTTPException 400
        try:
            service.nominate_for_award(nominator_id=nominator.id, nominee_id=nominee.id, award_type_id=award_type_id)
            assert False, "Expected HTTPException for duplicate nomination"
        except HTTPException as e:
            assert e.status_code == 400
    finally:
        cleanup(db, award_type_id=award_type_id, award_ids=award_ids, user_emails=['dup_nom@example.com','dup_nominee@example.com'])
        db.close()


def test_duplicate_award_type_key_and_name():
    db = SessionLocal()
    service = AwardsService(db)
    award_type_id = None
    try:
        # Create first award type
        at = service.create_award_type(
            award_key="DUP_KEY_2",
            name="Dup Name Test",
            points=50,
            frequency="ADHOC",
            eligibility_rule="PEER"
        )
        award_type_id = at.id

        # Duplicate key should raise HTTPException
        try:
            service.create_award_type(
                award_key="DUP_KEY_2",
                name="Another Name",
                points=10,
                frequency="ADHOC",
                eligibility_rule="PEER"
            )
            assert False, "Expected HTTPException for duplicate award key"
        except HTTPException as e:
            assert e.status_code == 400

        # Duplicate name (case-insensitive) should raise HTTPException
        try:
            service.create_award_type(
                award_key="DUP_KEY_3",
                name="dup name test",  # lowercased
                points=10,
                frequency="ADHOC",
                eligibility_rule="PEER"
            )
            assert False, "Expected HTTPException for duplicate award name"
        except HTTPException as e:
            assert e.status_code == 400

    finally:
        cleanup(db, award_type_id=award_type_id)
        db.close()
