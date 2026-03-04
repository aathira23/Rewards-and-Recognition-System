"""
Configuration API endpoints.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.utils.enums import UserRole
from app.services.config_service import ConfigService
from app.schemas.system_config import SystemConfigResponse, SystemConfigUpdate
from app.utils.response import success, client_error
from app.utils.constants import ERROR_ACCESS_DENIED, SUCCESS_CONFIGS_RETRIEVED, ERROR_CONFIG_RETRIEVAL_FAILED, SUCCESS_CONFIG_UPDATED

router = APIRouter()


@router.get("/", response_model=List[SystemConfigResponse])
def list_configs(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """List all system configurations (Admin/HR only)."""
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        return client_error(message=ERROR_ACCESS_DENIED, status_code=403)

    service = ConfigService(db)
    try:
        configs = service.get_all_configs()
        return success(data=[SystemConfigResponse.model_validate(c) for c in configs], message=SUCCESS_CONFIGS_RETRIEVED)
    except Exception as e:
        return client_error(message=ERROR_CONFIG_RETRIEVAL_FAILED.format(str(e)), status_code=500)


@router.put("/{key}")
def update_config(
    key: str,
    payload: SystemConfigUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Update a system configuration (Admin/HR only)."""
    if current_user.role not in (UserRole.HR.value, UserRole.ADMIN.value):
        return client_error(message=ERROR_ACCESS_DENIED, status_code=403)

    service = ConfigService(db)
    config = service.set_config(key, payload.value, payload.description)
    return success(data=SystemConfigResponse.model_validate(config), message=f"Config '{key}' updated")


@router.get("/feature-flags")
def get_feature_flags(
    db: Session = Depends(get_db),
):
    """Public endpoint — returns current feature flag values (no auth required)."""
    flags = get_all_feature_flags(db)
    return success(data=flags, message="Feature flags retrieved")
