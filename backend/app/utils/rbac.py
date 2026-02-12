"""
Role-based access control decorators and utilities.
"""
from functools import wraps
from typing import List
from fastapi import HTTPException, status, Depends
from app.core.dependencies import get_current_user
from app.utils.enums import UserRole


def require_roles(allowed_roles: List[str]):
    """
    Decorator to enforce role-based access control.
    
    Usage:
        @router.get("/admin-only")
        @require_roles([UserRole.HR.value])
        def admin_endpoint(current_user = Depends(get_current_user)):
            ...
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, current_user=None, **kwargs):
            if current_user is None:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Authentication required"
                )
            
            if current_user.role not in allowed_roles:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Access denied. Required roles: {', '.join(allowed_roles)}"
                )
            
            return await func(*args, current_user=current_user, **kwargs)
        return wrapper
    return decorator


def require_hr(func):
    """Shortcut decorator for HR-only endpoints."""
    return require_roles([UserRole.HR.value])(func)


def require_manager_or_above(func):
    """Shortcut decorator for Manager, Dept Head, or HR."""
    return require_roles([
        UserRole.MANAGER.value,
        UserRole.DEPT_HEAD.value,
        UserRole.HR.value
    ])(func)
