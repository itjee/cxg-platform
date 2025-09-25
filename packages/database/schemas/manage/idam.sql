
-- ============================================================================
-- 3. 사용자 및 접근 관리 (Identity & Access Management) -> idam
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS idam;

COMMENT ON SCHEMA idam
IS 'IDAM: 운영자/IAM 스키마: 운영자 인증/인가 관련 메타를 관리. 최소권한(RBAC)과 접근 감사를 전제.';

/*

DROP TABLE IF EXISTS idam.users CASCADE;
DROP TABLE IF EXISTS idam.permissions CASCADE;
DROP TABLE IF EXISTS idam.roles CASCADE;
DROP TABLE IF EXISTS idam.role_permissions CASCADE;
DROP TABLE IF EXISTS idam.user_roles CASCADE;
DROP TABLE IF EXISTS idam.login_logs CASCADE;
DROP TABLE IF EXISTS idam.sessions CASCADE;
DROP TABLE IF EXISTS idam.api_keys CASCADE;

*/

-- ============================================================================
-- 운영자 계정
-- ============================================================================
CREATE TABLE IF NOT EXISTS idam.users
(
    id                          UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),  -- 사용자 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT CURRENT_TIMESTAMP,     -- 생성일시
    created_by                  UUID,                                                               -- 생성자 ID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                           -- 수정일시
    updated_by                  UUID,                                                               -- 수정자 ID

	user_type                   VARCHAR(20)                 NOT NULL DEFAULT 'USER',                -- 사용자 타입 (ADMIN, USER, SYSTEM)
	full_name                   VARCHAR(100)                NOT NULL,                               -- 전체 이름
	email                       VARCHAR(255)                NOT NULL,                               -- 이메일 주소
	phone                       VARCHAR(20),                                                        -- 전화번호

    -- 인증 정보
    username                    VARCHAR(100)                NOT NULL,                               -- 로그인명(아이디)
    password                    VARCHAR(255),                                                       -- 암호화된 비밀번호 (SSO 사용시 NULL)
    salt_key                    VARCHAR(100),                                                       -- 비밀번호 솔트

    -- SSO 정보
    sso_provider                VARCHAR(50),                                                        -- SSO 제공자 (google, azure, okta)
    sso_subject                 VARCHAR(255),                                                       -- SSO 제공자의 고유 식별자

    -- MFA 설정
    mfa_enabled                 BOOLEAN                     NOT NULL DEFAULT FALSE,                 -- MFA 활성화 여부
    mfa_secret                  VARCHAR(255),                                                       -- TOTP 시크릿 키
    backup_codes                TEXT[],                                                             -- MFA 백업 코드 배열

    -- 계정 상태
    status                      VARCHAR(20)                 NOT NULL DEFAULT 'ACTIVE',              -- 계정 상태

    -- 보안 정보
    last_login_at               TIMESTAMP WITH TIME ZONE,                                           -- 마지막 로그인 일시
    last_login_ip               INET,                                                               -- 마지막 로그인 IP
    failed_login_attempts       INTEGER                     NOT NULL DEFAULT 0,                     -- 로그인 실패 횟수
    locked_until                TIMESTAMP WITH TIME ZONE,                                           -- 계정 잠금 해제 일시
    password_changed_at         TIMESTAMP WITH TIME ZONE,                                           -- 비밀번호 변경 일시
    force_password_change       BOOLEAN                     NOT NULL DEFAULT FALSE,                 -- 비밀번호 강제 변경 여부

    -- 추가 메타데이터
    timezone                    VARCHAR(50)                 DEFAULT 'UTC',                          -- 사용자 시간대
    locale                      VARCHAR(10)                 DEFAULT 'ko-KR',                        -- 사용자 로케일


    department                  VARCHAR(100),                                                       -- 부서명
    position                    VARCHAR(100),                                                       -- 직책

    CONSTRAINT uk_users__username              UNIQUE (username),
    CONSTRAINT uk_users__email                 UNIQUE (email),
    CONSTRAINT uk_users__sso_provider_subject  UNIQUE (sso_provider, sso_subject),

    CONSTRAINT ck_users__status                CHECK (status IN ('ACTIVE', 'INACTIVE', 'LOCKED', 'SUSPENDED')),
	CONSTRAINT ck_users__user_type             CHECK (user_type IN ('MASTER', 'TENANT', 'SYSTEM')),
    CONSTRAINT ck_users__sso_consistency       CHECK (
														(sso_provider IS NULL AND sso_subject IS NULL) OR
														(sso_provider IS NOT NULL AND sso_subject IS NOT NULL)
													 )
);

