-- ============================================================================
-- 9. 시스템 설정 (Configuration Management) -> cnfg
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS cnfg;

COMMENT ON SCHEMA cnfg
IS 'CNFG: 시스템 설정/플래그 스키마: 런타임 설정과 기능 토글(테넌트 오버라이드 포함).';

-- ============================================================================
-- 시스템 구성 관리
-- ============================================================================
CREATE TABLE IF NOT EXISTS cnfg.configurations
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),    	-- 시스템 구성 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 구성 설정 생성 일시
    created_by                  UUID,                                                              	-- 구성 설정 생성자 UUID (관리자 또는 시스템)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 구성 설정 수정 일시
    updated_by                  UUID,                                                              	-- 구성 설정 수정자 UUID

	-- 설정 기본 정보
    config_category             VARCHAR(50)              NOT NULL,                                 	-- 설정 카테고리 (SYSTEM/SECURITY/BILLING/NOTIFICATION/INTEGRATION)
    config_code                 VARCHAR(200)             NOT NULL,                                 	-- 설정 코드 (고유 식별자)
    config_value                TEXT,                                                              	-- 현재 설정 값
    config_type                 VARCHAR(20)              NOT NULL DEFAULT 'STRING',               	-- 설정값 데이터 타입 (STRING/INTEGER/BOOLEAN/JSON/ENCRYPTED)

	-- 설정 설명 및 기본값
    description                 TEXT,                                                              	-- 설정 설명 (용도, 영향, 주의사항)
    default_value               TEXT,                                                              	-- 기본값

	-- 설정 제약 조건
    required                 	BOOLEAN                  DEFAULT FALSE,                           	-- 필수 설정 여부
    validation_rules            JSONB                    DEFAULT '{}',                            	-- 유효성 검사 규칙 (JSON 형태)

	-- 환경별 구성
    environment                 VARCHAR(20)              NOT NULL DEFAULT 'PRODUCTION',           	-- 적용 환경 (DEVELOPMENT/STAGING/PRODUCTION)
    applies_to_all 				BOOLEAN                  DEFAULT TRUE,                            	-- 모든 환경 적용 여부

	-- 변경 이력 추적
    previous_value              TEXT,                                                              	-- 이전 설정 값 (변경 추적용)
    changed_by                  VARCHAR(100),                                                      	-- 변경자 (관리자 또는 시스템)
	change_reason               TEXT,                                                              	-- 변경 사유

	-- 설정 적용 상태
    start_time             	 	TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,                 -- 설정 적용 시작 시간
    close_time                	TIMESTAMP WITH TIME ZONE,                                          	-- 설정 적용 종료 시간 (NULL: 무기한)

	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- 구성 상태 (ACTIVE/INACTIVE/DEPRECATED)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT uk_configurations__category_key_env 		UNIQUE (config_category, config_code, environment),
    CONSTRAINT ck_configurations__config_category 		CHECK (config_category IN ('SYSTEM', 'SECURITY', 'BILLING', 'NOTIFICATION', 'INTEGRATION', 'PERFORMANCE', 'MONITORING')),
    CONSTRAINT ck_configurations__config_type 			CHECK (config_type IN ('STRING', 'INTEGER', 'BOOLEAN', 'JSON', 'ENCRYPTED', 'DECIMAL')),
    CONSTRAINT ck_configurations__environment 			CHECK (environment IN ('DEVELOPMENT', 'STAGING', 'PRODUCTION', 'ALL')),
    CONSTRAINT ck_configurations__status 				CHECK (status IN ('ACTIVE', 'INACTIVE', 'DEPRECATED')),
    CONSTRAINT ck_configurations__effective_period 		CHECK (close_time IS NULL OR close_time >= start_time),
    CONSTRAINT ck_configurations__config_code_format	CHECK (config_code ~ '^[a-zA-Z0-9._-]+$')
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  cnfg.configurations					IS '시스템 구성 관리 - 플랫폼 전역 설정과 환경별 구성을 중앙화하여 관리하고 변경 이력을 추적';
COMMENT ON COLUMN cnfg.configurations.id 				IS '시스템 구성 고유 식별자 - UUID 형태의 기본키, 각 설정 항목을 구분하는 고유값';
COMMENT ON COLUMN cnfg.configurations.created_at 		IS '구성 설정 생성 일시 - 설정이 시스템에 등록된 시점의 타임스탬프';
COMMENT ON COLUMN cnfg.configurations.created_by 		IS '구성 설정 생성자 UUID - 설정을 생성한 관리자 또는 시스템의 식별자';
COMMENT ON COLUMN cnfg.configurations.updated_at 		IS '구성 설정 수정 일시 - 설정이 최종 변경된 시점의 타임스탬프';
COMMENT ON COLUMN cnfg.configurations.updated_by 		IS '구성 설정 수정자 UUID - 설정을 최종 수정한 관리자 또는 시스템의 식별자';
COMMENT ON COLUMN cnfg.configurations.config_category 	IS '설정 카테고리 - SYSTEM(시스템), SECURITY(보안), BILLING(과금), NOTIFICATION(알림), INTEGRATION(통합), PERFORMANCE(성능), MONITORING(모니터링)';
COMMENT ON COLUMN cnfg.configurations.config_code 		IS '설정 키 - 설정 항목을 식별하는 고유한 키 (예: smtp.host, jwt.expiry_hours, max_concurrent_users)';
COMMENT ON COLUMN cnfg.configurations.config_value 		IS '현재 설정 값 - 실제 적용되고 있는 설정값 (암호화된 값 포함)';
COMMENT ON COLUMN cnfg.configurations.config_type 		IS '설정값 데이터 타입 - STRING(문자열), INTEGER(정수), BOOLEAN(불린), JSON(JSON객체), ENCRYPTED(암호화된값), DECIMAL(소수)';
COMMENT ON COLUMN cnfg.configurations.description 		IS '설정 설명 - 설정의 용도, 시스템에 미치는 영향, 변경 시 주의사항 등의 상세 설명';
COMMENT ON COLUMN cnfg.configurations.default_value 	IS '기본값 - 설정이 정의되지 않았을 때 사용되는 기본값';
COMMENT ON COLUMN cnfg.configurations.required 			IS '필수 설정 여부 - TRUE(필수설정, 값이 반드시 존재해야 함), FALSE(선택설정)';
COMMENT ON COLUMN cnfg.configurations.validation_rules 	IS '유효성 검사 규칙 - 설정값의 형식, 범위, 패턴 등을 검증하는 규칙 (JSON 형태)';
COMMENT ON COLUMN cnfg.configurations.environment 		IS '적용 환경 - DEVELOPMENT(개발), STAGING(스테이징), PRODUCTION(운영), ALL(모든환경)';
COMMENT ON COLUMN cnfg.configurations.applies_to_all 	IS '모든 환경 적용 여부 - TRUE(모든 환경에 동일 적용), FALSE(환경별 개별 설정)';
COMMENT ON COLUMN cnfg.configurations.previous_value 	IS '이전 설정 값 - 변경 전의 설정값 (변경 이력 추적 및 롤백용)';
COMMENT ON COLUMN cnfg.configurations.changed_by 		IS '변경자 - 설정을 변경한 관리자나 시스템의 이름 또는 식별자';
COMMENT ON COLUMN cnfg.configurations.change_reason 	IS '변경 사유 - 설정 변경의 목적이나 배경, 관련 이슈 번호 등';
COMMENT ON COLUMN cnfg.configurations.start_time 		IS '설정 적용 시작 시간 - 이 설정이 실제로 효력을 발휘하기 시작하는 시점';
COMMENT ON COLUMN cnfg.configurations.close_time 		IS '설정 적용 종료 시간 - 이 설정이 효력을 잃는 시점 (NULL인 경우 무기한)';
COMMENT ON COLUMN cnfg.configurations.status 			IS '구성 상태 - ACTIVE(활성), INACTIVE(비활성), DEPRECATED(사용중단예정) 설정의 생명주기 상태';
COMMENT ON COLUMN cnfg.configurations.deleted 			IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 카테고리-키-환경 조합 고유성 보장
CREATE UNIQUE INDEX IF NOT EXISTS ux_configurations
	ON cnfg.configurations (config_category, config_code, environment)
 WHERE deleted = FALSE;

