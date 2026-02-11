"""
Wallet management API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user_id
from app.schemas.wallets import WalletResponse, WalletAllocateRequest, WalletRewardRequest

from app.utils.response import success

router = APIRouter()


@router.get("/manager", response_model=WalletResponse)
def get_manager_wallet(
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Get manager wallet balance and details."""
    # Placeholder for future logic
    return success(message="Manager wallet logic not yet implemented", status_code=501)


@router.post("/manager/allocate", status_code=status.HTTP_201_CREATED)
def allocate_manager_budget(
    request: WalletAllocateRequest,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """HR allocates budget to manager wallet."""
    return success(message="Budget allocation not yet implemented", status_code=501)


@router.post("/manager/reward", status_code=status.HTTP_201_CREATED)
def manager_reward_employee(
    request: WalletRewardRequest,
    db: Session = Depends(get_db),
    current_user_id: int = Depends(get_current_user_id)
):
    """Manager rewards employee from their wallet."""
    return success(message="Manager reward logic not yet implemented", status_code=501)
