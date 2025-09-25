"""
테넌트 스키마 모듈

스키마 클래스 네이밍 규칙:
- 프론트엔드 → 백엔드 요청: {Action}Request (예: TenantCreateRequest, TenantUpdateRequest)
- 백엔드 → 프론트엔드 응답: {Entity}Response (예: TenantResponse, TenantListResponse)
- 새로운 PascalCase 클래스: {Entity}{Action} (예: TenantCreate, TenantRead, TenantUpdate)
"""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel


# 요청(Request) 모델 - 프론트엔드에서 백엔드로 보내는 데이터
class TenantCreateRequest(BaseModel):
    tenant_code: str
    tenant_name: str
    tenant_type: str = "STANDARD"
    business_no: str | None = None
    business_name: str | None = None
    business_type: str = "CORPORATE"
    ceo_name: str | None = None
    business_kind: str | None = None
    business_item: str | None = None
    postcode: str | None = None
    address1: str | None = None
    address2: str | None = None
    phone_no: str | None = None
    employee_count: int = 0
    start_date: date
    close_date: date | None = None
    timezone: str = "Asia/Seoul"
    locale: str = "ko-KR"
    currency: str = "KRW"
    extra_data: dict = {}
    status: str = "ACTIVE"


class TenantUpdateRequest(BaseModel):
    tenant_code: str | None = None
    tenant_name: str | None = None
    tenant_type: str | None = None
    business_no: str | None = None
    business_name: str | None = None
    business_type: str | None = None
    ceo_name: str | None = None
    business_kind: str | None = None
    business_item: str | None = None
    postcode: str | None = None
    address1: str | None = None
    address2: str | None = None
    phone_no: str | None = None
    employee_count: int | None = None
    start_date: date | None = None
    close_date: date | None = None
    timezone: str | None = None
    locale: str | None = None
    currency: str | None = None
    extra_data: dict | None = None
    status: str | None = None


# 응답(Response) 모델 - 백엔드에서 프론트엔드로 보내는 데이터
class TenantResponse(BaseModel):
    id: UUID
    created_at: datetime
    created_by: UUID | None = None
    updated_at: datetime | None = None
    updated_by: UUID | None = None
    tenant_code: str
    tenant_name: str
    tenant_type: str
    business_no: str | None = None
    business_name: str | None = None
    business_type: str
    ceo_name: str | None = None
    business_kind: str | None = None
    business_item: str | None = None
    postcode: str | None = None
    address1: str | None = None
    address2: str | None = None
    phone_no: str | None = None
    employee_count: int
    start_date: date
    close_date: date | None = None
    timezone: str
    locale: str
    currency: str
    extra_data: dict
    status: str
    deleted: bool

    class Config:
        from_attributes = True


class TenantListResponse(BaseModel):
    tenants: list[TenantResponse]


# 새로운 PascalCase 스키마 클래스들
class TenantCreate(BaseModel):
    """테넌트 생성을 위한 스키마"""

    tenant_code: str
    tenant_name: str
    tenant_type: str = "STANDARD"
    business_no: str | None = None
    business_name: str | None = None
    business_type: str = "CORPORATE"
    ceo_name: str | None = None
    business_kind: str | None = None
    business_item: str | None = None
    postcode: str | None = None
    address1: str | None = None
    address2: str | None = None
    phone_no: str | None = None
    employee_count: int = 0
    start_date: date
    close_date: date | None = None
    timezone: str = "Asia/Seoul"
    locale: str = "ko-KR"
    currency: str = "KRW"
    extra_data: dict = {}
    status: str = "ACTIVE"


class TenantRead(BaseModel):
    """테넌트 조회를 위한 스키마"""

    id: UUID
    created_at: datetime
    created_by: UUID | None = None
    updated_at: datetime | None = None
    updated_by: UUID | None = None
    tenant_code: str
    tenant_name: str
    tenant_type: str
    business_no: str | None = None
    business_name: str | None = None
    business_type: str
    ceo_name: str | None = None
    business_kind: str | None = None
    business_item: str | None = None
    postcode: str | None = None
    address1: str | None = None
    address2: str | None = None
    phone_no: str | None = None
    employee_count: int
    start_date: date
    close_date: date | None = None
    timezone: str
    locale: str
    currency: str
    extra_data: dict
    status: str
    deleted: bool

    class Config:
        from_attributes = True


class TenantUpdate(BaseModel):
    """테넌트 수정을 위한 스키마"""

    tenant_code: str | None = None
    tenant_name: str | None = None
    tenant_type: str | None = None
    business_no: str | None = None
    business_name: str | None = None
    business_type: str | None = None
    ceo_name: str | None = None
    business_kind: str | None = None
    business_item: str | None = None
    postcode: str | None = None
    address1: str | None = None
    address2: str | None = None
    phone_no: str | None = None
    employee_count: int | None = None
    start_date: date | None = None
    close_date: date | None = None
    timezone: str | None = None
    locale: str | None = None
    currency: str | None = None
    extra_data: dict | None = None
    status: str | None = None


__all__ = [
    # Request/Response models (existing)
    "TenantCreateRequest",
    "TenantUpdateRequest",
    "TenantResponse",
    "TenantListResponse",
    # PascalCase models (new)
    "TenantCreate",
    "TenantRead",
    "TenantUpdate",
]
