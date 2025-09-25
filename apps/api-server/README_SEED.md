# IDAM 기본 데이터 시드 가이드

IDAM(Identity and Access Management) 시스템의 기본 권한과 역할 데이터를 생성하는 가이드입니다.

## 시드 데이터 실행

### 1. 기본 실행
```bash
cd apps/api-server
python seed_idam.py
```

### 2. 가상환경에서 실행 (권장)
```bash
cd apps/api-server
source venv/bin/activate  # 또는 conda activate your-env
python seed_idam.py
```

## 생성되는 데이터

### 📋 권한 (Permissions) - 총 26개

#### 사용자 관리 (USER 카테고리)
- `USER_CREATE`: 사용자 생성
- `USER_READ`: 사용자 조회
- `USER_UPDATE`: 사용자 수정
- `USER_DELETE`: 사용자 삭제
- `USER_LIST`: 사용자 목록 조회

#### 역할 관리 (ADMIN 카테고리)
- `ROLE_CREATE`: 역할 생성
- `ROLE_READ`: 역할 조회
- `ROLE_UPDATE`: 역할 수정
- `ROLE_DELETE`: 역할 삭제
- `ROLE_LIST`: 역할 목록 조회

#### 권한 관리 (ADMIN 카테고리)
- `PERMISSION_CREATE`: 권한 생성 (시스템 권한)
- `PERMISSION_READ`: 권한 조회
- `PERMISSION_UPDATE`: 권한 수정 (시스템 권한)
- `PERMISSION_DELETE`: 권한 삭제 (시스템 권한)
- `PERMISSION_LIST`: 권한 목록 조회

#### 테넌트 관리 (TENANT 카테고리)
- `TENANT_CREATE`: 테넌트 생성
- `TENANT_READ`: 테넌트 조회
- `TENANT_UPDATE`: 테넌트 수정
- `TENANT_DELETE`: 테넌트 삭제
- `TENANT_LIST`: 테넌트 목록 조회

#### API 키 관리 (API 카테고리)
- `API_KEY_CREATE`: API 키 생성
- `API_KEY_READ`: API 키 조회
- `API_KEY_UPDATE`: API 키 수정
- `API_KEY_DELETE`: API 키 삭제
- `API_KEY_LIST`: API 키 목록 조회

#### 시스템 관리 (SYSTEM 카테고리)
- `SYSTEM_ADMIN`: 시스템 관리자 (시스템 권한)
- `AUDIT_VIEW`: 감사 로그 조회
- `DASHBOARD_VIEW`: 대시보드 조회

### 👥 역할 (Roles) - 총 5개

#### 1. 슈퍼 관리자 (SUPER_ADMIN)
- **타입**: SYSTEM
- **우선순위**: 1 (최고)
- **권한**: 모든 권한 (26개)
- **설명**: 모든 시스템 권한을 가진 최고 관리자

#### 2. 관리자 (ADMIN)
- **타입**: ADMIN
- **우선순위**: 10
- **권한**: 대부분의 관리 권한 (시스템 권한 제외)
- **설명**: 시스템 관리 권한을 가진 관리자

#### 3. 테넌트 관리자 (TENANT_ADMIN)
- **타입**: CUSTOM
- **우선순위**: 20
- **권한**: 테넌트 관련 권한 + API 키 관리
- **설명**: 테넌트 관리 권한을 가진 관리자

#### 4. 사용자 매니저 (USER_MANAGER)
- **타입**: CUSTOM
- **우선순위**: 30
- **권한**: 사용자 관리 권한 + 읽기 권한
- **설명**: 사용자 관리 권한을 가진 매니저

#### 5. 뷰어 (VIEWER) ⭐ 기본 역할
- **타입**: CUSTOM
- **우선순위**: 100
- **권한**: 모든 읽기 권한
- **설명**: 읽기 전용 권한을 가진 사용자
- **특징**: 신규 사용자의 기본 역할

## 시드 데이터 특징

### 🔒 보안 특징
- **시스템 권한**: 일부 권한은 `is_system=True`로 설정되어 시스템에서만 관리
- **역할 계층**: 우선순위를 통한 역할 계층 구조
- **기본 역할**: 신규 사용자에게 자동 할당되는 안전한 기본 역할

### 🔄 확장성
- **모듈화**: 카테고리별로 권한 그룹화
- **표준화**: 일관된 네이밍 컨벤션 (RESOURCE_ACTION)
- **유연성**: 새로운 권한과 역할 쉽게 추가 가능

### 📊 관리 편의성
- **명확한 설명**: 모든 권한과 역할에 한국어 설명
- **상태 관리**: ACTIVE/INACTIVE 상태로 권한 제어
- **중복 방지**: 기존 데이터가 있으면 생성하지 않음

## 주의사항

1. **데이터베이스 백업**: 실행 전 데이터베이스 백업 권장
2. **환경 확인**: 올바른 데이터베이스 환경에서 실행되는지 확인
3. **권한 확인**: 데이터베이스 쓰기 권한이 있는지 확인
4. **중복 실행**: 여러 번 실행해도 중복 데이터는 생성되지 않음

## 문제 해결

### 데이터베이스 연결 오류
```bash
# 데이터베이스 서비스 상태 확인
systemctl status postgresql  # PostgreSQL 예시

# 연결 정보 확인
# src/core/config.py의 DATABASE_URL 설정 확인
```

### 모듈 import 오류
```bash
# Python 경로 확인
export PYTHONPATH="${PYTHONPATH}:/path/to/your/project/apps/api-server/src"

# 또는 가상환경 활성화
source venv/bin/activate
```

### 권한 부족 오류
```bash
# 데이터베이스 사용자 권한 확인
# 스키마 생성 권한이 필요할 수 있습니다
```