COMMENT ON TABLE  idam.users                        IS '운영자 사용자 계정 관리';
COMMENT ON COLUMN idam.users.id                     IS '사용자 고유 식별자';
COMMENT ON COLUMN idam.users.created_at             IS '생성일시';
COMMENT ON COLUMN idam.users.created_by             IS '생성자 ID';
COMMENT ON COLUMN idam.users.updated_at             IS '수정일시';
COMMENT ON COLUMN idam.users.updated_by             IS '수정자 ID';
COMMENT ON COLUMN idam.users.user_type              IS '사용자 타입 (MASTER: 운영관리자, TENANT: 테넌트사용자, SYSTEM: 시스템)';
COMMENT ON COLUMN idam.users.full_name              IS '전체 이름';
COMMENT ON COLUMN idam.users.email                  IS '이메일 주소';
COMMENT ON COLUMN idam.users.phone                  IS '전화번호';
COMMENT ON COLUMN idam.users.username               IS '로그인 사용자명';
COMMENT ON COLUMN idam.users.password               IS '암호화된 비밀번호 (SSO 사용시 NULL)';
COMMENT ON COLUMN idam.users.salt_key               IS '비밀번호 솔트';
COMMENT ON COLUMN idam.users.sso_provider           IS 'SSO 제공자 (google, azure, okta)';
COMMENT ON COLUMN idam.users.sso_subject            IS 'SSO 제공자의 고유 식별자';
COMMENT ON COLUMN idam.users.mfa_enabled            IS 'MFA 활성화 여부';
COMMENT ON COLUMN idam.users.mfa_secret             IS 'TOTP 시크릿 키';
COMMENT ON COLUMN idam.users.backup_codes           IS 'MFA 백업 코드 배열';
COMMENT ON COLUMN idam.users.status                 IS '계정 상태 (ACTIVE, INACTIVE, LOCKED, SUSPENDED)';
COMMENT ON COLUMN idam.users.last_login_at          IS '마지막 로그인 일시';
COMMENT ON COLUMN idam.users.last_login_ip          IS '마지막 로그인 IP';
COMMENT ON COLUMN idam.users.failed_login_attempts  IS '로그인 실패 횟수';
COMMENT ON COLUMN idam.users.locked_until           IS '계정 잠금 해제 일시';
COMMENT ON COLUMN idam.users.password_changed_at    IS '비밀번호 변경 일시';
COMMENT ON COLUMN idam.users.force_password_change  IS '비밀번호 강제 변경 여부';
COMMENT ON COLUMN idam.users.timezone               IS '사용자 시간대';
COMMENT ON COLUMN idam.users.locale                 IS '사용자 로케일';
COMMENT ON COLUMN idam.users.department             IS '부서명';
COMMENT ON COLUMN idam.users.position               IS '직책';

CREATE INDEX IF NOT EXISTS ix_users__user_type
	ON idam.users (user_type);

-- 이메일 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_users__email
    ON idam.users (email)
 WHERE status = 'ACTIVE';

-- 사용자명 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_users__username
    ON idam.users (username)
 WHERE status = 'ACTIVE';

-- 계정 상태별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_users__status
    ON idam.users (status);

-- 마지막 로그인 일시 조회용 인덱스 (비활성 사용자 식별)
CREATE INDEX IF NOT EXISTS ix_users__last_login_at
    ON idam.users (last_login_at)
 WHERE status = 'ACTIVE';

-- SSO 제공자별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_users__sso_provider
    ON idam.users (sso_provider)
 WHERE sso_provider IS NOT NULL;

-- 잠긴 계정 조회용 인덱스 (자동 해제 처리용)
CREATE INDEX IF NOT EXISTS ix_users__locked_until
    ON idam.users (locked_until)
 WHERE locked_until IS NOT NULL;

-- 비밀번호 강제 변경 대상 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_users__force_password_change
    ON idam.users (force_password_change)
 WHERE force_password_change = TRUE;


-- ============================================================================
-- 권한 카탈로그
-- ============================================================================
CREATE TABLE IF NOT EXISTS idam.permissions
(
    id                          UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),  -- 권한 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT CURRENT_TIMESTAMP,     -- 생성일시
    created_by                  UUID,                                                               -- 생성자 ID
    updated_at                  TIMESTAMP WITH TIME ZONE,     										-- 수정일시
    updated_by                  UUID,                                                               -- 수정자 ID

    -- 권한 정보
    permission_code             VARCHAR(100)                NOT NULL,                               -- 권한 코드 (tenant:read, system:config:write)
    permission_name             VARCHAR(100)                NOT NULL,                               -- 권한 명칭
    description                 TEXT,                                                               -- 권한 설명
    category                    VARCHAR(50)                 NOT NULL,                               -- 권한 카테고리 (tenant, system, billing, monitoring)

    -- 권한 레벨
    resource_type               VARCHAR(50)                 NOT NULL,                               -- 리소스 타입 (tenant, system, billing)
    action                      VARCHAR(50)                 NOT NULL,                               -- 액션 (CREATE, READ, UPDATE, DELETE, LIST, MANAGE)

	-- 권한 스코프 (통합 관리의 핵심)
    scope                       VARCHAR(20)                 NOT NULL DEFAULT 'GLOBAL',             -- 권한 적용 범위 (GLOBAL, TENANT)
    applies_to                  VARCHAR(20)                 NOT NULL DEFAULT 'ALL',                -- 적용 대상 (ALL, MASTER, TENANT, SYSTEM)

    -- 메타데이터
    is_system        			BOOLEAN                     NOT NULL DEFAULT FALSE,                 -- 시스템 기본 권한 여부
    status                      VARCHAR(20)                 NOT NULL DEFAULT 'ACTIVE',             	-- 권한 상태

    CONSTRAINT uk_permissions__permission_code UNIQUE (permission_code),

    CONSTRAINT ck_permissions__status          CHECK (status IN ('ACTIVE', 'INACTIVE')),
    CONSTRAINT ck_permissions__action          CHECK (action IN ('CREATE', 'READ', 'UPDATE', 'DELETE', 'LIST', 'MANAGE')),
    CONSTRAINT ck_permissions__scope           CHECK (scope IN ('GLOBAL', 'TENANT')),
    CONSTRAINT ck_permissions__applies_to      CHECK (applies_to IN ('ALL', 'MASTER', 'TENANT', 'SYSTEM'))
);

