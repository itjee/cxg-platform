# 코딩 컨벤션

CXG 플랫폼의 일관된 코드 품질 유지를 위해 다음 코딩 컨벤션을 준수합니다.

## 🐍 Python (백엔드)
```python
# 파일명: kebab-case
# user-service.py, order-management.py

# 함수/변수: snake_case
def get_user_by_id(user_id: str) -> Optional[User]:
    pass

# 클래스: PascalCase
class UserService:
    pass

# 상수: UPPER_SNAKE_CASE
MAX_RETRY_COUNT = 3
DEFAULT_PAGE_SIZE = 20

# API 엔드포인트: snake_case + _endpoint
async def create_user_endpoint(user_data: UserCreate):
    pass
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
