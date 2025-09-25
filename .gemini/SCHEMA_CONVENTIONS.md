# 스키마 클래스 네이밍 규칙

## 개요
API 스키마 클래스의 일관된 네이밍을 위한 규칙을 정의합니다. 이를 통해 데이터 흐름을 명확히 구분하고 코드의 가독성을 향상시킵니다.

## 네이밍 규칙

### 클래스 모델명 네이밍 규칙 요약
- **요청 모델**: `{Action}Request` (예: UserCreateRequest, TenantUpdateRequest)
- **응답 모델**: `{Entity}Response` (예: UserResponse, TenantResponse)
- **내부 엔티티**: `{Entity}` (예: User, Tenant)

### 1. 요청(Request) 클래스
**프론트엔드에서 백엔드로 보내는 데이터**

- **규칙**: `{Action}Request`
- **예시**:
  - `UserCreateRequest` - 사용자 생성 요청
  - `UserUpdateRequest` - 사용자 수정 요청
  - `UserLoginRequest` - 사용자 로그인 요청
  - `ProductSearchRequest` - 상품 검색 요청

```python
class UserCreateRequest(BaseModel):
    username: str
    email: EmailStr
    password: str
    full_name: str
```

### 2. 응답(Response) 클래스
**백엔드에서 프론트엔드로 보내는 데이터**

- **규칙**: `{Entity}Response`
- **예시**:
  - `UserResponse` - 사용자 정보 응답
  - `TokenResponse` - 토큰 정보 응답
  - `UserListResponse` - 사용자 목록 응답
  - `ProductSearchResponse` - 상품 검색 결과 응답

```python
class UserResponse(BaseModel):
    id: uuid.UUID
    username: str
    email: EmailStr
    full_name: str
    created_at: datetime

    class Config:
        from_attributes = True
```

### 3. 내부 데이터 전송 클래스
**서비스 간 또는 내부 로직에서 사용하는 데이터**

- **규칙**: `{Entity}` (단순형)
- **예시**:
  - `User` - 사용자 엔티티
  - `Token` - 토큰 엔티티
  - `Product` - 상품 엔티티

```python
class User(BaseModel):
    id: uuid.UUID
    username: str
    email: EmailStr
    # 호환성을 위해 유지되는 클래스
```

## 목적 및 장점

### 1. 명확한 데이터 흐름 구분
- **Request**: 클라이언트 → 서버
- **Response**: 서버 → 클라이언트
- **Entity**: 내부 로직

### 2. 데이터베이스 모델과의 구분
- **DB Model**: `User` (SQLAlchemy 모델)
- **API Schema**: `UserResponse`, `UserCreateRequest` (Pydantic 모델)

### 3. 코드 가독성 향상
```python
# 명확한 의도 파악 가능
def create_user(request: UserCreateRequest) -> UserResponse:
    # 요청 데이터를 받아서 응답 데이터를 반환
    pass
```

### 4. API 문서 자동 생성 개선
FastAPI의 자동 문서화에서 스키마 이름이 명확하게 표시됨

## 적용 예시

### 사용자 관리 API
```python
# endpoints/users.py
@router.post("/", response_model=UserResponse)
async def create_user(request: UserCreateRequest):
    pass

@router.put("/{user_id}", response_model=UserResponse)
async def update_user(user_id: str, request: UserUpdateRequest):
    pass

@router.get("/", response_model=UserListResponse)
async def list_users():
    pass
```

### 인증 API
```python
# endpoints/auth.py
@router.post("/login", response_model=TokenResponse)
async def login(request: UserLoginRequest):
    pass

@router.post("/register", response_model=UserResponse)
async def register(request: UserCreateRequest):
    pass
```

## 마이그레이션 가이드

기존 코드에서 새로운 규칙으로 변경할 때:

1. **Request 클래스 이름 변경**
   - `UserCreate` → `UserCreateRequest`
   - `UserLogin` → `UserLoginRequest`

2. **Response 클래스 이름 변경**
   - `User` → `UserResponse` (API 응답용)
   - `Token` → `TokenResponse` (API 응답용)

3. **Import 구문 업데이트**
```python
# Before
from src.schemas.user import UserCreate, User

# After
from src.schemas.user import UserCreateRequest, UserResponse
```

4. **호환성 유지**
기존 내부 로직에서 사용하는 단순 클래스는 당분간 유지하여 점진적 마이그레이션

## 체크리스트

새로운 스키마 클래스 생성 시 확인사항:

- [ ] 클래스 이름이 네이밍 규칙을 따르는가?
- [ ] Request 클래스에는 필요한 validation이 포함되었는가?
- [ ] Response 클래스에는 `from_attributes = True` 설정이 있는가?
- [ ] API 엔드포인트에서 올바른 스키마를 사용하는가?
- [ ] Import 구문이 업데이트되었는가?
