"""
Award nominations and official award types.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user, oauth2_scheme
from app.schemas.awards import AwardNominationCreate, AwardResponse, AwardActionRequest, ApprovalHistoryItem
from app.schemas.award_types import AwardTypeCreate, AwardTypeUpdate, AwardTypeResponse
from app.services.awards_service import AwardsService
from app.utils.enums import UserRole, ApprovalLevel
from app.utils.response import success, client_error, created, conflict, server_error, paginated_success
from app.services.user_profiles_client import get_users_batch


def _enrich_award_responses(responses: list[AwardResponse], token: str) -> list[AwardResponse]:
    """Populate nominee / nominator from the authoritative profile source.

    Always enriches via the centralized User Service batch API (cached).
    """
    uid_set = set()
    for r in responses:
        if r.nominee_id:
            uid_set.add(r.nominee_id)
        if r.nominator_id:
            uid_set.add(r.nominator_id)
    if not uid_set:
        return responses

    profiles = get_users_batch(list(uid_set), token)

    for r in responses:
        p = profiles.get(r.nominee_id)
        if p and getattr(p, "name", None):
            r.nominee = {"id": r.nominee_id, "name": p.name}
        if r.persona_label:
            r.nominator = {"id": r.nominator_id, "name": r.persona_label}
        else:
            p = profiles.get(r.nominator_id)
            if p and getattr(p, "name", None):
                r.nominator = {"id": r.nominator_id, "name": p.name}
    return responses
from app.utils.constants import (
    DEFAULT_PAGE_SIZE, SUCCESS_NOMINATION_SUCCESSFUL, SUCCESS_NOMINATIONS_FETCHED,
    SUCCESS_AWARD_TYPES_FETCHED, ERROR_ONLY_HR_ADMIN_CREATE_AWARD_TYPE,
    SUCCESS_AWARD_TYPE_CREATED, ERROR_ONLY_HR_ADMIN_UPDATE_AWARD_TYPE,
    ERROR_AWARD_TYPE_NOT_FOUND, SUCCESS_AWARD_TYPE_UPDATED,
    SUCCESS_NO_APPROVAL_HISTORY, SUCCESS_APPROVAL_HISTORY_FETCHED,
    ERROR_NOMINATION_NOT_FOUND, ERROR_UNAUTHORIZED_NOMINATION_VIEW,
    SUCCESS_NOMINATION_DETAILS_FETCHED, ERROR_EMPLOYEES_CANNOT_APPROVE,
    ERROR_INVALID_NOMINATION_ACTION, SUCCESS_NOMINATION_APPROVED,
    SUCCESS_NOMINATION_REJECTED, SUCCESS_APPROVAL_STATUS_RETRIEVED
)

router = APIRouter()


# Award Nominations
@router.post("/nominations")
def nominate_for_award(
    nomination: AwardNominationCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    token: str = Depends(oauth2_scheme)
):
    """Nominate an employee for an award."""
    service = AwardsService(db, token=token)
    try:
        result = service.nominate_for_award(
            nominator_id=current_user.id,
            nominee_id=nomination.nominee_id,
            award_type_id=nomination.award_type_id,
            citation=nomination.citation,
            persona_type=nomination.persona_type,
            persona_label=nomination.persona_label,
        )
        resp = AwardResponse.model_validate(result)
        _enrich_award_responses([resp], token)
        return created(data=resp, message=SUCCESS_NOMINATION_SUCCESSFUL)
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
    current_user = Depends(get_current_user),
    token: str = Depends(oauth2_scheme)
):
    """Get award nominations (filtered by role)."""
    service = AwardsService(db, token=token)
    total, nominations = service.get_nominations(
        user_id=current_user.id,
        role=current_user.role,
        status_filter=status_filter,
        page=page,
        per_page=per_page
    )
    items = [AwardResponse.model_validate(n) for n in nominations]
    _enrich_award_responses(items, token)
    return paginated_success(
        items=items,
        total=total,
        page=page,
        per_page=per_page,
        message=SUCCESS_NOMINATIONS_FETCHED,
    )


# Award types (renamed path to /awards) - MOVED BEFORE {nomination_id} to avoid routing conflict
@router.get("/")
def get_award_types(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get award types the current user is eligible to nominate for."""
    service = AwardsService(db)
    # HR and Admin see ALL award types (including inactive) for config management.
    # Other roles only see active award types they are eligible for.
    is_hr_admin = current_user.role in (UserRole.HR.value, UserRole.ADMIN.value)
    active_only = not is_hr_admin

    types = service.get_award_types(active_only=active_only, user_role=current_user.role)
    return success(data=[AwardTypeResponse.model_validate(t) for t in types], message=SUCCESS_AWARD_TYPES_FETCHED)


