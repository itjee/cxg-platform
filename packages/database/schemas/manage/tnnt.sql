-- ============================================================================
-- 1. 테넌트 관리 (Tenant Management) -> tnnt
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS tnnt;

COMMENT ON SCHEMA tnnt
IS 'TNNT: 테넌트(고객) 메타 관리 스키마: 테넌트 식별/구독/온보딩 정보를 보관. 운영DB의 루트 앵커 도메인.';


/*

DROP TABLE IF EXISTS tnnt.tenants CASCADE;
DROP TABLE IF EXISTS tnnt.subscriptions CASCADE;
DROP TABLE IF EXISTS tnnt.onboardings CASCADE;
DROP TABLE IF EXISTS tnnt.tenant_users CASCADE;
DROP TABLE IF EXISTS tnnt.tenant_roles CASCADE;

*/

-- ============================================================================
-- 테넌트 마스터 정보
-- ============================================================================
CREATE TABLE IF NOT EXISTS tnnt.tenants
(
    -- 기본 식별자 및 감사 필드
    id                  UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 테넌트 고유 식별자 (UUID)
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 테넌트 등록 일시
    created_by          UUID,                                                              	-- 테넌트 등록자 UUID
    updated_at          TIMESTAMP WITH TIME ZONE,                                          	-- 테넌트 수정 일시
    updated_by          UUID,                                                              	-- 테넌트 수정자 UUID

	-- 테넌트 기본 정보
    tenant_code         VARCHAR(20)              NOT NULL,                                 	-- 테넌트 식별 코드 (스키마명으로 사용, 영문+숫자 조합)
    tenant_name         VARCHAR(100)             NOT NULL,                                 	-- 테넌트(회사)명
    tenant_type         VARCHAR(20)              NOT NULL DEFAULT 'STANDARD',              	-- 테넌트 유형 (TRIAL/STANDARD/PREMIUM/ENTERPRISE)

	-- 사업자 등록 정보
    business_no         VARCHAR(20),                                                      	-- 사업자등록번호
    business_name       VARCHAR(200),                                                     	-- 상호(법인명)
    business_type       CHAR(1)                  DEFAULT 'C',                            	-- 사업자구분 (C:법인, S:개인)
    ceo_name            VARCHAR(50),                                                      	-- 대표자명
    business_kind       VARCHAR(100),                                                     	-- 업태
    business_item       VARCHAR(100),                                                     	-- 종목

	-- 주소 정보
    postcode            VARCHAR(10),                                                      	-- 우편번호
    address1            VARCHAR(100),                                                     	-- 주소1 (기본주소)
    address2            VARCHAR(100),                                                     	-- 주소2 (상세주소)
    phone_no            VARCHAR(20),                                                      	-- 대표 전화번호
    employee_count      INTEGER                  DEFAULT 0,                              	-- 직원 수 (라이선스 관리용)

	-- 계약 정보
    start_date          DATE                     NOT NULL,                                	-- 계약 시작일
    close_date          DATE,                                                             	-- 계약 종료일 (NULL: 무기한)

	-- 지역화 설정
    timezone            VARCHAR(50)              DEFAULT 'Asia/Seoul',                    	-- 시간대 (기본: 한국)
    locale              VARCHAR(10)              DEFAULT 'ko-KR',                        	-- 로케일 (언어-국가)
    currency            CHAR(3)                  DEFAULT 'KRW',                          	-- 기본 통화 (ISO 4217)

	-- 확장 가능한 메타데이터
    extra_data          JSONB                    DEFAULT '{}',                           	-- 추가 메타정보 (JSON 형태)

	-- 상태 관리
    status              VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- 테넌트 상태 (TRIAL/ACTIVE/SUSPENDED/TERMINATED)
    deleted          	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT ck_tenants__status				CHECK (status IN ('TRIAL', 'ACTIVE', 'SUSPENDED', 'TERMINATED')),
    CONSTRAINT ck_tenants__tenant_type			CHECK (tenant_type IN ('TRIAL', 'STANDARD', 'PREMIUM', 'ENTERPRISE')),
    CONSTRAINT ck_tenants__business_type		CHECK (business_type IN ('C', 'S')),
    CONSTRAINT ck_tenants__employee_count		CHECK (employee_count >= 0),
    CONSTRAINT ck_tenants__start_date_valid		CHECK (start_date <= CURRENT_DATE),
    CONSTRAINT ck_tenants__close_date_valid		CHECK (close_date IS NULL OR close_date >= start_date),
    CONSTRAINT ck_tenants__tenant_code_format	CHECK (tenant_code ~ '^[a-zA-Z0-9_-]{3,20}$')
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  tnnt.tenants					IS '테넌트 마스터 정보 - 각 고객사(테넌트)의 기본 정보, 계약 상태, 사업자 정보를 관리하는 멀티테넌트 시스템의 핵심 테이블';
COMMENT ON COLUMN tnnt.tenants.id 				IS '테넌트 고유 식별자 - UUID 형태의 기본키, 시스템 내부에서 테넌트를 구분하는 고유값';
COMMENT ON COLUMN tnnt.tenants.created_at 		IS '테넌트 등록 일시 - 레코드 생성 시점의 타임스탬프, 계약 시작 추적용';
COMMENT ON COLUMN tnnt.tenants.created_by 		IS '테넌트 등록자 - 테넌트를 시스템에 등록한 관리자의 UUID';
COMMENT ON COLUMN tnnt.tenants.updated_at 		IS '테넌트 수정 일시 - 레코드 최종 수정 시점의 타임스탬프, 변경 이력 추적용';
COMMENT ON COLUMN tnnt.tenants.updated_by 		IS '테넌트 수정자 - 테넌트 정보를 최종 수정한 관리자의 UUID';
COMMENT ON COLUMN tnnt.tenants.tenant_code 		IS '테넌트 식별 코드 - 스키마명으로 사용되는 고유 코드, 영문+숫자+하이픈+언더스코어 조합 (3-20자)';
COMMENT ON COLUMN tnnt.tenants.tenant_name 		IS '테넌트(회사)명 - 고객사의 공식 회사명 또는 서비스명';
COMMENT ON COLUMN tnnt.tenants.tenant_type 		IS '테넌트 유형 - TRIAL(체험판), STANDARD(표준), PREMIUM(프리미엄), ENTERPRISE(기업) 구분';
COMMENT ON COLUMN tnnt.tenants.business_no 		IS '사업자등록번호 - 국세청 발급 사업자등록번호 (하이픈 포함 가능)';
COMMENT ON COLUMN tnnt.tenants.business_name 	IS '상호(법인명) - 사업자등록증상의 공식 상호명';
COMMENT ON COLUMN tnnt.tenants.business_type 	IS '사업자구분 - C(법인사업자), S(개인사업자) 구분';
COMMENT ON COLUMN tnnt.tenants.ceo_name 		IS '대표자명 - 사업자등록증상의 대표자 성명';
COMMENT ON COLUMN tnnt.tenants.business_kind 	IS '업태 - 사업의 형태나 성격 (예: 제조업, 서비스업, 도소매업)';
COMMENT ON COLUMN tnnt.tenants.business_item 	IS '종목 - 구체적인 사업 품목 (예: 소프트웨어 개발, 컨설팅)';
COMMENT ON COLUMN tnnt.tenants.postcode 		IS '우편번호 - 사업장 소재지 우편번호 (5자리 또는 6자리)';
COMMENT ON COLUMN tnnt.tenants.address1 		IS '주소1 - 기본 주소 (시/도, 시/군/구, 읍/면/동)';
COMMENT ON COLUMN tnnt.tenants.address2 		IS '주소2 - 상세 주소 (건물명, 층수, 호수 등)';
COMMENT ON COLUMN tnnt.tenants.phone_no 		IS '대표 전화번호 - 고객사의 대표 연락처 (하이픈 포함 가능)';
COMMENT ON COLUMN tnnt.tenants.employee_count 	IS '직원 수 - 라이선스 산정 및 과금을 위한 임직원 수 (0 이상)';
COMMENT ON COLUMN tnnt.tenants.start_date 		IS '계약 시작일 - 서비스 이용 계약 시작 날짜';
COMMENT ON COLUMN tnnt.tenants.close_date 		IS '계약 종료일 - 서비스 이용 계약 종료 날짜 (NULL인 경우 무기한 계약)';
COMMENT ON COLUMN tnnt.tenants.timezone 		IS '시간대 - 테넌트의 기본 시간대 설정 (예: Asia/Seoul, America/New_York)';
COMMENT ON COLUMN tnnt.tenants.locale 			IS '로케일 - 언어 및 지역 설정 (ISO 639-1_ISO 3166-1 형태, 예: ko-KR, en-US)';
COMMENT ON COLUMN tnnt.tenants.currency 		IS '기본 통화 - 과금 및 보고서에 사용할 기본 통화 (ISO 4217 코드, 예: KRW, USD)';
COMMENT ON COLUMN tnnt.tenants.extra_data 		IS '추가 메타정보 - 확장 가능한 JSON 형태의 부가 정보 (특별 요구사항, 커스텀 설정 등)';
COMMENT ON COLUMN tnnt.tenants.status 			IS '테넌트 상태 - TRIAL(체험중), ACTIVE(정상운영), SUSPENDED(일시중단), TERMINATED(계약종료)';
COMMENT ON COLUMN tnnt.tenants.deleted 			IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성 상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 테넌트 코드 고유성 보장 (스키마명 중복 방지)
CREATE UNIQUE INDEX IF NOT EXISTS ux_tenants__tenant_code
    ON tnnt.tenants (tenant_code);

-- 사업자등록번호 고유성 보장 (중복 가입 방지)
CREATE UNIQUE INDEX IF NOT EXISTS ux_tenants__business_no
    ON tnnt.tenants (business_no)
 WHERE business_no IS NOT NULL;

-- 활성 상태 테넌트 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenants__status_active
    ON tnnt.tenants (status)
 WHERE deleted = FALSE;

-- 테넌트 유형별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenants__tenant_type
    ON tnnt.tenants (tenant_type)
 WHERE deleted = FALSE;

-- 계약 시작일 기준 정렬 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenants__start_date
    ON tnnt.tenants (start_date DESC);

-- 계약 만료 예정 테넌트 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenants__close_date
    ON tnnt.tenants (close_date)
 WHERE close_date IS NOT NULL
   AND deleted = FALSE;

-- 직원 수 기준 라이선스 관리 최적화
CREATE INDEX IF NOT EXISTS ix_tenants__employee_count
    ON tnnt.tenants (employee_count DESC)
 WHERE deleted = FALSE;

-- 최신 가입 테넌트 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenants__created_at
    ON tnnt.tenants (created_at DESC);

-- 회사명으로 검색 최적화
CREATE INDEX IF NOT EXISTS ix_tenants__tenant_name
    ON tnnt.tenants (tenant_name)
 WHERE deleted = FALSE;

-- 상호명으로 검색 최적화
CREATE INDEX IF NOT EXISTS ix_tenants__business_name
    ON tnnt.tenants (business_name)
 WHERE business_name IS NOT NULL
   AND deleted = FALSE;


-- ============================================================================
-- 테넌트 구독 및 요금제 관리
-- ============================================================================
CREATE TABLE IF NOT EXISTS tnnt.subscriptions
(
    -- 기본 식별자 및 감사 필드
    id                  UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 구독 고유 식별자 (UUID)
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 구독 등록 일시
    created_by          UUID,                                                              	-- 구독 등록자 UUID
    updated_at          TIMESTAMP WITH TIME ZONE,                                          	-- 구독 수정 일시
    updated_by          UUID,                                                              	-- 구독 수정자 UUID

	-- 테넌트 연결
    tenant_id           UUID                     NOT NULL,                                 	-- 구독 대상 테넌트 ID

	-- 구독 계획 정보
    plan_id             UUID                     NOT NULL,                                 	-- 구독 계획 ID (plans 테이블 참조)
    start_date          DATE                     NOT NULL,                                 	-- 구독 시작일
    close_date          DATE,                                                             	-- 구독 종료일 (NULL: 무기한)
    billing_cycle       VARCHAR(20)              NOT NULL DEFAULT 'MONTHLY',              	-- 청구 주기 (MONTHLY/QUARTERLY/YEARLY)

	-- 사용량 제한 설정
    max_users           INTEGER                  DEFAULT 50,                              	-- 최대 허용 사용자 수
    max_storage         INTEGER                  DEFAULT 100,                             	-- 최대 스토리지 용량 (GB 단위)
    max_api_calls       INTEGER                  DEFAULT 10000,                           	-- 월간 최대 API 호출 횟수

	-- 요금 정보
    base_amount         NUMERIC(18,4)            NOT NULL,                                	-- 기본 요금 (고정 비용)
    user_amount         NUMERIC(18,4)            DEFAULT 0,                               	-- 사용자당 추가 요금
    currency            CHAR(3)                  NOT NULL DEFAULT 'KRW',                 	-- 통화 단위 (ISO 4217)

	-- 갱신 설정
    auto_renewal        BOOLEAN                  DEFAULT TRUE,                            	-- 자동 갱신 여부
    noti_renewal        BOOLEAN                  DEFAULT FALSE,                           	-- 갱신 알림 발송 여부

	-- 상태 관리
    status              VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- 구독 상태 (ACTIVE/SUSPENDED/EXPIRED/CANCELED)
    deleted          	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT fk_subscriptions__tenant_id		FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id),

    CONSTRAINT ck_subscriptions__status			CHECK (status IN ('ACTIVE', 'SUSPENDED', 'EXPIRED', 'CANCELED')),
    CONSTRAINT ck_subscriptions__billing_cycle	CHECK (billing_cycle IN ('MONTHLY', 'QUARTERLY', 'YEARLY')),
    CONSTRAINT ck_subscriptions__max_users		CHECK (max_users IS NULL OR max_users > 0),
    CONSTRAINT ck_subscriptions__max_storage	CHECK (max_storage IS NULL OR max_storage > 0),
    CONSTRAINT ck_subscriptions__max_api_calls	CHECK (max_api_calls IS NULL OR max_api_calls > 0),
    CONSTRAINT ck_subscriptions__base_amount	CHECK (base_amount >= 0),
    CONSTRAINT ck_subscriptions__user_amount	CHECK (user_amount >= 0),
    CONSTRAINT ck_subscriptions__date_valid		CHECK (close_date IS NULL OR close_date >= start_date)
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  tnnt.subscriptions					IS '테넌트 구독 및 요금제 관리 - 각 테넌트의 구독 계획, 사용량 제한, 청구 정보, 갱신 설정을 관리하는 테이블';
COMMENT ON COLUMN tnnt.subscriptions.id 				IS '구독 고유 식별자 - UUID 형태의 기본키, 구독 계약을 구분하는 고유값';
COMMENT ON COLUMN tnnt.subscriptions.created_at 		IS '구독 등록 일시 - 레코드 생성 시점의 타임스탬프, 구독 계약 시작 추적용';
COMMENT ON COLUMN tnnt.subscriptions.created_by 		IS '구독 등록자 - 구독을 등록한 관리자 또는 시스템의 UUID';
COMMENT ON COLUMN tnnt.subscriptions.updated_at 		IS '구독 수정 일시 - 레코드 최종 수정 시점의 타임스탬프, 변경 이력 추적용';
COMMENT ON COLUMN tnnt.subscriptions.updated_by 		IS '구독 수정자 - 구독 정보를 최종 수정한 관리자 또는 시스템의 UUID';
COMMENT ON COLUMN tnnt.subscriptions.tenant_id 			IS '구독 대상 테넌트 ID - 구독을 보유한 테넌트의 고유 식별자 (tenants 테이블 참조)';
COMMENT ON COLUMN tnnt.subscriptions.plan_id 			IS '구독 계획 ID - 선택된 요금제의 고유 식별자 (plans 테이블 참조)';
COMMENT ON COLUMN tnnt.subscriptions.start_date 		IS '구독 시작일 - 구독 서비스 이용 시작 날짜, 청구 기준일';
COMMENT ON COLUMN tnnt.subscriptions.close_date 		IS '구독 종료일 - 구독 서비스 이용 종료 날짜 (NULL인 경우 무기한 구독)';
COMMENT ON COLUMN tnnt.subscriptions.billing_cycle 		IS '청구 주기 - MONTHLY(월별), QUARTERLY(분기별), YEARLY(연별) 청구 주기 설정';
COMMENT ON COLUMN tnnt.subscriptions.max_users 			IS '최대 허용 사용자 수 - 구독 계획에서 허용하는 최대 활성 사용자 수 (라이선스 제한)';
COMMENT ON COLUMN tnnt.subscriptions.max_storage 		IS '최대 스토리지 용량 - 구독 계획에서 허용하는 최대 저장공간 크기 (GB 단위)';
COMMENT ON COLUMN tnnt.subscriptions.max_api_calls 		IS '월간 최대 API 호출 횟수 - 구독 계획에서 허용하는 월간 API 요청 한도';
COMMENT ON COLUMN tnnt.subscriptions.base_amount 		IS '기본 요금 - 구독 계획의 고정 월/분기/연 요금 (최소 청구 금액)';
COMMENT ON COLUMN tnnt.subscriptions.user_amount 		IS '사용자당 추가 요금 - 기본 사용자 수를 초과하는 각 사용자에 대한 추가 과금액';
COMMENT ON COLUMN tnnt.subscriptions.currency 			IS '통화 단위 - 요금 표시 및 청구에 사용할 통화 (ISO 4217 코드, 예: KRW, USD)';
COMMENT ON COLUMN tnnt.subscriptions.auto_renewal 		IS '자동 갱신 여부 - TRUE(자동 갱신), FALSE(수동 갱신), 구독 만료 시 자동 연장 설정';
COMMENT ON COLUMN tnnt.subscriptions.noti_renewal 		IS '갱신 알림 발송 여부 - TRUE(알림 발송), FALSE(알림 미발송), 갱신 전 사전 알림 설정';
COMMENT ON COLUMN tnnt.subscriptions.status 			IS '구독 상태 - ACTIVE(활성), SUSPENDED(일시중단), EXPIRED(만료), CANCELED(해지)';
COMMENT ON COLUMN tnnt.subscriptions.deleted 			IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성 상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 테넌트별 구독 정보 조회 최적화
CREATE INDEX IF NOT EXISTS ix_subscriptions__tenant_id
    ON tnnt.subscriptions (tenant_id);

-- 요금제별 구독 현황 조회 최적화
CREATE INDEX IF NOT EXISTS ix_subscriptions__plan_id
    ON tnnt.subscriptions (plan_id);

-- 활성 구독 상태별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_subscriptions__status_active
    ON tnnt.subscriptions (status)
 WHERE deleted = FALSE;

-- 청구 주기별 구독 관리 최적화
CREATE INDEX IF NOT EXISTS ix_subscriptions__billing_cycle
    ON tnnt.subscriptions (billing_cycle)
 WHERE deleted = FALSE;

-- 구독 시작일 기준 정렬 조회 최적화
CREATE INDEX IF NOT EXISTS ix_subscriptions__start_date
    ON tnnt.subscriptions (start_date DESC);

-- 구독 만료 예정 조회 최적화
CREATE INDEX IF NOT EXISTS ix_subscriptions__close_date
    ON tnnt.subscriptions (close_date)
 WHERE close_date IS NOT NULL AND deleted = FALSE;

-- 자동 갱신 대상 구독 조회 최적화
CREATE INDEX IF NOT EXISTS ix_subscriptions__auto_renewal
    ON tnnt.subscriptions (auto_renewal, close_date)
 WHERE status = 'ACTIVE' AND deleted = FALSE;

-- 테넌트별 구독 상태 복합 조회 최적화
CREATE INDEX IF NOT EXISTS ix_subscriptions__tenant_status
    ON tnnt.subscriptions (tenant_id, status)
 WHERE deleted = FALSE;

-- 요금 범위별 구독 분석 최적화
CREATE INDEX IF NOT EXISTS ix_subscriptions__amount_range
    ON tnnt.subscriptions (base_amount DESC)
 WHERE deleted = FALSE;

-- 최신 구독 가입 조회 최적화
CREATE INDEX IF NOT EXISTS ix_subscriptions__created_at
    ON tnnt.subscriptions (created_at DESC);

-- 갱신 알림 대상 구독 조회 최적화
CREATE INDEX IF NOT EXISTS ix_subscriptions__renewal_noti
    ON tnnt.subscriptions (noti_renewal, close_date)
 WHERE status = 'ACTIVE' AND deleted = FALSE;

-- 사용량 제한별 구독 분석 최적화
CREATE INDEX IF NOT EXISTS ix_subscriptions__usage_limits
    ON tnnt.subscriptions (max_users, max_storage, max_api_calls)
 WHERE deleted = FALSE;


-- ============================================================================
-- 테넌트 온보딩 프로세스 추적
-- 단순한 고객 등록이 아니라, “새로운 테넌트(고객사)가 플랫폼에 정상적으로 안착할 수 있도록 단계별로 관리하는 프로세스”를 의미합니다.
-- ============================================================================
CREATE TABLE IF NOT EXISTS tnnt.onboardings
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 온보딩 프로세스 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 온보딩 단계 생성 일시
    created_by                  UUID,                                 								-- 온보딩 단계 생성자 UUID (시스템)
    updated_at                  TIMESTAMP WITH TIME ZONE,                   						-- 온보딩 단계 수정 일시
    updated_by                  UUID,                                 								-- 온보딩 단계 수정자 UUID

	-- 대상 테넌트
    tenant_id                   UUID                     NOT NULL,                                 	-- 온보딩 대상 테넌트 ID

	-- 온보딩 단계 정보
    step_name                   VARCHAR(50)              NOT NULL,                                 	-- 온보딩 단계명 (REGISTRATION/EMAIL_VERIFICATION/SCHEMA_CREATION/INITIAL_SETUP/COMPLETED)
    step_order                  INTEGER                  NOT NULL,                                 	-- 단계 실행 순서 (1, 2, 3, ...)
    step_status                 VARCHAR(20)              NOT NULL DEFAULT 'PENDING',              	-- 단계 상태 (PENDING/IN_PROGRESS/COMPLETED/FAILED)

	-- 단계 처리 시간 정보
    started_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 단계 시작 일시
    completed_at                TIMESTAMP WITH TIME ZONE,                                          	-- 단계 완료 일시
    error_message               TEXT,                                                              	-- 실패 시 오류 메시지
    retry_count                 INTEGER                  DEFAULT 0,                               	-- 재시도 횟수 (실패 시)

	-- 단계별 메타데이터
    step_data                   JSONB                    DEFAULT '{}',                            	-- 각 단계별 필요한 추가 데이터 (JSON 형태)

	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- 온보딩 레코드 상태 (ACTIVE/ARCHIVED/OBSOLETE)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT fk_onboardings__tenant_id 			FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,

    CONSTRAINT ck_onboardings__step_name 			CHECK (step_name IN ('REGISTRATION', 'EMAIL_VERIFICATION', 'SCHEMA_CREATION', 'INITIAL_SETUP', 'DATA_MIGRATION', 'CONFIGURATION', 'COMPLETED')),
    CONSTRAINT ck_onboardings__step_status 			CHECK (step_status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'SKIPPED')),
    CONSTRAINT ck_onboardings__status 				CHECK (status IN ('ACTIVE', 'ARCHIVED', 'OBSOLETE')),
    CONSTRAINT ck_onboardings__step_order 			CHECK (step_order > 0),
    CONSTRAINT ck_onboardings__retry_count 			CHECK (retry_count >= 0),
    CONSTRAINT ck_onboardings__completion_logic 	CHECK ((step_status = 'COMPLETED' AND completed_at IS NOT NULL) OR (step_status != 'COMPLETED')),
    CONSTRAINT ck_onboardings__start_logic 			CHECK ((step_status IN ('IN_PROGRESS', 'COMPLETED', 'FAILED') AND started_at IS NOT NULL) OR (step_status = 'PENDING')),
    CONSTRAINT ck_onboardings__time_sequence 		CHECK (completed_at IS NULL OR started_at IS NULL OR completed_at >= started_at)
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  tnnt.onboardings					IS '테넌트 온보딩 프로세스 추적 - 신규 테넌트의 초기 설정 과정을 단계별로 관리하고 진행 상황을 추적';
COMMENT ON COLUMN tnnt.onboardings.id 				IS '온보딩 프로세스 고유 식별자 - UUID 형태의 기본키, 각 온보딩 단계를 구분하는 고유값';
COMMENT ON COLUMN tnnt.onboardings.created_at 		IS '온보딩 단계 생성 일시 - 해당 온보딩 단계가 시스템에 등록된 시점의 타임스탬프';
COMMENT ON COLUMN tnnt.onboardings.created_by 		IS '온보딩 단계 생성자 UUID - 온보딩 프로세스를 생성한 시스템 또는 관리자의 식별자';
COMMENT ON COLUMN tnnt.onboardings.updated_at 		IS '온보딩 단계 수정 일시 - 온보딩 단계 정보가 최종 변경된 시점의 타임스탬프';
COMMENT ON COLUMN tnnt.onboardings.updated_by 		IS '온보딩 단계 수정자 UUID - 온보딩 단계를 최종 수정한 시스템 또는 관리자의 식별자';
COMMENT ON COLUMN tnnt.onboardings.tenant_id 		IS '온보딩 대상 테넌트 ID - 온보딩 과정을 진행하는 테넌트의 고유 식별자 (tenants 테이블 참조)';
COMMENT ON COLUMN tnnt.onboardings.step_name 		IS '온보딩 단계명 - REGISTRATION(가입), EMAIL_VERIFICATION(이메일인증), SCHEMA_CREATION(스키마생성), INITIAL_SETUP(초기설정), DATA_MIGRATION(데이터마이그레이션), CONFIGURATION(환경설정), COMPLETED(완료)';
COMMENT ON COLUMN tnnt.onboardings.step_order 		IS '단계 실행 순서 - 온보딩 프로세스에서 이 단계가 수행되어야 하는 순서 (1부터 시작하는 정수)';
COMMENT ON COLUMN tnnt.onboardings.step_status 		IS '단계 상태 - PENDING(대기중), IN_PROGRESS(진행중), COMPLETED(완료), FAILED(실패), SKIPPED(건너뜀) 각 단계의 진행 상태';
COMMENT ON COLUMN tnnt.onboardings.started_at 		IS '단계 시작 일시 - 해당 온보딩 단계가 실제로 시작된 시점';
COMMENT ON COLUMN tnnt.onboardings.completed_at 	IS '단계 완료 일시 - 해당 온보딩 단계가 성공적으로 완료된 시점';
COMMENT ON COLUMN tnnt.onboardings.error_message 	IS '실패 시 오류 메시지 - 온보딩 단계가 실패했을 때의 상세 오류 내용 및 원인';
COMMENT ON COLUMN tnnt.onboardings.retry_count 		IS '재시도 횟수 - 해당 단계가 실패한 후 재시도된 횟수 (자동 또는 수동 재시도 포함)';
COMMENT ON COLUMN tnnt.onboardings.step_data 		IS '각 단계별 필요한 추가 데이터 - 온보딩 단계 수행에 필요한 설정값, 파라미터, 결과 데이터 등을 JSON 형태로 저장';
COMMENT ON COLUMN tnnt.onboardings.status 			IS '온보딩 레코드 상태 - ACTIVE(활성), ARCHIVED(보관), OBSOLETE(구버전) 온보딩 기록의 생명주기 관리';
COMMENT ON COLUMN tnnt.onboardings.deleted 			IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 테넌트별 온보딩 단계 조회 최적화
CREATE INDEX IF NOT EXISTS ix_onboardings__tenant_id
    ON tnnt.onboardings (tenant_id, step_order)
 WHERE deleted = FALSE;

