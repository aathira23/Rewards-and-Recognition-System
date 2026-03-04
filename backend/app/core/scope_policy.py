from typing import List, Optional, Dict, Any, Set
from fastapi import HTTPException, status
from app.utils.enums import UserRole, Scope

# Centralized Role-to-Scope Policy
# Defines the default scope and allowable scopes for each user role.
ROLE_SCOPE_POLICY: Dict[str, Dict[str, Any]] = {
    UserRole.ADMIN.value: {
        "default": Scope.ORG,
        "allowed": {Scope.ORG, Scope.DEPARTMENT, Scope.TEAM}
    },
    UserRole.HR.value: {
        "default": Scope.ORG,
        "allowed": {Scope.ORG, Scope.DEPARTMENT, Scope.TEAM}
    },
    UserRole.DEPT_HEAD.value: {
        "default": Scope.DEPARTMENT,
        "allowed": {Scope.DEPARTMENT, Scope.TEAM}
    },
    UserRole.MANAGER.value: {
        "default": Scope.TEAM,
        "allowed": {Scope.TEAM}
    },
    UserRole.EMPLOYEE.value: {
        "default": Scope.TEAM,
        "allowed": {Scope.TEAM}
    }
}

def resolve_effective_scope(requested_scope: Optional[Scope | str], user_role: str) -> Scope:
    """
    Validates whether the requested scope is allowed for the user's role
    and returns the final effective scope.
    
    Args:
        requested_scope: The scope requested by the user (ORG, DEPARTMENT, TEAM)
        user_role: The role of the current user
        
    Returns:
        The effective scope as a Scope Enum.
        
    Raises:
        HTTPException: If the requested scope is not permitted for the user's role.
    """
    policy = ROLE_SCOPE_POLICY.get(user_role)
    
    if not policy:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied: role not permitted for analytics"
        )
    
    # If string provided, convert to Enum
    target_scope = requested_scope
    if isinstance(requested_scope, str):
        try:
            target_scope = Scope(requested_scope.upper())
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid scope: {requested_scope}"
            )

    # Use default if no scope requested
    effective_scope = target_scope or policy["default"]
    
    # Validate permission
    if effective_scope not in policy["allowed"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Access denied: {effective_scope.value} scope is not permitted for {user_role} role"
        )
        
    return effective_scope
