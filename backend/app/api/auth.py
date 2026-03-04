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
from app.models.users import User
from app.utils.constants import ERROR_INCORRECT_LOGIN, SUCCESS_LOGIN

from fastapi.security import OAuth2PasswordRequestForm

router = APIRouter()


@router.post("/login")
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """Login endpoint compatible with OAuth2 Password Flow."""
    user = db.query(User).filter(User.email == form_data.username).first()
    if not user or not verify_password(form_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=ERROR_INCORRECT_LOGIN,
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_expires = timedelta(hours=24)
    token_data = {"sub": str(user.id), "email": user.email, "role": user.role}
    access_token = create_access_token(data=token_data, expires_delta=access_expires)

    # Return standard OAuth2 response at the top level for Swagger compatibility
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "message": SUCCESS_LOGIN
    }
