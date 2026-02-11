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
from app.services.points_service import PointsService
from app.services.store_service import StoreService
from app.utils.response import success, created, client_error

router = APIRouter()


@router.get("/balance")
def get_points_balance(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get current user's points balance and aggregates."""
    service = PointsService(db)
    aggregates = service.get_aggregates(current_user.id)
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
    service = PointsService(db)
    aggregates = service.get_aggregates(current_user.id)
    total, history = service.fetch_ledger_history(
        current_user.id, category, start_date, end_date, page, per_page
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


@router.post("/convert", response_model=PointsConversionResponse, status_code=status.HTTP_201_CREATED)
def convert_points_request(
    request: PointsConversionCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Request points conversion to cash/payroll. (User Shortcut)"""
    service = StoreService(db)
    try:
        # Get conversion rate from active policies
        policies = service.get_policies()
        rate = 0.1 # default fallback
        for p in policies:
            if p.recognition_type == "CONVERSION" and p.conversion_reward_type == request.conversion_type:
                rate = float(p.conversion_rate or 0.1)
                break
                
        calculated_cash = float(request.points_converted) * rate
        conversion = service.create_conversion_request(
            user_id=current_user_id,
            points=request.points_converted,
            conversion_type=request.conversion_type,
            cash_amount=calculated_cash
        )
        data = PointsConversionResponse.model_validate(conversion)
        return created(data=data, message="Conversion request submitted")
    except ValueError as e:
        return client_error(message=str(e))


@router.get("/conversions", response_model=List[PointsConversionResponse])
def get_conversions(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get conversion requests (User's own requests)."""
    service = StoreService(db)
    conversions = service.get_conversion_history(current_user_id)
    data = [PointsConversionResponse.model_validate(c) for c in conversions]
    return success(data=data)


@router.post("/conversions/{conversion_id}/action")
def action_conversion(
    conversion_id: int,
    request: PointsConversionActionRequest,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Approve or reject a conversion request (Admin logic)."""
    service = StoreService(db)
    try:
        if request.action.upper() == "APPROVE":
            result = service.approve_conversion(conversion_id, current_user_id)
            data = PointsConversionResponse.model_validate(result)
            return success(data=data, message="Request approved and points deducted")
        else:
            result = service.reject_conversion(conversion_id, current_user_id)
            data = PointsConversionResponse.model_validate(result)
            return success(data=data, message="Request rejected")
    except ValueError as e:
        return client_error(message=str(e))


# --- Policy/Rules Endpoints ---

@router.get("/rules", response_model=List[PointsPolicyResponse])
def get_points_rules(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get all points policy rules."""
    service = StoreService(db)
    policies = service.get_policies()
    data = [PointsPolicyResponse.model_validate(p) for p in policies]
    return success(data=data, message="Policies retrieved")


@router.post("/rules", response_model=PointsPolicyResponse, status_code=status.HTTP_201_CREATED)
def create_points_rule(
    rule: PointsPolicyCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Create a new points policy rule (admin only)."""
    service = StoreService(db)
    result = service.create_policy(rule)
    data = PointsPolicyResponse.model_validate(result)
    return created(data=data, message="Rule created successfully")


@router.put("/rules/{rule_id}", response_model=PointsPolicyResponse)
def update_points_rule(
    rule_id: int,
    rule: PointsPolicyUpdate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Update a points policy rule (admin only)."""
    service = StoreService(db)
    try:
        result = service.update_policy(rule_id, rule)
        data = PointsPolicyResponse.model_validate(result)
        return success(data=data, message="Rule updated successfully")
    except ValueError as e:
        return client_error(message=str(e))
