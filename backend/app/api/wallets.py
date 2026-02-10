"""
Wallet management API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user_id
from app.schemas.wallets import WalletResponse, WalletAllocateRequest, WalletRewardRequest

router = APIRouter()


@router.get("/manager", response_model=WalletResponse)
def get_manager_wallet(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get manager wallet balance and details."""
    # TODO: Implement get manager wallet logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.post("/manager/allocate", status_code=status.HTTP_201_CREATED)
def allocate_manager_budget(
    request: WalletAllocateRequest,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """HR allocates budget to manager wallet."""
    # TODO: Implement budget allocation logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )


@router.post("/manager/reward", status_code=status.HTTP_201_CREATED)
def manager_reward_employee(
    request: WalletRewardRequest,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Manager rewards employee from their wallet."""
    # TODO: Implement manager reward logic
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Not yet implemented"
    )
