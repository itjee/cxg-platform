-- 통합 IDAM 역할-권한 매핑 기본 데이터
-- 통합된 역할별 권한 할당

BEGIN;

-- 역할-권한 매핑 데이터 삽입
-- 주의: permissions_unified.sql과 roles_unified.sql을 먼저 실행해야 합니다.

-- ============================================================================
-- 1. 슈퍼 관리자 (SUPER_ADMIN) - 모든 권한 (28개)
-- ============================================================================
INSERT INTO idam.role_permissions (
    role_id,
    permission_id,
    granted_by
)
SELECT
    r.id        as role_id,
    p.id        as permission_id,
    u.id        as granted_by
FROM
    idam.roles r
CROSS JOIN
    idam.permissions p
LEFT JOIN
    idam.users u
    ON u.username = 'admin'
WHERE
    r.role_code = 'SUPER_ADMIN'
AND NOT EXISTS
    (
        SELECT 1
        FROM
            idam.role_permissions rp
        WHERE
            rp.role_id = r.id
        AND rp.permission_id = p.id
    );

-- ============================================================================
-- 2. 플랫폼 관리자 (PLATFORM_ADMIN) - 시스템 권한 제외 (25개)
-- ============================================================================
INSERT INTO idam.role_permissions
(
    role_id,
    permission_id,
    granted_by
)
SELECT
    r.id        as role_id,
    p.id        as permission_id,
    u.id        as granted_by
FROM
    idam.roles r
JOIN
    idam.permissions p ON p.permission_code IN
    (
        -- 사용자 관리 (5개)
        'USER_CREATE', 'USER_READ', 'USER_UPDATE', 'USER_DELETE', 'USER_LIST',
        -- 역할 관리 (5개)
        'ROLE_CREATE', 'ROLE_READ', 'ROLE_UPDATE', 'ROLE_DELETE', 'ROLE_LIST',
        -- 권한 관리 (2개) - 시스템 권한 제외
        'PERMISSION_READ', 'PERMISSION_LIST',
        -- 테넌트 관리 (5개)
        'TENANT_CREATE', 'TENANT_READ', 'TENANT_UPDATE', 'TENANT_DELETE', 'TENANT_LIST',
        -- API 키 관리 (5개)
        'API_KEY_CREATE', 'API_KEY_READ', 'API_KEY_UPDATE', 'API_KEY_DELETE', 'API_KEY_LIST',
        -- 시스템 관리 (3개) - SYSTEM_MANAGE 제외
        'AUDIT_READ', 'AUDIT_LIST', 'DASHBOARD_READ'
    )
LEFT JOIN
    idam.users u
    ON u.username = 'admin'
WHERE
    r.role_code = 'PLATFORM_ADMIN'
AND NOT EXISTS
    (
        SELECT 1
        FROM
            idam.role_permissions rp
        WHERE
            rp.role_id = r.id
        AND rp.permission_id = p.id
    );

-- ============================================================================
-- 3. 테넌트 관리자 (TENANT_ADMIN) - 테넌트 관련 권한 (13개)
-- ============================================================================
INSERT INTO idam.role_permissions (
    role_id,
    permission_id,
    granted_by
)
SELECT
    r.id        as role_id,
    p.id        as permission_id,
    u.id        as granted_by
FROM
    idam.roles r
JOIN
    idam.permissions p ON p.permission_code IN
    (
        -- 테넌트 관리 (3개) - CREATE/DELETE 제외 (플랫폼 관리자만 가능)
        'TENANT_READ', 'TENANT_UPDATE', 'TENANT_LIST',
        -- 사용자 관리 (3개) - 테넌트 내 사용자 관리
        'USER_READ', 'USER_UPDATE', 'USER_LIST',
        -- API 키 관리 (5개) - 테넌트 내 API 키 관리
        'API_KEY_CREATE', 'API_KEY_READ', 'API_KEY_UPDATE', 'API_KEY_DELETE', 'API_KEY_LIST',
        -- 역할 조회 (2개)
        'ROLE_READ', 'ROLE_LIST',
        -- 시스템 (1개)
        'DASHBOARD_READ'
    )
LEFT JOIN
    idam.users u
    ON u.username = 'admin'
WHERE
    r.role_code = 'TENANT_ADMIN'
AND NOT EXISTS
    (
        SELECT 1
        FROM
            idam.role_permissions rp
        WHERE
            rp.role_id = r.id
        AND rp.permission_id = p.id
    );

-- ============================================================================
-- 4. 사용자 매니저 (USER_MANAGER) - 사용자 관리 권한 (8개)
-- ============================================================================
INSERT INTO idam.role_permissions (
    role_id,
    permission_id,
    granted_by
)
SELECT
    r.id        as role_id,
    p.id        as permission_id,
    u.id        as granted_by
FROM
    idam.roles r
JOIN
    idam.permissions p ON p.permission_code IN
    (
        -- 사용자 관리 (4개) - DELETE 제외
        'USER_CREATE', 'USER_READ', 'USER_UPDATE', 'USER_LIST',
        -- 역할 관리 (2개) - 조회만
        'ROLE_READ', 'ROLE_LIST',
        -- API 키 관리 (1개) - 조회만
        'API_KEY_READ',
        -- 시스템 (1개)
        'DASHBOARD_READ'
    )
