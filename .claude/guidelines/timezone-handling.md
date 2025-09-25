# 시간대 처리 가이드라인

## 📋 개요

CXG 플랫폼에서 시간 데이터의 일관된 처리를 위한 표준 가이드라인입니다.

## 🎯 기본 원칙

### 1. 저장 방식
- **데이터베이스**: 모든 시간 데이터는 **UTC로 저장**
- **컬럼 타입**: PostgreSQL `TIMESTAMP WITH TIME ZONE` (timestamptz) 사용
- **애플리케이션**: `datetime.utcnow()` 사용하여 UTC 시간 저장

### 2. 표시 방식
- **사용자 인터페이스**: 모든 시간은 **한국 시간(KST, Asia/Seoul)**으로 표시
- **API 응답**: 한국 시간으로 변환된 데이터 반환
- **로그 및 디버깅**: 시간대 정보 포함하여 기록

## 🔧 구현 방법

### 백엔드 (FastAPI + SQLAlchemy)

#### 1. 데이터베이스 연결 설정
```python
# src/core/database.py
from sqlalchemy import create_engine, event

# DB 엔진 생성 시 시간대 설정
mgmt_engine = create_engine(
    settings.DATABASE_URL_MANAGES,
    pool_pre_ping=True,
    connect_args={"options": "-c timezone=Asia/Seoul"}
)

# 연결 이벤트 리스너로 시간대 보장
@event.listens_for(mgmt_engine, "connect")
def set_timezone_mgmt(dbapi_connection, connection_record):
    with dbapi_connection.cursor() as cursor:
        cursor.execute("SET timezone='Asia/Seoul'")
```

#### 2. 모델 정의
```python
# src/models/base.py
from datetime import datetime
from sqlalchemy import Column, DateTime

class BaseModel(Base):
    __abstract__ = True
    # UTC로 저장
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, onupdate=datetime.utcnow, nullable=True)
```

#### 3. 서비스 레이어
```python
# 시간 업데이트 시
session.updated_at = datetime.utcnow()  # ✅ 올바름
session.updated_at = datetime.now()     # ❌ 잘못됨 (로컬 시간)

# 조회 시 추가 변환 불필요 (DB에서 자동 변환)
return SessionResponse(
    created_at=session.created_at,  # 이미 KST로 변환됨
    expires_at=session.expires_at,
)
```

#### 4. 쿼리 시 명시적 시간대 변환 (필요 시)
- `TIMESTAMP WITH TIME ZONE` 컬럼이 UTC를 저장하고 있으나, 데이터베이스 세션 설정(`SET timezone='Asia/Seoul'`)이 SQLAlchemy 쿼리 결과에 일관되게 적용되지 않는 경우, 서비스 레이어에서 명시적인 시간대 변환이 필요할 수 있습니다.
- 이 경우, `func.timezone`을 사용하여 UTC 시간을 한국 시간으로 변환합니다.
```python
# src/modules/mgmt/idam/services/login_logs.py 예시
from sqlalchemy import func

# ...
query = db.query(
    LoginLog.id,
    func.timezone('Asia/Seoul', func.timezone('UTC', LoginLog.created_at)).label('created_at'),
    func.timezone('Asia/Seoul', func.timezone('UTC', LoginLog.updated_at)).label('updated_at'),
    # ... 나머지 컬럼
)
# ...
```

### 프론트엔드 (React/Next.js)

#### 1. 시간 표시 함수
```typescript
// 표준 시간 표시 함수
const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString("ko-KR", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
};

// 날짜만 표시하는 경우
const formatDateOnly = (dateString: string) => {
  return new Date(dateString).toLocaleDateString("ko-KR", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
};
```

#### 2. 시간 계산 함수
```typescript
// 상대 시간 표시 (예: "3시간 전")
const getTimeAgo = (dateString: string) => {
  const now = new Date();
  const date = new Date(dateString);
  const diffMs = now.getTime() - date.getTime();

  // 백엔드에서 이미 KST로 변환된 시간이므로 추가 변환 불필요
  const diffMins = Math.floor(diffMs / (1000 * 60));
  const diffHours = Math.floor(diffMins / 60);
  const diffDays = Math.floor(diffHours / 24);

  if (diffMins < 1) return "방금 전";
  if (diffMins < 60) return `${diffMins}분 전`;
  if (diffHours < 24) return `${diffHours}시간 전`;
  return `${diffDays}일 전`;
};
```

