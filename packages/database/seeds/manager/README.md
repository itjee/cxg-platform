# IDAM 시드 데이터 SQL 스크립트

이 폴더에는 IDAM(Identity and Access Management) 시스템의 기본 권한과 역할 데이터를 생성하는 SQL 스크립트가 포함되어 있습니다.

## 📁 파일 구조

```
packages/database/seeds/manager/
├── README.md                 # 이 파일
├── permissions.sql          # 권한 기본 데이터 (28개)
├── roles.sql               # 역할 기본 데이터 (6개)
├── role_permissions.sql    # 역할-권한 매핑 데이터
└── seed_idam.sql          # 전체 실행 스크립트
```

## 🚀 실행 방법

### 1. 전체 실행 (권장)
```bash
# PostgreSQL에 연결하여 전체 시드 실행
psql -d your_database -f seed_idam.sql
```

### 2. 개별 실행
```bash
# 순서대로 실행 (의존성 주의)
psql -d your_database -f permissions.sql
psql -d your_database -f roles.sql
psql -d your_database -f role_permissions.sql
psql -d your_database -f user_roles.sql
```

### 3. Docker 환경에서 실행
```bash
# Docker 컨테이너 내부에서 실행
docker exec -i postgres_container psql -U username -d database_name < seed_idam.sql
```

## 📊 사용자-역할 매핑

### 기본 admin 사용자
- **사용자**: `admin` (기존 USERS 테이블에 존재)
- **할당 역할**: `SUPER_ADMIN`
- **권한 수**: 28개 (모든 권한)
- **할당자**: 자기 자신 (admin)

### 사용자별 권한 확인
```sql
-- 사용자별 역할 확인
SELECT u.username, r.role_code, r.role_name
FROM idam.users u
JOIN idam.user_roles ur ON u.id = ur.user_id
JOIN idam.roles r ON ur.role_id = r.id
ORDER BY u.username, r.priority;

-- 사용자별 권한 수 확인
SELECT
    u.username,
    COUNT(DISTINCT rp.permission_id) as total_permissions
FROM idam.users u
JOIN idam.user_roles ur ON u.id = ur.user_id
JOIN idam.role_permissions rp ON ur.role_id = rp.role_id
GROUP BY u.username;
```

## 📋 생성되는 데이터

### 권한 (Permissions) - 총 28개

#### 🙋‍♂️ 사용자 관리 (5개)
- `USER_CREATE`: 사용자 생성
- `USER_READ`: 사용자 조회
- `USER_UPDATE`: 사용자 수정
- `USER_DELETE`: 사용자 삭제
- `USER_LIST`: 사용자 목록 조회

#### 🛡️ 역할 관리 (5개)
- `ROLE_CREATE`: 역할 생성
- `ROLE_READ`: 역할 조회
- `ROLE_UPDATE`: 역할 수정
- `ROLE_DELETE`: 역할 삭제
- `ROLE_LIST`: 역할 목록 조회

#### 🔐 권한 관리 (4개)
- `PERMISSION_READ`: 권한 조회
- `PERMISSION_UPDATE`: 권한 수정 ⚠️ 시스템 권한
- `PERMISSION_LIST`: 권한 목록 조회
- `PERMISSION_MANAGE`: 권한 전체 관리 ⚠️ 시스템 권한

#### 🏢 테넌트 관리 (5개)
- `TENANT_CREATE`: 테넌트 생성
- `TENANT_READ`: 테넌트 조회
- `TENANT_UPDATE`: 테넌트 수정
- `TENANT_DELETE`: 테넌트 삭제
- `TENANT_LIST`: 테넌트 목록 조회

#### 🔑 API 키 관리 (5개)
- `API_KEY_CREATE`: API 키 생성
- `API_KEY_READ`: API 키 조회
- `API_KEY_UPDATE`: API 키 수정
- `API_KEY_DELETE`: API 키 삭제
- `API_KEY_LIST`: API 키 목록 조회

#### ⚙️ 시스템 관리 (4개)
- `SYSTEM_MANAGE`: 시스템 관리 ⚠️ 시스템 권한
- `AUDIT_READ`: 감사 로그 조회
- `AUDIT_LIST`: 감사 로그 목록 조회
- `DASHBOARD_READ`: 대시보드 조회