-- 카테고리별 설정 조회 최적화
CREATE INDEX IF NOT EXISTS ix_configurations__config_category
	ON cnfg.configurations (config_category, created_at DESC)
 WHERE deleted = FALSE;

-- 설정 키별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_configurations__config_code
	ON cnfg.configurations (config_code, environment)
 WHERE deleted = FALSE;

-- 환경별 설정 조회 최적화
CREATE INDEX IF NOT EXISTS ix_configurations__environment
	ON cnfg.configurations (environment, config_category)
 WHERE deleted = FALSE;

-- 활성 설정 조회 최적화
CREATE INDEX IF NOT EXISTS ix_configurations__active
	ON cnfg.configurations (status, config_category, config_code)
 WHERE deleted = FALSE AND status = 'ACTIVE';

-- 유효 기간 기준 설정 조회 최적화
CREATE INDEX IF NOT EXISTS ix_configurations__effective_period
	ON cnfg.configurations (start_time, close_time, status)
 WHERE deleted = FALSE;

-- 변경자별 설정 이력 조회 최적화
CREATE INDEX IF NOT EXISTS ix_configurations__changed_by
	ON cnfg.configurations (changed_by, updated_at DESC)
 WHERE changed_by IS NOT NULL AND deleted = FALSE;

-- 설정 타입별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_configurations__config_type
	ON cnfg.configurations (config_type, config_category)
 WHERE deleted = FALSE;

-- 필수 설정 조회 최적화
CREATE INDEX IF NOT EXISTS ix_configurations__required_settings
	ON cnfg.configurations (required, config_category, environment)
 WHERE required = TRUE AND deleted = FALSE;

-- 전역 설정 조회 최적화
CREATE INDEX IF NOT EXISTS ix_configurations__all_environments
	ON cnfg.configurations (applies_to_all, config_code)
 WHERE applies_to_all = TRUE AND deleted = FALSE;

