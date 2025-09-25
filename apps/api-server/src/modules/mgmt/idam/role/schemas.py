from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class RoleCreate(BaseModel):
    role_code: str = Field(..., min_length=1, max_length=100)
    role_name: str = Field(..., min_length=1, max_length=100)
    description: str | None = None
    role_type: str = Field(default="USER", max_length=50)
    scope: str = Field(default="GLOBAL", max_length=20)
    is_default: bool = Field(default=False)
    priority: int = Field(default=100)
    status: str = Field(default="ACTIVE", max_length=20)


class RoleCreateRequest(BaseModel):
    role_code: str = Field(..., min_length=1, max_length=100)
    role_name: str = Field(..., min_length=1, max_length=100)
    description: str | None = None
    role_type: str = Field(default="USER", max_length=50)
    scope: str = Field(default="GLOBAL", max_length=20)
    is_default: bool = Field(default=False)
    priority: int = Field(default=100)
    status: str = Field(default="ACTIVE", max_length=20)


class RoleRead(BaseModel):
    id: UUID
    role_code: str
    role_name: str
    description: str | None = None
    role_type: str
    scope: str
    is_default: bool
    priority: int
    status: str
    created_at: datetime
    updated_at: datetime | None = None
    created_by: UUID | None = None
    updated_by: UUID | None = None

    class Config:
        from_attributes = True


class RoleResponse(BaseModel):
    id: UUID
    role_code: str
    role_name: str
    description: str | None = None
    role_type: str
    scope: str
    is_default: bool
    priority: int
    status: str
    created_at: datetime
    updated_at: datetime | None = None
    created_by: UUID | None = None
    updated_by: UUID | None = None

    class Config:
        from_attributes = True


class RoleUpdate(BaseModel):
    role_name: str | None = None
    description: str | None = None
    role_type: str | None = None
    scope: str | None = None
    is_default: bool | None = None
    priority: int | None = None
    status: str | None = None


class RoleUpdateRequest(BaseModel):
    role_name: str | None = None
    description: str | None = None
    role_type: str | None = None
    scope: str | None = None
    is_default: bool | None = None
    priority: int | None = None
    status: str | None = None
