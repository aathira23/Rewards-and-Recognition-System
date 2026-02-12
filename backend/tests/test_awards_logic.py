import sys
import os
from sqlalchemy.orm import Session
from sqlalchemy import text

# Add parent directory to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.core.database import SessionLocal, engine, Base
from app.models.users import User
from app.models.award_types import AwardType
from app.models.awards import Award
from app.models.wallets import Wallet
from app.services.awards_service import AwardsService
from app.services.points_service import PointsService
from app.utils.enums import UserRole, AwardStatus

def setup_test_data(db: Session):
    # Ensure test users exist
    admin = db.query(User).filter(User.email == "admin@test.com").first()
    if not admin:
        admin = User(name="Test Admin", email="admin@test.com", password="hash", role=UserRole.HR.value)
        db.add(admin)
    
    employee = db.query(User).filter(User.email == "emp@test.com").first()
    if not employee:
        employee = User(name="Test Employee", email="emp@test.com", password="hash", role=UserRole.EMPLOYEE.value)
        db.add(employee)
    
    db.commit()
    db.refresh(admin)
    db.refresh(employee)
    return admin, employee

def cleanup_test_data(db: Session, admin, employee, award_type_id=None, award_id=None):
    if award_id:
        db.execute(text(f"DELETE FROM award_approvals WHERE award_id = {award_id}"))
        db.execute(text(f"DELETE FROM points_ledger WHERE reference_id = {award_id} AND reference_type = 'AWARD'"))
        db.execute(text(f"DELETE FROM points_batches WHERE source_id = {award_id} AND source_type = 'AWARD'"))
        db.execute(text(f"DELETE FROM awards WHERE id = {award_id}"))
    if award_type_id:
        db.execute(text(f"DELETE FROM award_types WHERE id = {award_type_id}"))
    
    # Reset wallet balance for employee
    wallet = db.query(Wallet).filter(Wallet.user_id == employee.id).first()
    if wallet:
        wallet.balance = 0
    
    db.commit()

def run_test():
    db = SessionLocal()
    admin, employee = setup_test_data(db)
    service = AwardsService(db)
    points_service = PointsService(db)
    
    award_type_id = None
    award_id = None
    
    try:
        print("1. Creating Award Type...")
        award_type = service.create_award_type(
            award_key="TEST_AWARD",
            name="Test Award",
            points=500,
            frequency="ADHOC",
            eligibility_rule="PEER",
            description="Testing award logic"
        )
        award_type_id = award_type.id
        print(f"Created Award Type: {award_type.name} with ID {award_type_id}")
        
        print("\n2. Nominating Employee...")
        award = service.nominate_for_award(
            nominator_id=admin.id,
            nominee_id=employee.id,
            award_type_id=award_type_id,
            justification="Great work in testing"
        )
        award_id = award.id
        print(f"Nominated with ID {award_id}, Status: {award.status}")
        assert award.status == AwardStatus.PENDING.value
        
        print("\n3. Approving Nomination...")
        balance_before = points_service.get_user_balance(employee.id)
        print(f"Balance before: {balance_before}")
        
        approved_award = service.approve_nomination(
            award_id=award_id,
            approver_id=admin.id,
            approval_level="HR",
            comments="Approved by test script"
        )
        print(f"Approved ID {award_id}, Status: {approved_award.status}")
        assert approved_award.status == AwardStatus.APPROVED.value
        
        balance_after = points_service.get_user_balance(employee.id)
        print(f"Balance after: {balance_after}")
        assert balance_after == balance_before + 500
        print("Success! Points awarded correctly.")
        
    except Exception as e:
        print(f"Test Failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("\nCleaning up...")
        cleanup_test_data(db, admin, employee, award_type_id, award_id)
        db.close()

if __name__ == "__main__":
    run_test()
