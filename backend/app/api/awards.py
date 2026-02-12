"""
Award nominations and official award types.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.users import User
from app.schemas.awards import AwardNominationCreate, AwardResponse, AwardActionRequest
from app.schemas.award_types import AwardTypeCreate, AwardTypeUpdate, AwardTypeResponse
from app.services.awards_service import AwardsService
from app.utils.enums import UserRole, ApprovalLevel

router = APIRouter()


# Award Nominations
@router.post("/nominations", response_model=AwardResponse, status_code=status.HTTP_201_CREATED)
def nominate_for_award(
    nomination: AwardNominationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Nominate an employee for an award."""
    service = AwardsService(db)
    return service.nominate_for_award(
        nominator_id=current_user.id,
        nominee_id=nomination.nominee_id,
        award_type_id=nomination.award_type_id,
        justification=nomination.justification
    )


@router.get("/nominations", response_model=List[AwardResponse])
def get_nominations(
    skip: int = 0,
    limit: int = 20,
    status_filter: str = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get award nominations (filtered by role)."""
    service = AwardsService(db)
    return service.get_nominations(
        user_id=current_user.id,
        role=current_user.role,
        status_filter=status_filter,
        skip=skip,
        limit=limit
    )


@router.get("/nominations/{nomination_id}", response_model=AwardResponse)
def get_nomination(
    nomination_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get specific nomination details."""
    service = AwardsService(db)
    nomination = service.get_nomination(nomination_id)
    if not nomination:
        raise HTTPException(status_code=404, detail="Nomination not found")
    
    # Check if user has access (Admin, or participant)
    if current_user.role != UserRole.HR.value and \
       current_user.id not in [nomination.nominator_id, nomination.nominee_id]:
        raise HTTPException(status_code=403, detail="Not authorized to view this nomination")
        
    return nomination


@router.post("/nominations/{nomination_id}/action", response_model=AwardResponse)
def action_nomination(
    nomination_id: int,
    request: AwardActionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Approve or reject an award nomination."""
    # Basic role check: Manager or above can approve
    if current_user.role == UserRole.EMPLOYEE.value:
        raise HTTPException(status_code=403, detail="Employees cannot approve nominations")
        
    service = AwardsService(db)
    
    # Determine approval level based on role
    approval_level = ApprovalLevel.MANAGER.value
    if current_user.role == UserRole.HR.value:
        approval_level = ApprovalLevel.HR.value
    elif current_user.role == UserRole.DEPT_HEAD.value:
        approval_level = ApprovalLevel.DEPT_HEAD.value

    if request.action == "APPROVE":
        return service.approve_nomination(
            award_id=nomination_id,
            approver_id=current_user.id,
            approval_level=approval_level,
            comments=request.comments
        )
    else:
        return service.reject_nomination(
            award_id=nomination_id,
            approver_id=current_user.id,
            approval_level=approval_level,
            comments=request.comments or "Rejected"
        )


# Award Types
@router.post("/types", response_model=AwardTypeResponse, status_code=status.HTTP_201_CREATED)
def create_award_type(
    award_type: AwardTypeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create a new award type (admin only)."""
    if current_user.role != UserRole.HR.value:
        raise HTTPException(status_code=403, detail="Only HR can create award types")
        
    service = AwardsService(db)
    return service.create_award_type(
        award_key=award_type.award_key,
        name=award_type.name,
        points=award_type.points,
        frequency=award_type.frequency,
        eligibility_rule=award_type.eligibility_rule,
        description=award_type.description
    )


@router.put("/types/{type_id}", response_model=AwardTypeResponse)
def update_award_type(
    type_id: int,
    award_type: AwardTypeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update an award type (admin only)."""
    if current_user.role != UserRole.HR.value:
        raise HTTPException(status_code=403, detail="Only HR can update award types")
        
    service = AwardsService(db)
    updated = service.update_award_type(type_id, award_type.model_dump(exclude_unset=True))
    if not updated:
        raise HTTPException(status_code=404, detail="Award type not found")
    return updated


@router.patch("/types/{type_id}/deactivate", response_model=AwardTypeResponse)
def deactivate_award_type(
    type_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Deactivate an award type (admin only)."""
    if current_user.role != UserRole.HR.value:
        raise HTTPException(status_code=403, detail="Only HR can deactivate award types")
        
    service = AwardsService(db)
    updated = service.update_award_type(type_id, {"is_active": False})
    if not updated:
        raise HTTPException(status_code=404, detail="Award type not found")
    return updated


@router.get("/types", response_model=List[AwardTypeResponse])
def get_award_types(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all award types."""
    service = AwardsService(db)
    return service.get_award_types()