### 역할 (Roles) - 총 6개

#### Role Type 계층 구조

##### 특권 레벨
- **SYSTEM**: 시스템 최고 권한 (삭제/수정 제한)

##### 플랫폼 레벨
- **PLATFORM**: 전체 플랫폼 관리 (글로벌 관리자)

##### 조직 레벨
- **ADMIN**: 조직 내 관리 (테넌트 관리자)
- **MANAGER**: 팀/부서 관리 (중간 관리자)

##### 사용자 레벨
- **USER**: 일반 사용자 (기본 사용자)
- **GUEST**: 게스트 사용자 (임시/제한적 접근)

| 역할 코드 | 역할명 | 타입 | 우선순위 | 기본 역할 | 권한 수 |
|-----------|--------|------|----------|-----------|---------|
| `SUPER_ADMIN` | 슈퍼 관리자 | SYSTEM | 1 | ❌ | 28개 (모든 권한) |
| `ADMIN` | 관리자 | PLATFORM | 10 | ❌ | 23개 (시스템 권한 제외) |
| `TENANT_ADMIN` | 테넌트 관리자 | ADMIN | 20 | ❌ | 11개 (조직 관리) |
| `USER_MANAGER` | 사용자 매니저 | MANAGER | 30 | ❌ | 8개 (팀/부서 관리) |
| `GUEST` | 게스트 | GUEST | 200 | ❌ | 1개 (대시보드만) |
| `VIEWER` | 뷰어 | USER | 100 | ✅ | 12개 (읽기 전용) |

## 🔒 보안 특징

### 시스템 권한
다음 권한들은 `is_system=true`로 설정되어 시스템에서만 관리됩니다:
- `PERMISSION_UPDATE`, `PERMISSION_MANAGE`
- `SYSTEM_MANAGE`

### 기본 역할
- **VIEWER** 역할이 `is_default=true`로 설정
- 신규 사용자 가입 시 자동으로 할당되는 안전한 기본 역할

### 우선순위 시스템
- 숫자가 낮을수록 높은 우선순위
- 역할 충돌 시 우선순위가 높은 역할이 적용
- Role Type에 따른 계층적 구조 유지

## 📊 데이터 확인 쿼리

### 권한 목록 조회
```sql
SELECT permission_code, permission_name, category, is_system, status
FROM idam.permissions
ORDER BY category, permission_code;
```

### 역할 목록 조회
```sql
SELECT role_code, role_name, role_type, is_default, priority, status
FROM idam.roles
ORDER BY priority;
```

### 역할별 권한 확인
```sql
SELECT
    r.role_code,
    r.role_name,
    COUNT(rp.permission_id) as permission_count,
    STRING_AGG(p.permission_code, ', ' ORDER BY p.permission_code) as permissions
FROM idam.roles r
LEFT JOIN idam.role_permissions rp ON r.id = rp.role_id
LEFT JOIN idam.permissions p ON rp.permission_id = p.id
GROUP BY r.id, r.role_code, r.role_name, r.priority
ORDER BY r.priority;
```

## ⚠️ 주의사항

1. **실행 순서**: 반드시 permissions → roles → role_permissions → user_roles 순서로 실행
2. **데이터베이스 백업**: 실행 전 데이터베이스 백업 권장
3. **중복 실행**: `ON CONFLICT DO NOTHING` 처리로 중복 실행 시 에러 없음
4. **스키마 존재**: `idam` 스키마가 미리 생성되어 있어야 함
5. **테이블 존재**: 관련 테이블들이 미리 생성되어 있어야 함
6. **admin 사용자 존재**: user_roles.sql 실행 전에 `admin` 사용자가 존재해야 함

## 🔧 문제 해결

### 스키마 없음 에러
```sql
-- idam 스키마 생성
CREATE SCHEMA IF NOT EXISTS idam;
```

### 테이블 없음 에러
```sql
-- 테이블 생성 스크립트 먼저 실행 필요
-- (마이그레이션 스크립트 확인)
```

### 권한 부족 에러
```sql
-- 데이터베이스 사용자에게 스키마 권한 부여
GRANT ALL ON SCHEMA idam TO username;
GRANT ALL ON ALL TABLES IN SCHEMA idam TO username;
```
