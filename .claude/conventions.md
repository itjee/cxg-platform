# 코딩 컨벤션

## 🐍 Python (백엔드) - Co-location 구조

### 디렉토리/파일명
```python
# 리소스 디렉토리: snake_case, 단수형
user/           # ✅ 올바른 예
role/           # ✅ 올바른 예
api_key/        # ✅ 올바른 예
users/          # ❌ 복수형 사용하지 않기
user-service/   # ❌ kebab-case 사용하지 않기

# 파일명: 표준화된 이름 사용
router.py       # APIRouter 정의
schemas.py      # Pydantic 스키마들
service.py      # 비즈니스 로직 서비스
model.py        # ORM 모델 import
__init__.py     # 모듈 exports
```

### 클래스/함수/변수명
```python
# 스키마 클래스: PascalCase
class UserCreate(BaseModel):    # ✅ 서비스 레이어용
    pass

class UserCreateRequest(BaseModel):  # ✅ API 호환용
    pass

# 서비스 클래스: PascalCase
class UserService:
    pass

# 함수/변수: snake_case
def get_user_by_id(user_id: str) -> Optional[User]:
    pass

# 상수: UPPER_SNAKE_CASE
MAX_RETRY_COUNT = 3
DEFAULT_PAGE_SIZE = 20

# 라우터 변수: 소문자
router = APIRouter(prefix="/users", tags=["IDAM - 사용자 관리"])
```

### Import 규칙
```python
# ✅ 로컬 imports 사용
from .schemas import UserCreate, UserResponse
from .service import UserService
from .model import User

# ❌ 상대 경로 imports 사용하지 않기
from ..schemas.users import UserCreateRequest
from ../services/users import UserService
```

## 📱 TypeScript (프론트엔드)
```typescript
// 파일명: PascalCase (컴포넌트)
// UserProfile.tsx, OrderHistory.tsx

// 변수/함수: camelCase
const getUserData = async (userId: string) => {};

// 타입/인터페이스: PascalCase
interface UserProfile {
  id: string;
  name: string;
}

// 상수: UPPER_SNAKE_CASE
const API_BASE_URL = '/api/v1';
```

## 🗄️ 데이터베이스
```sql
-- 테이블명: snake_case, 단수형
CREATE TABLE customer (
    id UUID PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    -- ...
);

-- 외래키: {entity}_id
customer_id UUID REFERENCES customer(id)

-- 인덱스: ix_{table}_{columns}
CREATE INDEX ix_customer_email ON customer(email);
```
