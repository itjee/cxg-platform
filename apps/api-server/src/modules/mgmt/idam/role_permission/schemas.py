from pydantic import BaseModel


# Existing Request/Response classes for API compatibility
class RolePermissionCreateRequest(BaseModel):
    role_id: str
    permission_id: str


class RolePermissionResponse(BaseModel):
    role_id: str
    permission_id: str

    class Config:
        from_attributes = True


class RolePermissionUpdateRequest(BaseModel):
    # RolePermission is typically managed by creation/deletion, not update
    # but including for completeness if partial updates were ever needed.
    role_id: str | None = None
    permission_id: str | None = None


# New PascalCase classes for service layer
class RolePermissionCreate(BaseModel):
    role_id: str
    permission_id: str


class RolePermissionRead(BaseModel):
    role_id: str
    permission_id: str

    class Config:
        from_attributes = True


class RolePermissionUpdate(BaseModel):
    role_id: str | None = None
    permission_id: str | None = None


__all__ = [
    "RolePermissionCreateRequest",
    "RolePermissionResponse",
    "RolePermissionUpdateRequest",
    "RolePermissionCreate",
    "RolePermissionRead",
    "RolePermissionUpdate",
]
