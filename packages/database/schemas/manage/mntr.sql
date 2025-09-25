-- ============================================================================
-- 5. 시스템 모니터링 (System Monitoring) -> mntr
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS mntr;

COMMENT ON SCHEMA mntr
IS 'MNTR: 시스템 모니터링 스키마: 서비스 가용성/성능 지표와 장애 이력을 관리.';

-- ============================================================================
-- 시스템 헬스체크
-- ============================================================================
CREATE TABLE IF NOT EXISTS mntr.health_checks
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 헬스체크 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,                   	-- 헬스체크 수행 일시
    created_by                  UUID,                                                              	-- 헬스체크 실행 시스템 UUID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 헬스체크 수정 일시
    updated_by                  UUID,                                                              	-- 헬스체크 수정자 UUID

	-- 모니터링 대상 정보
    service_name                VARCHAR(100)             NOT NULL,                                 	-- 모니터링 대상 서비스명 (API/DATABASE/REDIS/STORAGE 등)
    api_endpoint                VARCHAR(500),                                                      	-- 체크 대상 엔드포인트 URL
    check_type                  VARCHAR(50)              NOT NULL,                                 	-- 체크 유형 (HTTP/TCP/DATABASE/REDIS/CUSTOM)

	-- 체크 결과 정보
    response_time               INTEGER,                                                           	-- 응답 시간 (밀리초)
    error_message               TEXT,                                                              	-- 오류 메시지 (실패 시)

	-- 체크 설정 정보
    timeout_duration            INTEGER                  DEFAULT 5000,                            	-- 타임아웃 시간 (밀리초)
    expected_status_code        INTEGER,                                                           	-- HTTP 체크 시 예상 상태 코드 (200, 204 등)

	-- 확장 메타데이터
    check_data                  JSONB                    DEFAULT '{}',                            	-- 추가 체크 데이터 (헤더, 파라미터 등)

	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL,                                 	-- 헬스 상태 (HEALTHY/DEGRADED/UNHEALTHY)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT ck_health_checks__status 					CHECK (status IN ('HEALTHY', 'DEGRADED', 'UNHEALTHY')),
    CONSTRAINT ck_health_checks__check_type 				CHECK (check_type IN ('HTTP', 'TCP', 'DATABASE', 'REDIS', 'ELASTICSEARCH', 'CUSTOM')),
    CONSTRAINT ck_health_checks__response_time 				CHECK (response_time IS NULL OR response_time >= 0),
    CONSTRAINT ck_health_checks__timeout_duration 			CHECK (timeout_duration > 0),
    CONSTRAINT ck_health_checks__expected_status_code 		CHECK (expected_status_code IS NULL OR (expected_status_code >= 100 AND expected_status_code < 600))
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  mntr.health_checks						IS '시스템 헬스체크 - 각 서비스 컴포넌트의 상태 모니터링과 가용성 추적을 통한 시스템 안정성 관리';
COMMENT ON COLUMN mntr.health_checks.id 					IS '헬스체크 고유 식별자 - UUID 형태의 기본키, 각 헬스체크 실행을 구분하는 고유값';
COMMENT ON COLUMN mntr.health_checks.created_at 			IS '헬스체크 수행 일시 - 헬스체크가 실행된 시점의 타임스탬프';
COMMENT ON COLUMN mntr.health_checks.created_by 			IS '헬스체크 실행 시스템 UUID - 헬스체크를 수행한 모니터링 시스템 또는 스케줄러의 식별자';
COMMENT ON COLUMN mntr.health_checks.updated_at 			IS '헬스체크 수정 일시 - 헬스체크 결과가 수정된 시점의 타임스탬프';
COMMENT ON COLUMN mntr.health_checks.updated_by 			IS '헬스체크 수정자 UUID - 헬스체크 결과를 수정한 시스템 또는 관리자의 식별자';
COMMENT ON COLUMN mntr.health_checks.service_name 			IS '모니터링 대상 서비스명 - API(웹서비스), DATABASE(데이터베이스), REDIS(캐시), STORAGE(스토리지), QUEUE(메시지큐) 등 서비스 구분';
COMMENT ON COLUMN mntr.health_checks.api_endpoint 			IS '체크 대상 엔드포인트 URL - HTTP 헬스체크 시 호출할 URL 또는 TCP 연결할 주소 (예: https://api.example.com/health, tcp://redis:6379)';
COMMENT ON COLUMN mntr.health_checks.check_type	 			IS '체크 유형 - HTTP(웹서비스), TCP(포트연결), DATABASE(DB연결), REDIS(Redis연결), ELASTICSEARCH(검색엔진), CUSTOM(사용자정의)';
COMMENT ON COLUMN mntr.health_checks.response_time 			IS '응답 시간 - 헬스체크 요청부터 응답까지의 소요 시간 (밀리초 단위, 성능 모니터링 지표)';
COMMENT ON COLUMN mntr.health_checks.error_message 			IS '오류 메시지 - 헬스체크 실패 시 발생한 상세 오류 내용 (연결 실패, 타임아웃, 예외 메시지 등)';
COMMENT ON COLUMN mntr.health_checks.timeout_duration 		IS '타임아웃 시간 - 헬스체크 요청 시 최대 대기 시간 (밀리초, 기본값 5초)';
COMMENT ON COLUMN mntr.health_checks.expected_status_code 	IS 'HTTP 체크 시 예상 상태 코드 - 정상으로 간주할 HTTP 응답 코드 (200, 201, 204 등, HTTP 체크 시에만 사용)';
COMMENT ON COLUMN mntr.health_checks.check_data 			IS '추가 체크 데이터 - 헬스체크 수행 시 필요한 추가 설정 정보 (JSON 형태, HTTP 헤더, 인증 정보, 쿼리 파라미터 등)';
COMMENT ON COLUMN mntr.health_checks.status 				IS '헬스 상태 - HEALTHY(정상), DEGRADED(성능저하), UNHEALTHY(장애) 서비스 가용성 상태 구분';
COMMENT ON COLUMN mntr.health_checks.deleted 				IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 서비스별 헬스체크 이력 조회 최적화
CREATE INDEX IF NOT EXISTS ix_health_checks__service_name
    ON mntr.health_checks (service_name, created_at DESC)
 WHERE deleted = FALSE;