-- 단계 상태별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_onboardings__step_status
    ON tnnt.onboardings (step_status, created_at DESC)
 WHERE deleted = FALSE;

-- 단계명별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_onboardings__step_name
    ON tnnt.onboardings (step_name, step_status, created_at DESC)
 WHERE deleted = FALSE;

-- 테넌트별 단계 상태 조회 최적화
CREATE INDEX IF NOT EXISTS ix_onboardings__tenant_status
    ON tnnt.onboardings (tenant_id, step_status)
 WHERE deleted = FALSE;

-- 실패한 단계 조회 최적화
CREATE INDEX IF NOT EXISTS ix_onboardings__failed_steps
    ON tnnt.onboardings (step_status, retry_count, created_at DESC)
 WHERE step_status = 'FAILED' AND deleted = FALSE;

-- 진행중인 단계 조회 최적화
CREATE INDEX IF NOT EXISTS ix_onboardings__in_progress
    ON tnnt.onboardings (step_status, started_at DESC)
 WHERE step_status = 'IN_PROGRESS' AND deleted = FALSE;

-- 대기중인 단계 조회 최적화
CREATE INDEX IF NOT EXISTS ix_onboardings__pending_steps
    ON tnnt.onboardings (step_status, step_order, created_at DESC)
 WHERE step_status = 'PENDING' AND deleted = FALSE;

