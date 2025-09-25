from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


# Existing Request/Response classes for API compatibility
class UserRoleCreateRequest(BaseModel):
    user_id: str
    role_id: str


class UserRoleResponse(BaseModel):
    user_id: str
    role_id: str

    class Config:
        from_attributes = True


class UserRoleUpdateRequest(BaseModel):
    # UserRole is typically managed by creation/deletion, not update
    # but including for completeness if partial updates were ever needed.
    user_id: str | None = None
    role_id: str | None = None


# New PascalCase schema classes for service layer
class UserRoleCreate(BaseModel):
    """Schema for creating a new user role assignment"""

    user_id: UUID
    role_id: UUID
    scope: str = "GLOBAL"
    tenant_context: UUID | None = None
    granted_by: UUID | None = None
    expires_at: datetime | None = None
    status: str = "ACTIVE"


class UserRoleRead(BaseModel):
    """Schema for reading user role data"""

    id: UUID
    user_id: UUID
    role_id: UUID
    scope: str
    tenant_context: UUID | None
    granted_by: UUID | None
    granted_at: datetime | None
    expires_at: datetime | None
    status: str
    created_at: datetime
    updated_at: datetime | None

    class Config:
        from_attributes = True


class UserRoleUpdate(BaseModel):
    """Schema for updating user role data"""

    scope: str | None = None
    tenant_context: UUID | None = None
    expires_at: datetime | None = None
    status: str | None = None


__all__ = [
    "UserRoleCreateRequest",
    "UserRoleResponse",
    "UserRoleUpdateRequest",
    "UserRoleCreate",
    "UserRoleRead",
    "UserRoleUpdate",
]