COMMENT ON TABLE  idam.permissions                          IS '통합 권한 카탈로그 (글로벌 + 테넌트)';
COMMENT ON COLUMN idam.permissions.id                       IS '권한 고유 식별자';
COMMENT ON COLUMN idam.permissions.created_at               IS '생성일시';
COMMENT ON COLUMN idam.permissions.created_by               IS '생성자 ID';
COMMENT ON COLUMN idam.permissions.updated_at               IS '수정일시';
COMMENT ON COLUMN idam.permissions.updated_by               IS '수정자 ID';
COMMENT ON COLUMN idam.permissions.permission_code          IS '권한 코드 (tenant:read, system:config:write 등)';
COMMENT ON COLUMN idam.permissions.permission_name          IS '권한 명칭';
COMMENT ON COLUMN idam.permissions.description              IS '권한 설명';
COMMENT ON COLUMN idam.permissions.category                 IS '권한 카테고리 (tenant, system, billing, monitoring)';
COMMENT ON COLUMN idam.permissions.resource_type            IS '리소스 타입 (tenant, system, billing)';
COMMENT ON COLUMN idam.permissions.action                   IS '액션 (CREATE, READ, UPDATE, DELETE, LIST, MANAGE)';
COMMENT ON COLUMN idam.permissions.scope                    IS '권한 적용 범위 (GLOBAL: 전역, TENANT: 테넌트별)';
COMMENT ON COLUMN idam.permissions.applies_to               IS '적용 대상 (ALL: 모든 사용자, MASTER: 관리자만, TENANT: 사용자만, SYSTEM: 시스템만)';
COMMENT ON COLUMN idam.permissions.is_system     			IS '시스템 기본 권한 여부';
COMMENT ON COLUMN idam.permissions.status                   IS '권한 상태 (ACTIVE, INACTIVE)';

-- 권한 코드 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_permissions__permission_code
    ON idam.permissions (permission_code)
 WHERE status = 'ACTIVE';

-- 카테고리별 권한 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_permissions__category
    ON idam.permissions (category)
 WHERE status = 'ACTIVE';

-- 리소스 타입별 권한 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_permissions__resource_type
    ON idam.permissions (resource_type)
 WHERE status = 'ACTIVE';

-- 액션별 권한 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_permissions__action
    ON idam.permissions (action)
 WHERE status = 'ACTIVE';

CREATE INDEX IF NOT EXISTS ix_permissions__scope
	ON idam.permissions (scope)
 WHERE status = 'ACTIVE';

CREATE INDEX IF NOT EXISTS ix_permissions__applies_to
	ON idam.permissions (applies_to)
 WHERE status = 'ACTIVE';

-- 시스템 권한 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_permissions__is_system
    ON idam.permissions (is_system)
 WHERE is_system = TRUE;

-- 권한 상태별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_permissions__status
    ON idam.permissions (status);

-- 복합 조회용 인덱스 (카테고리 + 액션)
CREATE INDEX IF NOT EXISTS ix_permissions__category_action
    ON idam.permissions (category, action)
 WHERE status = 'ACTIVE';


-- ========================================
-- 역할 정의
-- ========================================
CREATE TABLE IF NOT EXISTS idam.roles
(
    id                          UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),	-- 역할 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT CURRENT_TIMESTAMP,     -- 생성일시
    created_by                  UUID,                                                               -- 생성자 ID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                           -- 수정일시
    updated_by                  UUID,                                                               -- 수정자 ID

    -- 역할 정보
    role_code                   VARCHAR(100)                NOT NULL,                               -- 역할 코드 (super_admin, tenant_admin, support)
    role_name                   VARCHAR(100)                NOT NULL,                               -- 역할 명칭
    description                 TEXT,                                                               -- 역할 설명

    -- 역할 속성
    role_type                   VARCHAR(50)                 NOT NULL DEFAULT 'USER',             	-- 역할 타입 (SYSTEM, PLATFORM, ADMIN, MANAGER, USER, GUEST)
	scope                       VARCHAR(20)                 NOT NULL DEFAULT 'GLOBAL',             	-- 적용 범위 (GLOBAL: 전역, TENANT: 테넌트별)

    is_default                  BOOLEAN                     NOT NULL DEFAULT FALSE,                 -- 기본 역할 여부
    priority                    INTEGER                     NOT NULL DEFAULT 100,                   -- 역할 우선순위 (낮을수록 높은 권한)

    -- 상태
    status                      VARCHAR(20)                 NOT NULL DEFAULT 'ACTIVE',             	-- 역할 상태

    CONSTRAINT uk_roles__role_code         UNIQUE (role_code),
    CONSTRAINT ck_roles__status            CHECK (status IN ('ACTIVE', 'INACTIVE')),
    CONSTRAINT ck_roles__role_type         CHECK (role_type IN ('SYSTEM', 'PLATFORM', 'ADMIN', 'MANAGER', 'USER', 'GUEST')),
    CONSTRAINT ck_roles__scope             CHECK (scope IN ('GLOBAL', 'TENANT'))
);

COMMENT ON TABLE  idam.roles                    IS '운영자 역할 정의';
COMMENT ON COLUMN idam.roles.id                 IS '역할 고유 식별자';
COMMENT ON COLUMN idam.roles.created_at         IS '생성일시';
COMMENT ON COLUMN idam.roles.created_by         IS '생성자 ID';
COMMENT ON COLUMN idam.roles.updated_at         IS '수정일시';
COMMENT ON COLUMN idam.roles.updated_by         IS '수정자 ID';
COMMENT ON COLUMN idam.roles.role_code          IS '역할 코드 (super_admin, tenant_admin, support)';
COMMENT ON COLUMN idam.roles.role_name          IS '역할 명칭';
COMMENT ON COLUMN idam.roles.description        IS '역할 설명';
COMMENT ON COLUMN idam.roles.role_type          IS '역할 타입 (SYSTEM > PLATFORM > ADMIN > MANAGER > USER > GUEST)';
COMMENT ON COLUMN idam.roles.scope              IS '역할 적용 범위 (GLOBAL: 전역, TENANT: 테넌트별)';
COMMENT ON COLUMN idam.roles.is_default         IS '기본 역할 여부';
COMMENT ON COLUMN idam.roles.priority           IS '역할 우선순위 (낮을수록 높은 권한)';
COMMENT ON COLUMN idam.roles.status             IS '역할 상태 (ACTIVE, INACTIVE)';

