"""
Wallet management API endpoints.
"""
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.wallets import WalletResponse, WalletAllocateRequest, WalletRewardRequest, BulkBudgetAllocationRequest

from app.services.wallets_service import WalletsService
from app.utils.response import success, created, client_error, forbidden
from app.utils.enums import UserRole
from app.core.dependencies import get_current_user

router = APIRouter()


@router.get("/manager", response_model=WalletResponse)
def get_manager_wallet(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Get manager wallet balance and details."""
    service = WalletsService(db)
    # Managers, Dept Heads, or HR/Admin may view manager wallet
    if getattr(current_user, "role", None) not in (UserRole.MANAGER.value, UserRole.DEPT_HEAD.value, UserRole.HR.value, UserRole.ADMIN.value):
        return forbidden("Only managers, dept heads, or HR/Admin may view manager wallets")

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
    # HR/Admin only
    if getattr(current_user, "role", None) not in (UserRole.HR.value, UserRole.ADMIN.value):
        return forbidden("Only HR/Admin can allocate budget")

    service = WalletsService(db)
    try:
        funding = service.allocate_budget(
            manager_id=request.manager_id,
            points=request.points,
            allocated_by=current_user.id
        )

        # Return the updated manager wallet
        wallet = service.get_manager_wallet(request.manager_id)
        data = WalletResponse.model_validate(wallet)
        return created(data=data, message=f"Allocated {request.points} points to manager")
    except ValueError as e:
        return client_error(message=str(e), status_code=400)


@router.post("/manager/reward", status_code=status.HTTP_201_CREATED)
def manager_reward_employee(
    request: WalletRewardRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Manager rewards employee from their wallet."""
    # Only managers, dept heads, HR or Admin may reward employees
    allowed_roles = (UserRole.MANAGER.value, UserRole.DEPT_HEAD.value, UserRole.HR.value, UserRole.ADMIN.value)
    if getattr(current_user, "role", None) not in allowed_roles:
        return forbidden("You do not have permission to reward employees from a budget")

    service = WalletsService(db)
    try:
        batch = service.manager_reward_employee(
            manager_id=current_user.id,
            employee_id=request.employee_id,
            points=request.points,
            reason=request.reason
        )
        # Return useful data (batch id and awarded details) instead of null
        resp_data = {
            "batch_id": getattr(batch, "id", None),
            "employee_id": request.employee_id,
            "points": request.points,
        }
        return created(data=resp_data, message=f"Successfully rewarded employee with {request.points} points")
    except ValueError as e:
        return client_error(message=str(e), status_code=400)


@router.post("/manager/bulk-allocate")
def bulk_allocate_budget(
    request: BulkBudgetAllocationRequest,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """HR bulk allocates budget to multiple managers."""
    if getattr(current_user, "role", None) not in (UserRole.HR.value, UserRole.ADMIN.value):
        return forbidden("Only HR/Admin can bulk allocate budget")

    service = WalletsService(db)
    count = service.bulk_allocate_budget(
        points=request.points,
        allocated_by=current_user.id,
        department_id=request.department_id,
        user_ids=request.user_ids,
        role_filter=request.role_filter
    )

    return success(data={"updated_wallets": count}, message=f"Successfully allocated points to {count} wallets")