-- 완료된 단계 조회 최적화
CREATE INDEX IF NOT EXISTS ix_onboardings__completed_steps
    ON tnnt.onboardings (step_status, completed_at DESC)
 WHERE step_status = 'COMPLETED' AND deleted = FALSE;

-- 재시도 분석 최적화
CREATE INDEX IF NOT EXISTS ix_onboardings__retry_analysis
    ON tnnt.onboardings (retry_count DESC, step_name, created_at DESC)
 WHERE retry_count > 0 AND deleted = FALSE;

-- 단계 순서별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_onboardings__step_order
    ON tnnt.onboardings (step_order, step_status)
 WHERE deleted = FALSE;

-- 테넌트별 진행상황 조회 최적화
CREATE INDEX IF NOT EXISTS ix_onboardings__tenant_progress
    ON tnnt.onboardings (tenant_id, step_name, step_status, step_order)
 WHERE deleted = FALSE;

-- 단계별 데이터 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_onboardings__step_data
    ON tnnt.onboardings USING GIN (step_data)
 WHERE deleted = FALSE;

-- 생성 시간 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_onboardings__created_at
    ON tnnt.onboardings (created_at DESC);


-- ============================================================================
-- 테넌트-사용자 연결 테이블 (관계만 관리)
-- ============================================================================
CREATE TABLE IF NOT EXISTS tnnt.tenant_users
(
    id                          UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),  -- 연결 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT CURRENT_TIMESTAMP,     -- 생성일시
    created_by                  UUID,                                                               -- 생성자 ID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                           -- 수정일시
    updated_by                  UUID,                                                               -- 수정자 ID

    -- 연결 정보
    tenant_id                   UUID                        NOT NULL,                               -- 테넌트 ID (tnnt.tenants 참조)
    user_id                     UUID                        NOT NULL,                               -- 사용자 ID (idam.users 참조)

    -- 테넌트 내 역할 정보
    role                        VARCHAR(50),                                                        -- 테넌트 내 역할/직책
    department                  VARCHAR(100),                                                       -- 테넌트 내 부서
    position                    VARCHAR(100),                                                       -- 테넌트 내 직급
    employee_id                 VARCHAR(50),                                                        -- 테넌트 내 사번

    -- 연결 상태 및 기간
    start_date                  DATE    NOT NULL DEFAULT CURRENT_DATE,                              -- 테넌트 가입일
    close_date                  DATE,                                                               -- 테넌트 탈퇴일
    status                      VARCHAR(20)                 NOT NULL DEFAULT 'ACTIVE',              -- 테넌트 내 상태

    -- 권한 설정
    is_primary                  BOOLEAN                     NOT NULL DEFAULT FALSE,                 -- 주 테넌트 여부 (사용자가 여러 테넌트에 속할 경우)
    is_admin                    BOOLEAN                     NOT NULL DEFAULT FALSE,                 -- 테넌트 관리자 여부

    -- 외래 키 제약 조건
    CONSTRAINT fk_tenant_users__tenant_id       FOREIGN KEY (tenant_id)    REFERENCES tnnt.tenants(id)    ON DELETE CASCADE,
    CONSTRAINT fk_tenant_users__user_id         FOREIGN KEY (user_id)      REFERENCES idam.users(id)      ON DELETE CASCADE,

    -- 고유 제약 조건
    CONSTRAINT uk_tenant_users__tenant_user     UNIQUE (tenant_id, user_id),

    -- 체크 제약 조건
    CONSTRAINT ck_tenant_users__status          CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED', 'LEFT')),
    CONSTRAINT ck_tenant_users__dates           CHECK (close_date IS NULL OR close_date > start_date),
    CONSTRAINT ck_tenant_users__primary_admin   CHECK (NOT (is_primary = true AND is_admin = false))  -- 주 테넌트면서 관리자가 아닐 수 없음
);

