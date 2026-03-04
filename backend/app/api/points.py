"""
Points management API endpoints.
"""
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from typing import List, Optional

from app.core.database import get_db
from app.core.dependencies import get_current_user, get_current_user_id
from app.utils.enums import UserRole
from app.utils.response import forbidden
from app.schemas.points_conversion import (
    PointsConversionCreate,
    PointsConversionResponse,
    PointsConversionActionRequest
)
from app.schemas.points_policy import PointsPolicyCreate, PointsPolicyUpdate, PointsPolicyResponse
from app.services.points_service import PointsService
from app.services.store_service import StoreService
from app.utils.response import success, created, client_error
from app.utils.constants import (
    DEFAULT_PAGE_SIZE, SUCCESS_POINTS_BALANCE_FETCHED, SUCCESS_POINTS_HISTORY_FETCHED,
    SUCCESS_CONVERSION_REQUESTED, ERROR_ONLY_HR_ADMIN_VIEW_PENDING_CONVERSIONS,
    ERROR_ONLY_HR_ADMIN_ACTION_CONVERSION, ERROR_INVALID_CONVERSION_ACTION,
    SUCCESS_CONVERSION_APPROVED, SUCCESS_CONVERSION_REJECTED,
    SUCCESS_POLICIES_RETRIEVED, ERROR_ONLY_HR_ADMIN_CREATE_RULE,
    SUCCESS_POINT_RULE_CREATED, ERROR_ONLY_HR_ADMIN_UPDATE_RULE,
    SUCCESS_POINT_RULE_UPDATED, INFO_CONVERSION_FEATURE_DISABLED
)
from app.utils.feature_flags import is_feature_enabled

router = APIRouter()

_CONVERSION_DISABLED_MSG = "Points conversion is not enabled for this organisation."


