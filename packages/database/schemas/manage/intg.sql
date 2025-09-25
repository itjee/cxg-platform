-- ============================================================================
-- 12. 외부 연동 (External Integrations) -> intg
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS intg;

COMMENT ON SCHEMA intg
IS 'INTG: 외부 연동 스키마: 서드파티 연동 엔드포인트 및 API Rate Limit 메타.';

-- ============================================================================
-- 외부 시스템 연동 테이블
-- ============================================================================
CREATE TABLE IF NOT EXISTS intg.apis
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 외부 연동 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 연동 설정 생성 일시
    created_by                  UUID,                                                              	-- 연동 설정 생성자 UUID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 연동 설정 수정 일시
    updated_by                  UUID,                                                              	-- 연동 설정 수정자 UUID

    -- 테넌트 연결
    tenant_id                   UUID,                                                              	-- 테넌트별 연동인 경우 테넌트 ID

    -- 연동 기본 정보
    api_type            		VARCHAR(50)              NOT NULL,                                 	-- 연동 유형 (PAYMENT_GATEWAY/CRM/ERP/EMAIL_SERVICE 등)
    api_name            		VARCHAR(200)             NOT NULL,                                 	-- 연동 이름
    provider               		VARCHAR(100)             NOT NULL,                                 	-- 서비스 제공업체명

    -- API 연결 설정
    api_endpoint                VARCHAR(500),                                                      	-- API 엔드포인트 URL
    api_version                 VARCHAR(20),                                                       	-- API 버전
    authentication_type         VARCHAR(50)              NOT NULL DEFAULT 'API_KEY',              	-- 인증 방식

    -- 암호화된 인증 정보
    api_key                		VARCHAR(255),                                                      	-- 암호화된 API 키
    client_id                   VARCHAR(255),                                                      	-- OAuth 클라이언트 ID
    client_secret          		VARCHAR(255),                                                      	-- 암호화된 클라이언트 시크릿
    access_token           		VARCHAR(255),                                                      	-- 암호화된 액세스 토큰
    refresh_token         	 	VARCHAR(255),                                                      	-- 암호화된 리프레시 토큰
    token_expires_at            TIMESTAMP WITH TIME ZONE,                                          	-- 토큰 만료 시각

    -- 연동 상세 설정
    configuration               JSONB                    NOT NULL DEFAULT '{}',                   	-- 연동별 상세 설정
    mapping_rules               JSONB                    NOT NULL DEFAULT '{}',                   	-- 데이터 매핑 규칙
    sync_frequency              VARCHAR(20)              NOT NULL DEFAULT 'HOURLY',               	-- 동기화 주기

    -- 상태 모니터링
    last_sync_at                TIMESTAMP WITH TIME ZONE,                                          	-- 마지막 동기화 시각
    last_success_at             TIMESTAMP WITH TIME ZONE,                                         	-- 마지막 성공 시각
    last_error_at               TIMESTAMP WITH TIME ZONE,                                          	-- 마지막 오류 발생 시각
    last_error_message          TEXT,                                                              	-- 마지막 오류 메시지
    consecutive_failures        INTEGER                  NOT NULL DEFAULT 0,                      	-- 연속 실패 횟수

    -- 사용 통계
    total_requests              INTEGER                  NOT NULL DEFAULT 0,                      	-- 총 요청 수
    successful_requests         INTEGER                  NOT NULL DEFAULT 0,                      	-- 성공 요청 수
    failed_requests             INTEGER                  NOT NULL DEFAULT 0,                      	-- 실패 요청 수

    -- 제한 설정
    rate_limit                  INTEGER                  NOT NULL DEFAULT 100,                    	-- 분당 요청 제한
    daily_limit         		INTEGER                  NOT NULL DEFAULT 10000,                  	-- 일일 요청 제한

    -- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',               	-- 연동 상태

    -- 논리적 삭제 플래그
    deleted                     BOOLEAN                  NOT NULL DEFAULT FALSE,                   	-- 논리적 삭제 플래그

    -- 제약조건
    CONSTRAINT fk_apis__tenant_id 	     				FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,

    CONSTRAINT ck_apis__api_type 						CHECK (api_type IN ('PAYMENT_GATEWAY', 'CRM', 'ERP', 'EMAIL_SERVICE', 'SMS_SERVICE', 'STORAGE', 'ANALYTICS', 'NOTIFICATION', 'IDENTITY_PROVIDER')),
    CONSTRAINT ck_apis__authentication_type 			CHECK (authentication_type IN ('API_KEY', 'OAUTH2', 'BASIC_AUTH', 'JWT', 'BEARER_TOKEN')),
    CONSTRAINT ck_apis__sync_frequency         			CHECK (sync_frequency IN ('REALTIME', 'HOURLY', 'DAILY', 'WEEKLY', 'MANUAL')),
    CONSTRAINT ck_apis__status         					CHECK (status IN ('ACTIVE', 'INACTIVE', 'ERROR', 'SUSPENDED')),
    CONSTRAINT ck_apis__consecutive_failures_positive	CHECK (consecutive_failures >= 0),
    CONSTRAINT ck_apis__requests_statistics_positive   	CHECK (total_requests >= 0 AND successful_requests >= 0 AND failed_requests >= 0),
    CONSTRAINT ck_apis__requests_statistics_logic      	CHECK (total_requests = successful_requests + failed_requests),
    CONSTRAINT ck_apis__rate_limits_positive         	CHECK (rate_limit > 0 AND daily_limit > 0),
    CONSTRAINT ck_apis__token_expiry_logic         		CHECK (authentication_type != 'OAUTH2' OR token_expires_at IS NOT NULL)
);

-- 컬럼별 코멘트 추가
COMMENT ON TABLE  intg.apis 						IS '외부 시스템 연동 - 결제, CRM, ERP 등 외부 서비스와의 API 연동 설정 및 상태 관리';
COMMENT ON COLUMN intg.apis.id 						IS '외부 연동 고유 식별자 (UUID)';
COMMENT ON COLUMN intg.apis.created_at 				IS '연동 설정 생성 일시';
COMMENT ON COLUMN intg.apis.created_by 				IS '연동 설정 생성자 UUID (시스템 관리자)';
COMMENT ON COLUMN intg.apis.updated_at 				IS '연동 설정 수정 일시';
COMMENT ON COLUMN intg.apis.updated_by 				IS '연동 설정 수정자 UUID';
COMMENT ON COLUMN intg.apis.tenant_id 				IS '테넌트별 연동인 경우 테넌트 ID - 전역 연동인 경우 NULL';
COMMENT ON COLUMN intg.apis.api_type 				IS '연동 유형 - 결제 게이트웨이, CRM, ERP, 이메일 서비스 등';
COMMENT ON COLUMN intg.apis.api_name 				IS '연동 이름 - 관리자가 식별하기 위한 친숙한 이름';
COMMENT ON COLUMN intg.apis.provider 				IS '서비스 제공업체명 - Stripe, Salesforce, AWS 등 실제 서비스 제공자';
COMMENT ON COLUMN intg.apis.api_endpoint 			IS 'API 엔드포인트 URL - 외부 서비스 API의 기본 URL';
COMMENT ON COLUMN intg.apis.api_version 			IS 'API 버전 - 사용하는 외부 서비스 API의 버전';
COMMENT ON COLUMN intg.apis.authentication_type 	IS '인증 방식 - API 키, OAuth2, 기본 인증, JWT 등';
COMMENT ON COLUMN intg.apis.api_key 				IS '암호화된 API 키 - 보안을 위해 해시화하여 저장';
COMMENT ON COLUMN intg.apis.client_id 				IS 'OAuth 클라이언트 ID - OAuth 인증 시 사용하는 클라이언트 식별자';
COMMENT ON COLUMN intg.apis.client_secret 			IS '암호화된 클라이언트 시크릿 - OAuth 클라이언트 비밀키 해시';
COMMENT ON COLUMN intg.apis.access_token 			IS '암호화된 액세스 토큰 - API 호출 시 사용하는 토큰 해시';
COMMENT ON COLUMN intg.apis.refresh_token 			IS '암호화된 리프레시 토큰 - 액세스 토큰 갱신용 토큰 해시';
COMMENT ON COLUMN intg.apis.token_expires_at 		IS '토큰 만료 시각 - 액세스 토큰이 만료되는 시간';
COMMENT ON COLUMN intg.apis.configuration 			IS '연동별 상세 설정 - JSON 형태의 서비스별 설정값들';
COMMENT ON COLUMN intg.apis.mapping_rules 			IS '데이터 매핑 규칙 - JSON 형태의 데이터 변환 및 매핑 규칙';
COMMENT ON COLUMN intg.apis.sync_frequency 			IS '동기화 주기 - 실시간, 시간별, 일별, 주별, 수동 중 선택';
COMMENT ON COLUMN intg.apis.last_sync_at 			IS '마지막 동기화 시각 - 가장 최근에 동기화를 시도한 시간';
COMMENT ON COLUMN intg.apis.last_success_at 		IS '마지막 성공 시각 - 가장 최근에 성공한 동기화 시간';
COMMENT ON COLUMN intg.apis.last_error_at 			IS '마지막 오류 발생 시각 - 가장 최근에 오류가 발생한 시간';
COMMENT ON COLUMN intg.apis.last_error_message 		IS '마지막 오류 메시지 - 가장 최근 오류의 상세 내용';
COMMENT ON COLUMN intg.apis.consecutive_failures 	IS '연속 실패 횟수 - 연속으로 실패한 동기화 시도 횟수';
COMMENT ON COLUMN intg.apis.total_requests 			IS '총 요청 수 - 이 연동을 통해 발생한 전체 API 요청 수';
COMMENT ON COLUMN intg.apis.successful_requests 	IS '성공 요청 수 - 성공한 API 요청 수';
COMMENT ON COLUMN intg.apis.failed_requests 		IS '실패 요청 수 - 실패한 API 요청 수';
COMMENT ON COLUMN intg.apis.rate_limit 				IS '분당 요청 제한 - 외부 서비스 호출 시 분당 최대 요청 수';
COMMENT ON COLUMN intg.apis.daily_limit 			IS '일일 요청 제한 - 외부 서비스 호출 시 일일 최대 요청 수';
COMMENT ON COLUMN intg.apis.status 					IS '연동 상태 - 활성, 비활성, 오류, 중단 중 하나';
COMMENT ON COLUMN intg.apis.deleted 				IS '논리적 삭제 플래그 - 실제 삭제 대신 사용하는 소프트 딜리트';