COMMENT ON TABLE  tnnt.tenant_users                         IS '테넌트-사용자 연결 관리 (관계와 테넌트별 정보만 담당)';
COMMENT ON COLUMN tnnt.tenant_users.id                      IS '연결 고유 식별자';
COMMENT ON COLUMN tnnt.tenant_users.created_at              IS '생성일시';
COMMENT ON COLUMN tnnt.tenant_users.created_by              IS '생성자 ID';
COMMENT ON COLUMN tnnt.tenant_users.updated_at              IS '수정일시';
COMMENT ON COLUMN tnnt.tenant_users.updated_by              IS '수정자 ID';
COMMENT ON COLUMN tnnt.tenant_users.tenant_id               IS '테넌트 ID (tnnt.tenants 참조)';
COMMENT ON COLUMN tnnt.tenant_users.user_id                 IS '사용자 ID (idam.users 참조)';
COMMENT ON COLUMN tnnt.tenant_users.role                    IS '테넌트 내 역할/직책';
COMMENT ON COLUMN tnnt.tenant_users.department              IS '테넌트 내 부서';
COMMENT ON COLUMN tnnt.tenant_users.position                IS '테넌트 내 직급';
COMMENT ON COLUMN tnnt.tenant_users.employee_id             IS '테넌트 내 사번';
COMMENT ON COLUMN tnnt.tenant_users.start_date              IS '테넌트 가입일';
COMMENT ON COLUMN tnnt.tenant_users.close_date              IS '테넌트 탈퇴일';
COMMENT ON COLUMN tnnt.tenant_users.status                  IS '테넌트 내 상태 (ACTIVE, INACTIVE, SUSPENDED, LEFT)';
COMMENT ON COLUMN tnnt.tenant_users.is_primary              IS '주 테넌트 여부 (사용자가 여러 테넌트에 속할 경우)';
COMMENT ON COLUMN tnnt.tenant_users.is_admin                IS '테넌트 관리자 여부';

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS ix_tenant_users__tenant_id ON tnnt.tenant_users (tenant_id);
CREATE INDEX IF NOT EXISTS ix_tenant_users__user_id ON tnnt.tenant_users (user_id);
CREATE INDEX IF NOT EXISTS ix_tenant_users__status ON tnnt.tenant_users (status);
CREATE INDEX IF NOT EXISTS ix_tenant_users__is_primary ON tnnt.tenant_users (is_primary) WHERE is_primary = TRUE;
CREATE INDEX IF NOT EXISTS ix_tenant_users__is_admin ON tnnt.tenant_users (is_admin) WHERE is_admin = TRUE;
CREATE INDEX IF NOT EXISTS ix_tenant_users__start_date ON tnnt.tenant_users (start_date);
CREATE INDEX IF NOT EXISTS ix_tenant_users__close_date ON tnnt.tenant_users (close_date) WHERE close_date IS NOT NULL;

-- ============================================================================
-- 테넌트-역할 연결 테이블 (테넌트별 커스텀 역할)
-- ============================================================================
CREATE TABLE IF NOT EXISTS tnnt.tenant_roles
(
    id                          UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),  -- 연결 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT CURRENT_TIMESTAMP,     -- 생성일시
    created_by                  UUID,                                                               -- 생성자 ID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                           -- 수정일시
    updated_by                  UUID,                                                               -- 수정자 ID

    -- 연결 정보
    tenant_id                   UUID                        NOT NULL,                               -- 테넌트 ID (tnnt.tenants 참조)
    role_id                     UUID                        NOT NULL,                               -- 역할 ID (idam.roles 참조)

    -- 테넌트별 역할 설정
    role_name                   VARCHAR(100),                                                       -- 테넌트별 역할명 재정의
    description                 TEXT,                                                               -- 테넌트별 역할 설명 재정의

    -- 테넌트별 역할 속성
    is_default                  BOOLEAN                     NOT NULL DEFAULT FALSE,                 -- 테넌트 내 기본 역할 여부
    priority                    INTEGER,                                                            -- 테넌트 내 우선순위 (글로벌 우선순위와 별도)

    -- 활성화 상태
    enabled                     BOOLEAN                     NOT NULL DEFAULT TRUE,                  -- 테넌트 내 역할 활성화 여부
    enabled_at                  TIMESTAMP WITH TIME ZONE    DEFAULT CURRENT_TIMESTAMP,              -- 활성화 일시
    disabled_at                 TIMESTAMP WITH TIME ZONE,                                           -- 비활성화 일시

    -- 테넌트별 역할 제한
    max_users                   INTEGER,                                                            -- 이 역할을 가질 수 있는 최대 사용자 수
    current_users               INTEGER                     NOT NULL DEFAULT 0,                     -- 현재 이 역할을 가진 사용자 수

    -- 외래 키 제약 조건
    CONSTRAINT fk_tenant_roles__tenant_id       FOREIGN KEY (tenant_id)    REFERENCES tnnt.tenants(id)    ON DELETE CASCADE,
    CONSTRAINT fk_tenant_roles__role_id         FOREIGN KEY (role_id)      REFERENCES idam.roles(id)      ON DELETE CASCADE,

    -- 고유 제약 조건
    CONSTRAINT uk_tenant_roles__tenant_role     UNIQUE (tenant_id, role_id),

    -- 체크 제약 조건
    CONSTRAINT ck_tenant_roles__users_count     CHECK (current_users >= 0 AND (max_users IS NULL OR current_users <= max_users)),
    CONSTRAINT ck_tenant_roles__dates           CHECK (disabled_at IS NULL OR disabled_at > enabled_at)
);