-- 역할 코드 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_roles__role_code
    ON idam.roles (role_code)
 WHERE status = 'ACTIVE';

-- 역할 타입별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_roles__role_type
    ON idam.roles (role_type)
 WHERE status = 'ACTIVE';

CREATE INDEX IF NOT EXISTS ix_roles__scope
	ON idam.roles (scope)
 WHERE status = 'ACTIVE';

-- 기본 역할 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_roles__is_default
    ON idam.roles (is_default)
 WHERE is_default = TRUE
   AND status = 'ACTIVE';

-- 우선순위별 조회용 인덱스 (권한 충돌 해결용)
CREATE INDEX IF NOT EXISTS ix_roles__priority
    ON idam.roles (priority)
 WHERE status = 'ACTIVE';

-- 역할 상태별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_roles__status
    ON idam.roles (status);


-- ========================================
-- 역할-권한 매핑
-- ========================================
CREATE TABLE IF NOT EXISTS idam.role_permissions
(
    id                          UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),  -- 역할-권한 매핑 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT CURRENT_TIMESTAMP,     -- 생성일시
    created_by                  UUID,                                                               -- 생성자 ID
    updated_at                  TIMESTAMP WITH TIME ZONE,     -- 수정일시
    updated_by                  UUID,                                                               -- 수정자 ID

    role_id                     UUID                        NOT NULL,         						-- 역할 ID
    permission_id               UUID                        NOT NULL,   							-- 권한 ID

    -- 권한 부여 조건
    granted_at                  TIMESTAMP WITH TIME ZONE,     										-- 권한 부여일시
	granted_by                  UUID,              													-- 권한 부여자 ID

	CONSTRAINT fk_role_permissions__role_id 			FOREIGN KEY (role_id) 		REFERENCES idam.roles(id) 		ON DELETE CASCADE,
	CONSTRAINT fk_role_permissions__permission_id 		FOREIGN KEY (permission_id) REFERENCES idam.permissions(id) ON DELETE CASCADE
);

COMMENT ON TABLE  idam.role_permissions                     IS '역할-권한 매핑 관리';
COMMENT ON COLUMN idam.role_permissions.id                  IS '역할-권한 매핑 고유 식별자';
COMMENT ON COLUMN idam.role_permissions.created_at          IS '생성일시';
COMMENT ON COLUMN idam.role_permissions.created_by          IS '생성자 ID';
COMMENT ON COLUMN idam.role_permissions.updated_at          IS '수정일시';
COMMENT ON COLUMN idam.role_permissions.updated_by          IS '수정자 ID';
COMMENT ON COLUMN idam.role_permissions.role_id             IS '역할 ID';
COMMENT ON COLUMN idam.role_permissions.permission_id       IS '권한 ID';
COMMENT ON COLUMN idam.role_permissions.granted_by          IS '권한 부여자 ID';
COMMENT ON COLUMN idam.role_permissions.granted_at          IS '권한 부여일시';

--역할, 권한 매핑
CREATE UNIQUE INDEX IF NOT EXISTS ux_role_permissions
	ON idam.role_permissions (role_id, permission_id);

-- 역할 ID 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_role_permissions__role_id
    ON idam.role_permissions (role_id);

-- 권한 ID 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_role_permissions__permission_id
    ON idam.role_permissions (permission_id);

-- 권한 부여자 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_role_permissions__granted_by
    ON idam.role_permissions (granted_by)
 WHERE granted_by IS NOT NULL;

-- 권한 부여일시 조회용 인덱스 (감사 추적용)
CREATE INDEX IF NOT EXISTS ix_role_permissions__granted_at
    ON idam.role_permissions (granted_at);


-- ========================================
-- 사용자-역할 매핑
-- ========================================
CREATE TABLE IF NOT EXISTS idam.user_roles
(
    id                          UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),  -- 사용자-역할 매핑 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT CURRENT_TIMESTAMP,     -- 생성일시
    created_by                  UUID,                                                               -- 생성자 ID
    updated_at                  TIMESTAMP WITH TIME ZONE,     										-- 수정일시
    updated_by                  UUID,                                                               -- 수정자 ID

    user_id                     UUID                        NOT NULL,         						-- 사용자 ID
    role_id                     UUID                        NOT NULL,         						-- 역할 ID

    -- 권한 컨텍스트 (통합 시스템의 핵심)
    scope                       VARCHAR(20)                 NOT NULL DEFAULT 'GLOBAL',             	-- 권한 범위 (GLOBAL, TENANT)
	tenant_context              UUID,                                                               -- 권한 적용 테넌트 (NULL=글로벌)

    -- 역할 부여 정보
    granted_at                  TIMESTAMP WITH TIME ZONE,     										-- 역할 부여일시
	granted_by                  UUID,              													-- 역할 부여자 ID

    expires_at                  TIMESTAMP WITH TIME ZONE,                                           -- 역할 만료일 (NULL이면 무기한)

    -- 상태
    status                      VARCHAR(20)                 NOT NULL DEFAULT 'ACTIVE',             	-- 역할 상태

    CONSTRAINT fk_user_roles__user_id 			FOREIGN KEY (user_id) 		REFERENCES idam.users(id) 		ON DELETE CASCADE,
	CONSTRAINT fk_user_roles__role_id 			FOREIGN KEY (role_id) 		REFERENCES idam.roles(id) 		ON DELETE CASCADE,

	CONSTRAINT uk_user_roles__user_role_context 	UNIQUE 	(user_id, role_id, tenant_context),
    CONSTRAINT ck_user_roles__status               	CHECK 	(status IN ('ACTIVE', 'INACTIVE', 'EXPIRED')),
    CONSTRAINT ck_user_roles__scope             	CHECK 	(scope IN ('GLOBAL', 'TENANT'))
);

