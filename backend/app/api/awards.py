"""
Award nominations and official award types.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user_id
from app.schemas.awards import AwardNominationCreate, AwardResponse, AwardActionRequest
from app.schemas.award_types import AwardTypeCreate, AwardTypeUpdate, AwardTypeResponse

router = APIRouter()


# Award Nominations
@router.post("/nominations", response_model=AwardResponse, status_code=status.HTTP_201_CREATED)
def nominate_for_award(
    nomination: AwardNominationCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Nominate an employee for an award."""
    # TODO: Implement nomination logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.get("/nominations", response_model=List[AwardResponse])
def get_nominations(
    skip: int = 0,
    limit: int = 20,
    status_filter: str = None,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get award nominations (filtered by role)."""
    # TODO: Implement get nominations logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.get("/nominations/{nomination_id}", response_model=AwardResponse)
def get_nomination(
    nomination_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get specific nomination details."""
    # TODO: Implement get nomination logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.post("/nominations/{nomination_id}/action")
def action_nomination(
    nomination_id: int,
    request: AwardActionRequest,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Approve or reject an award nomination."""
    # TODO: Implement nomination action logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


# Award Types
@router.post("/types", response_model=AwardTypeResponse, status_code=status.HTTP_201_CREATED)
def create_award_type(
    award_type: AwardTypeCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Create a new award type (admin only)."""
    # TODO: Implement create award type logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.put("/types/{type_id}", response_model=AwardTypeResponse)
def update_award_type(
    type_id: int,
    award_type: AwardTypeUpdate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Update an award type (admin only)."""
    # TODO: Implement update award type logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.patch("/types/{type_id}/deactivate")
def deactivate_award_type(
    type_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Deactivate an award type (admin only)."""
    # TODO: Implement deactivate award type logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.get("/types", response_model=List[AwardTypeResponse])
def get_award_types(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get all award types."""
    # TODO: Implement get award types logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )
