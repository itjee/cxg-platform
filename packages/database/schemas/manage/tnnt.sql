-- ============================================================================
-- 1. 테넌트 관리 (Tenant Management) -> tnnt
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS tnnt;

COMMENT ON SCHEMA tnnt 
IS 'TNNT: 테넌트(고객) 메타 관리 스키마: 테넌트 식별/구독/온보딩 정보를 보관. 운영DB의 루트 앵커 도메인.';

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
-- 테넌트 사용자 정보
-- ============================================================================
CREATE TABLE IF NOT EXISTS tnnt.users
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 사용자 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 사용자 등록 일시
    created_by                  UUID,                                                              	-- 사용자 등록자 UUID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 사용자 정보 수정 일시
    updated_by                  UUID,                                                              	-- 사용자 정보 수정자 UUID
    
	-- 테넌트 연결
    tenant_id                   UUID                     NOT NULL,                                 	-- 테넌트 ID
    
	-- 사용자 기본 정보    
	user_name					VARCHAR(100)			 NOT NULL,									-- 사용자 이름(실명 또는 표시명)
    user_role              		VARCHAR(50)              NOT NULL DEFAULT 'USER',                 	-- 사용자 역할 (ADMIN/MANAGER/USER/READONLY)
	email             			VARCHAR(255)             NOT NULL,		                          	-- 이메일
    
	-- 인증 정보
	login_id                   	VARCHAR(100)             NOT NULL,                                 	-- 로그인 ID
    password            		VARCHAR(255),                                                      	-- 해시된 비밀번호 (bcrypt/argon2)
    last_login_at               TIMESTAMP WITH TIME ZONE,                                          	-- 마지막 로그인 일시
    login_count                 INTEGER                  DEFAULT 0,                               	-- 총 로그인 횟수
    failed_login_count          INTEGER                  DEFAULT 0,                               	-- 연속 로그인 실패 횟수
    password_changed_at         TIMESTAMP WITH TIME ZONE,                                          	-- 비밀번호 마지막 변경 일시
    
	-- 이메일 인증 정보
    is_email_verified           BOOLEAN                  DEFAULT FALSE,                           	-- 이메일 인증 완료 여부
    email_verification_token    VARCHAR(255),                                                      	-- 이메일 인증 토큰
    email_verified_at           TIMESTAMP WITH TIME ZONE,                                          	-- 이메일 인증 완료 일시
    
	-- 계정 잠금 정보
    is_locked                   BOOLEAN                  DEFAULT FALSE,                           	-- 계정 잠금 여부
    locked_at                   TIMESTAMP WITH TIME ZONE,                                          	-- 계정 잠금 일시
    locked_reason               VARCHAR(255),                                                      	-- 계정 잠금 사유
    
	-- 사용자 개인화 설정
    language                    VARCHAR(10)              DEFAULT 'ko',                            	-- 사용 언어 (ISO 639-1)
    timezone                    VARCHAR(50)              DEFAULT 'Asia/Seoul',                    	-- 개인 시간대 설정
    notification_preferences    JSONB                    DEFAULT '{}',                            	-- 알림 설정 (JSON 형태)
    
	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- 사용자 상태 (ACTIVE/INACTIVE/SUSPENDED)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그
    
	-- 제약조건
    CONSTRAINT fk_users__tenant_id 					FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,
		
	CONSTRAINT uk_users__login_id					UNIQUE (login_id),
	
    CONSTRAINT ck_users__user_role 					CHECK (user_role IN ('ADMIN', 'MANAGER', 'USER', 'READONLY')),
    CONSTRAINT ck_users__status 					CHECK (status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED')),
    CONSTRAINT ck_users__failed_login_count 		CHECK (failed_login_count >= 0),
    CONSTRAINT ck_users__login_count 				CHECK (login_count >= 0),
    CONSTRAINT ck_users__email_format 				CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  tnnt.users							IS '테넌트 사용자 정보 - 각 테넌트의 사용자 계정, 권한, 인증 정보, 개인 설정을 관리하는 사용자 마스터 테이블';
COMMENT ON COLUMN tnnt.users.id 						IS '사용자 고유 식별자 - UUID 형태의 기본키, 시스템 내에서 사용자를 구분하는 고유값';
COMMENT ON COLUMN tnnt.users.created_at 				IS '사용자 등록 일시 - 계정이 시스템에 생성된 시점의 타임스탬프';
COMMENT ON COLUMN tnnt.users.created_by 				IS '사용자 등록자 - 계정을 생성한 관리자 또는 시스템의 UUID (자가가입의 경우 NULL)';
COMMENT ON COLUMN tnnt.users.updated_at 				IS '사용자 정보 수정 일시 - 사용자 정보가 최종 변경된 시점의 타임스탬프';
COMMENT ON COLUMN tnnt.users.updated_by 				IS '사용자 정보 수정자 - 사용자 정보를 최종 수정한 사용자 또는 관리자의 UUID';
COMMENT ON COLUMN tnnt.users.tenant_id 					IS '소속 테넌트 ID - 사용자가 소속된 테넌트(회사)의 고유 식별자 (tenants 테이블 참조)';
COMMENT ON COLUMN tnnt.users.email 						IS '사용자 이메일 - 이메일 주소';
COMMENT ON COLUMN tnnt.users.user_name 					IS '사용자 이름 - 실명 또는 표시명 (UI에서 사용자 식별용)';
COMMENT ON COLUMN tnnt.users.user_role 					IS '사용자 역할 - ADMIN(관리자), MANAGER(매니저), USER(일반사용자), READONLY(읽기전용) 권한 구분';
COMMENT ON COLUMN tnnt.users.login_id					IS '로그인 ID - 이메일 주소 (중복 불가)';
COMMENT ON COLUMN tnnt.users.password 					IS '해시된 비밀번호 - bcrypt, argon2 등으로 암호화된 비밀번호 (평문 저장 금지)';
COMMENT ON COLUMN tnnt.users.last_login_at 				IS '마지막 로그인 일시 - 사용자의 최근 로그인 성공 시점 (활성도 측정용)';
COMMENT ON COLUMN tnnt.users.login_count 				IS '총 로그인 횟수 - 누적 로그인 성공 횟수 (사용 패턴 분석용)';
COMMENT ON COLUMN tnnt.users.failed_login_count 		IS '연속 로그인 실패 횟수 - 보안 정책 적용을 위한 연속 실패 카운트 (성공 시 0으로 리셋)';
COMMENT ON COLUMN tnnt.users.password_changed_at 		IS '비밀번호 마지막 변경 일시 - 비밀번호 정책 적용을 위한 변경 이력 추적';
COMMENT ON COLUMN tnnt.users.is_email_verified 			IS '이메일 인증 완료 여부 - TRUE(인증완료), FALSE(인증대기), 계정 활성화 조건';
COMMENT ON COLUMN tnnt.users.email_verification_token 	IS '이메일 인증 토큰 - 이메일 인증 시 사용하는 일회성 토큰 (인증 후 삭제)';
COMMENT ON COLUMN tnnt.users.email_verified_at 			IS '이메일 인증 완료 일시 - 사용자가 이메일 인증을 완료한 시점';
COMMENT ON COLUMN tnnt.users.is_locked 					IS '계정 잠금 여부 - TRUE(잠금상태), FALSE(정상상태), 보안 위반 시 계정 차단용';
COMMENT ON COLUMN tnnt.users.locked_at 					IS '계정 잠금 일시 - 계정이 잠금된 시점 (잠금 해제 정책 적용용)';
COMMENT ON COLUMN tnnt.users.locked_reason 				IS '계정 잠금 사유 - 잠금 원인에 대한 설명 (연속 로그인 실패, 관리자 조치 등)';
COMMENT ON COLUMN tnnt.users.language 					IS '사용 언어 - 사용자 인터페이스 언어 설정 (ISO 639-1 코드, 예: ko, en)';
COMMENT ON COLUMN tnnt.users.timezone 					IS '개인 시간대 설정 - 사용자별 시간대 표시 설정 (예: Asia/Seoul, America/New_York)';
COMMENT ON COLUMN tnnt.users.notification_preferences 	IS '알림 설정 - 이메일, SMS, 푸시 알림 등의 개인 설정 정보 (JSON 형태)';
COMMENT ON COLUMN tnnt.users.status 					IS '사용자 상태 - ACTIVE(활성), INACTIVE(비활성), SUSPENDED(일시정지) 계정 상태 구분';
COMMENT ON COLUMN tnnt.users.deleted 					IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 이메일 고유성 보장 (활성 사용자만)
CREATE UNIQUE INDEX IF NOT EXISTS ux_users__email
    ON tnnt.users (email)
 WHERE deleted = FALSE;
 
 -- 로그인 ID
CREATE UNIQUE INDEX IF NOT EXISTS ux_users__login_id
    ON tnnt.users (login_id)
 WHERE deleted = FALSE;

-- 테넌트별 사용자 조회 최적화
CREATE INDEX IF NOT EXISTS ix_users__tenant_id
    ON tnnt.users (tenant_id)
 WHERE deleted = FALSE;

-- 역할별 사용자 조회 최적화
CREATE INDEX IF NOT EXISTS ix_users__user_role
    ON tnnt.users (user_role)
 WHERE deleted = FALSE;

-- 상태별 사용자 조회 최적화
CREATE INDEX IF NOT EXISTS ix_users__status
    ON tnnt.users (status)
 WHERE deleted = FALSE;

-- 테넌트별 역할 조회 최적화
CREATE INDEX IF NOT EXISTS ix_users__tenant_role
    ON tnnt.users (tenant_id, user_role)
 WHERE deleted = FALSE;

-- 최근 로그인 사용자 조회 최적화
CREATE INDEX IF NOT EXISTS ix_users__last_login
    ON tnnt.users (last_login_at DESC NULLS LAST)
 WHERE deleted = FALSE;

-- 잠금된 계정 관리 최적화
CREATE INDEX IF NOT EXISTS ix_users__is_locked
    ON tnnt.users (is_locked, locked_at)
 WHERE is_locked = TRUE AND deleted = FALSE;

-- 로그인 실패 모니터링 최적화
CREATE INDEX IF NOT EXISTS ix_users__failed_login
    ON tnnt.users (failed_login_count DESC, email)
 WHERE failed_login_count > 0 AND deleted = FALSE;

-- 이메일 인증 대기 사용자 조회 최적화
CREATE INDEX IF NOT EXISTS ix_users__email_verification
    ON tnnt.users (is_email_verified, email_verification_token)
 WHERE is_email_verified = FALSE AND deleted = FALSE;

-- 최신 가입 사용자 조회 최적화
CREATE INDEX IF NOT EXISTS ix_users__created_at
    ON tnnt.users (created_at DESC);

-- 비밀번호 변경 정책 적용 최적화
CREATE INDEX IF NOT EXISTS ix_users__password_change
    ON tnnt.users (password_changed_at ASC NULLS FIRST)
 WHERE deleted = FALSE;

-- 알림 설정 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_users__notification_prefs
    ON tnnt.users USING GIN (notification_preferences)
 WHERE deleted = FALSE;


-- ============================================================================
-- API 키 관리
-- ============================================================================
CREATE TABLE IF NOT EXISTS tnnt.api_keys
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- API 키 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- API 키 생성 일시
    created_by                  UUID,                                                              	-- API 키 생성자 UUID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- API 키 수정 일시
    updated_by                  UUID,                                                              	-- API 키 수정자 UUID
    
	-- 소유자 정보
    tenant_id                   UUID                     NOT NULL,                                 	-- 소유 테넌트 ID
    user_id                     UUID,                                                              	-- 소유 사용자 ID (테넌트 공통 키인 경우 NULL)
    
	-- API 키 기본 정보
    key_name                    VARCHAR(100)             NOT NULL,                                 	-- API 키 이름 (사용자 정의)
    key_hashed                 	VARCHAR(255)             NOT NULL,                                 	-- 해시된 API 키 (SHA-256 등)
    key_prefix                  VARCHAR(20)              NOT NULL,                                 	-- 식별용 접두어 (화면 표시용, 예: ak_1234...)
    
	-- 권한 및 접근 제한
    permissions                 JSONB                    DEFAULT '{}',                            	-- 허용된 API 권한 목록 (JSON 형태)
    allowed_ips                 TEXT[],                                                            	-- 접근 허용 IP 주소 목록 (CIDR 표기 지원)
    rate_limit       INTEGER                  DEFAULT 1000,                            				-- 분당 API 요청 제한
    rate_limit_per_hour         INTEGER                  DEFAULT 10000,                           	-- 시간당 API 요청 제한
    
	-- 사용 통계
    last_used_at                TIMESTAMP WITH TIME ZONE,                                          	-- 마지막 사용 일시
    total_requests              INTEGER                  DEFAULT 0,                               	-- 총 요청 횟수
    
	-- 만료 관리
    expires_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 만료 일시 (NULL: 무기한)
    
	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- API 키 상태 (ACTIVE/SUSPENDED/EXPIRED)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그
    
	-- 제약조건
    CONSTRAINT fk_api_keys__tenant_id 			FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,
    CONSTRAINT fk_api_keys__user_id 			FOREIGN KEY (user_id) 	REFERENCES tnnt.users(id)	ON DELETE CASCADE,
	
    CONSTRAINT ck_api_keys__status 				CHECK (status IN ('ACTIVE', 'SUSPENDED', 'EXPIRED')),
    CONSTRAINT ck_api_keys__rate_limit_minute 	CHECK (rate_limit IS NULL OR rate_limit > 0),
    CONSTRAINT ck_api_keys__rate_limit_hour 	CHECK (rate_limit_per_hour IS NULL OR rate_limit_per_hour > 0),
    CONSTRAINT ck_api_keys__total_requests 		CHECK (total_requests >= 0),
    CONSTRAINT ck_api_keys__expires_valid 		CHECK (expires_at IS NULL OR expires_at > created_at)
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  tnnt.api_keys						IS 'API 키 관리 - 테넌트 및 사용자별 API 접근 키, 권한, 사용량 제한, 통계를 관리하는 테이블';
COMMENT ON COLUMN tnnt.api_keys.id 					IS 'API 키 고유 식별자 - UUID 형태의 기본키, 시스템 내에서 API 키를 구분하는 고유값';
COMMENT ON COLUMN tnnt.api_keys.created_at 			IS 'API 키 생성 일시 - API 키가 발급된 시점의 타임스탬프';
COMMENT ON COLUMN tnnt.api_keys.created_by 			IS 'API 키 생성자 - API 키를 발급한 사용자 또는 시스템의 UUID';
COMMENT ON COLUMN tnnt.api_keys.updated_at 			IS 'API 키 수정 일시 - API 키 정보가 최종 변경된 시점의 타임스탬프';
COMMENT ON COLUMN tnnt.api_keys.updated_by 			IS 'API 키 수정자 - API 키 정보를 최종 수정한 사용자 또는 시스템의 UUID';
COMMENT ON COLUMN tnnt.api_keys.tenant_id 			IS '소유 테넌트 ID - API 키를 소유한 테넌트의 고유 식별자 (tenants 테이블 참조)';
COMMENT ON COLUMN tnnt.api_keys.user_id 			IS '소유 사용자 ID - API 키를 소유한 사용자의 고유 식별자 (users 테이블 참조, 테넌트 공통 키인 경우 NULL)';
COMMENT ON COLUMN tnnt.api_keys.key_name 			IS 'API 키 이름 - 사용자가 정의한 API 키의 용도나 설명 (예: Production API Key, Test Key)';
COMMENT ON COLUMN tnnt.api_keys.key_hashed 			IS '해시된 API 키 - SHA-256 등으로 암호화된 실제 API 키 값 (원본 키는 저장하지 않음)';
COMMENT ON COLUMN tnnt.api_keys.key_prefix 			IS '식별용 접두어 - 보안을 위해 화면에 표시되는 API 키의 앞 부분 (예: ak_1234..., sk_abcd...)';
COMMENT ON COLUMN tnnt.api_keys.permissions 		IS '허용된 API 권한 목록 - 이 키로 접근 가능한 API 엔드포인트와 작업 목록 (JSON 형태)';
COMMENT ON COLUMN tnnt.api_keys.allowed_ips 		IS '접근 허용 IP 주소 목록 - 이 API 키 사용이 허용된 IP 주소들 (CIDR 표기법 지원, 예: 192.168.1.0/24)';
COMMENT ON COLUMN tnnt.api_keys.rate_limit 			IS '분당 API 요청 제한 - 이 키로 분당 허용되는 최대 요청 수 (Rate Limiting 적용)';
COMMENT ON COLUMN tnnt.api_keys.rate_limit_per_hour IS '시간당 API 요청 제한 - 이 키로 시간당 허용되는 최대 요청 수 (Quota 관리)';
COMMENT ON COLUMN tnnt.api_keys.last_used_at 		IS '마지막 사용 일시 - 이 API 키가 마지막으로 사용된 시점 (활성도 측정용)';
COMMENT ON COLUMN tnnt.api_keys.total_requests 		IS '총 요청 횟수 - 이 API 키로 처리된 누적 요청 수 (사용량 통계)';
COMMENT ON COLUMN tnnt.api_keys.expires_at 			IS '만료 일시 - API 키의 유효 기간 만료 시점 (NULL인 경우 무기한)';
COMMENT ON COLUMN tnnt.api_keys.status 				IS 'API 키 상태 - ACTIVE(활성), SUSPENDED(일시정지), EXPIRED(만료됨) 상태 구분';
COMMENT ON COLUMN tnnt.api_keys.deleted 			IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- API 키 해시값 고유성 보장
CREATE UNIQUE INDEX IF NOT EXISTS ux_api_keys__key_hashed
    ON tnnt.api_keys (key_hashed)
 WHERE deleted = FALSE;

-- 테넌트별 API 키 조회 최적화
CREATE INDEX IF NOT EXISTS ix_api_keys__tenant_id
    ON tnnt.api_keys (tenant_id)
 WHERE deleted = FALSE;

-- 사용자별 API 키 조회 최적화
CREATE INDEX IF NOT EXISTS ix_api_keys__user_id
    ON tnnt.api_keys (user_id)
 WHERE user_id IS NOT NULL AND deleted = FALSE;

-- 상태별 API 키 조회 최적화
CREATE INDEX IF NOT EXISTS ix_api_keys__status_active
    ON tnnt.api_keys (status)
 WHERE deleted = FALSE;

-- 접두어로 API 키 검색 최적화
CREATE INDEX IF NOT EXISTS ix_api_keys__key_prefix
    ON tnnt.api_keys (key_prefix)
 WHERE deleted = FALSE;

-- 만료 예정 API 키 조회 최적화
CREATE INDEX IF NOT EXISTS ix_api_keys__expires_at
    ON tnnt.api_keys (expires_at)
 WHERE expires_at IS NOT NULL AND deleted = FALSE;

-- 최근 사용 API 키 조회 최적화
CREATE INDEX IF NOT EXISTS ix_api_keys__last_used
    ON tnnt.api_keys (last_used_at DESC NULLS LAST)
 WHERE deleted = FALSE;

-- 테넌트별 상태 복합 조회 최적화
CREATE INDEX IF NOT EXISTS ix_api_keys__tenant_status
    ON tnnt.api_keys (tenant_id, status)
 WHERE deleted = FALSE;

-- 사용량 기준 API 키 분석 최적화
CREATE INDEX IF NOT EXISTS ix_api_keys__total_requests
    ON tnnt.api_keys (total_requests DESC)
 WHERE deleted = FALSE;

-- 최신 생성 API 키 조회 최적화
CREATE INDEX IF NOT EXISTS ix_api_keys__created_at
    ON tnnt.api_keys (created_at DESC);

-- 권한 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_api_keys__permissions
    ON tnnt.api_keys USING GIN (permissions)
 WHERE deleted = FALSE;

-- 요청 제한별 API 키 분석 최적화
CREATE INDEX IF NOT EXISTS ix_api_keys__rate_limits
    ON tnnt.api_keys (rate_limit, rate_limit_per_hour)
 WHERE deleted = FALSE;


-- ============================================================================
-- 사용자 세션 추적
-- ============================================================================
CREATE TABLE IF NOT EXISTS tnnt.sessions
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 세션 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 세션 생성 일시
    created_by                  UUID,                                                              	-- 세션 생성자 UUID (보통 시스템)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 세션 수정 일시
    updated_by                  UUID,                                                              	-- 세션 수정자 UUID
    
	-- 사용자 정보
    tenant_id                   UUID                     NOT NULL,                                 	-- 세션 소유 테넌트 ID
    user_id                     UUID                     NOT NULL,                                 	-- 세션 소유 사용자 ID
    
	-- 세션 기본 정보
    session_token               VARCHAR(255)             NOT NULL UNIQUE,                          	-- 세션 토큰 (JWT, UUID 등)
    session_start               TIMESTAMP WITH TIME ZONE NOT NULL,                                 	-- 세션 시작 시간 (로그인 시점)
    session_close               TIMESTAMP WITH TIME ZONE,                                          	-- 세션 종료 시간 (로그아웃 또는 만료 시점)
    last_activity               TIMESTAMP WITH TIME ZONE NOT NULL,                                 	-- 마지막 활동 시간 (세션 갱신용)
    
	-- 클라이언트 접속 정보
    client_ip                   VARCHAR(45),                                                       	-- 클라이언트 IP 주소 (IPv4/IPv6 지원)
    user_agent                  TEXT,                                                              	-- 브라우저 User-Agent 문자열
    device_type                 VARCHAR(50),                                                       	-- 접속 디바이스 유형 (WEB/MOBILE/API)
    browser_name                VARCHAR(50),                                                       	-- 브라우저 이름 (Chrome, Safari, Firefox 등)
    os_name                     VARCHAR(50),                                                       	-- 운영체제 이름 (Windows, macOS, iOS 등)
    
	-- 지리적 위치 정보
    country                     VARCHAR(50),                                                       	-- 접속 국가 (GeoIP 기반)
    city                        VARCHAR(100),                                                      	-- 접속 도시 (GeoIP 기반)
    
	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- 세션 상태 (ACTIVE/EXPIRED/TERMINATED)
    
	-- 제약조건
    CONSTRAINT fk_sessions__tenant_id 		FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,
    CONSTRAINT fk_sessions__user_id 		FOREIGN KEY (user_id) 	REFERENCES tnnt.users(id)	ON DELETE CASCADE,
	
    CONSTRAINT ck_sessions__status 			CHECK (status IN ('ACTIVE', 'EXPIRED', 'TERMINATED')),
    CONSTRAINT ck_sessions__session_times 	CHECK (session_close IS NULL OR session_close >= session_start),
    CONSTRAINT ck_sessions__last_activity 	CHECK (last_activity >= session_start),
    CONSTRAINT ck_sessions__device_type 	CHECK (device_type IN ('WEB', 'MOBILE', 'API', 'DESKTOP'))
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  tnnt.sessions					IS '사용자 세션 추적 - 로그인 세션의 생성, 활동, 종료를 추적하여 보안 모니터링과 사용자 활동 분석을 지원';
COMMENT ON COLUMN tnnt.sessions.id 				IS '세션 고유 식별자 - UUID 형태의 기본키, 시스템 내에서 각 세션을 구분하는 고유값';
COMMENT ON COLUMN tnnt.sessions.created_at 		IS '세션 생성 일시 - 세션이 시스템에 등록된 시점의 타임스탬프';
COMMENT ON COLUMN tnnt.sessions.created_by 		IS '세션 생성자 UUID - 세션을 생성한 시스템 또는 프로세스의 식별자 (보통 인증 서비스)';
COMMENT ON COLUMN tnnt.sessions.updated_at 		IS '세션 수정 일시 - 세션 정보가 최종 갱신된 시점의 타임스탬프 (활동 갱신 시)';
COMMENT ON COLUMN tnnt.sessions.updated_by 		IS '세션 수정자 UUID - 세션을 최종 갱신한 시스템 또는 프로세스의 식별자';
COMMENT ON COLUMN tnnt.sessions.tenant_id 		IS '세션 소유 테넌트 ID - 이 세션이 속한 테넌트의 고유 식별자 (tenants 테이블 참조)';
COMMENT ON COLUMN tnnt.sessions.user_id 		IS '세션 소유 사용자 ID - 이 세션의 소유자인 사용자의 고유 식별자 (users 테이블 참조)';
COMMENT ON COLUMN tnnt.sessions.session_token 	IS '세션 토큰 - 클라이언트에서 사용하는 세션 식별 토큰 (JWT, UUID 등, 고유값)';
COMMENT ON COLUMN tnnt.sessions.session_start 	IS '세션 시작 시간 - 사용자가 로그인하여 세션이 생성된 정확한 시점';
COMMENT ON COLUMN tnnt.sessions.session_close 	IS '세션 종료 시간 - 로그아웃, 타임아웃, 강제 종료 등으로 세션이 종료된 시점 (NULL: 활성 세션)';
COMMENT ON COLUMN tnnt.sessions.last_activity 	IS '마지막 활동 시간 - 사용자의 마지막 API 호출 또는 페이지 접근 시점 (세션 만료 판단 기준)';
COMMENT ON COLUMN tnnt.sessions.client_ip 		IS '클라이언트 IP 주소 - 사용자가 접속한 IP 주소 (IPv4/IPv6 지원, 최대 45자)';
COMMENT ON COLUMN tnnt.sessions.user_agent 		IS '브라우저 User-Agent 문자열 - 클라이언트의 브라우저, 운영체제 등 환경 정보';
COMMENT ON COLUMN tnnt.sessions.device_type 	IS '접속 디바이스 유형 - WEB(웹브라우저), MOBILE(모바일앱), API(API 클라이언트), DESKTOP(데스크톱앱)';
COMMENT ON COLUMN tnnt.sessions.browser_name 	IS '브라우저 이름 - User-Agent에서 파싱한 브라우저 정보 (Chrome, Safari, Firefox, Edge 등)';
COMMENT ON COLUMN tnnt.sessions.os_name 		IS '운영체제 이름 - User-Agent에서 파싱한 OS 정보 (Windows, macOS, iOS, Android 등)';
COMMENT ON COLUMN tnnt.sessions.country 		IS '접속 국가 - GeoIP 데이터베이스 기반으로 파악한 사용자의 접속 국가';
COMMENT ON COLUMN tnnt.sessions.city 			IS '접속 도시 - GeoIP 데이터베이스 기반으로 파악한 사용자의 접속 도시';
COMMENT ON COLUMN tnnt.sessions.status 			IS '세션 상태 - ACTIVE(활성), EXPIRED(만료), TERMINATED(강제종료) 세션의 현재 상태';

-- 인덱스 생성
-- 세션 토큰 고유성 보장 및 빠른 검색
CREATE UNIQUE INDEX IF NOT EXISTS ux_sessions__session_token
    ON tnnt.sessions (session_token);

-- 사용자별 세션 조회 최적화
CREATE INDEX IF NOT EXISTS ix_sessions__user_id
    ON tnnt.sessions (user_id);

-- 테넌트별 세션 조회 최적화
CREATE INDEX IF NOT EXISTS ix_sessions__tenant_id
    ON tnnt.sessions (tenant_id);

-- 활성 세션 조회 최적화
CREATE INDEX IF NOT EXISTS ix_sessions__status_active
    ON tnnt.sessions (status, last_activity DESC)
 WHERE status = 'ACTIVE';

-- 최근 활동 세션 조회 최적화
CREATE INDEX IF NOT EXISTS ix_sessions__last_activity
    ON tnnt.sessions (last_activity DESC);

-- 세션 시작 시간 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_sessions__session_start
    ON tnnt.sessions (session_start DESC);

-- IP 주소별 세션 분석 최적화
CREATE INDEX IF NOT EXISTS ix_sessions__client_ip
    ON tnnt.sessions (client_ip, session_start DESC);

-- 디바이스 유형별 세션 분석 최적화
CREATE INDEX IF NOT EXISTS ix_sessions__device_type
    ON tnnt.sessions (device_type, session_start DESC);

-- 사용자별 활성 세션 조회 최적화
CREATE INDEX IF NOT EXISTS ix_sessions__user_active
    ON tnnt.sessions (user_id, status, last_activity DESC);

-- 테넌트+사용자 복합 조회 최적화
CREATE INDEX IF NOT EXISTS ix_sessions__tenant_user
    ON tnnt.sessions (tenant_id, user_id, session_start DESC);

-- 지역별 접속 통계 최적화
CREATE INDEX IF NOT EXISTS ix_sessions__country_city
    ON tnnt.sessions (country, city)
 WHERE country IS NOT NULL;

-- 브라우저/OS별 통계 최적화
CREATE INDEX IF NOT EXISTS ix_sessions__browser_os
    ON tnnt.sessions (browser_name, os_name)
 WHERE browser_name IS NOT NULL;

-- 만료된 세션 정리 작업 최적화
CREATE INDEX IF NOT EXISTS ix_sessions__expired_cleanup
    ON tnnt.sessions (session_close, status)
 WHERE status IN ('EXPIRED', 'TERMINATED');


-- ========================================
-- 테넌트 사용자 로그인 이력 (보안 감사용)
-- ========================================
CREATE TABLE IF NOT EXISTS tnnt.login_logs 
(
    id                          UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),	-- 로그인 이력 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE    NOT NULL DEFAULT CURRENT_TIMESTAMP,     -- 생성일시
    created_by                  UUID,                                                               -- 생성자 ID
    updated_at                  TIMESTAMP WITH TIME ZONE,     -- 수정일시
    updated_by                  UUID,                                                               -- 수정자 ID
    
    -- 멀티테넌트 식별
    tenant_id                   UUID                        NOT NULL,                               -- 테넌트 ID
    
    user_id                     UUID,                                                               -- 테넌트 사용자 ID
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
    
    -- 디바이스 정보
    device_type                 VARCHAR(50),                                                        -- 디바이스 타입 (desktop, mobile, tablet)
    device_fingerprint          VARCHAR(255),                                                       -- 디바이스 핑거프린트
    
    -- Foreign Keys
    CONSTRAINT fk_login_logs__user_id            FOREIGN KEY (user_id) REFERENCES tnnt.users(id) ON DELETE SET NULL,
    
    -- Unique Constraints
    
    -- Check Constraints
    CONSTRAINT ck_login_logs__attempt_type       CHECK (attempt_type IN ('LOGIN', 'LOGOUT', 'FAILED_LOGIN', 'LOCKED', 'PASSWORD_RESET', 'SESSION_EXPIRED'))
);