COMMENT ON TABLE  tnnt.tenant_roles                         IS '테넌트-역할 연결 관리 (테넌트별 역할 커스터마이징)';
COMMENT ON COLUMN tnnt.tenant_roles.id                      IS '연결 고유 식별자';
COMMENT ON COLUMN tnnt.tenant_roles.created_at              IS '생성일시';
COMMENT ON COLUMN tnnt.tenant_roles.created_by              IS '생성자 ID';
COMMENT ON COLUMN tnnt.tenant_roles.updated_at              IS '수정일시';
COMMENT ON COLUMN tnnt.tenant_roles.updated_by              IS '수정자 ID';
COMMENT ON COLUMN tnnt.tenant_roles.tenant_id               IS '테넌트 ID (tnnt.tenants 참조)';
COMMENT ON COLUMN tnnt.tenant_roles.role_id                 IS '역할 ID (idam.roles 참조)';
COMMENT ON COLUMN tnnt.tenant_roles.role_name               IS '테넌트별 역할명 재정의';
COMMENT ON COLUMN tnnt.tenant_roles.description             IS '테넌트별 역할 설명 재정의';
COMMENT ON COLUMN tnnt.tenant_roles.is_default              IS '테넌트 내 기본 역할 여부';
COMMENT ON COLUMN tnnt.tenant_roles.priority                IS '테넌트 내 우선순위 (글로벌 우선순위와 별도)';
COMMENT ON COLUMN tnnt.tenant_roles.enabled                 IS '테넌트 내 역할 활성화 여부';
COMMENT ON COLUMN tnnt.tenant_roles.max_users               IS '이 역할을 가질 수 있는 최대 사용자 수';
COMMENT ON COLUMN tnnt.tenant_roles.current_users           IS '현재 이 역할을 가진 사용자 수';

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS ix_tenant_roles__tenant_id   ON tnnt.tenant_roles (tenant_id);
CREATE INDEX IF NOT EXISTS ix_tenant_roles__role_id     ON tnnt.tenant_roles (role_id);
CREATE INDEX IF NOT EXISTS ix_tenant_roles__is_enabled  ON tnnt.tenant_roles (enabled);
CREATE INDEX IF NOT EXISTS ix_tenant_roles__is_default  ON tnnt.tenant_roles (is_default) WHERE is_default = TRUE;
CREATE INDEX IF NOT EXISTS ix_tenant_roles__priority    ON tnnt.tenant_roles (tenant_id, priority) WHERE priority IS NOT NULL;

