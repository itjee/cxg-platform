from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, field_serializer

from ..role.schemas import RoleResponse


class UserCreate(BaseModel):
    email: str
    username: str
    password: str
    full_name: str


class UserCreateRequest(BaseModel):
    email: str
    username: str
    password: str
    full_name: str


class UserListItemResponse(BaseModel):
    id: str
    username: str
    email: str
    full_name: str
    user_type: str
    created_at: str | None = None
    last_login_at: str | None = None

    class Config:
        from_attributes = True


class UserRead(BaseModel):
    id: str
    email: str | None = None
    username: str | None = None
    full_name: str | None = None
    created_at: str | None = None
    status: str | None = None
    last_login_at: str | None = None
    roles: list[RoleResponse] = []

    @field_serializer("id")
    def serialize_id(self, value: UUID | str) -> str:
        return str(value) if value else ""

    @field_serializer("created_at")
    def serialize_created_at(self, value: datetime | str | None) -> str | None:
        if value is None:
            return None
        if isinstance(value, datetime):
            return value.isoformat()
        return str(value)

    @field_serializer("last_login_at")
    def serialize_last_login_at(
        self, value: datetime | str | None
    ) -> str | None:
        if value is None:
            return None
        if isinstance(value, datetime):
            return value.isoformat()
        return str(value)

    class Config:
        from_attributes = True


class UserResponse(BaseModel):
    id: str
    email: str | None = None
    username: str | None = None
    full_name: str | None = None
    created_at: str | None = None
    status: str | None = None
    last_login_at: str | None = None
    roles: list[RoleResponse] = []

    @field_serializer("id")
    def serialize_id(self, value: UUID | str) -> str:
        return str(value) if value else ""

    @field_serializer("created_at")
    def serialize_created_at(self, value: datetime | str | None) -> str | None:
        if value is None:
            return None
        if isinstance(value, datetime):
            return value.isoformat()
        return str(value)

    @field_serializer("last_login_at")
    def serialize_last_login_at(
        self, value: datetime | str | None
    ) -> str | None:
        if value is None:
            return None
        if isinstance(value, datetime):
            return value.isoformat()
        return str(value)

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    email: str | None = None
    username: str | None = None
    password: str | None = None
    full_name: str | None = None


class UserUpdateRequest(BaseModel):
    email: str | None = None
    username: str | None = None
    password: str | None = None
    full_name: str | None = None


class UsersListResponse(BaseModel):
    users: list[UserListItemResponse]
    total: int
    skip: int
    limit: int