-- ======================================================
-- intg.apis 테이블 인덱스 정의
-- 목적: 연동 조회, 동기화, 오류 모니터링, 성능 분석 최적화
-- ======================================================

-- 활성 연동 조회용 인덱스
-- 설명: 상태가 ACTIVE인 연동 조회 최적화, 가장 빈번한 조회 패턴
CREATE INDEX IF NOT EXISTS ix_apis__active_integrations
    ON intg.apis (status, api_type)
 WHERE deleted = FALSE
   AND status = 'ACTIVE';

-- 테넌트별 연동 조회용 인덱스
-- 설명: 특정 테넌트에 속한 연동 조회 최적화
CREATE INDEX IF NOT EXISTS ix_apis__tenant_integrations
    ON intg.apis (tenant_id, api_type, status)
 WHERE deleted = FALSE;

-- 연동 유형별 조회용 인덱스
-- 설명: api_type 및 provider별 연동 조회 최적화
CREATE INDEX IF NOT EXISTS ix_apis__api_type_management
    ON intg.apis (api_type, provider, status)
 WHERE deleted = FALSE;

-- 동기화 스케줄 관리용 인덱스
-- 설명: 자동 동기화 대상 연동 조회 최적화
CREATE INDEX IF NOT EXISTS ix_apis__sync_scheduling
    ON intg.apis (sync_frequency, last_sync_at, status)
 WHERE deleted = FALSE
   AND status = 'ACTIVE'
   AND sync_frequency != 'MANUAL';

