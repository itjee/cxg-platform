# 통합 IDAM 마이그레이션 가이드

## 📋 개요

기존의 분리된 관리자/테넌트 인증 시스템을 통합 IDAM (Identity & Access Management) 시스템으로 마이그레이션하는 가이드입니다.

## 🔄 마이그레이션 전략

### **현재 구조 → 통합 구조**

```
기존 (분리형)                      →  통합 (Unified)
=====================================  =====================================
idam.users     (관리자만)           →  idam.users     (관리자 + 테넌트)
tnnt.users     (테넌트만)           →  tenant_users   (연결 관계만)
idam.sessions  (관리자)             →  idam.sessions  (통합)
tnnt.sessions  (테넌트)             →  [제거됨]
idam.api_keys  (관리자)             →  idam.api_keys  (통합)
tnnt.api_keys  (테넌트)             →  [제거됨]
```

## 🚀 마이그레이션 단계

### **1단계: 백업 및 준비**

```bash
# 1. 기존 데이터베이스 백업
pg_dump -h localhost -U postgres -d your_database > backup_before_migration.sql

# 2. 새로운 통합 스키마 생성
psql -d your_database -f packages/database/schemas/manage/idam_unified.sql
```

### **2단계: 데이터 마이그레이션**

#### **2.1 사용자 데이터 통합**

```sql
-- 기존 관리자 사용자 마이그레이션
INSERT INTO idam.users (
    id, username, email, full_name, password, salt_key,
    user_type, tenant_id, status, is_system,
    created_at, updated_at, created_by, updated_by,
    sso_provider, sso_subject, mfa_enabled, mfa_secret, backup_codes,
    last_login_at, last_login_ip, failed_login_attempts, locked_until,
    password_changed_at, force_password_change, timezone, locale,
    phone, department, position
)
SELECT
    id, username, email, full_name, password, salt_key,
    'ADMIN' as user_type,           -- 관리자로 분류
    NULL as tenant_id,              -- 테넌트 ID 없음
    status, is_system,
    created_at, updated_at, created_by, updated_by,
    sso_provider, sso_subject, mfa_enabled, mfa_secret, backup_codes,
    last_login_at, last_login_ip, failed_login_attempts, locked_until,
    password_changed_at, force_password_change, timezone, locale,
    phone, department, position
FROM old_idam.users
WHERE NOT EXISTS (
    SELECT 1 FROM idam.users WHERE idam.users.id = old_idam.users.id
);

-- 기존 테넌트 사용자 마이그레이션
INSERT INTO idam.users (
    id, username, email, full_name, password, salt_key,
    user_type, tenant_id, status, is_system,
    created_at, updated_at, created_by, updated_by,
    timezone, locale, phone, department, position
)
SELECT
    id, username, email, full_name, password, salt_key,
    'TENANT' as user_type,          -- 테넌트 사용자로 분류
    tenant_id,                      -- 테넌트 ID 유지
    status, false as is_system,
    created_at, updated_at, created_by, updated_by,
    timezone, locale, phone, department, position
FROM old_tnnt.users
WHERE NOT EXISTS (
    SELECT 1 FROM idam.users WHERE idam.users.id = old_tnnt.users.id
);

-- 테넌트-사용자 연결 관계 생성
INSERT INTO tenant_users (
    tenant_id, user_id, role_in_tenant, department, position,
    joined_at, status, is_primary,
    created_at, updated_at, created_by
)
SELECT
    u.tenant_id, u.id as user_id,
    u.position as role_in_tenant, u.department, u.position,
    u.created_at as joined_at, 'ACTIVE' as status, true as is_primary,
    u.created_at, u.updated_at, u.created_by
FROM idam.users u
WHERE u.user_type = 'TENANT' AND u.tenant_id IS NOT NULL;
```

#### **2.2 세션 데이터 통합**

```sql
-- 관리자 세션 마이그레이션
INSERT INTO idam.sessions (
    id, session_id, user_id, tenant_context, session_type,
    fingerprint, user_agent, ip_address, country_code, city,
    status, expires_at, last_activity_at, mfa_verified, mfa_verified_at,
    created_at, updated_at, created_by, updated_by
)
SELECT
    id, session_id, user_id,
    NULL as tenant_context,         -- 관리자는 글로벌 컨텍스트
    'WEB' as session_type,
    fingerprint, user_agent, ip_address, country_code, city,
    status, expires_at, last_activity_at, mfa_verified, mfa_verified_at,
    created_at, updated_at, created_by, updated_by
FROM old_idam.sessions;

-- 테넌트 세션 마이그레이션
INSERT INTO idam.sessions (
    id, session_id, user_id, tenant_context, session_type,
    fingerprint, user_agent, ip_address, country_code, city,
    status, expires_at, last_activity_at,
    created_at, updated_at, created_by, updated_by
)
SELECT
    s.id, s.session_id, s.user_id,
    u.tenant_id as tenant_context,  -- 사용자의 테넌트 컨텍스트
    'WEB' as session_type,
    s.fingerprint, s.user_agent, s.ip_address, s.country_code, s.city,
    s.status, s.expires_at, s.last_activity_at,
    s.created_at, s.updated_at, s.created_by, s.updated_by
FROM old_tnnt.sessions s
JOIN idam.users u ON s.user_id = u.id;
```

