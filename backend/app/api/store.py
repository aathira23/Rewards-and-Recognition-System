"""
Catalog & Rewards API - Catalog browsing, redemptions, and point conversions.
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user_id
from app.services.store_service import StoreService
from app.schemas.rewards import RewardResponse
from app.schemas.redemptions import RedemptionCreate, RedemptionResponse
from app.schemas.points_conversion import PointsConversionCreate, PointsConversionResponse
import logging
from app.utils.response import success, created, client_error

router = APIRouter()


@router.get("/items", response_model=List[RewardResponse])
def get_catalog_items(db: Session = Depends(get_db)):
    """Browse all active rewards in the catalog."""
    service = StoreService(db)
    items = service.get_catalog()
    # Convert models to schemas
    data = [RewardResponse.model_validate(i) for i in items]
    return success(data=data, message="Catalog retrieved successfully")


@router.post("/redeem", response_model=RedemptionResponse)
def redeem_reward(
    redemption_data: RedemptionCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Instantly redeem a reward (Merchandise/Vouchers). Deducts points immediately."""
    service = StoreService(db)
    try:
        redemption = service.redeem_reward(
            user_id=current_user_id,
            reward_id=redemption_data.reward_id
        )
        data = RedemptionResponse.model_validate(redemption)
        return created(data=data, message="Redemption successful")
    except ValueError as e:
        logger = logging.getLogger(__name__)
        logger.exception("Redemption failed for user %s reward %s: %s", current_user_id, redemption_data.reward_id, str(e))
        return client_error(message=str(e))




@router.get("/history")
def get_redemption_history(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
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
    conversion_data = []
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
        conversion_data.append(PointsConversionResponse.model_validate(conv_dict))
    
    return success(
        data={
            "redemptions": redemption_data,
            "conversions": conversion_data
        },
        message="History retrieved successfully"
    )