-- ============================================================================
-- 테넌트 사용자 통계 뷰 (편의성)
-- ============================================================================
CREATE OR REPLACE VIEW tnnt.v_tenant_user_stats AS
SELECT
    tu.tenant_id,
    tu.user_id,
    u.username,
    u.email,
    u.full_name,
    u.user_type,
    tu.role,
    tu.department,
    tu.position,
    tu.employee_id,
    tu.status as tenant_status,
    tu.is_primary,
    tu.is_admin as is_admin,
    tu.start_date,
    tu.close_date,

    -- 역할 정보 집계
    COUNT(tur.id) as role_count,
    STRING_AGG(
        COALESCE(tr.role_name, r.role_name),
        ', ' ORDER BY COALESCE(tr.priority, r.priority)
    ) as roles,

    -- 최고 우선순위 역할
    MIN(COALESCE(tr.priority, r.priority)) as highest_priority

FROM
    tnnt.tenant_users tu
JOIN
    idam.users u ON tu.user_id = u.id
LEFT JOIN
    idam.user_roles tur ON tu.id = tur.user_id AND tur.status = 'ACTIVE'
LEFT JOIN
    tnnt.tenant_roles tr ON tur.role_id = tr.id AND tr.is_enabled = TRUE
LEFT JOIN
    idam.roles r ON tr.role_id = r.id