LEFT JOIN
    idam.users u
    ON u.username = 'admin'
WHERE
    r.role_code = 'USER_MANAGER'
AND NOT EXISTS
    (
        SELECT 1
        FROM
            idam.role_permissions rp
        WHERE
            rp.role_id = r.id
        AND rp.permission_id = p.id
    );

-- ============================================================================
-- 5. 일반 사용자 (USER) - 기본 권한 (8개)
-- ============================================================================
INSERT INTO idam.role_permissions
(
    role_id,
    permission_id,
    granted_by
)
SELECT
    r.id        as role_id,
    p.id        as permission_id,
    u.id        as granted_by
FROM
    idam.roles r
JOIN
    idam.permissions p ON p.permission_code IN
    (
        -- 자기 정보 관리
        'USER_READ',
        -- 기본 조회 권한
        'ROLE_READ', 'ROLE_LIST',
        'PERMISSION_READ', 'PERMISSION_LIST',
        'TENANT_READ',
        'API_KEY_READ',
        'DASHBOARD_READ'
    )
LEFT JOIN
    idam.users u
    ON u.username = 'admin'
WHERE
    r.role_code = 'USER'
AND NOT EXISTS
    (
        SELECT 1
        FROM
            idam.role_permissions rp
        WHERE
            rp.role_id = r.id
        AND rp.permission_id = p.id
    );

-- ============================================================================
-- 6. 게스트 (GUEST) - 최소 권한 (1개)
-- ============================================================================
INSERT INTO idam.role_permissions
(
    role_id,
    permission_id,
    granted_by
)
SELECT
    r.id        as role_id,
    p.id        as permission_id,
    u.id        as granted_by
FROM
    idam.roles r
JOIN
    idam.permissions p ON p.permission_code IN
    (
        -- 대시보드 조회만
        'DASHBOARD_READ'
    )
LEFT JOIN
    idam.users u
    ON u.username = 'admin'
WHERE
    r.role_code = 'GUEST'
AND NOT EXISTS
    (
        SELECT 1
        FROM
            idam.role_permissions rp
        WHERE
            rp.role_id = r.id
        AND rp.permission_id = p.id
    );

-- ============================================================================
-- 7. API 서비스 (API_SERVICE) - API 전용 권한 (6개)
-- ============================================================================
INSERT INTO idam.role_permissions
(
    role_id,
    permission_id,
    granted_by
)
SELECT
    r.id        as role_id,
    p.id        as permission_id,
    u.id        as granted_by
FROM
    idam.roles r
JOIN
    idam.permissions p ON p.permission_code IN
    (
        -- API 키 관리
        'API_KEY_CREATE', 'API_KEY_READ', 'API_KEY_UPDATE', 'API_KEY_DELETE', 'API_KEY_LIST',
        -- 기본 조회
        'TENANT_READ'
    )
LEFT JOIN
    idam.users u
    ON u.username = 'admin'
WHERE
    r.role_code = 'API_SERVICE'
AND NOT EXISTS
    (
        SELECT 1
        FROM
            idam.role_permissions rp
        WHERE
            rp.role_id = r.id
        AND rp.permission_id = p.id
    );

-- ============================================================================
-- 8. 읽기 전용 관리자 (READONLY_ADMIN) - 모든 읽기 권한 (12개)
-- ============================================================================
INSERT INTO idam.role_permissions
(
    role_id,
    permission_id,
    granted_by
)
SELECT
    r.id        as role_id,
    p.id        as permission_id,
    u.id        as granted_by
FROM
    idam.roles r
JOIN
    idam.permissions p ON p.permission_code IN
    (
        -- 모든 READ/LIST 권한
        'USER_READ', 'USER_LIST',
        'ROLE_READ', 'ROLE_LIST',
        'PERMISSION_READ', 'PERMISSION_LIST',
        'TENANT_READ', 'TENANT_LIST',
        'API_KEY_READ', 'API_KEY_LIST',
        'AUDIT_READ', 'DASHBOARD_READ'
    )
LEFT JOIN
    idam.users u
    ON u.username = 'admin'
WHERE
    r.role_code = 'READONLY_ADMIN'
AND NOT EXISTS
    (
        SELECT 1
        FROM
            idam.role_permissions rp
        WHERE
            rp.role_id = r.id
        AND rp.permission_id = p.id
    );

COMMIT;

-- 역할-권한 할당 결과 조회
SELECT
    r.role_code,
    r.role_name,
    r.role_type,
    r.scope,
    r.priority,
    COUNT(rp.permission_id) as permission_count,
    STRING_AGG(p.permission_code, ', ' ORDER BY p.permission_code) as permissions
FROM idam.roles r
LEFT JOIN idam.role_permissions rp ON r.id = rp.role_id
LEFT JOIN idam.permissions p ON rp.permission_id = p.id
GROUP BY r.id, r.role_code, r.role_name, r.role_type, r.scope, r.priority
ORDER BY r.priority ASC;