@router.get("/balance")
def get_points_balance(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get current user's points balance and aggregates."""
    service = PointsService(db)
    aggregates = service.get_aggregates(current_user.id)
    return success(data=aggregates, message=SUCCESS_POINTS_BALANCE_FETCHED)


@router.get("/history")
def get_points_history(
    category: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    page: int = 1,
    per_page: int = DEFAULT_PAGE_SIZE,
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
        "total_converted": aggregates.get("total_converted", 0),
        "pending_count": aggregates["pending_count"],
        "history": history,
        "page": page,
        "per_page": per_page,
        "total": total,
    }
    return success(data=payload, message=SUCCESS_POINTS_HISTORY_FETCHED)


@router.post("/convert", response_model=PointsConversionResponse, status_code=status.HTTP_201_CREATED)
def convert_points_request(
    request: PointsConversionCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Request points conversion to cash/payroll. (User Shortcut)"""
    if not is_feature_enabled(db, 'conversion_enabled'):
        return client_error(message=_CONVERSION_DISABLED_MSG, status_code=403)
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
        conv_dict = {
            "id": conversion.id,
            "points_converted": conversion.points_converted,
            "conversion_type": conversion.conversion_type,
            "user_id": conversion.user_id,
            "user_name": conversion.user.name if conversion.user else None,
            "cash_amount": conversion.cash_amount,
            "status": conversion.status,
            "requested_at": conversion.requested_at,
            "approved_by": conversion.approved_by,
            "approved_by_name": conversion.approver.name if conversion.approver else None,
            "approved_at": conversion.approved_at,
        }
        data = PointsConversionResponse.model_validate(conv_dict)
        return created(data=data, message=SUCCESS_CONVERSION_REQUESTED)
    except ValueError as e:
        return client_error(message=str(e))


@router.get("/conversions", response_model=List[PointsConversionResponse])
def get_conversions(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get conversion requests: HR sees all requests; users see only their own."""
    if not is_feature_enabled(db, 'conversion_enabled'):
        return success(data=[], message=INFO_CONVERSION_FEATURE_DISABLED)
    service = StoreService(db)
    # HR/Admin can view all conversions
    if getattr(current_user, "role", None) in (UserRole.HR.value, UserRole.ADMIN.value):
        conversions = service.get_all_conversion_history()
    else:
        conversions = service.get_conversion_history(current_user_id)

    data = []
    for c in conversions:
        conv_dict = {
            "id": c.id,
            "points_converted": c.points_converted,
            "conversion_type": c.conversion_type,
            "user_id": c.user_id,
            "user_name": c.user.name if c.user else None,
            "cash_amount": c.cash_amount,
            "status": c.status,
            "requested_at": c.requested_at,
            "approved_by": c.approved_by,
            "approved_by_name": c.approver.name if c.approver else None,
            "approved_at": c.approved_at,
        }
        item = PointsConversionResponse.model_validate(conv_dict)
        data.append(item)
    return success(data=data)


@router.get("/conversions/pending", response_model=List[PointsConversionResponse])
def get_pending_conversions(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get pending conversion requests (HR only)."""
    if not is_feature_enabled(db, 'conversion_enabled'):
        return success(data=[], message=INFO_CONVERSION_FEATURE_DISABLED)
    if getattr(current_user, "role", None) not in (UserRole.HR.value, UserRole.ADMIN.value):
        return forbidden(ERROR_ONLY_HR_ADMIN_VIEW_PENDING_CONVERSIONS)

    service = StoreService(db)
    conversions = service.get_pending_conversions()
    data = []
    for c in conversions:
        conv_dict = {
            "id": c.id,
            "points_converted": c.points_converted,
            "conversion_type": c.conversion_type,
            "user_id": c.user_id,
            "user_name": c.user.name if c.user else None,
            "cash_amount": c.cash_amount,
            "status": c.status,
            "requested_at": c.requested_at,
            "approved_by": c.approved_by,
            "approved_by_name": c.approver.name if c.approver else None,
            "approved_at": c.approved_at,
        }
        item = PointsConversionResponse.model_validate(conv_dict)
        data.append(item)
    return success(data=data)


@router.post("/conversions/{conversion_id}/action")
def action_conversion(
    conversion_id: int,
    request: PointsConversionActionRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    current_user_id: int = Depends(get_current_user_id)
):
    """Approve or reject a conversion request (Admin logic)."""
    if not is_feature_enabled(db, 'conversion_enabled'):
        return client_error(message=_CONVERSION_DISABLED_MSG, status_code=403)
    service = StoreService(db)
    try:
        # Only HR/Admin users can approve/reject conversions
        if getattr(current_user, "role", None) not in (UserRole.HR.value, UserRole.ADMIN.value):
            return forbidden(ERROR_ONLY_HR_ADMIN_ACTION_CONVERSION)
        # Strictly validate action
        action = (request.action or "").strip().upper()
        if action not in ("APPROVE", "REJECT"):
            return client_error(message=ERROR_INVALID_CONVERSION_ACTION, status_code=400)

        if action == "APPROVE":
            result = service.approve_conversion(conversion_id, current_user_id)
            conv_dict = {
                "id": result.id,
                "points_converted": result.points_converted,
                "conversion_type": result.conversion_type,
                "user_id": result.user_id,
                "user_name": result.user.name if result.user else None,
                "cash_amount": result.cash_amount,
                "status": result.status,
                "requested_at": result.requested_at,
                "approved_by": result.approved_by,
                "approved_by_name": result.approver.name if result.approver else None,
                "approved_at": result.approved_at,
            }
            data = PointsConversionResponse.model_validate(conv_dict)
            return success(data=data, message=SUCCESS_CONVERSION_APPROVED)
        else:
            result = service.reject_conversion(conversion_id, current_user_id)
            conv_dict = {
                "id": result.id,
                "points_converted": result.points_converted,
                "conversion_type": result.conversion_type,
                "user_id": result.user_id,
                "user_name": result.user.name if result.user else None,
                "cash_amount": result.cash_amount,
                "status": result.status,
                "requested_at": result.requested_at,
                "approved_by": result.approved_by,
                "approved_by_name": result.approver.name if result.approver else None,
                "approved_at": result.approved_at,
            }
            data = PointsConversionResponse.model_validate(conv_dict)
            return success(data=data, message=SUCCESS_CONVERSION_REJECTED)
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
    return success(data=data, message=SUCCESS_POLICIES_RETRIEVED)


@router.post("/rules", response_model=PointsPolicyResponse, status_code=status.HTTP_201_CREATED)
def create_points_rule(
    rule: PointsPolicyCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new points policy rule (HR only)."""
    if getattr(current_user, "role", None) not in (UserRole.HR.value, UserRole.ADMIN.value):
        return forbidden(ERROR_ONLY_HR_ADMIN_CREATE_RULE)

    service = StoreService(db)
    result = service.create_policy(rule)
    data = PointsPolicyResponse.model_validate(result)
    return created(data=data, message=SUCCESS_POINT_RULE_CREATED)


@router.put("/rules/{rule_id}", response_model=PointsPolicyResponse)
def update_points_rule(
    rule_id: int,
    rule: PointsPolicyUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a points policy rule (HR only)."""
    if getattr(current_user, "role", None) not in (UserRole.HR.value, UserRole.ADMIN.value):
        return forbidden(ERROR_ONLY_HR_ADMIN_UPDATE_RULE)

    service = StoreService(db)
    try:
        result = service.update_policy(rule_id, rule)
        data = PointsPolicyResponse.model_validate(result)
        return success(data=data, message=SUCCESS_POINT_RULE_UPDATED)
    except ValueError as e:
        return client_error(message=str(e))
