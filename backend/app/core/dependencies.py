"""
Dependency injection utilities.
"""
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import decode_access_token

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/login")


def get_current_user_id(token: str = Depends(oauth2_scheme)) -> int:
    """
    Get current user ID from JWT token.
    
    Args:
        token: JWT access token
        
    Returns:
        User ID
        
    Raises:
        HTTPException: If token is invalid or user not found
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    payload = decode_access_token(token)
    if payload is None:
        raise credentials_exception
    
    user_id: Optional[int] = payload.get("sub")
    if user_id is None:
        raise credentials_exception
    
    return int(user_id)


def get_current_user(
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id)
):
    """
    Get current authenticated user from database.
    
    Args:
        db: Database session
        user_id: Current user ID from token
        
    Returns:
        User model instance
        
    Raises:
        HTTPException: If user not found
    """
    # TODO: Import User model and query database
    # from app.models.users import User
    # user = db.query(User).filter(User.id == user_id).first()
    # if user is None:
    #     raise HTTPException(status_code=404, detail="User not found")
    # return user
    pass
