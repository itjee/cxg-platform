"""
테넌트 모듈

Co-located 구조로 테넌트 관련 모든 컴포넌트를 포함합니다.
"""

# 모델
from .model import Tenant

# 라우터
from .router import router

# 스키마
from .schemas import (
    # PascalCase models (신규)
    TenantCreate,
    # Request/Response models (기존)
    TenantCreateRequest,
    TenantListResponse,
    TenantRead,
    TenantResponse,
    TenantUpdate,
    TenantUpdateRequest,
)

# 서비스
from .service import TenantService

__all__ = [
    # 모델
    "Tenant",
    # 스키마 - Request/Response (기존)
    "TenantCreateRequest",
    "TenantUpdateRequest",
    "TenantResponse",
    "TenantListResponse",
    # 스키마 - PascalCase (신규)
    "TenantCreate",
    "TenantRead",
    "TenantUpdate",
    # 서비스
    "TenantService",
    # 라우터
    "router",
]