-- 상태별 헬스체크 조회 최적화
CREATE INDEX IF NOT EXISTS ix_health_checks__status
    ON mntr.health_checks (status, created_at DESC)
 WHERE deleted = FALSE;

-- 체크 유형별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_health_checks__check_type
    ON mntr.health_checks (check_type, created_at DESC)
 WHERE deleted = FALSE;

-- 시간 기준 헬스체크 이력 조회 최적화
CREATE INDEX IF NOT EXISTS ix_health_checks__created_at
    ON mntr.health_checks (created_at DESC);

-- 장애 서비스 조회 최적화
CREATE INDEX IF NOT EXISTS ix_health_checks__unhealthy_services
    ON mntr.health_checks (status, service_name, created_at DESC)
 WHERE status = 'UNHEALTHY' AND deleted = FALSE;

-- 응답 시간별 성능 분석 최적화
CREATE INDEX IF NOT EXISTS ix_health_checks__response_time
    ON mntr.health_checks (response_time DESC NULLS LAST, created_at DESC)
 WHERE response_time IS NOT NULL AND deleted = FALSE;

-- 서비스별 상태 조회 최적화
CREATE INDEX IF NOT EXISTS ix_health_checks__service_status
    ON mntr.health_checks (service_name, status, created_at DESC)
 WHERE deleted = FALSE;

-- 엔드포인트별 헬스체크 조회 최적화
CREATE INDEX IF NOT EXISTS ix_health_checks__api_endpoint
    ON mntr.health_checks (api_endpoint, created_at DESC)
 WHERE api_endpoint IS NOT NULL AND deleted = FALSE;

