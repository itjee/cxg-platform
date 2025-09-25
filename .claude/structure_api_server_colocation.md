# 백엔드 API 서버 Co-location 구조 지침

## 📁 새로운 Co-location 구조 (2024년 9월 업데이트)

### 핵심 원칙
- **리소스별 패키지 (Co-location)**: 관련 파일들을 같은 디렉토리에 배치
- **표준화된 파일명**: `router.py`, `schemas.py`, `service.py`, `model.py`, `__init__.py`
- **일관된 네이밍**: PascalCase 스키마, 단수형 리소스명, 로컬 imports

### 디렉토리 구조

```
src/modules/
├── mgmt/                           # 관리자 모듈
│   ├── idam/                       # Identity & Access Management
│   │   ├── user/                   # 사용자 관리
│   │   │   ├── router.py           # router = APIRouter(prefix="/users", tags=["IDAM - 사용자 관리"])
│   │   │   ├── schemas.py          # UserCreate, UserRead, UserUpdate + Request/Response 클래스
│   │   │   ├── service.py          # class UserService:
│   │   │   ├── model.py            # from src.models.mgmt.idam.user import User
│   │   │   └── __init__.py         # 모든 클래스와 router export
│   │   ├── role/                   # 역할 관리
│   │   │   ├── router.py           # router = APIRouter(prefix="/roles", tags=["IDAM - 역할 관리"])
│   │   │   ├── schemas.py          # RoleCreate, RoleRead, RoleUpdate + Request/Response 클래스
│   │   │   ├── service.py          # class RoleService:
│   │   │   ├── model.py            # from src.models.mgmt.idam.role import Role
│   │   │   └── __init__.py
│   │   ├── permission/             # 권한 관리
│   │   │   ├── router.py           # router = APIRouter(prefix="/permissions", tags=["IDAM - 권한 관리"])
│   │   │   ├── schemas.py          # PermissionCreate, PermissionRead, PermissionUpdate
│   │   │   ├── service.py          # class PermissionService:
│   │   │   ├── model.py            # from src.models.mgmt.idam.permission import Permission
│   │   │   └── __init__.py
│   │   ├── session/                # 세션 관리
│   │   │   ├── router.py           # router = APIRouter(prefix="/sessions", tags=["IDAM - 세션 관리"])
│   │   │   ├── schemas.py          # SessionCreate, SessionRead, SessionUpdate
│   │   │   ├── service.py          # class SessionService:
│   │   │   ├── model.py            # from src.models.mgmt.idam.session import Session
│   │   │   └── __init__.py
│   │   ├── api_key/                # API 키 관리
│   │   │   ├── router.py           # router = APIRouter(prefix="/api-keys", tags=["IDAM - API 키 관리"])
│   │   │   ├── schemas.py          # ApiKeyCreate, ApiKeyRead, ApiKeyUpdate
│   │   │   ├── service.py          # class ApiKeyService:
│   │   │   ├── model.py            # from src.models.mgmt.idam.api_key import ApiKey
│   │   │   └── __init__.py
│   │   ├── login_log/              # 로그인 로그 관리
│   │   │   ├── router.py           # router = APIRouter(prefix="/login-logs", tags=["IDAM - 로그인 로그 관리"])
│   │   │   ├── schemas.py          # LoginLogCreate, LoginLogRead, LoginLogUpdate
│   │   │   ├── service.py          # class LoginLogService:
│   │   │   ├── model.py            # from src.models.mgmt.idam.login_log import LoginLog
│   │   │   └── __init__.py
│   │   ├── user_role/              # 사용자-역할 관계 관리
│   │   │   ├── router.py           # router = APIRouter(prefix="/user-roles", tags=["IDAM - 사용자 역할 관리"])
│   │   │   ├── schemas.py          # UserRoleCreate, UserRoleRead, UserRoleUpdate
│   │   │   ├── service.py          # class UserRoleService:
│   │   │   ├── model.py            # from src.models.mgmt.idam.user_role import UserRole
│   │   │   └── __init__.py
│   │   ├── role_permission/        # 역할-권한 관계 관리
│   │   │   ├── router.py           # router = APIRouter(prefix="/role-permissions", tags=["IDAM - 역할 권한 관리"])
│   │   │   ├── schemas.py          # RolePermissionCreate, RolePermissionRead, RolePermissionUpdate
│   │   │   ├── service.py          # class RolePermissionService:
│   │   │   ├── model.py            # from src.models.mgmt.idam.role_permission import RolePermission
│   │   │   └── __init__.py
│   │   └── router.py               # IDAM 메인 라우터 (새로운 co-located 모듈들을 import)
│   └── tnnt/                       # 테넌트 관리
│       ├── tenant/                 # 테넌트 관리
│       │   ├── router.py           # router = APIRouter(prefix="/tenants", tags=["TNNT - 테넌트 관리"])
│       │   ├── schemas.py          # TenantCreate, TenantRead, TenantUpdate
│       │   ├── service.py          # class TenantService:
│       │   ├── model.py            # from src.models.mgmt.tnnt.tenant import Tenant
│       │   └── __init__.py
│       └── router.py               # TNNT 메인 라우터
└── tnnt/                           # 테넌트별 비즈니스 모듈들
    ├── auth/                       # 테넌트 인증
    │   ├── router.py
    │   ├── schemas.py
    │   └── service.py
    └── [기타 테넌트 모듈들...]
```

## 📋 파일별 표준 구조

