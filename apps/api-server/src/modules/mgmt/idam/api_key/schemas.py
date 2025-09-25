from datetime import datetime

from pydantic import BaseModel, Field


class ApiKeyCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    expires_at: datetime | None = None


class ApiKeyCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    expires_at: datetime | None = None


class ApiKeyRead(BaseModel):
    id: str
    name: str
    user_id: str
    created_at: datetime
    expires_at: datetime | None = None
    is_active: bool

    class Config:
        from_attributes = True


class ApiKeyResponse(BaseModel):
    id: str
    name: str
    user_id: str
    created_at: datetime
    expires_at: datetime | None = None
    is_active: bool

    class Config:
        from_attributes = True


class ApiKeyUpdate(BaseModel):
    name: str | None = None
    expires_at: datetime | None = None
    is_active: bool | None = None


class ApiKeyUpdateRequest(BaseModel):
    name: str | None = None
    expires_at: datetime | None = None
    is_active: bool | None = None