COMMENT ON TABLE  idam.user_roles                           IS '사용자-역할 매핑 관리';
COMMENT ON COLUMN idam.user_roles.id                        IS '사용자-역할 매핑 고유 식별자';
COMMENT ON COLUMN idam.user_roles.created_at                IS '생성일시';
COMMENT ON COLUMN idam.user_roles.created_by                IS '생성자 ID';
COMMENT ON COLUMN idam.user_roles.updated_at                IS '수정일시';
COMMENT ON COLUMN idam.user_roles.updated_by                IS '수정자 ID';
COMMENT ON COLUMN idam.user_roles.user_id                   IS '사용자 ID';
COMMENT ON COLUMN idam.user_roles.role_id                   IS '역할 ID';
COMMENT ON COLUMN idam.user_roles.tenant_context            IS '권한 적용 테넌트 (NULL=글로벌, 값=특정 테넌트)';
COMMENT ON COLUMN idam.user_roles.scope                     IS '권한 범위 (GLOBAL: 전역, TENANT: 테넌트별)';
COMMENT ON COLUMN idam.user_roles.granted_by                IS '역할 부여자 ID';
COMMENT ON COLUMN idam.user_roles.granted_at                IS '역할 부여일시';
COMMENT ON COLUMN idam.user_roles.expires_at                IS '역할 만료일 (NULL이면 무기한)';
COMMENT ON COLUMN idam.user_roles.status                    IS '역할 상태 (ACTIVE, INACTIVE, EXPIRED)';

-- 사용자 ID 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_user_roles__user_id
    ON idam.user_roles (user_id)
 WHERE status = 'ACTIVE';

-- 역할 ID 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_user_roles__role_id
    ON idam.user_roles (role_id)
 WHERE status = 'ACTIVE';

-- 스코프 타입별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_user_roles__tenant_context
	ON idam.user_roles (tenant_context)
 WHERE tenant_context IS NOT NULL;

CREATE INDEX IF NOT EXISTS ix_user_roles__scope
	ON idam.user_roles (scope)
 WHERE status = 'ACTIVE';

-- 역할 만료일 조회용 인덱스 (만료 처리용)
CREATE INDEX IF NOT EXISTS ix_user_roles__expires_at
    ON idam.user_roles (expires_at)
 WHERE expires_at IS NOT NULL AND status = 'ACTIVE';

-- 역할 부여자 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_user_roles__granted_by
    ON idam.user_roles (granted_by)
 WHERE granted_by IS NOT NULL;

-- 역할 상태별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_user_roles__status
    ON idam.user_roles (status);

-- 복합 조회용 인덱스 (사용자 + 역할)
CREATE INDEX IF NOT EXISTS ix_user_roles__user_role
    ON idam.user_roles (user_id, role_id)
 WHERE status = 'ACTIVE';


-- ========================================
-- API 키 관리
-- ========================================
CREATE TABLE IF NOT EXISTS idam.api_keys
(
    id                          UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),  -- API 키 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT CURRENT_TIMESTAMP,     -- 생성일시
    created_by                  UUID,                                                               -- 생성자 ID
    updated_at                  TIMESTAMP WITH TIME ZONE,     -- 수정일시
    updated_by                  UUID,                                                               -- 수정자 ID

    -- API 키 정보
    key_id                      VARCHAR(100)                NOT NULL,                               -- 공개 키 ID (ak_xxxxxxxxxx)
    key_hash                    VARCHAR(255)                NOT NULL,                               -- 해시된 실제 키
    key_name                    VARCHAR(100)                NOT NULL,                               -- 키 이름/설명

    -- 소유자 정보
    user_id                     UUID                        NOT NULL,    							-- 사용자 ID
	tenant_context              UUID,                                                               -- 테넌트 컨텍스트
    service_account             VARCHAR(100),                                                       -- 서비스 계정명

    -- 권한 및 스코프
    scopes                      TEXT[],                                                             -- API 키 권한 스코프 배열
    allowed_ips                 INET[],                                                             -- 허용 IP 주소 배열

    -- 사용 제한
    rate_limit_per_minute       INTEGER                     DEFAULT 1000,                          	-- 분당 요청 제한
    rate_limit_per_hour         INTEGER                     DEFAULT 10000,                         	-- 시간당 요청 제한
    rate_limit_per_day          INTEGER                     DEFAULT 100000,                        	-- 일당 요청 제한

    -- 상태 및 만료
    status                      VARCHAR(20)                 NOT NULL DEFAULT 'ACTIVE',             	-- API 키 상태
    expires_at                  TIMESTAMP WITH TIME ZONE,                                           -- 만료일시

    -- 사용 통계
    last_used_at                TIMESTAMP WITH TIME ZONE,                                           -- 마지막 사용일시
    last_used_ip                INET,                                                               -- 마지막 사용 IP
    usage_count                 BIGINT                      NOT NULL DEFAULT 0,                     -- 사용 횟수

	CONSTRAINT fk_api_keys__user_id 		FOREIGN KEY (user_id) 		REFERENCES idam.users(id) 		ON DELETE CASCADE,

    CONSTRAINT uk_api_keys__key_id         	UNIQUE (key_id),
    CONSTRAINT ck_api_keys__status         	CHECK (status IN ('ACTIVE', 'INACTIVE', 'REVOKED'))
);