### 1. router.py
```python
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from src.core.database import get_db
from src.schemas.common.response import EnvelopeResponse

from .schemas import (
    ResourceCreate,
    ResourceCreateRequest,
    ResourceRead,
    ResourceResponse,
    ResourceUpdate,
    ResourceUpdateRequest,
)
from .service import ResourceService

router = APIRouter(prefix="/resources", tags=["카테고리 - 리소스 관리"])

@router.get("/", response_model=EnvelopeResponse[List[ResourceResponse]])
async def get_resources(db: Session = Depends(get_db)):
    # 구현
    pass
```

### 2. schemas.py
```python
from pydantic import BaseModel, Field
from typing import List, Optional
from uuid import UUID

# PascalCase 스키마 클래스 (서비스 레이어용)
class ResourceCreate(BaseModel):
    name: str
    description: str | None = None

class ResourceRead(BaseModel):
    id: UUID
    name: str
    description: str | None = None

    class Config:
        from_attributes = True

class ResourceUpdate(BaseModel):
    name: str | None = None
    description: str | None = None

# API 호환성을 위한 Request/Response 클래스
class ResourceCreateRequest(BaseModel):
    name: str
    description: str | None = None

class ResourceResponse(BaseModel):
    id: UUID
    name: str
    description: str | None = None

    class Config:
        from_attributes = True

class ResourceUpdateRequest(BaseModel):
    name: str | None = None
    description: str | None = None
```

### 3. service.py
```python
import logging
from typing import List, Optional
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from .model import Resource
from .schemas import ResourceCreate, ResourceRead, ResourceUpdate

logger = logging.getLogger(__name__)

class ResourceService:
    """리소스 관련 비즈니스 로직을 처리하는 서비스"""

    @staticmethod
    def create_resource(db: Session, resource: ResourceCreate) -> Resource:
        """새로운 리소스를 생성합니다."""
        try:
            db_resource = Resource(**resource.model_dump())
            db.add(db_resource)
            db.commit()
            db.refresh(db_resource)
            return db_resource
        except SQLAlchemyError as e:
            logger.error(f"리소스 생성 중 데이터베이스 에러: {e}")
            db.rollback()
            raise
```

### 4. model.py
```python
from src.models.mgmt.idam.resource import Resource

__all__ = ["Resource"]
```

### 5. __init__.py
```python
from .model import Resource
from .router import router
from .schemas import (
    ResourceCreate,
    ResourceCreateRequest,
    ResourceRead,
    ResourceResponse,
    ResourceUpdate,
    ResourceUpdateRequest,
)
from .service import ResourceService

__all__ = [
    "Resource",
    "router",
    "ResourceCreate",
    "ResourceCreateRequest",
    "ResourceRead",
    "ResourceResponse",
    "ResourceUpdate",
    "ResourceUpdateRequest",
    "ResourceService",
]
```

### 6. 메인 router.py (모듈 수준)
```python
from fastapi import APIRouter

from .user import router as user_router
from .role import router as role_router
from .permission import router as permission_router
# ... 기타 리소스 라우터들

router = APIRouter(prefix="/api/v1/mgmt/idam")

# 서브 라우터 등록 (새로운 co-located 구조)
router.include_router(user_router)
router.include_router(role_router)
router.include_router(permission_router)
# ... 기타 라우터들
```

## 🎯 네이밍 규칙

### 디렉토리명
- **단수형 사용**: `user/`, `role/`, `permission/` (복수형 ❌)
- **snake_case**: `api_key/`, `login_log/`, `user_role/`

### 스키마 클래스명
- **PascalCase**: `UserCreate`, `UserRead`, `UserUpdate`
- **Request/Response 클래스**: `UserCreateRequest`, `UserResponse`

### 서비스 클래스명
- **PascalCase**: `UserService`, `RoleService`

### 라우터 설정
- **prefix**: 복수형 사용 (`"/users"`, `"/roles"`)
- **tags**: 명확한 카테고리 표시 (`["IDAM - 사용자 관리"]`)

### Import 규칙
- **로컬 imports**: `from .schemas import ...`, `from .service import ...`
- **모델 imports**: `from src.models.mgmt.idam.user import User`

## 🔄 마이그레이션 가이드

### 기존 구조에서 새 구조로 이주
1. **새 디렉토리 생성**: 리소스명으로 디렉토리 생성
2. **파일 이동**: 기존 `routers/users.py` → `user/router.py`
3. **Import 경로 수정**: 상대 경로를 로컬 경로로 변경
4. **스키마 클래스 추가**: PascalCase 버전 추가
5. **메인 라우터 업데이트**: 새 모듈들을 import하도록 수정

### 백워드 호환성
- 기존 Request/Response 클래스는 유지
- API 엔드포인트는 동일하게 유지
- 서비스 메서드는 두 가지 스키마 타입 모두 지원

## ✅ 베스트 프랙티스

### DO ✅
- 관련 파일들을 같은 디렉토리에 배치
- PascalCase 스키마 클래스 사용
- 로컬 imports 사용 (`./schemas`, `./service`)
- 완전한 `__init__.py` 작성
- 일관된 네이밍 컨벤션 적용

### DON'T ❌
- 파일을 여러 디렉토리에 분산시키지 않기
- 부모 디렉토리 imports (`../schemas`) 사용하지 않기
- 복수형 디렉토리명 사용하지 않기
- 불완전한 export 하지 않기

## 🚀 장점

1. **가독성**: 관련 코드가 한 곳에 모여 있어 이해하기 쉬움
2. **유지보수성**: 수정할 때 한 디렉토리만 확인하면 됨
3. **재사용성**: 각 모듈이 독립적으로 import 가능
4. **확장성**: 새로운 리소스 추가 시 표준 구조 따르면 됨
5. **테스트 용이성**: 모듈별로 격리된 테스트 작성 가능

이 구조를 통해 더 체계적이고 유지보수하기 쉬운 백엔드 API를 개발할 수 있습니다.
