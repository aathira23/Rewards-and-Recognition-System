"""
Catalog & Rewards API - Catalog browsing, redemptions, and point conversions.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user_id, get_current_user, oauth2_scheme
from app.services.user_profiles_client import get_users_batch
from app.services.store_service import StoreService
from app.schemas.rewards import RewardResponse, RewardCreate, RewardUpdate
from app.schemas.redemptions import RedemptionCreate, RedemptionResponse
from app.schemas.points_conversion import PointsConversionResponse
import logging
from app.utils.response import success, created, client_error, paginated_success
from app.utils.enums import UserRole
from app.utils.constants import (
    DEFAULT_PAGE_SIZE, SUCCESS_STORE_ITEM_CREATED, SUCCESS_CATALOG_RETRIEVED,
    ERROR_ONLY_HR_CREATE_STORE_ITEM, ERROR_ONLY_HR_UPDATE_STORE_ITEM,
    SUCCESS_STORE_ITEM_UPDATED, SUCCESS_REDEMPTION_SUCCESSFUL, SUCCESS_HISTORY_RETRIEVED
)

router = APIRouter()


@router.get("/items")
def get_catalog_items(
    page: int = 1,
    per_page: int = DEFAULT_PAGE_SIZE,
    include_inactive: bool = False,
    db: Session = Depends(get_db),
):
    """Browse rewards in the catalog. Pass include_inactive=true to see all (HR/admin use)."""
    service = StoreService(db)
    total, items = service.get_catalog(page=page, per_page=per_page, include_inactive=include_inactive)
    # Convert models to schemas
    data = [RewardResponse.model_validate(i) for i in items]
    return paginated_success(
        items=data,
        total=total,
        page=page,
        per_page=per_page,
        message=SUCCESS_CATALOG_RETRIEVED,
    )


@router.post("/items", response_model=RewardResponse)
def create_store_item(
    reward_data: RewardCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Create a new item in the store catalog (HR/Admin only)."""
    # Check if user has HR/Admin role
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=ERROR_ONLY_HR_CREATE_STORE_ITEM
        )

    service = StoreService(db)
    try:
        reward = service.create_reward(reward_data)
        data = RewardResponse.model_validate(reward)
        return created(data=data, message=SUCCESS_STORE_ITEM_CREATED)
    except Exception as e:
        logger = logging.getLogger(__name__)
        logger.exception("Failed to create store item: %s", str(e))
        return client_error(message=str(e))


@router.put("/items/{reward_id}", response_model=RewardResponse)
def update_store_item(
    reward_id: int,
    reward_data: RewardUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a store item including stock quantity and active status (HR/Admin only)."""
    # Check if user has HR/Admin role
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=ERROR_ONLY_HR_UPDATE_STORE_ITEM
        )

    service = StoreService(db)
    try:
        reward = service.update_reward(reward_id, reward_data)
        data = RewardResponse.model_validate(reward)
        return success(data=data, message=SUCCESS_STORE_ITEM_UPDATED)
    except ValueError as e:
        logger = logging.getLogger(__name__)
        logger.exception("Failed to update store item %s: %s", reward_id, str(e))
        return client_error(message=str(e))


@router.post("/redeem", response_model=RedemptionResponse)
def redeem_reward(
    redemption_data: RedemptionCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id),
    token: str = Depends(oauth2_scheme),
):
    """Instantly redeem a reward (Merchandise/Vouchers). Deducts points immediately."""
    service = StoreService(db, token=token)
    try:
        redemption = service.redeem_reward(
            user_id=current_user_id,
            reward_id=redemption_data.reward_id
        )
        data = RedemptionResponse.model_validate(redemption)
        return created(data=data, message=SUCCESS_REDEMPTION_SUCCESSFUL)
    except ValueError as e:
        logger = logging.getLogger(__name__)
        logger.exception("Redemption failed for user %s reward %s: %s", current_user_id, redemption_data.reward_id, str(e))
        return client_error(message=str(e))




@router.get("/history")
def get_redemption_history(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id),
    token: str = Depends(oauth2_scheme)
):
    """Get history of all redemptions and conversion requests."""
    service = StoreService(db)

    # 1. Standard Redemptions (Merch/Vouchers)
    redemptions = service.get_redemption_history(current_user_id)
    redemption_data = []
    for r in redemptions:
        item = RedemptionResponse.model_validate(r)
        # Enrich with reward details
        if r.reward:
            item.reward_name = r.reward.name
            item.reward_category = r.reward.reward_type
        redemption_data.append(item)

    # 2. Conversions (Payroll/CSR)
    conversions = service.get_conversion_history(current_user_id)
    _uid_set = {c.user_id for c in conversions} | {c.approved_by for c in conversions if c.approved_by}
    _users_map = {uid: p.name for uid, p in get_users_batch(list(_uid_set), token).items()} if _uid_set else {}
    conversion_data = []
    for c in conversions:
        conv_dict = {
            "id": c.id,
            "points_converted": c.points_converted,
            "conversion_type": c.conversion_type,
            "user_id": c.user_id,
            "user_name": _users_map.get(c.user_id),
            "cash_amount": c.cash_amount,
            "status": c.status,
            "requested_at": c.requested_at,
            "approved_by": c.approved_by,
            "approved_by_name": _users_map.get(c.approved_by) if c.approved_by else None,
            "approved_at": c.approved_at,
        }
        conversion_data.append(PointsConversionResponse.model_validate(conv_dict))

    return success(
        data={
            "redemptions": redemption_data,
            "conversions": conversion_data
        },
        message=SUCCESS_HISTORY_RETRIEVED
    )
