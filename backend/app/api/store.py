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
    
    # 2. Conversions (Payroll/CSR)
    conversions = service.get_conversion_history(current_user_id)
    
    return success(
        data={
            "redemptions": redemptions,
            "conversions": conversions
        },
        message="History retrieved successfully"
    )
