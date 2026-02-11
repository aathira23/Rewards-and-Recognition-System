"""
Points management API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from app.core.database import get_db
from app.core.dependencies import get_current_user, get_current_user_id
from app.schemas.points_ledger import PointsLedgerResponse
from app.schemas.points_conversion import (
    PointsConversionCreate,
    PointsConversionResponse,
    PointsConversionActionRequest
)
from app.schemas.points_policy import PointsPolicyCreate, PointsPolicyUpdate, PointsPolicyResponse
from app.services import points_service
from app.utils.response import success

router = APIRouter()


@router.get("/balance")
def get_points_balance(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get current user's points balance and aggregates."""
    aggregates = points_service.get_aggregates(db, current_user.id)
    return success(data=aggregates, message="Balance fetched")


@router.get("/history")
def get_points_history(
    category: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    page: int = 1,
    per_page: int = 20,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get points history with balance, aggregates, and filters (received, spent, expired, pending)."""
    aggregates = points_service.get_aggregates(db, current_user.id)
    total, history = points_service.fetch_ledger_history(
        db, current_user.id, category, start_date, end_date, page, per_page
    )
    
    payload = {
        "balance": aggregates["balance"],
        "total_earned": aggregates["total_earned"],
        "total_redeemed": aggregates["total_redeemed"],
        "pending_count": aggregates["pending_count"],
        "history": history,
        "page": page,
        "per_page": per_page,
        "total": total,
    }
    return success(data=payload, message="Points history fetched")


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