-- 유효성 규칙 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_configurations__validation_rules
	ON cnfg.configurations USING GIN (validation_rules)
 WHERE deleted = FALSE;

-- 최근 변경 설정 조회 최적화
--CREATE INDEX IF NOT EXISTS ix_configurations__recent_changes
--	ON cnfg.configurations (updated_at DESC, changed_by)
-- WHERE updated_at > (NOW() - INTERVAL '30 days') AND deleted = FALSE;

-- 상태별 설정 조회 최적화
CREATE INDEX IF NOT EXISTS ix_configurations__status
	ON cnfg.configurations (status, config_category, created_at DESC)
 WHERE deleted = FALSE;

-- 생성 시간 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_configurations__created_at
	ON cnfg.configurations (created_at DESC);

-- ============================================================================
-- 기능 플래그 관리 테이블
-- ============================================================================
CREATE TABLE IF NOT EXISTS cnfg.feature_flags
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 기능 플래그 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 기능 플래그 생성 일시
    created_by                  UUID,                                                               -- 기능 플래그 생성자 UUID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                           -- 기능 플래그 수정 일시
    updated_by                  UUID,                                                               -- 기능 플래그 수정자 UUID

    -- 기능 기본 정보
    flag_code                   VARCHAR(100)             NOT NULL,                           		-- 기능 플래그 코드 (애플리케이션에서 사용)
    flag_name                   VARCHAR(200)             NOT NULL,                                  -- 기능 플래그 표시명
    description                 TEXT,                                                               -- 기능 상세 설명

    -- 플래그 활성화 설정
    enabled                 	BOOLEAN                  NOT NULL DEFAULT FALSE,                    -- 기능 전체 활성화 여부
    rollout_rate                INTEGER                  DEFAULT 0,                                 -- 점진적 배포 비율 (0-100%)

    -- 대상 환경 및 사용자 설정
    target_environment          VARCHAR(20)              DEFAULT 'PRODUCTION',                      -- 대상 환경 (DEVELOPMENT/STAGING/PRODUCTION/ALL)
    target_user_groups          TEXT[],                                                             -- 대상 사용자 그룹 배열
    target_tenant_types         TEXT[],                                                             -- 대상 테넌트 유형 배열
    excluded_tenants            UUID[],                                                             -- 제외할 테넌트 ID 목록

    -- 조건부 활성화 규칙
    activation_conditions       JSONB                    DEFAULT '{}',                              -- 기능 활성화 조건 (JSON 형태)
    deactivation_conditions     JSONB                    DEFAULT '{}',                              -- 기능 비활성화 조건 (JSON 형태)

    -- 스케줄링 정보
    scheduled_enable_at         TIMESTAMP WITH TIME ZONE,                                           -- 예약 활성화 시각
    scheduled_disable_at        TIMESTAMP WITH TIME ZONE,                                           -- 예약 비활성화 시각

    -- 사용량 및 성능 메트릭
    usage_count                 INTEGER                  DEFAULT 0,                                 -- 기능 호출 횟수
    error_count                 INTEGER                  DEFAULT 0,                                 -- 기능 사용 중 오류 발생 횟수
    last_used_at                TIMESTAMP WITH TIME ZONE,                                           -- 마지막 기능 사용 시각

    -- 관리 및 소유권 정보
    owner_team                  VARCHAR(100),                                                       -- 기능 소유 팀
    contact_email               VARCHAR(255),                                                       -- 담당자 연락처 이메일

    -- 논리적 삭제 플래그
    deleted                     BOOLEAN                  NOT NULL DEFAULT FALSE,                    -- 논리적 삭제 플래그

    -- 제약조건
	CONSTRAINT uk_feature_flags__flag_code 				UNIQUE (flag_code),

    CONSTRAINT ck_feature_flags__rollout_rate           CHECK (rollout_rate >= 0 AND rollout_rate <= 100),
    CONSTRAINT ck_feature_flags__target_environment     CHECK (target_environment IN ('DEVELOPMENT', 'STAGING', 'PRODUCTION', 'ALL')),
    CONSTRAINT ck_feature_flags__usage_count            CHECK (usage_count >= 0),
    CONSTRAINT ck_feature_flags__error_count            CHECK (error_count >= 0),
    CONSTRAINT ck_feature_flags__flag_code_format       CHECK (flag_code ~ '^[a-zA-Z0-9._-]+$'),
    CONSTRAINT ck_feature_flags__schedule_logic         CHECK (scheduled_disable_at IS NULL OR scheduled_enable_at IS NULL OR scheduled_disable_at > scheduled_enable_at),
    CONSTRAINT ck_feature_flags__contact_email_format   CHECK (contact_email IS NULL OR contact_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- 컬럼별 코멘트 추가
COMMENT ON TABLE  cnfg.feature_flags 							IS '기능 플래그 관리 테이블 - 애플리케이션 기능의 동적 활성화/비활성화 관리';
COMMENT ON COLUMN cnfg.feature_flags.id 						IS '기능 플래그 고유 식별자 (UUID)';
COMMENT ON COLUMN cnfg.feature_flags.created_at 				IS '기능 플래그 생성 일시';
COMMENT ON COLUMN cnfg.feature_flags.created_by 				IS '기능 플래그 생성자 UUID (개발팀 또는 제품팀)';
COMMENT ON COLUMN cnfg.feature_flags.updated_at 				IS '기능 플래그 수정 일시';
COMMENT ON COLUMN cnfg.feature_flags.updated_by 				IS '기능 플래그 수정자 UUID';
COMMENT ON COLUMN cnfg.feature_flags.flag_code 					IS '기능 플래그 코드 - 애플리케이션 코드에서 사용하는 고유 식별자';
COMMENT ON COLUMN cnfg.feature_flags.flag_name 					IS '기능 플래그 표시명 - 관리자 화면에서 보여지는 사용자 친화적 이름';
COMMENT ON COLUMN cnfg.feature_flags.description 				IS '기능 상세 설명 - 기능의 목적과 영향 범위 설명';
COMMENT ON COLUMN cnfg.feature_flags.enabled 					IS '기능 전체 활성화 여부 - 마스터 스위치 역할';
COMMENT ON COLUMN cnfg.feature_flags.rollout_rate 				IS '점진적 배포 비율 (0-100%) - 사용자 대상 점진적 기능 배포';
COMMENT ON COLUMN cnfg.feature_flags.target_environment 		IS '대상 환경 - 기능이 적용될 환경 (DEVELOPMENT/STAGING/PRODUCTION/ALL)';
COMMENT ON COLUMN cnfg.feature_flags.target_user_groups 		IS '대상 사용자 그룹 배열 - 기능이 적용될 사용자 그룹 목록';
COMMENT ON COLUMN cnfg.feature_flags.target_tenant_types 		IS '대상 테넌트 유형 배열 - 기능이 적용될 테넌트 유형 목록 (TRIAL/STANDARD/PREMIUM 등)';
COMMENT ON COLUMN cnfg.feature_flags.excluded_tenants 			IS '제외할 테넌트 ID 목록 - 기능 적용에서 제외할 특정 테넌트들';
COMMENT ON COLUMN cnfg.feature_flags.activation_conditions 		IS '기능 활성화 조건 - JSON 형태의 복잡한 활성화 조건';
COMMENT ON COLUMN cnfg.feature_flags.deactivation_conditions 	IS '기능 비활성화 조건 - JSON 형태의 복잡한 비활성화 조건';
COMMENT ON COLUMN cnfg.feature_flags.scheduled_enable_at 		IS '예약 활성화 시각 - 자동으로 기능을 활성화할 예정 시간';
COMMENT ON COLUMN cnfg.feature_flags.scheduled_disable_at 		IS '예약 비활성화 시각 - 자동으로 기능을 비활성화할 예정 시간';
COMMENT ON COLUMN cnfg.feature_flags.usage_count 				IS '기능 호출 횟수 - 기능이 실제로 사용된 총 횟수';
COMMENT ON COLUMN cnfg.feature_flags.error_count 				IS '기능 사용 중 오류 발생 횟수 - 기능 사용 시 발생한 오류 통계';
COMMENT ON COLUMN cnfg.feature_flags.last_used_at 				IS '마지막 기능 사용 시각 - 가장 최근 기능이 호출된 시간';
COMMENT ON COLUMN cnfg.feature_flags.owner_team 				IS '기능 소유 팀 - 기능을 담당하는 개발팀 (Backend/Frontend/Data 등)';
COMMENT ON COLUMN cnfg.feature_flags.contact_email 				IS '담당자 연락처 이메일 - 기능 관련 문의 시 연락할 담당자';
COMMENT ON COLUMN cnfg.feature_flags.deleted 					IS '논리적 삭제 플래그 - 실제 삭제 대신 사용하는 소프트 딜리트';

-- 인덱스 생성
-- 기본 조회용 인덱스 (논리적 삭제되지 않은 활성 플래그)
CREATE INDEX IF NOT EXISTS ix_feature_flags__active_lookup
    ON cnfg.feature_flags (flag_code, enabled)
 WHERE deleted = FALSE;

-- 환경별 조회용 인덱스 (특정 환경에서 활성화된 플래그)
CREATE INDEX IF NOT EXISTS ix_feature_flags__environment_enabled
    ON cnfg.feature_flags (target_environment, enabled, rollout_rate)
 WHERE deleted = FALSE;

-- 스케줄링 관리용 인덱스 (예약된 활성화/비활성화 작업)
CREATE INDEX IF NOT EXISTS ix_feature_flags__tasks
    ON cnfg.feature_flags (scheduled_enable_at, scheduled_disable_at)
 WHERE (scheduled_enable_at IS NOT NULL OR scheduled_disable_at IS NOT NULL)
   AND deleted = FALSE;

-- 사용량 분석용 인덱스 (최근 사용된 플래그들)
CREATE INDEX IF NOT EXISTS ix_feature_flags__usage_analysis
    ON cnfg.feature_flags (last_used_at DESC, usage_count DESC)
 WHERE deleted = FALSE;

-- 팀별 관리용 인덱스 (팀별 플래그 조회)
CREATE INDEX IF NOT EXISTS ix_feature_flags__team_management
    ON cnfg.feature_flags (owner_team, created_at DESC)
 WHERE deleted = FALSE;

-- 생성일자 기준 조회용 인덱스 (최근 생성된 플래그들)
CREATE INDEX IF NOT EXISTS ix_feature_flags__created_at
    ON cnfg.feature_flags (created_at DESC)
 WHERE deleted = FALSE;

-- GIN 인덱스 (사용자 그룹 배열 검색용)
CREATE INDEX IF NOT EXISTS ix_feature_flags__target_groups_gin
    ON cnfg.feature_flags USING GIN (target_user_groups)
 WHERE deleted = FALSE;

-- GIN 인덱스 (테넌트 유형 배열 검색용)
CREATE INDEX IF NOT EXISTS ix_feature_flags__tenant_types_gin
    ON cnfg.feature_flags USING GIN (target_tenant_types)
 WHERE deleted = FALSE;

-- GIN 인덱스 (활성화 조건 JSON 검색용)
CREATE INDEX IF NOT EXISTS ix_feature_flags__activation_conditions_gin
    ON cnfg.feature_flags USING GIN (activation_conditions)
 WHERE deleted = FALSE;


-- ============================================================================
-- 테넌트별 기능 오버라이드 테이블
-- ============================================================================
CREATE TABLE IF NOT EXISTS cnfg.tenant_features
(
    -- 기본 식별자 및 감사 필드
    id                  	UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 오버라이드 레코드 고유 식별자
    created_at          	TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 레코드 생성 일시
    created_by          	UUID,                                                               -- 레코드 생성자 UUID
    updated_at          	TIMESTAMP WITH TIME ZONE,                                           -- 레코드 최종 수정 일시
    updated_by          	UUID,                                                               -- 레코드 최종 수정자 UUID

    -- 관계 참조 필드
    tenant_id           	UUID                     NOT NULL,                                  -- 대상 테넌트 ID
    feature_flag_id     	UUID                     NOT NULL,                                  -- 대상 기능 플래그 ID

    -- 오버라이드 설정
    enabled    				BOOLEAN                  NOT NULL,                                  -- 테넌트별 기능 활성화 여부
    reason     				VARCHAR(500),                                                       -- 오버라이드 사유 설명

    -- 유효 기간 설정
    start_time          	TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 오버라이드 유효 시작 일시
    close_time          	TIMESTAMP WITH TIME ZONE,                                           -- 오버라이드 유효 종료 일시

    -- 승인 관리
    approved_by         	UUID,                                                               -- 승인자 UUID
    approved_at         	TIMESTAMP WITH TIME ZONE,                                           -- 승인 일시
    approval_reason     	TEXT,                                                               -- 승인 사유 메모

    -- 논리적 삭제 플래그
    deleted             	BOOLEAN                  NOT NULL DEFAULT FALSE,                    -- 논리적 삭제 플래그

    -- 제약조건
    CONSTRAINT fk_tenant_features__tenant_id		FOREIGN KEY (tenant_id) 		REFERENCES tnnt.tenants(id)			ON DELETE CASCADE,
    CONSTRAINT fk_tenant_features__feature_flag_id	FOREIGN KEY (feature_flag_id) 	REFERENCES cnfg.feature_flags(id)	ON DELETE CASCADE,

    CONSTRAINT uk_tenant_features__tenant_feature	UNIQUE (tenant_id, feature_flag_id),
    CONSTRAINT ck_tenant_features__validity_period	CHECK (close_time IS NULL OR close_time > start_time)
);

-- 컬럼별 코멘트 추가
COMMENT ON TABLE  cnfg.tenant_features 					IS '테넌트별 기능 오버라이드 - 특정 테넌트에 대한 기능 플래그 개별 설정 관리';
COMMENT ON COLUMN cnfg.tenant_features.id 				IS '오버라이드 레코드 고유 식별자 (UUID)';
COMMENT ON COLUMN cnfg.tenant_features.created_at 		IS '레코드 생성 일시';
COMMENT ON COLUMN cnfg.tenant_features.created_by 		IS '레코드 생성자 UUID (관리자 또는 시스템)';
COMMENT ON COLUMN cnfg.tenant_features.updated_at 		IS '레코드 최종 수정 일시';
COMMENT ON COLUMN cnfg.tenant_features.updated_by 		IS '레코드 최종 수정자 UUID';
COMMENT ON COLUMN cnfg.tenant_features.tenant_id 		IS '대상 테넌트 ID - 기능 오버라이드가 적용될 테넌트';
COMMENT ON COLUMN cnfg.tenant_features.feature_flag_id 	IS '대상 기능 플래그 ID - 오버라이드할 기능 플래그';
COMMENT ON COLUMN cnfg.tenant_features.enabled 			IS '테넌트별 기능 활성화 여부 - 전역 설정 대신 사용할 개별 설정';
COMMENT ON COLUMN cnfg.tenant_features.reason 			IS '오버라이드 사유 설명 - 왜 개별 설정이 필요한지에 대한 설명';
COMMENT ON COLUMN cnfg.tenant_features.start_time 		IS '오버라이드 유효 시작 일시 - 개별 설정이 적용되기 시작하는 시간';
COMMENT ON COLUMN cnfg.tenant_features.close_time 		IS '오버라이드 유효 종료 일시 - 개별 설정이 만료되는 시간 (NULL이면 무기한)';
COMMENT ON COLUMN cnfg.tenant_features.approved_by 		IS '승인자 UUID - 오버라이드를 승인한 관리자';
COMMENT ON COLUMN cnfg.tenant_features.approved_at 		IS '승인 일시 - 오버라이드가 승인된 시간';
COMMENT ON COLUMN cnfg.tenant_features.approval_reason 	IS '승인 사유 메모 - 승인자가 남긴 승인 이유';
COMMENT ON COLUMN cnfg.tenant_features.deleted 			IS '논리적 삭제 플래그 - 실제 삭제 대신 사용하는 소프트 딜리트';

-- 인덱스 생성
-- 테넌트별 기능 조회용 인덱스 (가장 빈번한 조회 패턴)
CREATE INDEX IF NOT EXISTS ix_tenant_features__tenant_lookup
	ON cnfg.tenant_features (tenant_id, enabled)
 WHERE deleted = FALSE;  -- 논리적 삭제되지 않은 활성 오버라이드만 대상

-- 기능별 테넌트 조회용 인덱스 (특정 기능을 사용하는 테넌트 조회)
CREATE INDEX IF NOT EXISTS ix_tenant_features__feature_lookup
	ON cnfg.tenant_features (feature_flag_id, enabled)
 WHERE deleted = FALSE;  -- 논리적 삭제되지 않은 활성 오버라이드만 대상

-- 유효 기간 관리용 인덱스 (만료된 오버라이드 정리 작업용)
CREATE INDEX IF NOT EXISTS ix_tenant_features__validity_management
	ON cnfg.tenant_features (close_time, start_time)
 WHERE deleted = FALSE
   AND close_time IS NOT NULL;  -- 종료 시간이 설정된 활성 오버라이드만 대상

-- 승인 관리용 인덱스 (승인 대기 중인 오버라이드 조회)
CREATE INDEX IF NOT EXISTS ix_tenant_features__approval_pending
	ON cnfg.tenant_features (approved_at, created_at DESC)
 WHERE deleted = FALSE;  -- 논리적 삭제되지 않은 레코드만 대상

-- 승인자별 관리용 인덱스 (승인자가 처리한 오버라이드 이력 조회)
CREATE INDEX IF NOT EXISTS ix_tenant_features__approver_history
	ON cnfg.tenant_features (approved_by, approved_at DESC)
 WHERE deleted = FALSE
   AND approved_by IS NOT NULL;  -- 승인 완료된 레코드만 대상

-- 생성일자 기준 조회용 인덱스 (최근 생성된 오버라이드들)
CREATE INDEX IF NOT EXISTS ix_tenant_features__created_at
	ON cnfg.tenant_features (created_at DESC)
 WHERE deleted = FALSE;  -- 논리적 삭제되지 않은 레코드만 대상

-- 현재 유효한 오버라이드 조회용 복합 인덱스
--CREATE INDEX IF NOT EXISTS ix_tenant_features__currently_active
--	ON cnfg.tenant_features (tenant_id, feature_flag_id, enabled)
-- WHERE deleted = FALSE
--   AND start_time <= NOW()
--   AND (close_time IS NULL OR close_time > NOW());  -- 현재 시점에서 유효한 오버라이드만 대상


-- ============================================================================
-- 서비스 할당량 관리
-- ============================================================================
CREATE TABLE IF NOT EXISTS cnfg.service_quotas
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 서비스 할당량 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 할당량 설정 생성 일시
    created_by                  UUID,                                                              	-- 할당량 설정 생성자 UUID (관리자)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 할당량 설정 수정 일시
    updated_by                  UUID,                                                              	-- 할당량 설정 수정자 UUID
    -- 테넌트 연결
    tenant_id                   UUID                     NOT NULL,                                 	-- 할당량 적용 대상 테넌트 ID
    -- 할당량 기본 정보
    quota_type                  VARCHAR(50)              NOT NULL,                                 	-- 할당량 유형 (USERS/STORAGE/API_CALLS/AI_REQUESTS/WORKFLOWS/DOCUMENTS)
    quota_limit                 INTEGER                  NOT NULL,                                 	-- 할당량 한도 (최대 허용량)
    quota_used                  INTEGER                  DEFAULT 0,                               	-- 현재 사용량
    quota_period                VARCHAR(20)              NOT NULL DEFAULT 'MONTHLY',              	-- 할당량 적용 기간 (DAILY/WEEKLY/MONTHLY/YEARLY)
    -- 할당량 적용 기간
    start_date           		DATE                     NOT NULL,                                 	-- 할당량 적용 시작일
    close_date            	 	DATE                     NOT NULL,                                 	-- 할당량 적용 종료일
    -- 알림 임계값 설정
    warning_threshold_rate   	INTEGER                  DEFAULT 80,                              	-- 경고 알림 임계값 (사용률 %)
    critical_threshold_rate  	INTEGER                  DEFAULT 95,                              	-- 위험 알림 임계값 (사용률 %)
    warning_alert_sent          BOOLEAN                  DEFAULT FALSE,                           	-- 경고 알림 발송 여부
    critical_alert_sent         BOOLEAN                  DEFAULT FALSE,                           	-- 위험 알림 발송 여부
    -- 초과 사용 정책
    allow_overage               BOOLEAN                  DEFAULT FALSE,                           	-- 할당량 초과 허용 여부
    overage_unit_charge         NUMERIC(18,4)            DEFAULT 0,                               	-- 초과 사용 시 단위당 추가 요금
    max_overage_rate         	INTEGER                  DEFAULT 0,                               	-- 최대 초과 허용률 (기본 할당량 대비 %)
    -- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- 할당량 상태 (ACTIVE/SUSPENDED/EXPIRED)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT fk_service_quotas__tenant_id 				FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,

    CONSTRAINT ck_service_quotas__quota_type 				CHECK (quota_type IN ('USERS', 'STORAGE', 'API_CALLS', 'AI_REQUESTS', 'WORKFLOWS', 'DOCUMENTS', 'BANDWIDTH')),
    CONSTRAINT ck_service_quotas__quota_period 				CHECK (quota_period IN ('DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY')),
    CONSTRAINT ck_service_quotas__status 					CHECK (status IN ('ACTIVE', 'SUSPENDED', 'EXPIRED')),
    CONSTRAINT ck_service_quotas__quota_limit 				CHECK (quota_limit > 0),
    CONSTRAINT ck_service_quotas__quota_used 				CHECK (quota_used >= 0),
    CONSTRAINT ck_service_quotas__warning_threshold_rate 	CHECK (warning_threshold_rate >= 0 AND warning_threshold_rate <= 100),
    CONSTRAINT ck_service_quotas__critical_threshold_rate 	CHECK (critical_threshold_rate >= 0 AND critical_threshold_rate <= 100),
    CONSTRAINT ck_service_quotas__threshold_order 			CHECK (critical_threshold_rate >= warning_threshold_rate),
    CONSTRAINT ck_service_quotas__overage_unit_charge 		CHECK (overage_unit_charge >= 0),
    CONSTRAINT ck_service_quotas__max_overage_rate 			CHECK (max_overage_rate >= 0 AND max_overage_rate <= 500),
    CONSTRAINT ck_service_quotas__period_dates 				CHECK (close_date >= start_date)
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  cnfg.service_quotas							IS '서비스 할당량 관리 - 테넌트별 리소스 사용 한도 설정, 모니터링, 초과 사용 제어를 통한 공정한 자원 분배';
COMMENT ON COLUMN cnfg.service_quotas.id 						IS '서비스 할당량 고유 식별자 - UUID 형태의 기본키, 각 할당량 설정을 구분하는 고유값';
COMMENT ON COLUMN cnfg.service_quotas.created_at 				IS '할당량 설정 생성 일시 - 할당량이 시스템에 등록된 시점의 타임스탬프';
COMMENT ON COLUMN cnfg.service_quotas.created_by 				IS '할당량 설정 생성자 UUID - 할당량을 설정한 관리자 또는 시스템의 식별자';
COMMENT ON COLUMN cnfg.service_quotas.updated_at 				IS '할당량 설정 수정 일시 - 할당량 정보가 최종 변경된 시점의 타임스탬프';
COMMENT ON COLUMN cnfg.service_quotas.updated_by 				IS '할당량 설정 수정자 UUID - 할당량을 최종 수정한 관리자 또는 시스템의 식별자';
COMMENT ON COLUMN cnfg.service_quotas.tenant_id 				IS '할당량 적용 대상 테넌트 ID - 이 할당량이 적용되는 테넌트의 고유 식별자 (tenants 테이블 참조)';
COMMENT ON COLUMN cnfg.service_quotas.quota_type 				IS '할당량 유형 - USERS(사용자수), STORAGE(스토리지), API_CALLS(API호출), AI_REQUESTS(AI요청), WORKFLOWS(워크플로우), DOCUMENTS(문서수), BANDWIDTH(대역폭)';
COMMENT ON COLUMN cnfg.service_quotas.quota_limit 				IS '할당량 한도 - 해당 기간 동안 허용되는 최대 사용량 (단위는 quota_type에 따라 다름)';
COMMENT ON COLUMN cnfg.service_quotas.quota_used 				IS '현재 사용량 - 현재까지 사용된 리소스의 양 (실시간 또는 주기적 업데이트)';
COMMENT ON COLUMN cnfg.service_quotas.quota_period 				IS '할당량 적용 기간 - DAILY(일별), WEEKLY(주별), MONTHLY(월별), YEARLY(연별) 할당량 초기화 주기';
COMMENT ON COLUMN cnfg.service_quotas.start_date 				IS '할당량 적용 시작일 - 현재 할당량 기간의 시작 날짜';
COMMENT ON COLUMN cnfg.service_quotas.close_date 				IS '할당량 적용 종료일 - 현재 할당량 기간의 종료 날짜 (이후 사용량 초기화)';
COMMENT ON COLUMN cnfg.service_quotas.warning_threshold_rate 	IS '경고 알림 임계값 - 할당량 대비 사용률이 이 비율을 초과하면 경고 알림 발송 (0-100%)';
COMMENT ON COLUMN cnfg.service_quotas.critical_threshold_rate 	IS '위험 알림 임계값 - 할당량 대비 사용률이 이 비율을 초과하면 긴급 알림 발송 (0-100%)';
COMMENT ON COLUMN cnfg.service_quotas.warning_alert_sent 		IS '경고 알림 발송 여부 - TRUE(경고 알림 발송됨), FALSE(미발송), 중복 알림 방지용';
COMMENT ON COLUMN cnfg.service_quotas.critical_alert_sent 		IS '위험 알림 발송 여부 - TRUE(위험 알림 발송됨), FALSE(미발송), 중복 알림 방지용';
COMMENT ON COLUMN cnfg.service_quotas.allow_overage 			IS '할당량 초과 허용 여부 - TRUE(초과 사용 허용), FALSE(할당량 도달 시 차단), 서비스 정책에 따른 설정';
COMMENT ON COLUMN cnfg.service_quotas.overage_unit_charge 		IS '초과 사용 시 단위당 추가 요금 - 할당량 초과 시 추가로 부과되는 단위별 요금 (통화: 테넌트 기본 통화)';
COMMENT ON COLUMN cnfg.service_quotas.max_overage_rate 			IS '최대 초과 허용률 - 기본 할당량 대비 최대 몇 퍼센트까지 초과 사용을 허용할지 설정 (0-500%)';
COMMENT ON COLUMN cnfg.service_quotas.status 					IS '할당량 상태 - ACTIVE(활성), SUSPENDED(일시중단), EXPIRED(만료) 할당량 적용 상태';
COMMENT ON COLUMN cnfg.service_quotas.deleted 					IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 테넌트별 할당량 조회 최적화
CREATE INDEX IF NOT EXISTS ix_service_quotas__tenant_id
	ON cnfg.service_quotas (tenant_id)
 WHERE deleted = FALSE;

-- 할당량 유형별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_service_quotas__quota_type
	ON cnfg.service_quotas (quota_type, created_at DESC)
 WHERE deleted = FALSE;

-- 상태별 할당량 조회 최적화
CREATE INDEX IF NOT EXISTS ix_service_quotas__status
	ON cnfg.service_quotas (status, created_at DESC)
 WHERE deleted = FALSE;

-- 테넌트별 할당량 유형 조회 최적화
CREATE INDEX IF NOT EXISTS ix_service_quotas__tenant_type
	ON cnfg.service_quotas (tenant_id, quota_type)
 WHERE deleted = FALSE;

-- 사용량 기준 할당량 조회 최적화
CREATE INDEX IF NOT EXISTS ix_service_quotas__quota_usage
	ON cnfg.service_quotas (quota_used, quota_limit, created_at DESC)
 WHERE deleted = FALSE;

-- 기간별 할당량 조회 최적화
CREATE INDEX IF NOT EXISTS ix_service_quotas__period_dates
	ON cnfg.service_quotas (start_date, close_date)
 WHERE deleted = FALSE;

-- 경고 알림 대상 조회 최적화
CREATE INDEX IF NOT EXISTS ix_service_quotas__warning_alerts
	ON cnfg.service_quotas (warning_threshold_rate, quota_used, quota_limit)
 WHERE warning_alert_sent = FALSE
   AND status = 'ACTIVE'
   AND deleted = FALSE;

-- 위험 알림 대상 조회 최적화
CREATE INDEX IF NOT EXISTS ix_service_quotas__critical_alerts
	ON cnfg.service_quotas (critical_threshold_rate, quota_used, quota_limit)
 WHERE critical_alert_sent = FALSE
   AND status = 'ACTIVE'
   AND deleted = FALSE;

-- 초과 허용 할당량 조회 최적화
CREATE INDEX IF NOT EXISTS ix_service_quotas__overage_enabled
	ON cnfg.service_quotas (allow_overage, max_overage_rate)
 WHERE allow_overage = TRUE
   AND deleted = FALSE;

-- 할당량 초과 상황 조회 최적화
CREATE INDEX IF NOT EXISTS ix_service_quotas__quota_exceeded
	ON cnfg.service_quotas (tenant_id, quota_type, quota_used, quota_limit)
 WHERE quota_used >= quota_limit
   AND deleted = FALSE;

-- 만료 예정 할당량 조회 최적화
CREATE INDEX IF NOT EXISTS ix_service_quotas__expiring_service_quotas
	ON cnfg.service_quotas (close_date, status)
 WHERE status = 'ACTIVE'
   AND deleted = FALSE;

-- 할당량 기간별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_service_quotas__quota_period
	ON cnfg.service_quotas (quota_period, start_date DESC)
 WHERE deleted = FALSE;

-- 생성 시간 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_service_quotas__created_at
	ON cnfg.service_quotas (created_at DESC);
