-- IDAM 전체 시드 데이터 실행 스크립트
-- 권한, 역할, 역할-권한 매핑을 순서대로 실행합니다.

-- 실행 시작 로그
SELECT 'IDAM 시드 데이터 생성을 시작합니다...' as message;
SELECT NOW() as start_time;

-- 1. 권한 생성
SELECT '1. 권한 생성 중...' as step;
\i permissions.sql

-- 2. 역할 생성
SELECT '2. 역할 생성 중...' as step;
\i roles.sql

-- 3. 역할-권한 매핑
SELECT '3. 역할-권한 매핑 중...' as step;
\i role_permissions.sql

-- 4. 사용자-역할 매핑
SELECT '4. 사용자-역할 매핑 중...' as step;
\i user_roles.sql

-- 실행 완료 로그 및 결과 확인
SELECT '✅ IDAM 시드 데이터 생성이 완료되었습니다!' as message;
SELECT NOW() as end_time;

-- 최종 결과 요약
SELECT '📊 생성된 데이터 요약' as summary;

SELECT
    '권한(Permissions)' as type,
    COUNT(*) as count
FROM idam.permissions
UNION ALL
SELECT
    '역할(Roles)' as type,
    COUNT(*) as count
FROM idam.roles
UNION ALL
SELECT
    '역할-권한 매핑(Role-Permissions)' as type,
    COUNT(*) as count
FROM idam.role_permissions
UNION ALL
SELECT
    '사용자-역할 매핑(User-Roles)' as type,
    COUNT(*) as count
FROM idam.user_roles;

-- 역할별 권한 수 확인
SELECT
    '역할별 권한 수' as info;

SELECT
    r.role_code,
    r.role_name,
    COUNT(rp.permission_id) as permission_count
FROM idam.roles r
LEFT JOIN idam.role_permissions rp ON r.id = rp.role_id
GROUP BY r.id, r.role_code, r.role_name, r.priority
ORDER BY r.priority ASC;