#### **2.3 API 키 데이터 통합**

```sql
-- 관리자 API 키 마이그레이션
INSERT INTO idam.api_keys (
    id, key_id, key_hash, key_name, user_id, tenant_context, service_account,
    scopes, allowed_ips, rate_limit_per_minute, rate_limit_per_hour, rate_limit_per_day,
    status, expires_at, last_used_at, last_used_ip, usage_count,
    created_at, updated_at, created_by, updated_by
)
SELECT
    id, key_id, key_hash, key_name, user_id,
    NULL as tenant_context,         -- 관리자는 글로벌 컨텍스트
    service_account,
    scopes, allowed_ips, rate_limit_per_minute, rate_limit_per_hour, rate_limit_per_day,
    status, expires_at, last_used_at, last_used_ip, usage_count,
    created_at, updated_at, created_by, updated_by
FROM old_idam.api_keys;

-- 테넌트 API 키 마이그레이션
INSERT INTO idam.api_keys (
    id, key_id, key_hash, key_name, user_id, tenant_context, service_account,
    scopes, allowed_ips, rate_limit_per_minute, rate_limit_per_hour, rate_limit_per_day,
    status, expires_at, last_used_at, last_used_ip, usage_count,
    created_at, updated_at, created_by, updated_by
)
SELECT
    k.id, k.key_id, k.key_hash, k.key_name, k.user_id,
    u.tenant_id as tenant_context,  -- 사용자의 테넌트 컨텍스트
    k.service_account,
    k.scopes, k.allowed_ips, k.rate_limit_per_minute, k.rate_limit_per_hour, k.rate_limit_per_day,
    k.status, k.expires_at, k.last_used_at, k.last_used_ip, k.usage_count,
    k.created_at, k.updated_at, k.created_by, k.updated_by
FROM old_tnnt.api_keys k
JOIN idam.users u ON k.user_id = u.id;
```

#### **2.4 로그인 로그 통합**

```sql
-- 관리자 로그인 로그 마이그레이션
INSERT INTO idam.login_logs (
    id, user_id, username, user_type, tenant_context,
    attempt_type, success, failure_reason, session_id,
    ip_address, user_agent, country_code, city,
    mfa_used, mfa_method,
    created_at, updated_at, created_by, updated_by
)
SELECT
    id, user_id, username, 'ADMIN' as user_type, NULL as tenant_context,
    attempt_type, success, failure_reason, session_id,
    ip_address, user_agent, country_code, city,
    mfa_used, mfa_method,
    created_at, updated_at, created_by, updated_by
FROM old_idam.login_logs;

-- 테넌트 로그인 로그 마이그레이션
INSERT INTO idam.login_logs (
    id, user_id, username, user_type, tenant_context,
    attempt_type, success, failure_reason, session_id,
    ip_address, user_agent, country_code, city,
    mfa_used, mfa_method,
    created_at, updated_at, created_by, updated_by
)
SELECT
    l.id, l.user_id, l.username, 'TENANT' as user_type, u.tenant_id as tenant_context,
    l.attempt_type, l.success, l.failure_reason, l.session_id,
    l.ip_address, l.user_agent, l.country_code, l.city,
    l.mfa_used, l.mfa_method,
    l.created_at, l.updated_at, l.created_by, l.updated_by
FROM old_tnnt.login_logs l
JOIN idam.users u ON l.user_id = u.id;
```

### **3단계: 권한 시스템 초기화**

```bash
# 통합 권한 시스템 시드 데이터 실행
psql -d your_database -f packages/database/seeds/manager/seed_idam_unified.sql
```

### **4단계: 검증 및 테스트**

#### **4.1 데이터 무결성 검증**

```sql
-- 사용자 수 검증
SELECT
    'old_total' as type,
    (SELECT COUNT(*) FROM old_idam.users) + (SELECT COUNT(*) FROM old_tnnt.users) as count
UNION ALL
SELECT
    'new_total' as type,
    COUNT(*) as count
FROM idam.users;

-- 세션 수 검증
SELECT
    'old_total' as type,
    (SELECT COUNT(*) FROM old_idam.sessions) + (SELECT COUNT(*) FROM old_tnnt.sessions) as count
UNION ALL
SELECT
    'new_total' as type,
    COUNT(*) as count
FROM idam.sessions;

-- API 키 수 검증
SELECT
    'old_total' as type,
    (SELECT COUNT(*) FROM old_idam.api_keys) + (SELECT COUNT(*) FROM old_tnnt.api_keys) as count
UNION ALL
SELECT
    'new_total' as type,
    COUNT(*) as count
FROM idam.api_keys;
```