GROUP BY
    tu.tenant_id, tu.user_id, u.username, u.email, u.full_name, u.user_type,
    tu.role, tu.department, tu.position, tu.employee_id,
    tu.status, tu.is_primary, tu.is_admin, tu.start_date, tu.close_date;

COMMENT ON VIEW tnnt.v_tenant_user_summary IS '테넌트 사용자 요약 정보 뷰 (역할 정보 포함)';

-- ============================================================================
-- 테넌트 역할 통계 뷰 (편의성)
-- ============================================================================
CREATE OR REPLACE VIEW tnnt.v_tenant_role_summary AS
SELECT
    tr.tenant_id,
    tr.role_id,
    r.role_code,
    COALESCE(tr.role_name, r.role_name) as role_name,
    COALESCE(tr.description, r.description) as description,
    r.role_type,
    r.scope,
    tr.is_default,
    tr.priority as tenant_priority,
    r.priority as global_priority,
    tr.enabled,
    tr.max_users,
    tr.current_users,

    -- 실제 사용자 수 (current_users와 대조용)
    COUNT(tur.id) as actual_user_count

FROM
    tnnt.tenant_roles tr
JOIN
    idam.roles r ON tr.role_id = r.id
LEFT JOIN
    idam.user_roles tur ON tr.id = tur.role_id AND tur.status = 'ACTIVE'
GROUP BY
    tr.tenant_id, tr.role_id, r.role_code, tr.role_name_override, r.role_name,
    tr.description_override, r.description, r.role_type, r.scope,
    tr.is_tenant_default, tr.tenant_priority, r.priority,
    tr.is_enabled, tr.max_users, tr.current_users;

COMMENT ON VIEW tnnt.v_tenant_role_summary IS '테넌트 역할 요약 정보 뷰 (사용자 수 포함)';

-- ============================================================================
-- 트리거 함수: 테넌트 역할 사용자 수 자동 업데이트
-- ============================================================================
CREATE OR REPLACE FUNCTION tnnt.update_tenant_role_user_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- 역할 할당 시 사용자 수 증가
        UPDATE tnnt.tenant_roles
        SET current_users = current_users + 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.tenant_role_id;
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        -- 역할 해제 시 사용자 수 감소
        UPDATE tnnt.tenant_roles
        SET current_users = GREATEST(current_users - 1, 0),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = OLD.tenant_role_id;
        RETURN OLD;

    ELSIF TG_OP = 'UPDATE' THEN
        -- 상태 변경 시 사용자 수 조정
        IF OLD.status = 'ACTIVE' AND NEW.status != 'ACTIVE' THEN
            -- 비활성화
            UPDATE tnnt.tenant_roles
            SET current_users = GREATEST(current_users - 1, 0),
                updated_at = CURRENT_TIMESTAMP
            WHERE id = NEW.tenant_role_id;
        ELSIF OLD.status != 'ACTIVE' AND NEW.status = 'ACTIVE' THEN
            -- 활성화
            UPDATE tnnt.tenant_roles
            SET current_users = current_users + 1,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = NEW.tenant_role_id;
        END IF;
        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER trigger_update_tenant_role_user_count
    AFTER INSERT OR UPDATE OR DELETE ON tnnt.tenant_user_roles
    FOR EACH ROW
    EXECUTE FUNCTION tnnt.update_tenant_role_user_count();
