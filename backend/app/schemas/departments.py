"""
Department schemas for request/response validation.
"""
from pydantic import BaseModel


class DepartmentBase(BaseModel):
    """Base department schema."""
    name: str


class DepartmentCreate(DepartmentBase):
    """Schema for creating a department."""
    pass


class DepartmentResponse(DepartmentBase):
    """Schema for department response."""
    id: int
    
    class Config:
        from_attributes = True
