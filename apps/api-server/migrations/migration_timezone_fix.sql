-- 시간대 처리 수정을 위한 마이그레이션 스크립트
-- BaseModel 및 시간 관련 컬럼들을 TIMESTAMP WITH TIME ZONE으로 변경

-- 사용 전 주의사항:
-- 1. 백업을 먼저 생성하세요
-- 2. 데이터 손실을 방지하기 위해 테스트 환경에서 먼저 실행하세요
-- 3. 운영 환경에서는 점검 시간에 실행하세요

BEGIN;

-- idam.users 테이블 시간 컬럼 수정
ALTER TABLE idam.users
    ALTER COLUMN created_at TYPE TIMESTAMP WITH TIME ZONE,
    ALTER COLUMN updated_at TYPE TIMESTAMP WITH TIME ZONE,
    ALTER COLUMN last_login_at TYPE TIMESTAMP WITH TIME ZONE,
    ALTER COLUMN locked_until TYPE TIMESTAMP WITH TIME ZONE,
    ALTER COLUMN password_changed_at TYPE TIMESTAMP WITH TIME ZONE;

-- idam.login_logs 테이블 시간 컬럼 수정
ALTER TABLE idam.login_logs
    ALTER COLUMN created_at TYPE TIMESTAMP WITH TIME ZONE,
    ALTER COLUMN updated_at TYPE TIMESTAMP WITH TIME ZONE;

-- idam.sessions 테이블 시간 컬럼 수정
ALTER TABLE idam.sessions
    ALTER COLUMN created_at TYPE TIMESTAMP WITH TIME ZONE,
    ALTER COLUMN updated_at TYPE TIMESTAMP WITH TIME ZONE,
    ALTER COLUMN expires_at TYPE TIMESTAMP WITH TIME ZONE,
    ALTER COLUMN last_activity_at TYPE TIMESTAMP WITH TIME ZONE,
    ALTER COLUMN mfa_verified_at TYPE TIMESTAMP WITH TIME ZONE;

-- idam.roles 테이블 시간 컬럼 수정 (만약 존재한다면)
ALTER TABLE idam.roles
    ALTER COLUMN created_at TYPE TIMESTAMP WITH TIME ZONE,
    ALTER COLUMN updated_at TYPE TIMESTAMP WITH TIME ZONE;

-- idam.permissions 테이블 시간 컬럼 수정 (만약 존재한다면)
ALTER TABLE idam.permissions
    ALTER COLUMN created_at TYPE TIMESTAMP WITH TIME ZONE,
    ALTER COLUMN updated_at TYPE TIMESTAMP WITH TIME ZONE;

-- idam.api_keys 테이블 시간 컬럼 수정 (만약 존재한다면)
ALTER TABLE idam.api_keys
    ALTER COLUMN created_at TYPE TIMESTAMP WITH TIME ZONE,
    ALTER COLUMN updated_at TYPE TIMESTAMP WITH TIME ZONE;

-- idam.user_roles 테이블 시간 컬럼 수정 (만약 존재한다면)
ALTER TABLE idam.user_roles
    ALTER COLUMN created_at TYPE TIMESTAMP WITH TIME ZONE,
    ALTER COLUMN updated_at TYPE TIMESTAMP WITH TIME ZONE;

-- idam.role_permissions 테이블 시간 컬럼 수정 (만약 존재한다면)
ALTER TABLE idam.role_permissions
    ALTER COLUMN created_at TYPE TIMESTAMP WITH TIME ZONE,
    ALTER COLUMN updated_at TYPE TIMESTAMP WITH TIME ZONE;

-- 기타 테넌트 관련 테이블들 (tnnt 스키마)
-- tnnt.tenants 테이블 (만약 존재한다면)
-- ALTER TABLE tnnt.tenants
--     ALTER COLUMN created_at TYPE TIMESTAMP WITH TIME ZONE,
--     ALTER COLUMN updated_at TYPE TIMESTAMP WITH TIME ZONE;

-- 변경사항 확인을 위한 쿼리
SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema IN ('idam', 'tnnt')
    AND column_name IN ('created_at', 'updated_at', 'last_login_at', 'expires_at', 'last_activity_at', 'mfa_verified_at', 'locked_until', 'password_changed_at')
ORDER BY table_schema, table_name, column_name;

COMMIT;

-- 마이그레이션 완료 후 시간대 설정 확인
-- SELECT current_setting('timezone');
-- SELECT now(), now() AT TIME ZONE 'UTC', now() AT TIME ZONE 'Asia/Seoul';