-- 오류 모니터링용 인덱스
-- 설명: 오류 상태 또는 연속 실패가 있는 연동 관리 최적화
CREATE INDEX IF NOT EXISTS ix_apis__error_monitoring
    ON intg.apis (status, consecutive_failures, last_error_at DESC)
 WHERE deleted = FALSE
   AND (status = 'ERROR' OR consecutive_failures > 0);

-- 토큰 만료 관리용 인덱스
-- 설명: OAuth2 인증 연동의 토큰 만료 모니터링 최적화
CREATE INDEX IF NOT EXISTS ix_apis__token_expiry_management
    ON intg.apis (authentication_type, token_expires_at, status)
 WHERE deleted = FALSE
   AND authentication_type = 'OAUTH2';

-- 성능 모니터링용 인덱스
-- 설명: API 사용량 분석 최적화, 사용 이력이 있는 연동만 대상
CREATE INDEX IF NOT EXISTS ix_apis__performance_monitoring
    ON intg.apis (api_type, total_requests DESC, successful_requests)
 WHERE deleted = FALSE
   AND total_requests > 0;

-- 제공업체별 연동 조회용 인덱스
-- 설명: provider별 연동 조회 최적화
CREATE INDEX IF NOT EXISTS ix_apis__provider_management
    ON intg.apis (provider, api_type, status)
 WHERE deleted = FALSE;

-- 연동명 검색용 인덱스
-- 설명: api_name으로 연동 조회 최적화
CREATE INDEX IF NOT EXISTS ix_apis__api_name
    ON intg.apis (api_name)
 WHERE deleted = FALSE;

-- 생성일자 기준 조회용 인덱스
-- 설명: 최근 생성된 연동 조회 최적화
CREATE INDEX IF NOT EXISTS ix_apis__created_at
    ON intg.apis (created_at DESC)
 WHERE deleted = FALSE;

-- 마지막 성공 시각 기준 조회용 인덱스
-- 설명: 마지막 성공 시각으로 동기화 상태 모니터링 최적화
CREATE INDEX IF NOT EXISTS ix_apis__last_success_monitoring
    ON intg.apis (last_success_at DESC, api_type)
 WHERE deleted = FALSE
   AND status = 'ACTIVE';

-- 실패율 분석용 인덱스
-- 설명: 실패가 발생한 연동 조회 및 실패율 분석 최적화
CREATE INDEX IF NOT EXISTS ix_apis__failure_rate_analysis
    ON intg.apis (failed_requests, total_requests, api_type)
 WHERE deleted = FALSE
   AND total_requests > 0
   AND failed_requests > 0;

-- 요청 제한 모니터링용 인덱스
-- 설명: rate_limit, daily_limit 관리 및 API 사용 제한 모니터링 최적화
CREATE INDEX IF NOT EXISTS ix_apis__rate_limit_monitoring
    ON intg.apis (rate_limit, daily_limit, total_requests)
 WHERE deleted = FALSE
   AND status = 'ACTIVE';

-- GIN 인덱스: 연동 설정 검색용
-- 설명: configuration JSON 검색 최적화
CREATE INDEX IF NOT EXISTS ix_apis__configuration_gin
    ON intg.apis USING GIN (configuration)
 WHERE deleted = FALSE
   AND configuration != '{}';

-- GIN 인덱스: 매핑 규칙 검색용
-- 설명: mapping_rules JSON 검색 최적화
CREATE INDEX IF NOT EXISTS ix_apis__mapping_rules_gin
    ON intg.apis USING GIN (mapping_rules)
 WHERE deleted = FALSE
   AND mapping_rules != '{}';


