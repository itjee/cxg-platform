-- IDAM Permissions Basic Data
-- Creates 28 essential permissions

BEGIN;

-- Insert basic permission data
INSERT INTO idam.permissions (
    permission_code,
    permission_name,
    description,
    category,
    resource_type,
    action,
    scope,
    applies_to,
    is_system,
    status
) VALUES
-- User Management Permissions (5)
(
    'USER_CREATE',
    '사용자 생성',
    '새로운 사용자 계정을 생성할 수 있는 권한',
    'USER',
    'USER',
    'CREATE',
    'GLOBAL',
    'MASTER',
    false,
    'ACTIVE'
),
(
    'USER_READ',
    '사용자 조회',
    '사용자 정보를 조회할 수 있는 권한',
    'USER',
    'USER',
    'READ',
    'GLOBAL',
    'ALL',
    false,
    'ACTIVE'
),
(
    'USER_UPDATE',
    '사용자 수정',
    '사용자 계정을 수정할 수 있는 권한',
    'USER',
    'USER',
    'UPDATE',
    'GLOBAL',
    'MASTER',
    false,
    'ACTIVE'
),
(
    'USER_DELETE',
    '사용자 삭제',
    '사용자 계정을 삭제할 수 있는 권한',
    'USER',
    'USER',
    'DELETE',
    'GLOBAL',
    'MASTER',
    false,
    'ACTIVE'
),
(
    'USER_LIST',
    '사용자 목록 조회',
    '사용자 목록을 조회할 수 있는 권한',
    'USER',
    'USER',
    'LIST',
    'GLOBAL',
    'ALL',
    false,
    'ACTIVE'
),

-- Role Management Permissions (5)
(
    'ROLE_CREATE',
    '역할 생성',
    '새로운 역할을 생성할 수 있는 권한',
    'ADMIN',
    'ROLE',
    'CREATE',
    'GLOBAL',
    'MASTER',
    false,
    'ACTIVE'
),
(
    'ROLE_READ',
    '역할 조회',
    '역할 정보를 조회할 수 있는 권한',
    'ADMIN',
    'ROLE',
    'READ',
    'GLOBAL',
    'ALL',
    false,
    'ACTIVE'
),
(
    'ROLE_UPDATE',
    '역할 수정',
    '역할을 수정할 수 있는 권한',
    'ADMIN',
    'ROLE',
    'UPDATE',
    'GLOBAL',
    'MASTER',
    false,
    'ACTIVE'
),
(
    'ROLE_DELETE',
    '역할 삭제',
    '역할을 삭제할 수 있는 권한',
    'ADMIN',
    'ROLE',
    'DELETE',
    'GLOBAL',
    'MASTER',
    false,
    'ACTIVE'
),
(
    'ROLE_LIST',
    '역할 목록 조회',
    '역할 목록을 조회할 수 있는 권한',
    'ADMIN',
    'ROLE',
    'LIST',
    'GLOBAL',
    'ALL',
    false,
    'ACTIVE'
),

-- Permission Management Permissions (4)
(
    'PERMISSION_READ',
    '권한 조회',
    '권한 정보를 조회할 수 있는 권한',
    'ADMIN',
    'PERMISSION',
    'READ',
    'GLOBAL',
    'ALL',
    false,
    'ACTIVE'
),
(
    'PERMISSION_UPDATE',
    '권한 수정',
    '권한을 수정할 수 있는 권한',
    'ADMIN',
    'PERMISSION',
    'UPDATE',
    'GLOBAL',
    'MASTER',
    true,
    'ACTIVE'
),
(
    'PERMISSION_LIST',
    '권한 목록 조회',
    '권한 목록을 조회할 수 있는 권한',
    'ADMIN',
    'PERMISSION',
    'LIST',
    'GLOBAL',
    'ALL',
    false,
    'ACTIVE'
),
(
    'PERMISSION_MANAGE',
    '권한 전체 관리',
    '모든 권한 관리 작업을 수행할 수 있는 관리자 권한',
    'ADMIN',
    'PERMISSION',
    'MANAGE',
    'GLOBAL',
    'MASTER',
    true,
    'ACTIVE'
),