COMMENT ON TABLE  tnnt.login_logs                     		IS '테넌트 사용자 로그인 이력 관리 (보안 감사용)';
COMMENT ON COLUMN tnnt.login_logs.id                  		IS '로그인 이력 고유 식별자';
COMMENT ON COLUMN tnnt.login_logs.created_at          		IS '생성일시';
COMMENT ON COLUMN tnnt.login_logs.created_by          		IS '생성자 ID';
COMMENT ON COLUMN tnnt.login_logs.updated_at          		IS '수정일시';
COMMENT ON COLUMN tnnt.login_logs.updated_by          		IS '수정자 ID';
COMMENT ON COLUMN tnnt.login_logs.tenant_id           		IS '테넌트 ID';
COMMENT ON COLUMN tnnt.login_logs.user_id             		IS '테넌트 사용자 ID';
COMMENT ON COLUMN tnnt.login_logs.username            		IS '사용자명 (삭제된 사용자 이력 보존용)';
COMMENT ON COLUMN tnnt.login_logs.attempt_type        		IS '시도 타입 (LOGIN, LOGOUT, FAILED_LOGIN, LOCKED, PASSWORD_RESET, SESSION_EXPIRED)';
COMMENT ON COLUMN tnnt.login_logs.success             		IS '성공 여부';
COMMENT ON COLUMN tnnt.login_logs.failure_reason      		IS '실패 사유 (INVALID_PASSWORD, ACCOUNT_LOCKED, MFA_FAILED)';
COMMENT ON COLUMN tnnt.login_logs.session_id          		IS '세션 ID';
COMMENT ON COLUMN tnnt.login_logs.ip_address          		IS 'IP 주소';
COMMENT ON COLUMN tnnt.login_logs.user_agent          		IS '사용자 에이전트';
COMMENT ON COLUMN tnnt.login_logs.country_code        		IS '국가 코드';
COMMENT ON COLUMN tnnt.login_logs.city                		IS '도시명';
COMMENT ON COLUMN tnnt.login_logs.mfa_used            		IS 'MFA 사용 여부';
COMMENT ON COLUMN tnnt.login_logs.mfa_method          		IS 'MFA 방법 (TOTP, SMS, EMAIL)';
COMMENT ON COLUMN tnnt.login_logs.device_type         		IS '디바이스 타입 (desktop, mobile, tablet)';
COMMENT ON COLUMN tnnt.login_logs.device_fingerprint  		IS '디바이스 핑거프린트';

