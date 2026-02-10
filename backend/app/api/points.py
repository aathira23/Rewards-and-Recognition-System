"""
Points management API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user_id
from app.schemas.points_ledger import PointsLedgerResponse
from app.schemas.points_conversion import (
    PointsConversionCreate,
    PointsConversionResponse,
    PointsConversionActionRequest
)
from app.schemas.points_policy import PointsPolicyCreate, PointsPolicyUpdate, PointsPolicyResponse

router = APIRouter()


@router.get("/balance")
def get_points_balance(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get current user's points balance."""
    # TODO: Implement get balance logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.get("/history", response_model=List[PointsLedgerResponse])
def get_points_history(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get points transaction history."""
    # TODO: Implement get history logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.post("/convert-to-cash", response_model=PointsConversionResponse, status_code=status.HTTP_201_CREATED)
def convert_points_to_cash(
    request: PointsConversionCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Request points conversion to cash/payroll."""
    # TODO: Implement conversion request logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.get("/conversions", response_model=List[PointsConversionResponse])
def get_conversions(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get conversion requests (user's own or all if admin)."""
    # TODO: Implement get conversions logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.post("/conversions/{conversion_id}/action")
def action_conversion(
    conversion_id: int,
    request: PointsConversionActionRequest,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Approve or reject a conversion request (admin only)."""
    # TODO: Implement conversion action logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


# Points Policy/Rules endpoints
@router.post("/rules/points", response_model=PointsPolicyResponse, status_code=status.HTTP_201_CREATED)
def create_points_rule(
    rule: PointsPolicyCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Create a new points policy rule (admin only)."""
    # TODO: Implement create rule logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.put("/rules/points/{rule_id}", response_model=PointsPolicyResponse)
def update_points_rule(
    rule_id: int,
    rule: PointsPolicyUpdate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Update a points policy rule (admin only)."""
    # TODO: Implement update rule logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.get("/rules/points", response_model=List[PointsPolicyResponse])
def get_points_rules(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get all points policy rules."""
    # TODO: Implement get rules logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )
