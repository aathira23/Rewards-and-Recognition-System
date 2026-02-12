"""
Wallet management API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.dependencies import get_current_user_id
from app.schemas.wallets import WalletResponse, WalletAllocateRequest, WalletRewardRequest, BulkBudgetAllocationRequest

from app.services.wallets_service import WalletsService
from app.utils.response import success, created, client_error
from app.core.dependencies import get_current_user

router = APIRouter()


@router.get("/manager", response_model=WalletResponse)
def get_manager_wallet(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get manager wallet balance and details."""
    service = WalletsService(db)
    wallet = service.get_manager_wallet(current_user.id)
    if not wallet:
        # Create one if it doesn't exist? Or just return 0 balance.
        from app.utils.enums import WalletType
        wallet = service.get_or_create_wallet(current_user.id, WalletType.MANAGER)
    
    data = WalletResponse.model_validate(wallet)
    return success(data=data, message="Manager wallet retrieved")


@router.post("/manager/allocate", response_model=WalletResponse, status_code=status.HTTP_201_CREATED)
def allocate_manager_budget(
    request: WalletAllocateRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """HR allocates budget to manager wallet."""
    # Simple role check for now
    if current_user.role not in ["HR", "ADMIN"]:
        return client_error(message="Only HR or Admin can allocate budget", status_code=403)
    
    service = WalletsService(db)
    funding = service.allocate_budget(
        manager_id=request.manager_id,
        points=request.points,
        allocated_by=current_user.id
    )
    
    # Return the updated manager wallet
    wallet = service.get_manager_wallet(request.manager_id)
    data = WalletResponse.model_validate(wallet)
    return created(data=data, message=f"Allocated {request.points} points to manager")


@router.post("/manager/reward", status_code=status.HTTP_201_CREATED)
def manager_reward_employee(
    request: WalletRewardRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Manager rewards employee from their wallet."""
    if current_user.role not in ["MANAGER", "ADMIN", "DEPT_HEAD"]:
       return client_error(message="Only managers can reward employees", status_code=403)

    service = WalletsService(db)
    try:
        batch = service.manager_reward_employee(
            manager_id=current_user.id,
            employee_id=request.employee_id,
            points=request.points,
            reason=request.reason
        )
        return created(message=f"Successfully rewarded employee with {request.points} points")
    except ValueError as e:
        return client_error(message=str(e))


@router.post("/manager/bulk-allocate")
def bulk_allocate_budget(
    request: BulkBudgetAllocationRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """HR bulk allocates budget to multiple managers."""
    from app.utils.enums import UserRole
    if current_user.role != UserRole.HR.value:
        return client_error(message="Only HR can bulk allocate budget", status_code=403)
        
    service = WalletsService(db)
    count = service.bulk_allocate_budget(
        points=request.points,
        allocated_by=current_user.id,
        department_id=request.department_id,
        user_ids=request.user_ids,
        role_filter=request.role_filter
    )
    
    return success(data={"updated_wallets": count}, message=f"Successfully allocated points to {count} wallets")
