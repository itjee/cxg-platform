from typing import Literal

from pydantic import BaseModel, EmailStr, validator


class LoginRequest(BaseModel):
    """로그인 요청 스키마"""

    username: str
    password: str


class LogoutRequest(BaseModel):
    """로그아웃 요청 스키마"""

    session_token: str


class AuthResponse(BaseModel):
    """인증 응답 스키마 (로그인 성공 시 반환)"""

    access_token: str
    token_type: str = "bearer"
    user_id: str
    email: str
    username: str
    session_token: str
    expires_at: str


class SignupRequest(BaseModel):
    """통합 회원가입 요청 스키마 (관리자 및 테넌트 사용자)"""

    user_type: Literal["MASTER", "TENANT"]
    email: EmailStr
    username: str
    password: str
    full_name: str

    # 관리자(MASTER) 특정 필드
    phone: str | None = None
    department: str | None = None
    position: str | None = None

    # 테넌트(TENANT) 특정 필드
    tenant_name: str | None = None
    create_new_tenant: bool | None = None
    invite_token: str | None = None

    # 공통 필드
    timezone: str = "Asia/Seoul"
    locale: str = "ko-KR"

    @validator("tenant_name", always=True)
    def tenant_name_required(cls, v, values):  # noqa: N805
        """user_type이 TENANT이고 새 테넌트를 생성할 경우 tenant_name은 필수입니다."""
        if (
            values.get("user_type") == "TENANT"
            and values.get("create_new_tenant")
            and not v
        ):
            raise ValueError(
                "새로운 TENANT 사용자를 생성하려면 테넌트 이름이 필요합니다."
            )
        return v

    @validator("create_new_tenant", always=True)
    def create_new_tenant_required(cls, v, values):  # noqa: N805
        """user_type이 TENANT일 경우 create_new_tenant 필드는 필수입니다."""
        if values.get("user_type") == "TENANT" and v is None:
            raise ValueError(
                "TENANT 사용자는 create_new_tenant 필드가 필요합니다."
            )
        return v


class UserCreateRequest(BaseModel):
    """사용자 생성 요청 스키마 (내부용)"""

    email: EmailStr
    username: str
    password: str
    full_name: str
    phone: str | None = None
    user_type: str = "USER"
    department: str | None = None
    position: str | None = None
    timezone: str = "Asia/Seoul"
    locale: str = "ko-KR"


class UserResponse(BaseModel):
    """사용자 정보 응답 스키마"""

    id: str
    email: str | None = None
    username: str | None = None
    full_name: str | None = None
    created_at: str | None = None


class UserUpdateRequest(BaseModel):
    """사용자 정보 업데이트 요청 스키마"""

    email: str | None = None
    username: str | None = None
    password: str | None = None
    full_name: str | None = None
