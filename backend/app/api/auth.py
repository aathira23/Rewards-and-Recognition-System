"""
Authentication API endpoints.
"""
from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import verify_password, create_access_token
from app.core.config import settings
from app.models.users import User
from app.schemas.users import Token
from app.utils.response import success, unauthorized

router = APIRouter()


@router.post("/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """Login endpoint for user authentication.

    Returns JWT access token on successful authentication.
    """
    # OAuth2PasswordRequestForm uses `username` field — we expect email there
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    token_data = {"sub": str(user.id), "email": user.email, "role": user.role}
    access_token = create_access_token(data=token_data, expires_delta=access_token_expires)

    return success(data={"access_token": access_token, "token_type": "bearer"}, message="Login successful")


@router.post("/logout")
def logout():
    """Logout endpoint (token invalidation if needed)."""
    # Token invalidation (blacklist) is not implemented; this is a placeholder.
    return success(data=None, message="Logged out successfully")
