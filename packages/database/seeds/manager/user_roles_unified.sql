-- 통합 IDAM 사용자-역할 매핑 기본 데이터
-- 기본 admin 사용자에게 SUPER_ADMIN 역할을 할당합니다.

BEGIN;

-- 사용자-역할 매핑 데이터 삽입
-- 주의: permissions_unified.sql, roles_unified.sql, role_permissions_unified.sql을 먼저 실행해야 합니다.

-- ============================================================================
-- 1. 기본 admin 사용자에게 SUPER_ADMIN 역할 할당
-- ============================================================================
INSERT INTO idam.user_roles (
    user_id,
    role_id,
    tenant_context,
    scope,
    granted_by,
    granted_at
)
SELECT
    u.id as user_id,
    r.id as role_id,
    NULL as tenant_context,  -- 글로벌 권한
    'GLOBAL' as scope,
    u.id as granted_by,      -- 자기 자신이 할당
    CURRENT_TIMESTAMP as granted_at
FROM
    idam.users u
CROSS JOIN
    idam.roles r
WHERE
    u.username = 'admin'
    AND u.user_type = 'MASTER'  -- 관리자 타입 사용자 (ADMIN → MASTER로 변경)
    AND r.role_code = 'SUPER_ADMIN'
AND NOT EXISTS (
    SELECT 1
    FROM idam.user_roles ur
    WHERE ur.user_id = u.id
    AND ur.role_id = r.id
    AND ur.tenant_context IS NULL
);

-- ============================================================================
-- 2. 샘플 테넌트 사용자 생성 및 역할 할당 (선택사항)
-- ============================================================================

-- 샘플 테넌트 사용자 생성 (tenant_id 컬럼 제거됨)
INSERT INTO idam.users (
    username,
    email,
    full_name,
    user_type,
    password,
    status
)
SELECT
    'tenant_admin_sample',
    'tenant.admin@example.com',
    '샘플 테넌트 관리자',
    'TENANT',
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeGBOKxrOulBzL9ae', -- bcrypt: 'password123'
    'ACTIVE'
WHERE NOT EXISTS (
    SELECT 1 FROM idam.users WHERE username = 'tenant_admin_sample'
);

-- 샘플 테넌트 사용자에게 TENANT_ADMIN 역할 할당
INSERT INTO idam.user_roles (
    user_id,
    role_id,
    tenant_context,
    scope,
    granted_by,
    granted_at
)
SELECT
    u.id as user_id,
    r.id as role_id,
    '550e8400-e29b-41d4-a716-446655440000'::UUID as tenant_context,  -- 샘플 테넌트 ID
    'TENANT' as scope,
    admin.id as granted_by,          -- admin이 할당
    CURRENT_TIMESTAMP as granted_at
FROM
    idam.users u
CROSS JOIN
    idam.roles r
CROSS JOIN
    idam.users admin
WHERE
    u.username = 'tenant_admin_sample'
    AND u.user_type = 'TENANT'
    AND r.role_code = 'TENANT_ADMIN'
    AND admin.username = 'admin'
AND NOT EXISTS (
    SELECT 1
    FROM idam.user_roles ur
    WHERE ur.user_id = u.id
    AND ur.role_id = r.id
    AND ur.tenant_context = '550e8400-e29b-41d4-a716-446655440000'::UUID
);

-- ============================================================================
-- 3. 샘플 일반 사용자 생성 및 역할 할당 (선택사항)
-- ============================================================================

-- 샘플 일반 사용자 생성 (tenant_id 컬럼 제거됨)
INSERT INTO idam.users (
    username,
    email,
    full_name,
    user_type,
    password,
    status
)
SELECT
    'user_sample',
    'user@example.com',
    '샘플 일반 사용자',
    'TENANT',
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LeGBOKxrOulBzL9ae', -- bcrypt: 'password123'
    'ACTIVE'
WHERE NOT EXISTS (
    SELECT 1 FROM idam.users WHERE username = 'user_sample'
);

-- 샘플 일반 사용자에게 USER 역할 할당
INSERT INTO idam.user_roles (
    user_id,
    role_id,
    tenant_context,
    scope,
    granted_by,
    granted_at
)
SELECT
    u.id as user_id,
    r.id as role_id,
    '550e8400-e29b-41d4-a716-446655440000'::UUID as tenant_context,  -- 샘플 테넌트 ID
    'TENANT' as scope,
    admin.id as granted_by,          -- admin이 할당
    CURRENT_TIMESTAMP as granted_at
FROM
    idam.users u
CROSS JOIN
    idam.roles r
CROSS JOIN
    idam.users admin
WHERE
    u.username = 'user_sample'
    AND u.user_type = 'TENANT'
    AND r.role_code = 'USER'
    AND admin.username = 'admin'
AND NOT EXISTS (
    SELECT 1
    FROM idam.user_roles ur
    WHERE ur.user_id = u.id
    AND ur.role_id = r.id
    AND ur.tenant_context = '550e8400-e29b-41d4-a716-446655440000'::UUID
);

COMMIT;

-- ============================================================================
-- 결과 조회
-- ============================================================================

-- 사용자-역할 할당 결과 조회
SELECT
    u.username,
    u.email,
    u.user_type,
    CASE
        WHEN ur.tenant_context IS NULL THEN 'GLOBAL'
        ELSE ur.tenant_context::TEXT
    END as tenant_context,
    r.role_code,
    r.role_name,
    r.role_type,
    ur.scope,
    ur.granted_at,
    granter.username as granted_by_username
FROM idam.users u
JOIN idam.user_roles ur ON u.id = ur.user_id
JOIN idam.roles r ON ur.role_id = r.id
LEFT JOIN idam.users granter ON ur.granted_by = granter.id
WHERE ur.status = 'ACTIVE'
ORDER BY u.user_type DESC, u.username, r.priority ASC;

-- 사용자별 권한 요약 조회
SELECT
    u.username,
    u.email,
    u.user_type,
    CASE
        WHEN ur.tenant_context IS NULL THEN 'GLOBAL'
        ELSE ur.tenant_context::TEXT
    END as tenant_context,
    COUNT(DISTINCT r.id) as role_count,
    COUNT(DISTINCT rp.permission_id) as total_permissions,
    STRING_AGG(DISTINCT r.role_code, ', ' ORDER BY r.role_code) as roles
FROM idam.users u
LEFT JOIN idam.user_roles ur ON u.id = ur.user_id AND ur.status = 'ACTIVE'
LEFT JOIN idam.roles r ON ur.role_id = r.id
LEFT JOIN idam.role_permissions rp ON r.id = rp.role_id
GROUP BY u.id, u.username, u.email, u.user_type, ur.tenant_context
ORDER BY u.user_type DESC, u.username;