COMMENT ON TABLE  idam.api_keys                             IS 'API 키 관리';
COMMENT ON COLUMN idam.api_keys.id                          IS 'API 키 고유 식별자';
COMMENT ON COLUMN idam.api_keys.created_at                  IS '생성일시';
COMMENT ON COLUMN idam.api_keys.created_by                  IS '생성자 ID';
COMMENT ON COLUMN idam.api_keys.updated_at                  IS '수정일시';
COMMENT ON COLUMN idam.api_keys.updated_by                  IS '수정자 ID';
COMMENT ON COLUMN idam.api_keys.key_id                      IS '공개 키 ID (ak_xxxxxxxxxx)';
COMMENT ON COLUMN idam.api_keys.key_hash                    IS '해시된 실제 키';
COMMENT ON COLUMN idam.api_keys.key_name                    IS '키 이름/설명';
COMMENT ON COLUMN idam.api_keys.user_id                     IS '사용자 ID';
COMMENT ON COLUMN idam.api_keys.tenant_context              IS '테넌트 컨텍스트 (키가 적용되는 테넌트)';
COMMENT ON COLUMN idam.api_keys.service_account             IS '서비스 계정명';
COMMENT ON COLUMN idam.api_keys.scopes                      IS 'API 키 권한 스코프 배열';
COMMENT ON COLUMN idam.api_keys.allowed_ips                 IS '허용 IP 주소 배열';
COMMENT ON COLUMN idam.api_keys.rate_limit_per_minute       IS '분당 요청 제한';
COMMENT ON COLUMN idam.api_keys.rate_limit_per_hour         IS '시간당 요청 제한';
COMMENT ON COLUMN idam.api_keys.rate_limit_per_day          IS '일당 요청 제한';
COMMENT ON COLUMN idam.api_keys.status                      IS 'API 키 상태 (ACTIVE, INACTIVE, REVOKED)';
COMMENT ON COLUMN idam.api_keys.expires_at                  IS '만료일시';
COMMENT ON COLUMN idam.api_keys.last_used_at                IS '마지막 사용일시';
COMMENT ON COLUMN idam.api_keys.last_used_ip                IS '마지막 사용 IP';
COMMENT ON COLUMN idam.api_keys.usage_count                 IS '사용 횟수';

-- 키 ID 조회용 인덱스 (API 인증용)
CREATE INDEX IF NOT EXISTS ix_api_keys__key_id
    ON idam.api_keys (key_id)
 WHERE status = 'ACTIVE';

-- 사용자 ID 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_api_keys__user_id
    ON idam.api_keys (user_id)
 WHERE status = 'ACTIVE' AND user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS ix_api_keys__tenant_context
	ON idam.api_keys (tenant_context)
 WHERE tenant_context IS NOT NULL;

-- 서비스 계정 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_api_keys__service_account
    ON idam.api_keys (service_account)
 WHERE status = 'ACTIVE' AND service_account IS NOT NULL;

-- API 키 상태별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_api_keys__status
    ON idam.api_keys (status);

-- 만료일시 조회용 인덱스 (만료 처리용)
CREATE INDEX IF NOT EXISTS ix_api_keys__expires_at
    ON idam.api_keys (expires_at)
 WHERE expires_at IS NOT NULL AND status = 'ACTIVE';

-- 마지막 사용일시 조회용 인덱스 (비활성 키 식별용)
CREATE INDEX IF NOT EXISTS ix_api_keys__last_used_at
    ON idam.api_keys (last_used_at)
 WHERE status = 'ACTIVE';

-- 사용 통계 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_api_keys__usage_count
    ON idam.api_keys (usage_count DESC)
 WHERE status = 'ACTIVE';


-- ========================================
-- 세션 관리
-- ========================================
CREATE TABLE IF NOT EXISTS idam.sessions
(
    id                          UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),  -- 세션 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT CURRENT_TIMESTAMP,     -- 생성일시
    created_by                  UUID,                                                               -- 생성자 ID
    updated_at                  TIMESTAMP WITH TIME ZONE,     										-- 수정일시
    updated_by                  UUID,                                                               -- 수정자 ID

    -- 세션 정보
    session_id                  VARCHAR(255)                NOT NULL,                               -- 세션 토큰 해시
    user_id                     UUID                        NOT NULL,    							-- 사용자 ID

	-- 세션 컨텍스트 (통합 시스템)
    tenant_context              UUID,                                                               -- 현재 세션의 테넌트 컨텍스트
    session_type                VARCHAR(20)                 NOT NULL DEFAULT 'WEB',                	-- 세션 타입 (WEB, API, MOBILE)

    -- 세션 메타데이터
    fingerprint          		VARCHAR(255),                                                       -- 디바이스 핑거프린트
    user_agent                  TEXT,                                                               -- 사용자 에이전트
    ip_address                  INET                        NOT NULL,                               -- IP 주소
    country_code                CHAR(2),                                                            -- 국가 코드
    city                        VARCHAR(100),                                                       -- 도시명

    -- 세션 상태
    status                      VARCHAR(20)                 NOT NULL DEFAULT 'ACTIVE',             	-- 세션 상태
    expires_at                  TIMESTAMP WITH TIME ZONE    NOT NULL,                               -- 만료일시
    last_activity_at            TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT CURRENT_TIMESTAMP,     -- 마지막 활동일시

    -- MFA 정보
    mfa_verified                BOOLEAN                     NOT NULL DEFAULT FALSE,                 -- MFA 인증 여부
    mfa_verified_at             TIMESTAMP WITH TIME ZONE,                                           -- MFA 인증일시

	CONSTRAINT fk_sessions__user_id 			FOREIGN KEY (user_id) 		REFERENCES idam.users(id) 		ON DELETE CASCADE,

    CONSTRAINT uk_sessions__session_id         	UNIQUE (session_id),
    CONSTRAINT ck_sessions__status             	CHECK (status IN ('ACTIVE', 'EXPIRED', 'REVOKED')),
	CONSTRAINT ck_sessions__session_type        CHECK (session_type IN ('WEB', 'API', 'MOBILE'))
);

