from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class PermissionCreate(BaseModel):
    permission_code: str = Field(..., min_length=1, max_length=100)
    permission_name: str = Field(..., min_length=1, max_length=100)
    description: str | None = None
    category: str = Field(..., min_length=1, max_length=50)
    resource_type: str = Field(..., min_length=1, max_length=50)
    action: str = Field(..., min_length=1, max_length=50)
    scope: str = Field(default="GLOBAL", max_length=20)
    applies_to: str = Field(default="ALL", max_length=20)
    is_system: bool = Field(default=False)
    status: str = Field(default="ACTIVE", max_length=20)


class PermissionCreateRequest(BaseModel):
    permission_code: str = Field(..., min_length=1, max_length=100)
    permission_name: str = Field(..., min_length=1, max_length=100)
    description: str | None = None
    category: str = Field(..., min_length=1, max_length=50)
    resource_type: str = Field(..., min_length=1, max_length=50)
    action: str = Field(..., min_length=1, max_length=50)
    scope: str = Field(default="GLOBAL", max_length=20)
    applies_to: str = Field(default="ALL", max_length=20)
    is_system: bool = Field(default=False)
    status: str = Field(default="ACTIVE", max_length=20)


class PermissionRead(BaseModel):
    id: UUID
    permission_code: str
    permission_name: str
    description: str | None = None
    category: str
    resource_type: str
    action: str
    scope: str
    applies_to: str
    is_system: bool
    status: str
    created_at: datetime
    updated_at: datetime | None = None
    created_by: UUID | None = None
    updated_by: UUID | None = None

    class Config:
        from_attributes = True


class PermissionResponse(BaseModel):
    id: UUID
    permission_code: str
    permission_name: str
    description: str | None = None
    category: str
    resource_type: str
    action: str
    scope: str
    applies_to: str
    is_system: bool
    status: str
    created_at: datetime
    updated_at: datetime | None = None
    created_by: UUID | None = None
    updated_by: UUID | None = None

    class Config:
        from_attributes = True


class PermissionUpdate(BaseModel):
    permission_name: str | None = None
    description: str | None = None
    category: str | None = None
    resource_type: str | None = None
    action: str | None = None
    scope: str | None = None
    applies_to: str | None = None
    is_system: bool | None = None
    status: str | None = None


class PermissionUpdateRequest(BaseModel):
    permission_name: str | None = None
    description: str | None = None
    category: str | None = None
    resource_type: str | None = None
    action: str | None = None
    scope: str | None = None
    applies_to: str | None = None
    is_system: bool | None = None
    status: str | None = None
