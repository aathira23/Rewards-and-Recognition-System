"""
Award nominations and official award types.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.users import User
from app.schemas.awards import AwardNominationCreate, AwardResponse, AwardActionRequest, ApprovalHistoryItem
from app.schemas.award_types import AwardTypeCreate, AwardTypeUpdate, AwardTypeResponse
from app.services.awards_service import AwardsService
from app.utils.enums import UserRole, ApprovalLevel
from app.utils.response import success, client_error, created, conflict, server_error, paginated_success
from app.utils.constants import DEFAULT_PAGE_SIZE

router = APIRouter()


# Award Nominations
@router.post("/nominations")
def nominate_for_award(
    nomination: AwardNominationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Nominate an employee for an award."""
    service = AwardsService(db)
    try:
        result = service.nominate_for_award(
            nominator_id=current_user.id,
            nominee_id=nomination.nominee_id,
            award_type_id=nomination.award_type_id,
            justification=nomination.justification
        )
        return created(data=AwardResponse.model_validate(result), message="Nomination successful")
    except HTTPException as e:
        # Map known duplicate nomination to structured conflict
        detail = e.detail if hasattr(e, 'detail') else str(e)
        if e.status_code == 400 and "pending nomination" in str(detail).lower():
            return conflict(message=str(detail), data={"field": "award_type_id", "value": nomination.award_type_id})
        # Propagate other HTTPExceptions
        raise e
    except Exception as e:
        return server_error(message=f"Nomination failed: {str(e)}")


@router.get("/nominations")
def get_nominations(
    page: int = 1,
    per_page: int = DEFAULT_PAGE_SIZE,
    status_filter: str = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get award nominations (filtered by role)."""
    service = AwardsService(db)
    total, nominations = service.get_nominations(
        user_id=current_user.id,
        role=current_user.role,
        status_filter=status_filter,
        page=page,
        per_page=per_page
    )
    return paginated_success(
        items=[AwardResponse.model_validate(n) for n in nominations],
        total=total,
        page=page,
        per_page=per_page,
        message="Nominations fetched",
    )


# Award types (renamed path to /awards) - MOVED BEFORE {nomination_id} to avoid routing conflict
@router.get("/")
def get_award_types(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get award types the current user is eligible to nominate for."""
    service = AwardsService(db)
    # HR and Admin should see all award types in the configuration/nomination lists
    role_filter = current_user.role
    if current_user.role in (UserRole.HR.value, UserRole.ADMIN.value):
        role_filter = None
    
    types = service.get_award_types(user_role=role_filter)
    return success(data=[AwardTypeResponse.model_validate(t) for t in types], message="Award types fetched")


@router.post("/")
def create_award_type(
    award_type: AwardTypeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new award type (admin only)."""
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        return client_error(message="Only HR/Admin can create award types", status_code=403)

    service = AwardsService(db)
    try:
        result = service.create_award_type(
            award_key=award_type.award_key,
            name=award_type.name,
            points=award_type.points,
            frequency=award_type.frequency,
            eligibility_rule=award_type.eligibility_rule,
            description=award_type.description,
            approval_workflow=award_type.approval_workflow
        )
        return created(data=AwardTypeResponse.model_validate(result), message="Award type created")
    except HTTPException as e:
        detail = e.detail if hasattr(e, 'detail') else str(e)
        # Distinguish key/name duplicates based on message
        if e.status_code == 400 and "key" in str(detail).lower():
            return conflict(message=str(detail), data={"field": "award_key", "value": award_type.award_key})
        if e.status_code == 400 and "name" in str(detail).lower():
            return conflict(message=str(detail), data={"field": "name", "value": award_type.name})
        raise e
    except Exception as e:
        return server_error(message=f"Failed to create award type: {str(e)}")


@router.put("/types/{type_id}")
def update_award_type(
    type_id: int,
    award_type: AwardTypeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update an award type (admin only)."""
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        return client_error(message="Only HR/Admin can update award types", status_code=403)

    service = AwardsService(db)
    updated = service.update_award_type(type_id, award_type.model_dump(exclude_unset=True))
    if not updated:
        return client_error(message="Award type not found", status_code=404)
    return success(data=AwardTypeResponse.model_validate(updated), message="Award type updated")


@router.get("/nominations/my-approvals")
def get_my_approval_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Return all nominations the current user has personally approved or rejected."""
    if current_user.role == UserRole.EMPLOYEE.value:
        return success(data=[], message="No approval history for employees")
    service = AwardsService(db)
    items = service.get_my_approval_history(user_id=current_user.id)
    return success(
        data=[ApprovalHistoryItem(**item).model_dump(mode='json') for item in items],
        message="Approval history fetched"
    )


# Nomination-specific routes - AFTER /types to avoid conflict
@router.get("/nominations/{nomination_id}")
def get_nomination(
    nomination_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get specific nomination details."""
    service = AwardsService(db)
    nomination = service.get_nomination(nomination_id)
    if not nomination:
        return client_error(message="Nomination not found", status_code=404)

    # Check if user has access (Admin, or participant)
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value) and \
       current_user.id not in [nomination.nominator_id, nomination.nominee_id]:
        return client_error(message="Not authorized to view this nomination", status_code=403)

    return success(data=AwardResponse.model_validate(nomination), message="Nomination details fetched")


@router.post("/nominations/{nomination_id}/action")
def action_nomination(
    nomination_id: int,
    request: AwardActionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Approve or reject an award nomination."""
    # Basic role check: Manager or above can approve
    if current_user.role == UserRole.EMPLOYEE.value:
        return client_error(message="Employees cannot approve nominations", status_code=403)

    service = AwardsService(db)
    # Validate action value strictly
    action = (request.action or "").strip().upper()
    if action not in ("APPROVE", "REJECT"):
        return client_error(message="Invalid action. Must be 'APPROVE' or 'REJECT'.", status_code=400)

    # Determine approval level based on role
    approval_level = ApprovalLevel.MANAGER.value
    if current_user.role in (UserRole.HR.value, UserRole.ADMIN.value):
        approval_level = ApprovalLevel.HR.value
    elif current_user.role == UserRole.DEPT_HEAD.value:
        approval_level = ApprovalLevel.DEPT_HEAD.value
    if action == "APPROVE":
        result = service.approve_nomination(
            award_id=nomination_id,
            approver_id=current_user.id,
            approval_level=approval_level,
            comments=request.comments
        )
        return success(data=AwardResponse.model_validate(result), message="Nomination approved")
    else:
        result = service.reject_nomination(
            award_id=nomination_id,
            approver_id=current_user.id,
            approval_level=approval_level,
            comments=request.comments or "Rejected"
        )
        return success(data=AwardResponse.model_validate(result), message="Nomination rejected")


@router.get("/nominations/{nomination_id}/approval-status")
def get_approval_status(
    nomination_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get detailed approval status and workflow progress for a nomination."""
    service = AwardsService(db)

    # Verify nomination exists and user has access
    nomination = service.get_nomination(nomination_id)
    if not nomination:
        return client_error(message="Nomination not found", status_code=404)

    # Check access: HR, or participants in the nomination
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value) and \
       current_user.id not in [nomination.nominator_id, nomination.nominee_id]:
        return client_error(message="Not authorized to view this nomination", status_code=403)

    status = service.get_approval_status(nomination_id)
    return success(data=status, message="Approval status retrieved")