-- ============================================================================
-- 웹훅 엔드포인트
-- ============================================================================
CREATE TABLE IF NOT EXISTS intg.webhooks
(
   id 							UUID 					 PRIMARY KEY DEFAULT gen_random_uuid(),		-- 웹훅 엔드포인트 고유 식별자
   created_at 					TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 엔드포인트 생성 일시
   created_by 					UUID,                                                        		-- 엔드포인트 생성자 UUID
   updated_at 					TIMESTAMP WITH TIME ZONE,                                    		-- 엔드포인트 수정 일시
   updated_by 					UUID,                                                       		-- 엔드포인트 수정자 UUID

   tenant_id 					UUID 					 NOT NULL,                                  -- 테넌트 ID (다중 테넌트 구분)
   integration_id 				UUID,                                                    			-- 연동 서비스 ID (외부 통합 서비스와 연관)

   -- 웹훅 기본 정보
   webhook_name 				VARCHAR(200)			 NOT NULL,                                  -- 웹훅 엔드포인트 이름
   webhook_url 					VARCHAR(500)			 NOT NULL,                                  -- 웹훅을 받을 대상 URL
   description 					TEXT,                                                       		-- 웹훅 엔드포인트 설명

   -- 이벤트 설정
   event_types 					TEXT[]					 NOT NULL,                                  -- 구독할 이벤트 유형 목록
   event_filters 				JSONB					 DEFAULT '{}',                              -- 이벤트 필터링 조건 (JSON 형태)

   -- 보안 설정
   secret_key_hash 				VARCHAR(255),                                           			-- 서명 검증용 시크릿 키 해시값
   signature_algorithm 			VARCHAR(20)				 DEFAULT 'HMAC_SHA256',                  	-- 웹훅 서명 알고리즘

   -- HTTP 전송 설정
   http_method 					VARCHAR(10)				 DEFAULT 'POST',                            -- HTTP 요청 메소드
   content_type 				VARCHAR(50)				 DEFAULT 'application/json',                -- HTTP 컨텐츠 타입
   custom_headers 				JSONB					 DEFAULT '{}',                              -- 커스텀 HTTP 헤더 (JSON 형태)
   timeout 						INTEGER					 DEFAULT 30,                                -- HTTP 요청 타임아웃 (초)

   -- 재시도 설정
   max_retry_attempts 			INTEGER					 DEFAULT 3,                                 -- 최대 재시도 횟수
   retry_backoff 				INTEGER					 DEFAULT 60,                               	-- 재시도 간격 (초)

   -- 전송 통계
   total_deliveries 			INTEGER					 DEFAULT 0,                                 -- 총 웹훅 전송 횟수
   successful_deliveries 		INTEGER					 DEFAULT 0,                                	-- 성공한 웹훅 전송 횟수
   failed_deliveries 			INTEGER					 DEFAULT 0,                                 -- 실패한 웹훅 전송 횟수
   last_delivery_at 			TIMESTAMP WITH TIME ZONE,                              				-- 마지막 웹훅 전송 시각
   last_success_at 				TIMESTAMP WITH TIME ZONE,                               			-- 마지막 성공 전송 시각
   last_failure_at 				TIMESTAMP WITH TIME ZONE,                               			-- 마지막 실패 전송 시각
   last_failure_reason 			TEXT,                                               				-- 마지막 실패 사유

   -- 상태 관리
   enabled 						BOOLEAN					 DEFAULT TRUE,                              -- 웹훅 활성화 여부
   deleted 						BOOLEAN					 NOT NULL DEFAULT FALSE,                    -- 논리적 삭제 여부

   CONSTRAINT fk_webhooks__tenant_id       		FOREIGN KEY (tenant_id) 		REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,
   CONSTRAINT fk_webhooks__integration_id		FOREIGN KEY (integration_id) 	REFERENCES intg.apis(id)	ON DELETE CASCADE,

   CONSTRAINT ck_webhooks__http_method      	CHECK (http_method IN ('POST', 'PUT', 'PATCH')),
   CONSTRAINT ck_webhooks__signature_algorithm	CHECK (signature_algorithm IN ('HMAC_SHA256', 'HMAC_SHA512'))
);

-- 테이블 및 컬럼 주석
COMMENT ON TABLE  intg.webhooks 						IS '웹훅 엔드포인트 - 외부 시스템으로 이벤트 알림을 전송하는 웹훅 관리';
COMMENT ON COLUMN intg.webhooks.id 						IS '웹훅 엔드포인트 고유 식별자';
COMMENT ON COLUMN intg.webhooks.created_at 				IS '엔드포인트 생성 일시';
COMMENT ON COLUMN intg.webhooks.created_by 				IS '엔드포인트 생성자 UUID';
COMMENT ON COLUMN intg.webhooks.updated_at 				IS '엔드포인트 수정 일시';
COMMENT ON COLUMN intg.webhooks.updated_by 				IS '엔드포인트 수정자 UUID';
COMMENT ON COLUMN intg.webhooks.tenant_id 				IS '테넌트 ID (다중 테넌트 구분)';
COMMENT ON COLUMN intg.webhooks.integration_id 			IS '연동 서비스 ID (외부 통합 서비스와 연관)';
COMMENT ON COLUMN intg.webhooks.webhook_name 			IS '웹훅 엔드포인트 이름';
COMMENT ON COLUMN intg.webhooks.webhook_url 			IS '웹훅을 받을 대상 URL';
COMMENT ON COLUMN intg.webhooks.description 			IS '웹훅 엔드포인트 설명';
COMMENT ON COLUMN intg.webhooks.event_types 			IS '구독할 이벤트 유형 목록 (배열)';
COMMENT ON COLUMN intg.webhooks.event_filters 			IS '이벤트 필터링 조건 (JSON 형태)';
COMMENT ON COLUMN intg.webhooks.secret_key_hash 		IS '서명 검증용 시크릿 키 해시값';
COMMENT ON COLUMN intg.webhooks.signature_algorithm 	IS '웹훅 서명 알고리즘 (HMAC_SHA256, HMAC_SHA512)';
COMMENT ON COLUMN intg.webhooks.http_method 			IS 'HTTP 요청 메소드 (POST, PUT, PATCH)';
COMMENT ON COLUMN intg.webhooks.content_type 			IS 'HTTP 컨텐츠 타입';
COMMENT ON COLUMN intg.webhooks.custom_headers 			IS '커스텀 HTTP 헤더 (JSON 형태)';
COMMENT ON COLUMN intg.webhooks.timeout 				IS 'HTTP 요청 타임아웃 (초)';
COMMENT ON COLUMN intg.webhooks.max_retry_attempts 		IS '최대 재시도 횟수';
COMMENT ON COLUMN intg.webhooks.retry_backoff 			IS '재시도 간격 (초)';
COMMENT ON COLUMN intg.webhooks.total_deliveries 		IS '총 웹훅 전송 횟수';
COMMENT ON COLUMN intg.webhooks.successful_deliveries 	IS '성공한 웹훅 전송 횟수';
COMMENT ON COLUMN intg.webhooks.failed_deliveries 		IS '실패한 웹훅 전송 횟수';
COMMENT ON COLUMN intg.webhooks.last_delivery_at 		IS '마지막 웹훅 전송 시각';
COMMENT ON COLUMN intg.webhooks.last_success_at 		IS '마지막 성공 전송 시각';
COMMENT ON COLUMN intg.webhooks.last_failure_at 		IS '마지막 실패 전송 시각';
COMMENT ON COLUMN intg.webhooks.last_failure_reason 	IS '마지막 실패 사유';
COMMENT ON COLUMN intg.webhooks.enabled 				IS '웹훅 활성화 여부';
COMMENT ON COLUMN intg.webhooks.deleted 				IS '논리적 삭제 여부';

-- 인덱스

-- 활성 웹훅 엔드포인트만 인덱싱
CREATE INDEX IF NOT EXISTS ix_webhooks__tenant_id
    ON intg.webhooks (tenant_id)
 WHERE deleted = FALSE;

-- 활성 웹훅 엔드포인트만 인덱싱
CREATE INDEX IF NOT EXISTS ix_webhooks__integration_id
    ON intg.webhooks (integration_id)
 WHERE deleted = FALSE;

-- 이벤트 타입 배열 검색용
CREATE INDEX IF NOT EXISTS ix_webhooks__event_types
    ON intg.webhooks USING GIN (event_types)
 WHERE deleted = FALSE;

-- 활성/비활성 및 삭제 상태 조회용
CREATE INDEX IF NOT EXISTS ix_webhooks__enabled_deleted
    ON intg.webhooks (enabled, deleted);

-- 마지막 전송 시각 기준 정렬용
CREATE INDEX IF NOT EXISTS ix_webhooks__last_delivery_at
    ON intg.webhooks (last_delivery_at)
 WHERE deleted = FALSE;

-- 엔드포인트 이름 검색용
CREATE INDEX IF NOT EXISTS ix_webhooks__webhook_name
    ON intg.webhooks (webhook_name)
 WHERE deleted = FALSE;

-- ============================================================================
-- API 호출 제한
-- ============================================================================
CREATE TABLE IF NOT EXISTS intg.rate_limits
(
   id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),    	-- API 호출 제한 고유 식별자
   created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,         -- 제한 규칙 생성 일시
   created_by                  UUID,                                                              	-- 제한 규칙 생성자 UUID
   updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 제한 규칙 수정 일시
   updated_by                  UUID,                                                              	-- 제한 규칙 수정자 UUID

   -- 제한 대상
   tenant_id                   UUID,                                                              	-- 테넌트별 제한 대상 ID
   user_id                     UUID,                                                              	-- 사용자별 제한 대상 ID
   api_key_id                  UUID,                                                              	-- API 키별 제한 대상 ID
   client_ip                   VARCHAR(45),                                                       	-- IP별 제한 대상 주소

   -- 제한 설정
   limit_type                  VARCHAR(50)              NOT NULL,                                 	-- 제한 유형 (분당/시간당/일당 요청 수)
   limit_value                 INTEGER                  NOT NULL,                                 	-- 제한 임계값
   window_size                 INTEGER                  NOT NULL,                                 	-- 시간 윈도우 크기 (초)

   -- 현재 사용량 추적
   current_usage               INTEGER                  DEFAULT 0,                                	-- 현재 윈도우 내 사용량
   window_start                TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,                           	-- 현재 윈도우 시작 시각

   -- 제한 초과 처리
   action_on_exceed            VARCHAR(20)              DEFAULT 'BLOCK' NOT NULL,                	-- 제한 초과 시 조치 방법
   burst_allowance             INTEGER                  DEFAULT 0,                                	-- 버스트 트래픽 허용량

   -- 통계 및 모니터링
   last_access_at              TIMESTAMP WITH TIME ZONE,                                          	-- 마지막 API 접근 시각
   total_requests              INTEGER                  DEFAULT 0,                                	-- 총 요청 수
   blocked_requests            INTEGER                  DEFAULT 0,                                	-- 차단된 요청 수

   -- 만료 관리
   expires_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 제한 규칙 만료 시각
   deleted                     BOOLEAN                  DEFAULT FALSE NOT NULL,                   	-- 논리적 삭제 여부

   CONSTRAINT fk_rate_limits__tenant_id       	FOREIGN KEY (tenant_id) 	REFERENCES tnnt.tenants(id)		ON DELETE CASCADE,
   CONSTRAINT fk_rate_limits__api_key_id      	FOREIGN KEY (api_key_id) 	REFERENCES tnnt.api_keys(id)	ON DELETE CASCADE,
   CONSTRAINT fk_rate_limits__user_id       	FOREIGN KEY (user_id) 		REFERENCES tnnt.users(id)		ON DELETE CASCADE,

   CONSTRAINT ck_rate_limits__action_on_exceed 	CHECK (action_on_exceed IN ('BLOCK', 'THROTTLE', 'LOG_ONLY')),
   CONSTRAINT ck_rate_limits__limit_type        CHECK (limit_type IN ('REQUESTS_PER_MINUTE', 'REQUESTS_PER_HOUR', 'REQUESTS_PER_DAY', 'BANDWIDTH'))
);