#### **4.2 권한 시스템 테스트**

```sql
-- 사용자별 권한 확인
SELECT
    u.username,
    u.user_type,
    COUNT(DISTINCT r.id) as role_count,
    COUNT(DISTINCT p.id) as permission_count
FROM idam.users u
LEFT JOIN idam.user_roles ur ON u.id = ur.user_id AND ur.status = 'ACTIVE'
LEFT JOIN idam.roles r ON ur.role_id = r.id
LEFT JOIN idam.role_permissions rp ON r.id = rp.role_id
LEFT JOIN idam.permissions p ON rp.permission_id = p.id
GROUP BY u.id, u.username, u.user_type
ORDER BY u.user_type, u.username;
```

### **5단계: 애플리케이션 코드 업데이트**

#### **5.1 인증 서비스 통합**

```typescript
// 기존 (분리형)
class AdminAuthService { ... }
class TenantAuthService { ... }

// 통합 후
class UnifiedAuthService {
    async authenticate(username: string, password: string, context?: string) {
        // 통합 인증 로직
        const user = await this.findUser(username);

        // 컨텍스트별 권한 확인
        const permissions = await this.getUserPermissions(user.id, context);

        return { user, permissions, context };
    }

    async getUserPermissions(userId: string, tenantContext?: string) {
        // 사용자의 역할과 권한을 컨텍스트별로 조회
        return await this.queryUserPermissions(userId, tenantContext);
    }
}
```

#### **5.2 API 엔드포인트 통합**

```typescript
// 기존 (분리형)
// /api/admin/auth/login
// /api/tenant/auth/login

// 통합 후
// /api/auth/login (컨텍스트 파라미터로 구분)
```

## 🔍 마이그레이션 체크리스트

### **✅ 사전 준비**
- [ ] 기존 데이터베이스 백업 완료
- [ ] 통합 스키마 검토 완료
- [ ] 테스트 환경 구축 완료
- [ ] 롤백 계획 수립 완료

### **✅ 데이터 마이그레이션**
- [ ] 사용자 데이터 통합 완료
- [ ] 세션 데이터 통합 완료
- [ ] API 키 데이터 통합 완료
- [ ] 로그인 로그 통합 완료
- [ ] 테넌트 연결 관계 생성 완료

### **✅ 시스템 초기화**
- [ ] 권한 시드 데이터 실행 완료
- [ ] 역할 시드 데이터 실행 완료
- [ ] 역할-권한 매핑 완료
- [ ] 사용자-역할 매핑 완료

### **✅ 검증 및 테스트**
- [ ] 데이터 무결성 검증 완료
- [ ] 권한 시스템 테스트 완료
- [ ] 성능 테스트 완료
- [ ] 보안 테스트 완료

### **✅ 애플리케이션 업데이트**
- [ ] 인증 서비스 통합 완료
- [ ] API 엔드포인트 업데이트 완료
- [ ] 프론트엔드 인증 플로우 업데이트 완료
- [ ] 문서 업데이트 완료

## 🚨 주의사항

### **1. 데이터 무결성**
- 마이그레이션 중 외래 키 제약 조건 주의
- 중복 사용자명/이메일 확인 및 처리
- 세션 만료 처리

### **2. 성능 고려사항**
- 대용량 데이터 마이그레이션 시 배치 처리
- 인덱스 재구성 필요
- 통계 정보 업데이트

### **3. 보안 고려사항**
- 기존 패스워드 해시 호환성 확인
- API 키 유효성 검증
- 세션 무효화 및 재발급

### **4. 롤백 계획**
- 마이그레이션 실패 시 롤백 스크립트 준비
- 데이터베이스 복구 절차 수립
- 애플리케이션 코드 롤백 계획

## 📚 참고 자료

- [통합 IDAM 스키마 문서](./schemas/manage/idam_unified.sql)
- [시드 데이터 가이드](./seeds/manager/README.md)
- [API 문서](../../docs/api/)

## 🤝 지원

마이그레이션 과정에서 문제가 발생하면 다음을 확인하세요:

1. **로그 확인**: PostgreSQL 로그에서 에러 메시지 확인
2. **데이터 검증**: 각 단계별 검증 쿼리 실행
3. **롤백 실행**: 문제 발생 시 즉시 롤백
4. **문의**: 개발팀에 상세한 에러 로그와 함께 문의
