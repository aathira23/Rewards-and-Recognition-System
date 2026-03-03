from typing import List, Optional, Dict, Any
from fastapi import HTTPException, status
from app.utils.enums import UserRole

# Centralized Role-to-Scope Policy
# Defines the default scope and allowable scopes for each user role.
ROLE_SCOPE_POLICY: Dict[str, Dict[str, Any]] = {
    UserRole.ADMIN.value: {
        "default": "ORG",
        "allowed": ["ORG", "DEPARTMENT", "TEAM"]
    },
    UserRole.HR.value: {
        "default": "ORG",
        "allowed": ["ORG", "DEPARTMENT", "TEAM"]
    },
    UserRole.DEPT_HEAD.value: {
        "default": "DEPARTMENT",
        "allowed": ["DEPARTMENT", "TEAM"]
    },
    UserRole.MANAGER.value: {
        "default": "TEAM",
        "allowed": ["TEAM"]
    },
    UserRole.EMPLOYEE.value: {
        "default": "TEAM",
        "allowed": ["TEAM"]
    }
}

def resolve_effective_scope(requested_scope: Optional[str], user_role: str) -> str:
    """
    Validates whether the requested scope is allowed for the user's role
    and returns the final effective scope.
    
    Args:
        requested_scope: The scope requested by the user (ORG, DEPARTMENT, TEAM)
        user_role: The role of the current user
        
    Returns:
        The effective scope to be used for analytics.
        
    Raises:
        HTTPException: If the requested scope is not permitted for the user's role.
    """
    policy = ROLE_SCOPE_POLICY.get(user_role)
    
    if not policy:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied: role not permitted for analytics"
        )
    
    # Use default if no scope requested
    effective_scope = requested_scope or policy["default"]
    
    # Validate permission
    if effective_scope not in policy["allowed"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Access denied: {effective_scope} scope is not permitted for {user_role} role"
        )
        
    return effective_scope