-- 테이블 및 컬럼 주석
COMMENT ON TABLE  intg.rate_limits						IS 'API 호출 제한 - 테넌트, 사용자, IP별 API 사용량 제한 및 모니터링';
COMMENT ON COLUMN intg.rate_limits.id               	IS 'API 호출 제한 고유 식별자';
COMMENT ON COLUMN intg.rate_limits.created_at       	IS '제한 규칙 생성 일시';
COMMENT ON COLUMN intg.rate_limits.created_by       	IS '제한 규칙 생성자 UUID';
COMMENT ON COLUMN intg.rate_limits.updated_at       	IS '제한 규칙 수정 일시';
COMMENT ON COLUMN intg.rate_limits.updated_by       	IS '제한 규칙 수정자 UUID';
COMMENT ON COLUMN intg.rate_limits.tenant_id        	IS '테넌트별 제한 대상 ID';
COMMENT ON COLUMN intg.rate_limits.api_key_id       	IS 'API 키별 제한 대상 ID';
COMMENT ON COLUMN intg.rate_limits.user_id          	IS '사용자별 제한 대상 ID';
COMMENT ON COLUMN intg.rate_limits.client_ip        	IS 'IP별 제한 대상 주소 (IPv4/IPv6)';
COMMENT ON COLUMN intg.rate_limits.limit_type       	IS '제한 유형 (REQUESTS_PER_MINUTE, REQUESTS_PER_HOUR, REQUESTS_PER_DAY, BANDWIDTH)';
COMMENT ON COLUMN intg.rate_limits.limit_value      	IS '제한 임계값 (요청 수 또는 대역폭)';
COMMENT ON COLUMN intg.rate_limits.window_size      	IS '시간 윈도우 크기 (초 단위)';
COMMENT ON COLUMN intg.rate_limits.current_usage    	IS '현재 윈도우 내 사용량';
COMMENT ON COLUMN intg.rate_limits.window_start     	IS '현재 윈도우 시작 시각';
COMMENT ON COLUMN intg.rate_limits.action_on_exceed 	IS '제한 초과 시 조치 방법 (BLOCK, THROTTLE, LOG_ONLY)';
COMMENT ON COLUMN intg.rate_limits.burst_allowance  	IS '버스트 트래픽 허용량';
COMMENT ON COLUMN intg.rate_limits.last_access_at   	IS '마지막 API 접근 시각';
COMMENT ON COLUMN intg.rate_limits.total_requests   	IS '총 요청 수 (누적 통계)';
COMMENT ON COLUMN intg.rate_limits.blocked_requests 	IS '차단된 요청 수 (누적 통계)';
COMMENT ON COLUMN intg.rate_limits.expires_at       	IS '제한 규칙 만료 시각';
COMMENT ON COLUMN intg.rate_limits.deleted          	IS '논리적 삭제 여부';

-- 테넌트별 제한 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_rate_limits__tenant_id
	ON intg.rate_limits (tenant_id)
 WHERE deleted = FALSE;

-- API 키별 제한 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_rate_limits__api_key_id
	ON intg.rate_limits (api_key_id)
 WHERE deleted = FALSE;

-- 사용자별 제한 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_rate_limits__user_id
	ON intg.rate_limits (user_id)
 WHERE deleted = FALSE;

-- IP별 제한 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_rate_limits__client_ip
	ON intg.rate_limits (client_ip)
 WHERE deleted = FALSE;

-- 제한 유형별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_rate_limits__limit_type
	ON intg.rate_limits (limit_type)
 WHERE deleted = FALSE;

-- 만료된 제한 규칙 정리용 인덱스
CREATE INDEX IF NOT EXISTS ix_rate_limits__expires_at
	ON intg.rate_limits (expires_at)
 WHERE deleted = FALSE
   AND expires_at IS NOT NULL;

-- 윈도우 시작 시각 기준 정리용 인덱스
CREATE INDEX IF NOT EXISTS ix_rate_limits__window_start
	ON intg.rate_limits (window_start)
 WHERE deleted = FALSE;

-- 복합 조회 최적화용 인덱스 (테넌트 + 제한 유형)
CREATE INDEX IF NOT EXISTS ix_rate_limits__tenant_limit_type
	ON intg.rate_limits (tenant_id, limit_type)
 WHERE deleted = FALSE;

-- 마지막 접근 시각 기준 통계용 인덱스
CREATE INDEX IF NOT EXISTS ix_rate_limits__last_access_at
	ON intg.rate_limits (last_access_at)
 WHERE deleted = FALSE;
