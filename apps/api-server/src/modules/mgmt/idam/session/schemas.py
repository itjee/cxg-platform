from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, field_serializer


class SessionCreate(BaseModel):
    session_id: str
    user_id: UUID | None = None
    fingerprint: str | None = None
    user_agent: str | None = None
    ip_address: str
    country_code: str | None = None
    city: str | None = None
    status: str = "ACTIVE"
    expires_at: datetime
    last_activity_at: datetime
    mfa_verified: bool = False
    mfa_verified_at: datetime | None = None


class SessionCreateRequest(BaseModel):
    session_id: str
    user_id: UUID | None = None
    fingerprint: str | None = None
    user_agent: str | None = None
    ip_address: str
    country_code: str | None = None
    city: str | None = None
    status: str = "ACTIVE"
    expires_at: datetime
    last_activity_at: datetime
    mfa_verified: bool = False
    mfa_verified_at: datetime | None = None


class SessionRead(BaseModel):
    id: UUID
    created_at: datetime
    updated_at: datetime | None = None
    created_by: UUID | None = None
    updated_by: UUID | None = None
    session_id: str
    user_id: UUID | None = None
    fingerprint: str | None = None
    user_agent: str | None = None
    ip_address: str
    country_code: str | None = None
    city: str | None = None
    status: str
    expires_at: datetime
    last_activity_at: datetime
    mfa_verified: bool = False
    mfa_verified_at: datetime | None = None

    class Config:
        from_attributes = True


class SessionResponse(BaseModel):
    id: UUID
    created_at: datetime
    updated_at: datetime | None = None
    created_by: UUID | None = None
    updated_by: UUID | None = None
    session_id: str
    user_id: UUID | None = None
    fingerprint: str | None = None
    user_agent: str | None = None
    ip_address: str
    country_code: str | None = None
    city: str | None = None
    status: str
    expires_at: datetime
    last_activity_at: datetime
    mfa_verified: bool = False
    mfa_verified_at: datetime | None = None
    # User 정보
    username: str | None = None
    email: str | None = None
    full_name: str | None = None

    @field_serializer(
        "created_at",
        "updated_at",
        "expires_at",
        "last_activity_at",
        "mfa_verified_at",
        when_used="json",
    )
    def serialize_datetime(self, dt: datetime | None) -> str | None:
        """시간을 타임존 정보 없이 한국 시간으로 직렬화"""
        if dt is None:
            return None
        # 이미 데이터베이스에서 한국 시간으로 변환된 상태이므로 타임존 정보 제거
        return dt.replace(tzinfo=None).isoformat()

    class Config:
        from_attributes = True


class SessionUpdate(BaseModel):
    fingerprint: str | None = None
    user_agent: str | None = None
    country_code: str | None = None
    city: str | None = None
    status: str | None = None
    expires_at: datetime | None = None
    last_activity_at: datetime | None = None
    mfa_verified: bool | None = None
    mfa_verified_at: datetime | None = None


class SessionUpdateRequest(BaseModel):
    fingerprint: str | None = None
    user_agent: str | None = None
    country_code: str | None = None
    city: str | None = None
    status: str | None = None
    expires_at: datetime | None = None
    last_activity_at: datetime | None = None
    mfa_verified: bool | None = None
    mfa_verified_at: datetime | None = None


class SessionListResponse(BaseModel):
    items: list[SessionResponse]
    total: int
    page: int
    size: int
    pages: int


class SessionFilterRequest(BaseModel):
    user_id: str | None = None
    username: str | None = None
    status: str | None = None
    ip_address: str | None = None
    start_date: datetime | None = None
    end_date: datetime | None = None
    page: int = 1
    size: int = 20


class SessionRevokeRequest(BaseModel):
    session_ids: list[str]


class SessionStatsResponse(BaseModel):
    active_sessions: int
    expired_sessions: int
    revoked_sessions: int
    unique_users: int
    unique_ips: int
    mfa_verified_sessions: int
