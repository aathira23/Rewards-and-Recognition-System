"""
Store API endpoints (rewards catalog, redemptions).
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user_id
from app.schemas.rewards import RewardCreate, RewardUpdate, RewardResponse
from app.schemas.redemptions import RedemptionCreate, RedemptionResponse

router = APIRouter()


# Reward Items
@router.get("/items", response_model=List[RewardResponse])
def get_store_items(
    reward_type: str = None,
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get reward catalog items."""
    # TODO: Implement get store items logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.get("/items/{item_id}", response_model=RewardResponse)
def get_store_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get specific reward item details."""
    # TODO: Implement get store item logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.post("/items", response_model=RewardResponse, status_code=status.HTTP_201_CREATED)
def create_store_item(
    item: RewardCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Create a new reward item (admin only)."""
    # TODO: Implement create store item logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.put("/items/{item_id}", response_model=RewardResponse)
def update_store_item(
    item_id: int,
    item: RewardUpdate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Update a reward item (admin only)."""
    # TODO: Implement update store item logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.patch("/items/{item_id}/deactivate")
def deactivate_store_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Deactivate a reward item (admin only)."""
    # TODO: Implement deactivate store item logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


# Redemptions
@router.post("/redeem", response_model=RedemptionResponse, status_code=status.HTTP_201_CREATED)
def redeem_reward(
    redemption: RedemptionCreate,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Redeem points for a reward."""
    # TODO: Implement redeem reward logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.get("/redemptions", response_model=List[RedemptionResponse])
def get_redemptions(
    skip: int = 0,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get redemption history."""
    # TODO: Implement get redemptions logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )
