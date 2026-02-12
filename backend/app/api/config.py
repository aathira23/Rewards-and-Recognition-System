"""
Configuration API endpoints.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.utils.enums import UserRole
from app.services.config_service import ConfigService
from app.schemas.system_config import SystemConfigResponse, SystemConfigUpdate
from app.utils.response import success, client_error

router = APIRouter()


@router.get("/", response_model=List[SystemConfigResponse])
def list_configs(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """List all system configurations (Admin/HR only)."""
    if current_user.role != UserRole.HR.value:
        return client_error(message="Access denied", status_code=403)
        
    service = ConfigService(db)
    configs = service.get_all_configs()
    return success(data=configs, message="Configurations retrieved")


@router.put("/{key}")
def update_config(
    key: str,
    payload: SystemConfigUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a system configuration (Admin/HR only)."""
    if current_user.role != UserRole.HR.value:
        return client_error(message="Access denied", status_code=403)
        
    service = ConfigService(db)
    config = service.set_config(key, payload.value, payload.description)
    return success(data=SystemConfigResponse.model_validate(config), message=f"Config '{key}' updated")
