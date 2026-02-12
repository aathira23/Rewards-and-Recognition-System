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
from app.utils.enums import UserRole, AwardStatus, ApprovalLevel

def setup_test_users(db: Session):
    """Ensure we have a user for each role in the multi-level workflow."""
    roles = {
        "HR": "hr_test@example.com",
        "DEPT_HEAD": "dept_head_test@example.com",
        "MANAGER": "manager_test@example.com",
        "EMPLOYEE": "emp_test@example.com",
        "NOMINEE": "nominee_test@example.com"
    }
    users = {}
    for role, email in roles.items():
        user = db.query(User).filter(User.email == email).first()
        if not user:
            user = User(name=f"Test {role}", email=email, password="hash", role=UserRole[role].value if role in UserRole.__members__ else UserRole.EMPLOYEE.value)
            db.add(user)
            db.commit()
            db.refresh(user)
        users[role] = user
    return users

def cleanup_test_data(db: Session, award_type_id=None, award_ids=None):
    if award_ids:
        ids_str = ",".join(map(str, award_ids))
        db.execute(text(f"DELETE FROM award_approvals WHERE award_id IN ({ids_str})"))
        db.execute(text(f"DELETE FROM points_ledger WHERE reference_id IN ({ids_str}) AND reference_type = 'AWARD'"))
        db.execute(text(f"DELETE FROM points_batches WHERE source_id IN ({ids_str}) AND source_type = 'AWARD'"))
        db.execute(text(f"DELETE FROM awards WHERE id IN ({ids_str})"))
    if award_type_id:
        db.execute(text(f"DELETE FROM award_types WHERE id = {award_type_id}"))
    db.commit()

def run_multi_level_test():
    db = SessionLocal()
    users = setup_test_users(db)
    service = AwardsService(db)
    points_service = PointsService(db)
    
    award_type_id = None
    award_ids = []
    
    try:
        # 1. Setup Award Type with workflow: MANAGER, DEPT_HEAD, HR
        award_type = service.create_award_type(
            award_key="ML_DYNAMIC_TEST",
            name="Multi-Level Dynamic Test",
            points=1000,
            frequency="ADHOC",
            eligibility_rule="PEER",
            approval_workflow="MANAGER,DEPT_HEAD,HR"
        )
        award_type_id = award_type.id
        print(f"Created Award Type: {award_type.name} with workflow: {award_type.approval_workflow}")

        # --- FLOW 1: EMPLOYEE NOMINATES (Full workflow: 3 levels) ---
        print("\n>>> Testing Flow: Employee Nominates (MANAGER -> DEPT_HEAD -> HR)")
        award1 = service.nominate_for_award(
            nominator_id=users["EMPLOYEE"].id,
            nominee_id=users["NOMINEE"].id,
            award_type_id=award_type_id,
            justification="Great peer work"
        )
        award_ids.append(award1.id)
        
        status_info = service.get_approval_status(award1.id)
        print(f"Nominated by Employee. Status: {award1.status}, Next Required: {status_info['next_required_level']}")
        assert award1.status == AwardStatus.PENDING.value
        assert status_info["next_required_level"] == "MANAGER"

        # Manager Approves
        print("Manager approving...")
        service.approve_nomination(award1.id, users["MANAGER"].id, "MANAGER")
        status_info = service.get_approval_status(award1.id)
        assert status_info["next_required_level"] == "DEPT_HEAD"

        # Dept Head Approves
        print("Dept Head approving...")
        service.approve_nomination(award1.id, users["DEPT_HEAD"].id, "DEPT_HEAD")
        status_info = service.get_approval_status(award1.id)
        assert status_info["next_required_level"] == "HR"

        # HR Approves
        print("HR approving...")
        service.approve_nomination(award1.id, users["HR"].id, "HR")
        assert service.get_nomination(award1.id).status == AwardStatus.APPROVED.value
        print("Flow 1 Success!")

        # --- FLOW 2: MANAGER NOMINATES (Skip MANAGER level) ---
        print("\n>>> Testing Flow: Manager Nominates (DEPT_HEAD -> HR)")
        award2 = service.nominate_for_award(
            nominator_id=users["MANAGER"].id,
            nominee_id=users["NOMINEE"].id,
            award_type_id=award_type_id
        )
        award_ids.append(award2.id)
        status_info = service.get_approval_status(award2.id)
        print(f"Nominated by Manager. Status: {award2.status}, Next Required: {status_info['next_required_level']}")
        assert status_info["next_required_level"] == "DEPT_HEAD"
        print("Flow 2 Success!")

        # --- FLOW 3: DEPT_HEAD NOMINATES (Skip MANAGER and DEPT_HEAD) ---
        print("\n>>> Testing Flow: Dept Head Nominates (HR only)")
        award3 = service.nominate_for_award(
            nominator_id=users["DEPT_HEAD"].id,
            nominee_id=users["NOMINEE"].id,
            award_type_id=award_type_id
        )
        award_ids.append(award3.id)
        status_info = service.get_approval_status(award3.id)
        print(f"Nominated by Dept Head. Status: {award3.status}, Next Required: {status_info['next_required_level']}")
        assert status_info["next_required_level"] == "HR"
        print("Flow 3 Success!")

        # --- FLOW 4: HR NOMINATES (Auto-Approval) ---
        print("\n>>> Testing Flow: HR Nominates (Auto-Approved)")
        award4 = service.nominate_for_award(
            nominator_id=users["HR"].id,
            nominee_id=users["NOMINEE"].id,
            award_type_id=award_type_id
        )
        award_ids.append(award4.id)
        print(f"Nominated by HR. Status: {award4.status}")
        assert award4.status == AwardStatus.APPROVED.value
        print("Flow 4 Success!")

    except Exception as e:
        print(f"Test Failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        cleanup_test_data(db, award_type_id, award_ids)
        db.close()

if __name__ == "__main__":
    run_multi_level_test()