-- Tenant Management Permissions (5)
(
    'TENANT_CREATE',
    '테넌트 생성',
    '새로운 테넌트를 생성할 수 있는 권한',
    'TENANT',
    'TENANT',
    'CREATE',
    'GLOBAL',
    'MASTER',
    false,
    'ACTIVE'
),
(
    'TENANT_READ',
    '테넌트 조회',
    '테넌트 정보를 조회할 수 있는 권한',
    'TENANT',
    'TENANT',
    'READ',
    'TENANT',
    'ALL',
    false,
    'ACTIVE'
),
(
    'TENANT_UPDATE',
    '테넌트 수정',
    '테넌트를 수정할 수 있는 권한',
    'TENANT',
    'TENANT',
    'UPDATE',
    'TENANT',
    'TENANT',
    false,
    'ACTIVE'
),
(
    'TENANT_DELETE',
    '테넌트 삭제',
    '테넌트를 삭제할 수 있는 권한',
    'TENANT',
    'TENANT',
    'DELETE',
    'GLOBAL',
    'MASTER',
    false,
    'ACTIVE'
),
(
    'TENANT_LIST',
    '테넌트 목록 조회',
    '테넌트 목록을 조회할 수 있는 권한',
    'TENANT',
    'TENANT',
    'LIST',
    'GLOBAL',
    'ALL',
    false,
    'ACTIVE'
),

-- API Key Management Permissions (5)
(
    'API_KEY_CREATE',
    'API 키 생성',
    '새로운 API 키를 생성할 수 있는 권한',
    'API',
    'API_KEY',
    'CREATE',
    'TENANT',
    'ALL',
    false,
    'ACTIVE'
),
(
    'API_KEY_READ',
    'API 키 조회',
    'API 키 정보를 조회할 수 있는 권한',
    'API',
    'API_KEY',
    'READ',
    'TENANT',
    'ALL',
    false,
    'ACTIVE'
),
(
    'API_KEY_UPDATE',
    'API 키 수정',
    'API 키를 수정할 수 있는 권한',
    'API',
    'API_KEY',
    'UPDATE',
    'TENANT',
    'ALL',
    false,
    'ACTIVE'
),
(
    'API_KEY_DELETE',
    'API 키 삭제',
    'API 키를 삭제할 수 있는 권한',
    'API',
    'API_KEY',
    'DELETE',
    'TENANT',
    'ALL',
    false,
    'ACTIVE'
),
(
    'API_KEY_LIST',
    'API 키 목록 조회',
    'API 키 목록을 조회할 수 있는 권한',
    'API',
    'API_KEY',
    'LIST',
    'TENANT',
    'ALL',
    false,
    'ACTIVE'
),

-- System Management Permissions (4)
(
    'SYSTEM_MANAGE',
    '시스템 관리',
    '모든 시스템 리소스를 관리할 수 있는 관리자 권한',
    'SYSTEM',
    'SYSTEM',
    'MANAGE',
    'GLOBAL',
    'MASTER',
    true,
    'ACTIVE'
),
(
    'AUDIT_READ',
    '감사 조회',
    '시스템 감사 로그를 조회할 수 있는 권한',
    'SYSTEM',
    'AUDIT',
    'READ',
    'GLOBAL',
    'MASTER',
    false,
    'ACTIVE'
),
(
    'AUDIT_LIST',
    '감사 목록 조회',
    '감사 로그 목록을 조회할 수 있는 권한',
    'SYSTEM',
    'AUDIT',
    'LIST',
    'GLOBAL',
    'MASTER',
    false,
    'ACTIVE'
),
(
    'DASHBOARD_READ',
    '대시보드 조회',
    '관리자 대시보드를 조회할 수 있는 권한',
    'SYSTEM',
    'DASHBOARD',
    'READ',
    'GLOBAL',
    'ALL',
    false,
    'ACTIVE'
)
ON CONFLICT (permission_code) DO NOTHING;

COMMIT;

-- Query results
SELECT
    permission_code,
    permission_name,
    category,
    resource_type,
    action,
    scope,
    applies_to,
    is_system,
    status
FROM idam.permissions
ORDER BY
    CASE category
        WHEN 'USER' THEN 1
        WHEN 'ADMIN' THEN 2
        WHEN 'TENANT' THEN 3
        WHEN 'API' THEN 4
        WHEN 'SYSTEM' THEN 5
        ELSE 6
    END,
    permission_code;