-- 오류 분석을 위한 인덱스
CREATE INDEX IF NOT EXISTS ix_health_checks__error_analysis
    ON mntr.health_checks (status, error_message)
 WHERE status != 'HEALTHY' AND error_message IS NOT NULL AND deleted = FALSE;

-- 서비스별 성능 모니터링 최적화
CREATE INDEX IF NOT EXISTS ix_health_checks__performance_monitoring
    ON mntr.health_checks (service_name, response_time, created_at DESC)
 WHERE response_time IS NOT NULL AND deleted = FALSE;

-- 타임아웃 분석 최적화
CREATE INDEX IF NOT EXISTS ix_health_checks__timeout_analysis
    ON mntr.health_checks (timeout_duration, response_time, created_at DESC)
 WHERE response_time IS NOT NULL AND deleted = FALSE;

-- 체크 데이터 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_health_checks__check_data
    ON mntr.health_checks USING GIN (check_data)
 WHERE deleted = FALSE;

-- 일별 헬스체크 요약 최적화
-- CREATE INDEX IF NOT EXISTS ix_health_checks__daily_summary
--     ON mntr.health_checks (service_name, status, DATE(created_at))
--  WHERE deleted = FALSE;


-- ============================================================================
-- 장애 및 인시던트 관리
-- ============================================================================
CREATE TABLE IF NOT EXISTS mntr.incidents
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 인시던트 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,                   	-- 인시던트 등록 일시
    created_by                  UUID,                                                              	-- 인시던트 등록자 UUID (시스템 또는 관리자)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 인시던트 수정 일시
    updated_by                  UUID,                                                              	-- 인시던트 수정자 UUID

	-- 인시던트 기본 정보
    incident_no                 VARCHAR(50)              NOT NULL,                          		-- 인시던트 번호 (INC-2024-001 형식)
    title                       VARCHAR(200)             NOT NULL,                                 	-- 인시던트 제목
    description                 TEXT,                                                              	-- 인시던트 상세 설명
    severity                    VARCHAR(20)              NOT NULL DEFAULT 'MEDIUM',               	-- 심각도 (CRITICAL/HIGH/MEDIUM/LOW)

	-- 영향 범위 정보
    affected_services           TEXT[],                                                            	-- 영향받은 서비스 목록 (배열)
    affected_tenants            UUID[],                                                            	-- 영향받은 테넌트 ID 목록 (배열)
    impact_scope                VARCHAR(20)              NOT NULL DEFAULT 'PARTIAL',              	-- 영향 범위 (GLOBAL/PARTIAL/SINGLE_TENANT)

	-- 인시던트 시간 정보
    incident_start_time         TIMESTAMP WITH TIME ZONE NOT NULL,                                 	-- 인시던트 시작 시간 (장애 발생 시점)
    incident_end_time           TIMESTAMP WITH TIME ZONE,                                          	-- 인시던트 종료 시간 (서비스 복구 시점)
    detection_time              TIMESTAMP WITH TIME ZONE,                                          	-- 장애 감지 시간 (모니터링 시스템 감지 시점)
    resolution_time             TIMESTAMP WITH TIME ZONE,                                          	-- 해결 완료 시간 (근본 해결 시점)

	-- 담당자 및 에스컬레이션 정보
    assigned_to                 VARCHAR(100),                                                      	-- 담당 엔지니어 또는 팀명
    escalation_level            INTEGER                  DEFAULT 1,                               	-- 에스컬레이션 단계 (1차, 2차, 3차 등)
    resolution_summary          TEXT,                                                              	-- 해결 요약 (임시 조치 및 최종 해결 방법)

	-- 사후 분석 정보
    root_cause                  TEXT,                                                              	-- 근본 원인 분석 (RCA)
    preventive_actions          TEXT,                                                              	-- 재발 방지 조치 계획
    lessons_learned             TEXT,                                                              	-- 교훈 및 개선 사항

	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'OPEN',                 	-- 인시던트 상태 (OPEN/IN_PROGRESS/RESOLVED/CLOSED)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
	CONSTRAINT uk_incidents__incident_no		UNIQUE (incident_no),

    CONSTRAINT ck_incidents__severity 			CHECK (severity IN ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW')),
    CONSTRAINT ck_incidents__impact_scope 		CHECK (impact_scope IN ('GLOBAL', 'PARTIAL', 'SINGLE_TENANT')),
    CONSTRAINT ck_incidents__status 			CHECK (status IN ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED')),
    CONSTRAINT ck_incidents__escalation_level 	CHECK (escalation_level >= 1 AND escalation_level <= 5),
    CONSTRAINT ck_incidents__time_sequence 		CHECK (incident_end_time IS NULL OR incident_end_time >= incident_start_time),
    CONSTRAINT ck_incidents__detection_valid 	CHECK (detection_time IS NULL OR detection_time >= incident_start_time),
    CONSTRAINT ck_incidents__resolution_valid 	CHECK (resolution_time IS NULL OR resolution_time >= incident_start_time)
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  mntr.incidents						IS '장애 및 인시던트 관리 - 시스템 장애 발생부터 해결까지 전 과정 추적과 사후 분석을 통한 서비스 안정성 관리';
COMMENT ON COLUMN mntr.incidents.id 					IS '인시던트 고유 식별자 - UUID 형태의 기본키, 각 인시던트를 구분하는 고유값';
COMMENT ON COLUMN mntr.incidents.created_at 			IS '인시던트 등록 일시 - 인시던트가 시스템에 등록된 시점의 타임스탬프';
COMMENT ON COLUMN mntr.incidents.created_by 			IS '인시던트 등록자 UUID - 인시던트를 등록한 시스템, 모니터링 도구, 또는 관리자의 식별자';
COMMENT ON COLUMN mntr.incidents.updated_at 			IS '인시던트 수정 일시 - 인시던트 정보가 최종 변경된 시점의 타임스탬프';
COMMENT ON COLUMN mntr.incidents.updated_by 			IS '인시던트 수정자 UUID - 인시던트 정보를 최종 수정한 담당자 또는 시스템의 식별자';
COMMENT ON COLUMN mntr.incidents.incident_no 			IS '인시던트 번호 - 시스템에서 발급하는 고유한 인시던트 식별번호 (예: INC-2024-001, INCIDENT-20241201-001)';
COMMENT ON COLUMN mntr.incidents.title 					IS '인시던트 제목 - 장애 상황을 간략히 설명하는 제목 (예: API 서버 응답 지연, 데이터베이스 연결 장애)';
COMMENT ON COLUMN mntr.incidents.description 			IS '인시던트 상세 설명 - 장애 현상, 발생 경위, 영향 범위 등의 상세한 설명';
COMMENT ON COLUMN mntr.incidents.severity 				IS '심각도 - CRITICAL(서비스 완전 중단), HIGH(주요 기능 장애), MEDIUM(부분 기능 장애), LOW(경미한 문제) 중요도 구분';
COMMENT ON COLUMN mntr.incidents.affected_services 		IS '영향받은 서비스 목록 - 장애로 인해 영향을 받은 서비스들의 배열 (예: [API, DATABASE, REDIS])';
COMMENT ON COLUMN mntr.incidents.affected_tenants 		IS '영향받은 테넌트 ID 목록 - 장애 영향을 받은 특정 테넌트들의 UUID 배열 (전체 장애시 NULL)';
COMMENT ON COLUMN mntr.incidents.impact_scope 			IS '영향 범위 - GLOBAL(전체 서비스), PARTIAL(일부 서비스/지역), SINGLE_TENANT(특정 테넌트만) 장애 파급 범위';
COMMENT ON COLUMN mntr.incidents.incident_start_time 	IS '인시던트 시작 시간 - 실제 장애가 발생하기 시작한 시점 (고객 영향 시작 시점)';
COMMENT ON COLUMN mntr.incidents.incident_end_time 		IS '인시던트 종료 시간 - 서비스가 완전히 복구된 시점 (고객 영향 종료 시점, 진행중인 경우 NULL)';
COMMENT ON COLUMN mntr.incidents.detection_time 		IS '장애 감지 시간 - 모니터링 시스템이나 담당자가 장애를 최초 감지한 시점';
COMMENT ON COLUMN mntr.incidents.resolution_time 		IS '해결 완료 시간 - 근본 원인이 해결되고 모든 후속 조치가 완료된 시점';
COMMENT ON COLUMN mntr.incidents.assigned_to 			IS '담당 엔지니어 또는 팀명 - 인시던트 해결을 담당하는 엔지니어, 팀, 또는 벤더명';
COMMENT ON COLUMN mntr.incidents.escalation_level 		IS '에스컬레이션 단계 - 1차(일반), 2차(시니어), 3차(매니저), 4차(경영진), 5차(외부지원) 단계별 대응 레벨';
COMMENT ON COLUMN mntr.incidents.resolution_summary 	IS '해결 요약 - 임시 조치, 근본 해결 방법, 적용된 패치나 설정 변경 사항 등의 요약';
COMMENT ON COLUMN mntr.incidents.root_cause 			IS '근본 원인 분석 - 장애가 발생한 근본적인 원인에 대한 상세 분석 결과 (RCA: Root Cause Analysis)';
COMMENT ON COLUMN mntr.incidents.preventive_actions 	IS '재발 방지 조치 계획 - 동일한 장애의 재발을 방지하기 위한 구체적인 개선 조치 계획';
COMMENT ON COLUMN mntr.incidents.lessons_learned 		IS '교훈 및 개선 사항 - 인시던트를 통해 얻은 교훈과 프로세스, 시스템 개선 방안';
COMMENT ON COLUMN mntr.incidents.status 				IS '인시던트 상태 - OPEN(접수), IN_PROGRESS(진행중), RESOLVED(해결완료), CLOSED(종료) 처리 단계 구분';
COMMENT ON COLUMN mntr.incidents.deleted 				IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 인시던트 번호 고유성 보장
CREATE UNIQUE INDEX IF NOT EXISTS ux_incidents__incident_no
    ON mntr.incidents (incident_no)
 WHERE deleted = FALSE;

-- 심각도별 인시던트 조회 최적화
CREATE INDEX IF NOT EXISTS ix_incidents__severity
    ON mntr.incidents (severity, created_at DESC)
 WHERE deleted = FALSE;

-- 상태별 인시던트 조회 최적화
CREATE INDEX IF NOT EXISTS ix_incidents__status
    ON mntr.incidents (status, created_at DESC)
 WHERE deleted = FALSE;

-- 장애 발생 시간 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_incidents__incident_start_time
    ON mntr.incidents (incident_start_time DESC);

-- 진행중인 인시던트 조회 최적화
CREATE INDEX IF NOT EXISTS ix_incidents__open_incidents
    ON mntr.incidents (status, severity, created_at DESC)
 WHERE status IN ('OPEN', 'IN_PROGRESS')
   AND deleted = FALSE;

-- 크리티컬 인시던트 조회 최적화
CREATE INDEX IF NOT EXISTS ix_incidents__critical_incidents
    ON mntr.incidents (severity, incident_start_time DESC)
 WHERE severity = 'CRITICAL'
   AND deleted = FALSE;

-- 영향 범위별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_incidents__impact_scope
    ON mntr.incidents (impact_scope, created_at DESC)
 WHERE deleted = FALSE;

-- 담당자별 인시던트 조회 최적화
CREATE INDEX IF NOT EXISTS ix_incidents__assigned_to
    ON mntr.incidents (assigned_to, status, created_at DESC)
 WHERE assigned_to IS NOT NULL
   AND deleted = FALSE;

-- 에스컬레이션 단계별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_incidents__escalation_level
    ON mntr.incidents (escalation_level, severity, created_at DESC)
 WHERE deleted = FALSE;

-- 해결된 인시던트 분석 최적화
CREATE INDEX IF NOT EXISTS ix_incidents__resolution_analysis
    ON mntr.incidents (status, resolution_time DESC NULLS LAST)
 WHERE status IN ('RESOLVED', 'CLOSED')
   AND deleted = FALSE;

-- 영향받은 서비스 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_incidents__affected_services
    ON mntr.incidents USING GIN (affected_services)
 WHERE deleted = FALSE;

-- 영향받은 테넌트 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_incidents__affected_tenants
    ON mntr.incidents USING GIN (affected_tenants)
 WHERE deleted = FALSE;

-- 시간 분석을 위한 복합 인덱스
CREATE INDEX IF NOT EXISTS ix_incidents__time_analysis
    ON mntr.incidents (incident_start_time, incident_end_time, detection_time, resolution_time)
 WHERE deleted = FALSE;

-- 최신 등록 인시던트 조회 최적화
CREATE INDEX IF NOT EXISTS ix_incidents__created_at
    ON mntr.incidents (created_at DESC);


-- ============================================================================
-- 시스템 성능 메트릭
-- ============================================================================
CREATE TABLE IF NOT EXISTS mntr.system_metrics
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),    	-- 메트릭 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 메트릭 수집 일시
    created_by                  UUID,                                 								-- 메트릭 수집 시스템 UUID
    updated_at                  TIMESTAMP WITH TIME ZONE,                   						-- 메트릭 수정 일시
    updated_by                  UUID,                                 								-- 메트릭 수정자 UUID

	-- 메트릭 분류 및 정보
    metric_category             VARCHAR(50)              NOT NULL,                                 	-- 메트릭 분류 (PERFORMANCE/RESOURCE/BUSINESS/SECURITY)
    metric_name                 VARCHAR(100)             NOT NULL,                                 	-- 메트릭 이름 (CPU_USAGE/RESPONSE_TIME/ACTIVE_USERS 등)
    metric_value                NUMERIC(18,4)            NOT NULL,                                 	-- 측정된 메트릭 값
    metric_unit                 VARCHAR(20)              NOT NULL,                                 	-- 메트릭 단위 (PERCENT/MILLISECONDS/COUNT/BYTES)

	-- 측정 대상 정보
    service_name                VARCHAR(100),                                                      	-- 측정 대상 서비스명
    instance_id                 VARCHAR(100),                                                      	-- 인스턴스 식별자
    tenant_id                   UUID,                                                              	-- 테넌트별 메트릭인 경우 테넌트 ID

	-- 시간 정보
    measure_time            	TIMESTAMP WITH TIME ZONE NOT NULL,                                 	-- 실제 측정 시점
    summary_period          	VARCHAR(20)              DEFAULT 'MINUTE',                        	-- 집계 주기 (MINUTE/HOUR/DAY)

	-- 임계값 및 알림 정보
    warning_threshold           NUMERIC(18,4),                                                     	-- 경고 임계값
    critical_threshold          NUMERIC(18,4),                                                     	-- 위험 임계값
    alert_triggered             BOOLEAN                  DEFAULT FALSE,                           	-- 알림 발생 여부

	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- 메트릭 상태 (ACTIVE/INACTIVE/ARCHIVED)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT fk_system_metrics__tenant_id 			FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,

    CONSTRAINT ck_system_metrics__metric_category 		CHECK (metric_category IN ('PERFORMANCE', 'RESOURCE', 'BUSINESS', 'SECURITY')),
    CONSTRAINT ck_system_metrics__summary_period 		CHECK (summary_period IN ('MINUTE', 'HOUR', 'DAY')),
    CONSTRAINT ck_system_metrics__metric_unit 			CHECK (metric_unit IN ('PERCENT', 'MILLISECONDS', 'COUNT', 'BYTES', 'MBPS', 'REQUESTS_PER_SECOND')),
    CONSTRAINT ck_system_metrics__status 				CHECK (status IN ('ACTIVE', 'INACTIVE', 'ARCHIVED')),
    CONSTRAINT ck_system_metrics__metric_value 			CHECK (metric_value >= 0),
    CONSTRAINT ck_system_metrics__warning_threshold 	CHECK (warning_threshold IS NULL OR warning_threshold >= 0),
    CONSTRAINT ck_system_metrics__critical_threshold 	CHECK (critical_threshold IS NULL OR critical_threshold >= 0),
    CONSTRAINT ck_system_metrics__threshold_order 		CHECK (critical_threshold IS NULL OR warning_threshold IS NULL OR critical_threshold >= warning_threshold)
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  mntr.system_metrics						IS '시스템 성능 메트릭 - 각종 시스템 지표의 시계열 데이터를 수집하여 성능 모니터링, 용량 계획, 알림 처리를 지원';
COMMENT ON COLUMN mntr.system_metrics.id 					IS '메트릭 고유 식별자 - UUID 형태의 기본키, 각 메트릭 측정 데이터를 구분하는 고유값';
COMMENT ON COLUMN mntr.system_metrics.created_at 			IS '메트릭 수집 일시 - 메트릭이 시스템에 저장된 시점의 타임스탬프';
COMMENT ON COLUMN mntr.system_metrics.created_by 			IS '메트릭 수집 시스템 UUID - 메트릭을 수집한 모니터링 시스템 또는 에이전트의 식별자';
COMMENT ON COLUMN mntr.system_metrics.updated_at 			IS '메트릭 수정 일시 - 메트릭 데이터가 수정된 시점의 타임스탬프 (재계산 시 갱신)';
COMMENT ON COLUMN mntr.system_metrics.updated_by 			IS '메트릭 수정자 UUID - 메트릭을 수정한 시스템 또는 프로세스의 식별자';
COMMENT ON COLUMN mntr.system_metrics.metric_category 		IS '메트릭 분류 - PERFORMANCE(성능), RESOURCE(리소스), BUSINESS(비즈니스), SECURITY(보안) 용도별 분류';
COMMENT ON COLUMN mntr.system_metrics.metric_name 			IS '메트릭 이름 - CPU_USAGE(CPU 사용률), RESPONSE_TIME(응답시간), ACTIVE_USERS(활성사용자), MEMORY_USAGE(메모리사용량) 등';
COMMENT ON COLUMN mntr.system_metrics.metric_value 			IS '측정된 메트릭 값 - 실제 측정된 수치 (음수 불가, 소수점 4자리까지 지원)';
COMMENT ON COLUMN mntr.system_metrics.metric_unit 			IS '메트릭 단위 - PERCENT(백분율), MILLISECONDS(밀리초), COUNT(개수), BYTES(바이트), MBPS(메가비트/초), REQUESTS_PER_SECOND(초당요청수)';
COMMENT ON COLUMN mntr.system_metrics.service_name 			IS '측정 대상 서비스명 - API(웹서비스), DATABASE(데이터베이스), REDIS(캐시), QUEUE(메시지큐) 등 서비스 구분';
COMMENT ON COLUMN mntr.system_metrics.instance_id 			IS '인스턴스 식별자 - 클러스터 환경에서 특정 인스턴스를 구분하는 식별자 (서버명, 컨테이너ID 등)';
COMMENT ON COLUMN mntr.system_metrics.tenant_id 			IS '테넌트별 메트릭인 경우 테넌트 ID - 특정 테넌트와 관련된 메트릭의 경우 해당 테넌트 식별자 (tenants 테이블 참조)';
COMMENT ON COLUMN mntr.system_metrics.measure_time 			IS '실제 측정 시점 - 메트릭이 실제로 측정된 정확한 시간 (집계 데이터의 경우 집계 기간 종료 시점)';
COMMENT ON COLUMN mntr.system_metrics.summary_period 		IS '집계 주기 - MINUTE(분별), HOUR(시간별), DAY(일별) 집계 단위 구분';
COMMENT ON COLUMN mntr.system_metrics.warning_threshold 	IS '경고 임계값 - 이 값을 초과하면 경고 알림을 발생시키는 기준값';
COMMENT ON COLUMN mntr.system_metrics.critical_threshold 	IS '위험 임계값 - 이 값을 초과하면 긴급 알림을 발생시키는 기준값 (warning_threshold보다 높음)';
COMMENT ON COLUMN mntr.system_metrics.alert_triggered 		IS '알림 발생 여부 - TRUE(임계값 초과로 알림 발생), FALSE(정상 범위), 알림 중복 방지용';
COMMENT ON COLUMN mntr.system_metrics.status 				IS '메트릭 상태 - ACTIVE(활성수집), INACTIVE(수집중단), ARCHIVED(보관용) 메트릭 수집 상태';
COMMENT ON COLUMN mntr.system_metrics.deleted 				IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 시간 기준 메트릭 조회 최적화 (가장 중요)
CREATE INDEX IF NOT EXISTS ix_system_metrics__measure_time
    ON mntr.system_metrics (measure_time DESC);

-- 분류별 메트릭 조회 최적화
CREATE INDEX IF NOT EXISTS ix_system_metrics__metric_category
    ON mntr.system_metrics (metric_category, measure_time DESC)
 WHERE deleted = FALSE;

-- 메트릭명별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_system_metrics__metric_name
    ON mntr.system_metrics (metric_name, measure_time DESC)
 WHERE deleted = FALSE;

-- 서비스별 메트릭 조회 최적화
CREATE INDEX IF NOT EXISTS ix_system_metrics__service_name
    ON mntr.system_metrics (service_name, measure_time DESC)
 WHERE service_name IS NOT NULL
   AND deleted = FALSE;

-- 테넌트별 메트릭 조회 최적화
CREATE INDEX IF NOT EXISTS ix_system_metrics__tenant_id
    ON mntr.system_metrics (tenant_id, measure_time DESC)
 WHERE tenant_id IS NOT NULL
   AND deleted = FALSE;

-- 인스턴스별 메트릭 조회 최적화
CREATE INDEX IF NOT EXISTS ix_system_metrics__instance_id
    ON mntr.system_metrics (instance_id, measure_time DESC)
 WHERE instance_id IS NOT NULL
   AND deleted = FALSE;

-- 집계 주기별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_system_metrics__summary_period
    ON mntr.system_metrics (summary_period, measure_time DESC)
 WHERE deleted = FALSE;

-- 알림 분석 최적화
CREATE INDEX IF NOT EXISTS ix_system_metrics__alert_analysis
    ON mntr.system_metrics (alert_triggered, critical_threshold, warning_threshold, measure_time DESC)
 WHERE deleted = FALSE;

-- 높은 값 메트릭 분석 최적화
CREATE INDEX IF NOT EXISTS ix_system_metrics__high_values
    ON mntr.system_metrics (metric_name, metric_value DESC, measure_time DESC)
 WHERE deleted = FALSE;

-- 서비스별 특정 메트릭 조회 최적화
CREATE INDEX IF NOT EXISTS ix_system_metrics__service_metric
    ON mntr.system_metrics (service_name, metric_name, measure_time DESC)
 WHERE service_name IS NOT NULL
   AND deleted = FALSE;

-- 테넌트별 분류 조회 최적화
CREATE INDEX IF NOT EXISTS ix_system_metrics__tenant_category
    ON mntr.system_metrics (tenant_id, metric_category, measure_time DESC)
 WHERE tenant_id IS NOT NULL
   AND deleted = FALSE;

-- 수집 시간 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_system_metrics__created_at
    ON mntr.system_metrics (created_at DESC);

-- 일별 집계 데이터 조회 최적화
CREATE INDEX IF NOT EXISTS ix_system_metrics__daily_aggregation
    ON mntr.system_metrics (summary_period, measure_time DESC)
 WHERE summary_period = 'DAY'
   AND deleted = FALSE;

-- 성능 메트릭 조회 최적화
CREATE INDEX IF NOT EXISTS ix_system_metrics__performance_category
    ON mntr.system_metrics (metric_category, metric_name, measure_time DESC)
 WHERE metric_category = 'PERFORMANCE'
   AND deleted = FALSE;