@router.post("/")
def create_award_type(
    award_type: AwardTypeCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new award type (admin only)."""
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        return client_error(message=ERROR_ONLY_HR_ADMIN_CREATE_AWARD_TYPE, status_code=403)

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
        return created(data=AwardTypeResponse.model_validate(result), message=SUCCESS_AWARD_TYPE_CREATED)
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
    current_user = Depends(get_current_user)
):
    """Update an award type (admin only)."""
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        return client_error(message=ERROR_ONLY_HR_ADMIN_UPDATE_AWARD_TYPE, status_code=403)

    service = AwardsService(db)
    updated = service.update_award_type(type_id, award_type.model_dump(exclude_unset=True))
    if not updated:
        return client_error(message=ERROR_AWARD_TYPE_NOT_FOUND, status_code=404)
    return success(data=AwardTypeResponse.model_validate(updated), message=SUCCESS_AWARD_TYPE_UPDATED)


@router.get("/nominations/my-approvals")
def get_my_approval_history(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    token: str = Depends(oauth2_scheme)
):
    """Return all nominations the current user has personally approved or rejected."""
    if current_user.role == UserRole.EMPLOYEE.value:
        return success(data=[], message=SUCCESS_NO_APPROVAL_HISTORY)
    service = AwardsService(db, token=token)
    items = service.get_my_approval_history(user_id=current_user.id)
    return success(
        data=[ApprovalHistoryItem(**item).model_dump(mode='json') for item in items],
        message=SUCCESS_APPROVAL_HISTORY_FETCHED
    )


# Nomination-specific routes - AFTER /types to avoid conflict
@router.get("/nominations/{nomination_id}")
def get_nomination(
    nomination_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    token: str = Depends(oauth2_scheme)
):
    """Get specific nomination details."""
    service = AwardsService(db)
    nomination = service.get_nomination(nomination_id)
    if not nomination:
        return client_error(message=ERROR_NOMINATION_NOT_FOUND, status_code=404)

    # Check if user has access (Admin, or participant)
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value) and \
       current_user.id not in [nomination.nominator_id, nomination.nominee_id]:
        return client_error(message=ERROR_UNAUTHORIZED_NOMINATION_VIEW, status_code=403)

    resp = AwardResponse.model_validate(nomination)
    _enrich_award_responses([resp], token)
    return success(data=resp, message=SUCCESS_NOMINATION_DETAILS_FETCHED)


@router.post("/nominations/{nomination_id}/action")
def action_nomination(
    nomination_id: int,
    request: AwardActionRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    token: str = Depends(oauth2_scheme)
):
    """Approve or reject an award nomination."""
    # Basic role check: Manager or above can approve
    if current_user.role == UserRole.EMPLOYEE.value:
        return client_error(message=ERROR_EMPLOYEES_CANNOT_APPROVE, status_code=403)

    service = AwardsService(db, token=token)
    # Validate action value strictly
    action = (request.action or "").strip().upper()
    if action not in ("APPROVE", "REJECT"):
        return client_error(message=ERROR_INVALID_NOMINATION_ACTION, status_code=400)

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
        resp = AwardResponse.model_validate(result)
        _enrich_award_responses([resp], token)
        return success(data=resp, message=SUCCESS_NOMINATION_APPROVED)
    else:
        result = service.reject_nomination(
            award_id=nomination_id,
            approver_id=current_user.id,
            approval_level=approval_level,
            comments=request.comments or "Rejected"
        )
        resp = AwardResponse.model_validate(result)
        _enrich_award_responses([resp], token)
        return success(data=resp, message=SUCCESS_NOMINATION_REJECTED)


@router.get("/nominations/{nomination_id}/approval-status")
def get_approval_status(
    nomination_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    token: str = Depends(oauth2_scheme)
):
    """Get detailed approval status and workflow progress for a nomination."""
    service = AwardsService(db, token=token)

    # Verify nomination exists and user has access
    nomination = service.get_nomination(nomination_id)
    if not nomination:
        return client_error(message=ERROR_NOMINATION_NOT_FOUND, status_code=404)

    # Check access: HR, or participants in the nomination
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value) and \
       current_user.id not in [nomination.nominator_id, nomination.nominee_id]:
        return client_error(message=ERROR_UNAUTHORIZED_NOMINATION_VIEW, status_code=403)

    status = service.get_approval_status(nomination_id)
    return success(data=status, message=SUCCESS_APPROVAL_STATUS_RETRIEVED)