-- 테넌트 ID 조회용 인덱스 (RLS 정책용)
CREATE INDEX IF NOT EXISTS ix_tnnt_login_logs__tenant_id
    ON tnnt.login_logs(tenant_id);

-- 사용자 ID 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_tnnt_login_logs__user_id
    ON tnnt.login_logs(tenant_id, user_id)
 WHERE user_id IS NOT NULL;

-- 생성일시 조회용 인덱스 (시간 순 조회)
CREATE INDEX IF NOT EXISTS ix_tnnt_login_logs__created_at
    ON tnnt.login_logs(tenant_id, created_at DESC);

-- 시도 타입별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_tnnt_login_logs__attempt_type
    ON tnnt.login_logs(tenant_id, attempt_type);

-- 성공 여부별 조회용 인덱스 (실패 로그인 추적용)
CREATE INDEX IF NOT EXISTS ix_tnnt_login_logs__success
    ON tnnt.login_logs(tenant_id, success, created_at DESC)
 WHERE success = FALSE;

-- IP 주소 조회용 인덱스 (보안 모니터링용)
CREATE INDEX IF NOT EXISTS ix_tnnt_login_logs__ip_address
    ON tnnt.login_logs(tenant_id, ip_address, created_at DESC);

-- 사용자명 조회용 인덱스 (삭제된 사용자 추적용)
CREATE INDEX IF NOT EXISTS ix_tnnt_login_logs__username
    ON tnnt.login_logs(tenant_id, username)
 WHERE username IS NOT NULL;

-- 실패 사유별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_tnnt_login_logs__failure_reason
    ON tnnt.login_logs(tenant_id, failure_reason, created_at DESC)
 WHERE failure_reason IS NOT NULL;

-- MFA 사용 현황 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_tnnt_login_logs__mfa_used
    ON tnnt.login_logs(tenant_id, mfa_used, created_at DESC)
 WHERE mfa_used = TRUE;

-- 디바이스 핑거프린트 조회용 인덱스 (디바이스 추적용)
CREATE INDEX IF NOT EXISTS ix_tnnt_login_logs__device_fingerprint
    ON tnnt.login_logs(tenant_id, device_fingerprint, created_at DESC)
 WHERE device_fingerprint IS NOT NULL;

-- 복합 조회용 인덱스 (사용자 + 시간)
CREATE INDEX IF NOT EXISTS ix_tnnt_login_logs__user_created
    ON tnnt.login_logs(tenant_id, user_id, created_at DESC)
 WHERE user_id IS NOT NULL;