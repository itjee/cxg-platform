from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, field_serializer


class LoginLogCreate(BaseModel):
    user_id: UUID | None = None
    user_type: str | None = None
    tenant_context: UUID | None = None
    username: str | None
    attempt_type: str
    success: bool
    failure_reason: str | None
    session_id: str | None
    ip_address: str
    user_agent: str | None
    country_code: str | None
    city: str | None
    mfa_used: bool
    mfa_method: str | None


class LoginLogRead(BaseModel):
    id: UUID
    created_at: datetime
    updated_at: datetime | None = None
    created_by: UUID | None = None
    updated_by: UUID | None = None
    user_id: UUID | None = None
    user_type: str | None = None
    tenant_context: UUID | None = None
    username: str | None
    attempt_type: str
    success: bool
    failure_reason: str | None
    session_id: str | None
    ip_address: str
    user_agent: str | None
    country_code: str | None
    city: str | None
    mfa_used: bool
    mfa_method: str | None

    @field_serializer("created_at", "updated_at", when_used="json")
    def serialize_datetime(self, dt: datetime | None) -> str | None:
        """시간을 타임존 정보 없이 한국 시간으로 직렬화"""
        if dt is None:
            return None
        # 이미 데이터베이스에서 한국 시간으로 변환된 상태이므로 타임존 정보 제거
        return dt.replace(tzinfo=None).isoformat()

    class Config:
        from_attributes = True


class LoginLogUpdate(BaseModel):
    user_id: UUID | None = None
    user_type: str | None = None
    tenant_context: UUID | None = None
    username: str | None = None
    attempt_type: str | None = None
    success: bool | None = None
    failure_reason: str | None = None
    session_id: str | None = None
    ip_address: str | None = None
    user_agent: str | None = None
    country_code: str | None = None
    city: str | None = None
    mfa_used: bool | None = None
    mfa_method: str | None = None


class LoginLogResponse(BaseModel):
    id: UUID
    created_at: datetime
    updated_at: datetime | None = None
    created_by: UUID | None = None
    updated_by: UUID | None = None
    user_id: UUID | None = None
    user_type: str | None = None
    tenant_context: UUID | None = None
    username: str | None
    attempt_type: str
    success: bool
    failure_reason: str | None
    session_id: str | None
    ip_address: str
    user_agent: str | None
    country_code: str | None
    city: str | None
    mfa_used: bool
    mfa_method: str | None

    @field_serializer("created_at", "updated_at", when_used="json")
    def serialize_datetime(self, dt: datetime | None) -> str | None:
        """시간을 타임존 정보 없이 한국 시간으로 직렬화"""
        if dt is None:
            return None
        # 이미 데이터베이스에서 한국 시간으로 변환된 상태이므로 타임존 정보 제거
        return dt.replace(tzinfo=None).isoformat()

    class Config:
        from_attributes = True


class LoginLogListResponse(BaseModel):
    items: list[LoginLogResponse]
    total: int
    page: int
    size: int
    pages: int


class LoginLogFilterRequest(BaseModel):
    user_id: str | None = None
    username: str | None = None
    attempt_type: str | None = None
    success: bool | None = None
    ip_address: str | None = None
    start_date: datetime | None = None
    end_date: datetime | None = None
    page: int = 1
    size: int = 20
