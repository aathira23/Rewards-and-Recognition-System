"""
Authentication API endpoints.
"""
from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import (
    verify_password,
    create_access_token,
)
from app.core.config import settings
from app.models.users import User
from app.schemas.users import Token, UserLogin
from app.utils.response import success

router = APIRouter()


@router.post("/login", response_model=Token)
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    """Login endpoint for user authentication. Returns a long-lived access token."""
    user = db.query(User).filter(User.email == login_data.email).first()
    if not user or not verify_password(login_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Token expires in 24 hours for easier testing/development
    access_expires = timedelta(hours=24)
    token_data = {"sub": str(user.id), "email": user.email, "role": user.role}

    access_token = create_access_token(data=token_data, expires_delta=access_expires)

    return success(
        data={"access_token": access_token, "token_type": "bearer"},
        message="Login successful",
    )
