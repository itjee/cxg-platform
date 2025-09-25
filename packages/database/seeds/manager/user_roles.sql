-- IDAM 사용자-역할 매핑 기본 데이터
-- 기본 admin 사용자에게 SUPER_ADMIN 역할을 할당합니다.

BEGIN;

-- 사용자-역할 매핑 테이블에 기본 데이터 삽입
-- 주의: permissions.sql, roles.sql, role_permissions.sql을 먼저 실행해야 합니다.

-- 1. 기본 admin 사용자에게 SUPER_ADMIN 역할 할당
INSERT INTO idam.user_roles (
    user_id,
    role_id,
    assigned_by,
    tenant_id
)
SELECT
    u.id as user_id,
    r.id as role_id,
    u.id as assigned_by,  -- 자기 자신이 할당
    u.tenant_id as tenant_id
FROM
    idam.users u
CROSS JOIN
    idam.roles r
WHERE
    u.username = 'admin'
    AND r.role_code = 'SUPER_ADMIN'
AND NOT EXISTS (
    SELECT 1
    FROM idam.user_roles ur
    WHERE ur.user_id = u.id
    AND ur.role_id = r.id
);

COMMIT;

-- 사용자-역할 할당 결과 조회
SELECT
    u.username,
    u.email,
    r.role_code,
    r.role_name,
    r.role_type,
    r.priority,
    ur.assigned_at,
    assigner.username as assigned_by_username
FROM idam.users u
JOIN idam.user_roles ur ON u.id = ur.user_id
JOIN idam.roles r ON ur.role_id = r.id
LEFT JOIN idam.users assigner ON ur.assigned_by = assigner.id
ORDER BY u.username, r.priority ASC;

-- 사용자별 권한 요약 조회
SELECT
    u.username,
    u.email,
    COUNT(DISTINCT r.id) as role_count,
    COUNT(DISTINCT rp.permission_id) as total_permissions,
    STRING_AGG(DISTINCT r.role_code, ', ' ORDER BY r.role_code) as roles
FROM idam.users u
LEFT JOIN idam.user_roles ur ON u.id = ur.user_id
LEFT JOIN idam.roles r ON ur.role_id = r.id
LEFT JOIN idam.role_permissions rp ON r.id = rp.role_id
GROUP BY u.id, u.username, u.email
ORDER BY u.username;
