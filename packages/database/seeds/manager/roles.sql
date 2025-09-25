-- IDAM 역할 기본 데이터
-- 총 6개의 기본 역할을 생성합니다.

BEGIN;

-- 역할 테이블에 기본 데이터 삽입
INSERT INTO idam.roles (
    role_code,
    role_name,
    description,
    role_type,
    scope,
    is_default,
    priority,
    status
) VALUES
-- 시스템 관리자 (최고 권한)
(
    'SUPER_ADMIN',
    '슈퍼 관리자',
    '모든 시스템 권한을 가진 최고 관리자',
    'SYSTEM',
    'GLOBAL',
    false,
    1,
    'ACTIVE'
),
-- 플랫폼 관리자 (전체 플랫폼 관리)
(
    'ADMIN',
    '관리자',
    '전체 플랫폼 관리 권한을 가진 관리자',
    'PLATFORM',
    'GLOBAL',
    false,
    10,
    'ACTIVE'
),
-- 테넌트 관리자 (조직 관리)
(
    'TENANT_ADMIN',
    '테넌트 관리자',
    '테넌트 조직 관리 권한을 가진 관리자',
    'ADMIN',
    'GLOBAL',
    false,
    20,
    'ACTIVE'
),
-- 사용자 매니저 (팀/부서 관리)
(
    'USER_MANAGER',
    '사용자 매니저',
    '팀/부서 사용자 관리 권한을 가진 매니저',
    'MANAGER',
    'GLOBAL',
    false,
    30,
    'ACTIVE'
),
-- 게스트 (임시/제한적 접근)
(
    'GUEST',
    '게스트',
    '임시 또는 제한적 접근 권한을 가진 게스트 사용자',
    'GUEST',
    'GLOBAL',
    false,
    200,
    'ACTIVE'
),
-- 일반 사용자 (읽기 전용, 기본 역할)
(
    'VIEWER',
    '뷰어',
    '읽기 전용 권한을 가진 일반 사용자',
    'USER',
    'GLOBAL',
    true,
    100,
    'ACTIVE'
)
ON CONFLICT (role_code) DO NOTHING;

COMMIT;

-- 역할 생성 결과 조회
SELECT
    role_code,
    role_name,
    description,
    role_type,
    scope,
    is_default,
    priority,
    status
FROM idam.roles
ORDER BY priority ASC;