COMMENT ON TABLE  idam.sessions                             IS '사용자 세션 관리';
COMMENT ON COLUMN idam.sessions.id                          IS '세션 고유 식별자';
COMMENT ON COLUMN idam.sessions.created_at                  IS '생성일시';
COMMENT ON COLUMN idam.sessions.created_by                  IS '생성자 ID';
COMMENT ON COLUMN idam.sessions.updated_at                  IS '수정일시';
COMMENT ON COLUMN idam.sessions.updated_by                  IS '수정자 ID';
COMMENT ON COLUMN idam.sessions.session_id                  IS '세션 토큰 해시';
COMMENT ON COLUMN idam.sessions.user_id                     IS '사용자 ID';
COMMENT ON COLUMN idam.sessions.tenant_context              IS '현재 세션의 테넌트 컨텍스트';
COMMENT ON COLUMN idam.sessions.session_type                IS '세션 타입 (WEB, API, MOBILE)';
COMMENT ON COLUMN idam.sessions.fingerprint          		IS '디바이스 핑거프린트';
COMMENT ON COLUMN idam.sessions.user_agent                  IS '사용자 에이전트';
COMMENT ON COLUMN idam.sessions.ip_address                  IS 'IP 주소';
COMMENT ON COLUMN idam.sessions.country_code                IS '국가 코드';
COMMENT ON COLUMN idam.sessions.city                        IS '도시명';
COMMENT ON COLUMN idam.sessions.status                      IS '세션 상태 (ACTIVE, EXPIRED, REVOKED)';
COMMENT ON COLUMN idam.sessions.expires_at                  IS '만료일시';
COMMENT ON COLUMN idam.sessions.last_activity_at            IS '마지막 활동일시';
COMMENT ON COLUMN idam.sessions.mfa_verified                IS 'MFA 인증 여부';
COMMENT ON COLUMN idam.sessions.mfa_verified_at             IS 'MFA 인증일시';

-- 세션 ID 조회용 인덱스 (세션 인증용)
CREATE INDEX IF NOT EXISTS ix_sessions__session_id
    ON idam.sessions (session_id)
 WHERE status = 'ACTIVE';

-- 사용자 ID 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_sessions__user_id
    ON idam.sessions (user_id)
 WHERE status = 'ACTIVE';

CREATE INDEX IF NOT EXISTS ix_sessions__tenant_context
	ON idam.sessions (tenant_context)
 WHERE tenant_context IS NOT NULL;

-- 세션 상태별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_sessions__status
    ON idam.sessions (status);

-- 만료일시 조회용 인덱스 (만료 세션 정리용)
CREATE INDEX IF NOT EXISTS ix_sessions__expires_at
    ON idam.sessions (expires_at)
 WHERE status = 'ACTIVE';

-- 마지막 활동일시 조회용 인덱스 (비활성 세션 식별용)
CREATE INDEX IF NOT EXISTS ix_sessions__last_activity_at
    ON idam.sessions (last_activity_at)
 WHERE status = 'ACTIVE';

-- IP 주소 조회용 인덱스 (보안 모니터링용)
CREATE INDEX IF NOT EXISTS ix_sessions__ip_address
    ON idam.sessions (ip_address)
 WHERE status = 'ACTIVE';

-- 디바이스 핑거프린트 조회용 인덱스 (디바이스 추적용)
CREATE INDEX IF NOT EXISTS ix_sessions__fingerprint
    ON idam.sessions (fingerprint)
 WHERE fingerprint IS NOT NULL AND status = 'ACTIVE';

-- MFA 인증 여부 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_sessions__mfa_verified
    ON idam.sessions (mfa_verified)
 WHERE status = 'ACTIVE';