## 📝 코딩 표준

### ✅ DO (해야 할 것)

#### 백엔드
```python
# UTC로 저장
created_at = datetime.utcnow()

# DB 연결 시 시간대 설정
connect_args={"options": "-c timezone=Asia/Seoul"}

# 자동 변환된 시간 그대로 반환
return Response(created_at=item.created_at)
```

#### 프론트엔드
```typescript
// 백엔드에서 받은 시간 그대로 사용
const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleString("ko-KR", {
    // timeZone 옵션 사용 안 함
  });
};
```

### ❌ DON'T (하지 말 것)

#### 백엔드
```python
# 로컬 시간 사용 금지
created_at = datetime.now()  # ❌

# 불필요한 수동 시간대 변환 금지 (단, DB 세션 설정이 적용되지 않는 경우 예외)
# 예: kst_time = utc_time.astimezone(timezone('Asia/Seoul'))
# 예: korean_time = utc_time + timedelta(hours=9)
```

#### 프론트엔드
```typescript
// 불필요한 시간대 변환 금지
new Date(dateString).toLocaleString("ko-KR", {
  timeZone: "Asia/Seoul"  // ❌ 이미 KST로 변환됨
});

// 수동 시간대 계산 금지
const kstTime = new Date(utcTime.getTime() + 9 * 60 * 60 * 1000);  // ❌
```

## 🧪 테스트 가이드라인

### 1. 단위 테스트
```python
def test_timezone_handling():
    # UTC로 저장되는지 확인
    utc_now = datetime.utcnow()
    record = create_test_record(created_at=utc_now)

    # DB에서 조회 시 KST로 변환되는지 확인
    retrieved = get_record(record.id)
    assert retrieved.created_at.hour == (utc_now.hour + 9) % 24
```

### 2. 통합 테스트
```typescript
test('API returns Korean time', async () => {
  const response = await fetch('/api/v1/mgmt/login-logs');
  const data = await response.json();

  // 시간 형식 확인
  expect(data.items[0].created_at).toMatch(/^\d{4}-\d{2}-\d{2}/);
});
```

## 🔍 디버깅 및 모니터링

### 1. 로깅 시 주의사항
```python
# 시간대 정보 포함하여 로깅
logger.info(f"Login at {datetime.utcnow().isoformat()}Z (UTC)")
logger.info(f"Login at {korean_time.isoformat()} (KST)")
```

### 2. 문제 진단 체크리스트
- [ ] DB 연결 설정에 `timezone=Asia/Seoul` 포함되어 있는가?
- [ ] BaseModel에서 `datetime.utcnow()` 사용하고 있는가?
- [ ] 프론트엔드에서 불필요한 `timeZone` 옵션 사용하고 있지 않은가?
- [ ] 수동 시간대 변환 코드가 없는가?

## 📚 참고 자료

### PostgreSQL 시간대 처리
- [PostgreSQL Timezone Documentation](https://www.postgresql.org/docs/current/datatype-datetime.html#DATATYPE-TIMEZONES)
- `timestamptz`는 항상 UTC로 저장하고 조회 시 세션 시간대로 변환

### JavaScript 시간 처리
- [MDN Date Documentation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date)
- `toLocaleString()` 메서드를 활용한 지역화

### 업계 모범 사례
- **저장**: UTC (Universal Coordinated Time)
- **표시**: 사용자 지역 시간대
- **API**: ISO 8601 형식 권장

---

## 🚨 중요 알림

**이 가이드라인을 따르면:**
- ✅ 글로벌 확장 시에도 문제없음
- ✅ 서머타임(DST) 자동 처리
- ✅ 서버 이전 시에도 데이터 일관성 유지
- ✅ 성능 최적화 (DB 레벨 처리)
- ✅ 표준 준수로 유지보수성 향상

**마지막 업데이트**: 2025-09-24
**적용 범위**: CXG 플랫폼 전체 (Management System, Tenant System)