-- ========================================
-- 로그인 이력 (보안 감사용)
-- ========================================
CREATE TABLE IF NOT EXISTS idam.login_logs
(
    id                          UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),  -- 로그인 이력 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT CURRENT_TIMESTAMP,     -- 생성일시
    created_by                  UUID,                                                               -- 생성자 ID
    updated_at                  TIMESTAMP WITH TIME ZONE,     										-- 수정일시
    updated_by                  UUID,                                                               -- 수정자 ID

    user_id                     UUID,                                                               -- 사용자 ID (존재하지 않는 사용자의 경우 NULL)
	user_type                   VARCHAR(20),                                                        -- 사용자 타입 (로그 보존용)
    tenant_context              UUID,                                                               -- 로그인 시 테넌트 컨텍스트

	username                    VARCHAR(100),                                                       -- 사용자명 (삭제된 사용자 이력 보존용)

    -- 로그인 시도 정보
    attempt_type                VARCHAR(20)                 NOT NULL,                               -- 시도 타입 (LOGIN, LOGOUT, FAILED_LOGIN, LOCKED)
    success                     BOOLEAN                     NOT NULL,                               -- 성공 여부
    failure_reason              VARCHAR(100),                                                       -- 실패 사유 (INVALID_PASSWORD, ACCOUNT_LOCKED, MFA_FAILED)

    -- 세션 정보
    session_id                  VARCHAR(255),                                                       -- 세션 ID
    ip_address                  INET                        NOT NULL,                               -- IP 주소
    user_agent                  TEXT,                                                               -- 사용자 에이전트
    country_code                CHAR(2),                                                            -- 국가 코드
    city                        VARCHAR(100),                                                       -- 도시명

    -- MFA 정보
    mfa_used                    BOOLEAN                     NOT NULL DEFAULT FALSE,                 -- MFA 사용 여부
    mfa_method                  VARCHAR(50),                                                        -- MFA 방법 (TOTP, SMS, EMAIL)

    CONSTRAINT fk_login_logs__user_id 			FOREIGN KEY (user_id) 		REFERENCES idam.users(id) 		ON DELETE SET NULL,

	CONSTRAINT ck_idam_login_logs__attempt_type CHECK (
        attempt_type IN ('LOGIN', 'LOGOUT', 'FAILED_LOGIN', 'LOCKED', 'PASSWORD_RESET')
    ),
	CONSTRAINT ck_login_logs__user_type         CHECK (user_type IN ('MASTER', 'TENANT', 'SYSTEM'))
);

COMMENT ON TABLE idam.login_logs                         IS '로그인 이력 관리 (보안 감사용)';
COMMENT ON COLUMN idam.login_logs.id                     IS '로그인 이력 고유 식별자';
COMMENT ON COLUMN idam.login_logs.created_at             IS '생성일시';
COMMENT ON COLUMN idam.login_logs.created_by             IS '생성자 ID';
COMMENT ON COLUMN idam.login_logs.updated_at             IS '수정일시';
COMMENT ON COLUMN idam.login_logs.updated_by             IS '수정자 ID';
COMMENT ON COLUMN idam.login_logs.user_id                IS '사용자 ID';
COMMENT ON COLUMN idam.login_logs.username               IS '사용자명 (삭제된 사용자 이력 보존용)';
COMMENT ON COLUMN idam.login_logs.user_type              IS '사용자 타입 (로그 분석용)';
COMMENT ON COLUMN idam.login_logs.tenant_context         IS '로그인 시 테넌트 컨텍스트';
COMMENT ON COLUMN idam.login_logs.attempt_type           IS '시도 타입 (LOGIN, LOGOUT, FAILED_LOGIN, LOCKED, PASSWORD_RESET)';
COMMENT ON COLUMN idam.login_logs.success                IS '성공 여부';
COMMENT ON COLUMN idam.login_logs.failure_reason         IS '실패 사유 (INVALID_PASSWORD, ACCOUNT_LOCKED, MFA_FAILED)';
COMMENT ON COLUMN idam.login_logs.session_id             IS '세션 ID';
COMMENT ON COLUMN idam.login_logs.ip_address             IS 'IP 주소';
COMMENT ON COLUMN idam.login_logs.user_agent             IS '사용자 에이전트';
COMMENT ON COLUMN idam.login_logs.country_code           IS '국가 코드';
COMMENT ON COLUMN idam.login_logs.city                   IS '도시명';
COMMENT ON COLUMN idam.login_logs.mfa_used               IS 'MFA 사용 여부';
COMMENT ON COLUMN idam.login_logs.mfa_method             IS 'MFA 방법 (TOTP, SMS, EMAIL)';

-- 사용자 ID 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_login_logs__user_id
    ON idam.login_logs (user_id)
 WHERE user_id IS NOT NULL;

-- 생성일시 조회용 인덱스 (시간 순 조회)
CREATE INDEX IF NOT EXISTS ix_login_logs__created_at
    ON idam.login_logs (created_at DESC);

CREATE INDEX IF NOT EXISTS ix_login_logs__user_type
	ON idam.login_logs (user_type);

CREATE INDEX IF NOT EXISTS ix_login_logs__tenant_context
	ON idam.login_logs (tenant_context)
 WHERE tenant_context IS NOT NULL;

-- 시도 타입별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_login_logs__attempt_type
    ON idam.login_logs (attempt_type);

-- 성공 여부별 조회용 인덱스 (실패 로그인 추적용)
CREATE INDEX IF NOT EXISTS ix_login_logs__success
    ON idam.login_logs (success, created_at DESC)
 WHERE success = FALSE;

-- IP 주소 조회용 인덱스 (보안 모니터링용)
CREATE INDEX IF NOT EXISTS ix_login_logs__ip_address
    ON idam.login_logs (ip_address, created_at DESC);

-- 사용자명 조회용 인덱스 (삭제된 사용자 추적용)
CREATE INDEX IF NOT EXISTS ix_login_logs__username
    ON idam.login_logs (username)
 WHERE username IS NOT NULL;

-- 실패 사유별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_login_logs__failure_reason
    ON idam.login_logs (failure_reason, created_at DESC)
 WHERE failure_reason IS NOT NULL;

-- MFA 사용 현황 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_login_logs__mfa_used
    ON idam.login_logs (mfa_used, created_at DESC)
 WHERE mfa_used = TRUE;

-- 복합 조회용 인덱스 (사용자 + 시간)
CREATE INDEX IF NOT EXISTS ix_login_logs__user_created
    ON idam.login_logs (user_id, created_at DESC)
 WHERE user_id IS NOT NULL;
