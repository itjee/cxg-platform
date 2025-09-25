-- ============================================================================
-- 2. 인프라 및 리소스 관리 (Infrastructure Management) -> ifra
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS ifra;

COMMENT ON SCHEMA ifra
IS 'IFRA: 인프라/리소스 관리 스키마: 클라우드/온프레미스 리소스 카탈로그 및 사용량 메트릭(리소스 단위)을 관리. 비용/용량 계획의 근거 데이터.';

-- ============================================================================
-- 클라우드 리소스 관리 테이블
-- ============================================================================
CREATE TABLE IF NOT EXISTS ifra.resources
(
    -- 기본 식별자 및 감사 필드
    id                  UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 리소스 고유 식별자 (UUID)
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 리소스 등록 일시
    created_by          UUID,							                                 	-- 리소스 등록자 UUID
    updated_at          TIMESTAMP WITH TIME ZONE,                                          	-- 리소스 수정 일시
    updated_by          UUID,                                                              	-- 리소스 수정자 UUID

	-- 테넌트 연결 (멀티테넌시)
    tenant_id           UUID,                                                              	-- 테넌트 식별자 (NULL: 공통 리소스)
    -- 리소스 기본 정보
    resource_type       VARCHAR(50)              NOT NULL,                                 	-- 리소스 유형 (DATABASE/STORAGE/COMPUTE/NETWORK/CACHE/LOAD_BALANCER/CDN)
    resource_name       VARCHAR(100)             NOT NULL,                                 	-- 사용자 정의 리소스 이름
    resource_arn        VARCHAR(500),                                                      	-- 클라우드 리소스 ARN/Resource ID
    resource_id         VARCHAR(100)             NOT NULL,                                 	-- 클라우드 제공업체 리소스 식별자

	-- 리소스 위치 정보
    region              VARCHAR(50)              NOT NULL DEFAULT 'ap-northeast-2',       	-- 클라우드 리전 (기본: 서울)
    availability_zone   VARCHAR(50),                                                      	-- 가용영역 (예: ap-northeast-2a)

	-- 리소스 스펙 정보
    instance_type       VARCHAR(50),                                                      	-- 인스턴스 타입 (예: t3.medium, Standard_D2s_v3)
    cpu_cores           INTEGER,                                                          	-- CPU 코어 수
    memory_size         INTEGER,                                                          	-- 메모리 크기 (MB 단위)
    storage_size        INTEGER,                                                          	-- 스토리지 크기 (GB 단위)

	-- 비용 관리 정보
    hourly_cost         NUMERIC(18,4),                                                    	-- 시간당 비용
    monthly_cost        NUMERIC(18,4),                                                    	-- 월간 예상 비용
    currency            CHAR(3)                  NOT NULL DEFAULT 'USD',                 	-- 통화 단위 (USD/KRW/EUR/JPY)

	-- 확장 가능한 메타데이터
    tags                JSONB                    DEFAULT '{}',                            	-- 리소스 태그 (JSON 형태)
    configuration       JSONB                    DEFAULT '{}',                             	-- 리소스 설정 정보 (JSON 형태),

	-- 리소스 상태 관리
    status              VARCHAR(20)              NOT NULL DEFAULT 'PROVISIONING',         	-- 리소스 상태 (PROVISIONING/RUNNING/STOPPED/TERMINATED/ERROR/MAINTENANCE)
    deleted          	BOOLEAN                  NOT NULL DEFAULT FALSE,                  	-- 논리적 삭제 플래그

	-- 외래키 제약조건
    CONSTRAINT fk_resources__tenant_id 			FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,

	-- 체크 제약조건
    CONSTRAINT ck_resources__resource_type 		CHECK (resource_type IN ('DATABASE', 'STORAGE', 'COMPUTE', 'NETWORK', 'CACHE', 'LOAD_BALANCER', 'CDN')),
    CONSTRAINT ck_resources__status        		CHECK (status IN ('PROVISIONING', 'RUNNING', 'STOPPED', 'TERMINATED', 'ERROR', 'MAINTENANCE')),
    CONSTRAINT ck_resources__currency      		CHECK (currency IN ('USD', 'KRW', 'EUR', 'JPY')),
    CONSTRAINT ck_resources__cpu_cores     		CHECK (cpu_cores IS NULL OR cpu_cores > 0),
    CONSTRAINT ck_resources__memory_size   		CHECK (memory_size IS NULL OR memory_size > 0),
    CONSTRAINT ck_resources__storage_size  		CHECK (storage_size IS NULL OR storage_size > 0),
    CONSTRAINT ck_resources__hourly_cost   		CHECK (hourly_cost IS NULL OR hourly_cost >= 0),
    CONSTRAINT ck_resources__monthly_cost  		CHECK (monthly_cost IS NULL OR monthly_cost >= 0)
);

-- 테이블 코멘트
COMMENT ON TABLE  ifra.resources 					IS '클라우드 리소스 관리 테이블 - AWS/Azure/GCP 등 클라우드 리소스의 프로비저닝, 상태 추적, 비용 관리를 위한 테이블';
-- 컬럼 코멘트
COMMENT ON COLUMN ifra.resources.id 				IS '리소스 고유 식별자 - UUID 형태의 기본키';
COMMENT ON COLUMN ifra.resources.created_at 		IS '리소스 등록 일시 - 레코드 생성 시점의 타임스탬프';
COMMENT ON COLUMN ifra.resources.created_by 		IS '리소스 등록자 - 리소스를 등록한 사용자의 UUID';
COMMENT ON COLUMN ifra.resources.updated_at 		IS '리소스 수정 일시 - 레코드 최종 수정 시점의 타임스탬프';
COMMENT ON COLUMN ifra.resources.updated_by 		IS '리소스 수정자 - 리소스를 최종 수정한 사용자의 UUID';
COMMENT ON COLUMN ifra.resources.tenant_id 			IS '테넌트 식별자 - 멀티테넌시 환경에서 리소스 소유자 구분 (NULL인 경우 공통 리소스)';
COMMENT ON COLUMN ifra.resources.resource_type 		IS '리소스 유형 - DATABASE(데이터베이스), STORAGE(스토리지), COMPUTE(컴퓨팅), NETWORK(네트워크), CACHE(캐시), LOAD_BALANCER(로드밸런서), CDN';
COMMENT ON COLUMN ifra.resources.resource_name 		IS '리소스 이름 - 사용자가 정의한 리소스의 논리적 이름';
COMMENT ON COLUMN ifra.resources.resource_arn 		IS '클라우드 리소스 ARN - AWS ARN, Azure Resource ID, GCP Resource Name 등 클라우드 고유 식별자';
COMMENT ON COLUMN ifra.resources.resource_id 		IS '클라우드 리소스 ID - 클라우드 제공업체에서 할당한 리소스 식별자 (예: i-1234567890abcdef0)';
COMMENT ON COLUMN ifra.resources.region 			IS '리전 정보 - 리소스가 위치한 클라우드 리전 (기본값: ap-northeast-2, 서울 리전)';
COMMENT ON COLUMN ifra.resources.availability_zone 	IS '가용영역 - 리전 내의 특정 가용영역 (예: ap-northeast-2a)';
COMMENT ON COLUMN ifra.resources.instance_type 		IS '인스턴스 타입 - 클라우드 제공업체의 인스턴스 유형 (예: t3.medium, Standard_D2s_v3)';
COMMENT ON COLUMN ifra.resources.cpu_cores 			IS 'CPU 코어 수 - 리소스에 할당된 가상 CPU 코어 개수';
COMMENT ON COLUMN ifra.resources.memory_size 		IS '메모리 크기 - 리소스에 할당된 메모리 크기 (MB 단위)';
COMMENT ON COLUMN ifra.resources.storage_size	 	IS '스토리지 크기 - 리소스에 할당된 스토리지 크기 (GB 단위)';
COMMENT ON COLUMN ifra.resources.hourly_cost 		IS '시간당 비용 - 리소스 운영에 소요되는 시간당 비용';
COMMENT ON COLUMN ifra.resources.monthly_cost 		IS '월간 예상 비용 - 현재 사용량 기준 월간 예상 비용';
COMMENT ON COLUMN ifra.resources.currency 			IS '통화 단위 - 비용 정보의 통화 (USD, KRW, EUR, JPY 등)';
COMMENT ON COLUMN ifra.resources.tags 				IS '리소스 태그 - 리소스 분류 및 관리를 위한 태그 정보 (JSON 형태, 예: {"Environment": "Production", "Team": "Backend"})';
COMMENT ON COLUMN ifra.resources.configuration 		IS '설정 정보 - 리소스별 상세 설정 정보 (JSON 형태, 보안그룹, 네트워킹 설정 등)';
COMMENT ON COLUMN ifra.resources.status 			IS '리소스 상태 - PROVISIONING(프로비저닝 중), RUNNING(실행 중), STOPPED(중지됨), TERMINATED(종료됨), ERROR(오류), MAINTENANCE(점검 중)';
COMMENT ON COLUMN ifra.resources.deleted 			IS '삭제 여부 - 논리적 삭제 플래그 (TRUE: 삭제됨, FALSE: 활성 상태)';

-- 인덱스 생성
-- 클라우드 리소스 ID로 빠른 검색
CREATE UNIQUE INDEX IF NOT EXISTS ux_resources__resource_id
    ON ifra.resources (resource_id)
 WHERE deleted = FALSE;

-- 테넌트별 리소스 조회 최적화
CREATE INDEX IF NOT EXISTS ix_resources__tenant_id
    ON ifra.resources (tenant_id);

-- 리소스 타입별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_resources__resource_type
    ON ifra.resources (resource_type);

-- 리소스 상태별 조회 최적화 (삭제되지 않은 리소스만)
CREATE INDEX IF NOT EXISTS ix_resources__status_active
    ON ifra.resources (status)
 WHERE deleted = FALSE;

-- 리전별 리소스 관리를 위한 인덱스
CREATE INDEX IF NOT EXISTS ix_resources__region
    ON ifra.resources (region);

-- 테넌트 + 리소스 타입 복합 조회 최적화
CREATE INDEX IF NOT EXISTS ix_resources__tenant_type
    ON ifra.resources (tenant_id, resource_type)
 WHERE deleted = FALSE;

-- 비용 관리를 위한 인덱스 (월간 비용 높은 순 조회)
CREATE INDEX IF NOT EXISTS ix_resources__monthly_cost
    ON ifra.resources (monthly_cost DESC NULLS LAST)
 WHERE deleted = FALSE;

-- ARN으로 리소스 검색 (AWS 환경)
CREATE INDEX IF NOT EXISTS ix_resources__resource_arn
    ON ifra.resources (resource_arn)
 WHERE resource_arn IS NOT NULL AND deleted = FALSE;

-- 생성일시 기준 최신 리소스 조회 최적화
CREATE INDEX IF NOT EXISTS ix_resources__created_at
    ON ifra.resources (created_at DESC);

-- 태그 기반 리소스 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_resources__tags
    ON ifra.resources USING GIN (tags);

-- 설정 정보 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_resources__configuration
    ON ifra.resources USING GIN (configuration);

-- 리소스 이름으로 검색 최적화 (부분 검색 지원)
CREATE INDEX IF NOT EXISTS ix_resources__resource_name
    ON ifra.resources (resource_name);

-- 인스턴스 타입별 리소스 분석용 인덱스
CREATE INDEX IF NOT EXISTS ix_resources__instance_type
    ON ifra.resources (instance_type)
    WHERE instance_type IS NOT NULL AND deleted = FALSE;


-- ============================================================================
-- 리소스 사용량 메트릭
-- ============================================================================
CREATE TABLE IF NOT EXISTS ifra.resource_usages
(
    -- 기본 식별자 및 감사 필드
    id                  		UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),    	-- 메트릭 고유 식별자 (UUID)
    created_at          		TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,                   	-- 메트릭 등록 일시
    created_by          		UUID,                                 								-- 메트릭 수집 시스템 UUID
    updated_at          		TIMESTAMP WITH TIME ZONE,                   						-- 메트릭 수정 일시
    updated_by          		UUID,                                 								-- 메트릭 수정 시스템 UUID

	-- 리소스 연결
    resource_id         		UUID                     NOT NULL,                                 	-- 대상 리소스 ID (resources 참조)
    tenant_id           		UUID,                                                              	-- 테넌트 ID (공통 리소스의 경우 NULL)

	-- 메트릭 정보
    metric_name         		VARCHAR(50)              NOT NULL,                                 	-- 메트릭 이름 (CPU_UTILIZATION/MEMORY_USAGE/DISK_USAGE/NETWORK_IN/NETWORK_OUT)
    metric_value        		NUMERIC(18,4)            NOT NULL,                                 	-- 메트릭 측정값
    metric_unit        	 		VARCHAR(20)              NOT NULL,                                 	-- 메트릭 단위 (PERCENT/BYTES/COUNT/MBPS)

	-- 시간 정보
    measure_time    			TIMESTAMP WITH TIME ZONE NOT NULL,                                 	-- 실제 측정 시점
    summary_period  			VARCHAR(20)              NOT NULL DEFAULT 'HOURLY',              	-- 집계 주기 (MINUTE/HOURLY/DAILY/MONTHLY)

	-- 제약조건
    CONSTRAINT fk_resource_usages__resource_id 			FOREIGN KEY (resource_id) 	REFERENCES ifra.resources(id)	ON DELETE CASCADE,
    CONSTRAINT fk_resource_usages__tenant_id 			FOREIGN KEY (tenant_id) 	REFERENCES tnnt.tenants(id)		ON DELETE CASCADE,

    CONSTRAINT ck_resource_usages__summary_period 		CHECK (summary_period IN ('MINUTE', 'HOURLY', 'DAILY', 'MONTHLY')),
    CONSTRAINT ck_resource_usages__metric_name 			CHECK (metric_name IN ('CPU_UTILIZATION', 'MEMORY_USAGE', 'DISK_USAGE', 'NETWORK_IN', 'NETWORK_OUT', 'IOPS', 'LATENCY')),
    CONSTRAINT ck_resource_usages__metric_unit 			CHECK (metric_unit IN ('PERCENT', 'BYTES', 'COUNT', 'MBPS', 'MILLISECONDS')),
    CONSTRAINT ck_resource_usages__metric_value 		CHECK (metric_value >= 0)
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  ifra.resource_usages					IS '리소스 사용량 메트릭 - 인프라 리소스의 실시간 및 집계된 사용량 데이터를 저장하여 모니터링, 알람, 용량 계획에 활용';
COMMENT ON COLUMN ifra.resource_usages.id 				IS '메트릭 고유 식별자 - UUID 형태의 기본키, 각 메트릭 데이터 포인트를 구분하는 고유값';
COMMENT ON COLUMN ifra.resource_usages.created_at 		IS '메트릭 등록 일시 - 메트릭 데이터가 시스템에 저장된 시점의 타임스탬프';
COMMENT ON COLUMN ifra.resource_usages.created_by 		IS '메트릭 수집 시스템 UUID - 메트릭을 수집한 모니터링 시스템 또는 에이전트의 식별자';
COMMENT ON COLUMN ifra.resource_usages.updated_at 		IS '메트릭 수정 일시 - 메트릭 데이터가 최종 수정된 시점의 타임스탬프 (재계산 시 갱신)';
COMMENT ON COLUMN ifra.resource_usages.updated_by 		IS '메트릭 수정 시스템 UUID - 메트릭을 최종 수정한 시스템 또는 프로세스의 식별자';
COMMENT ON COLUMN ifra.resource_usages.resource_id 		IS '대상 리소스 ID - 메트릭이 수집된 인프라 리소스의 고유 식별자 (resources 테이블 참조)';
COMMENT ON COLUMN ifra.resource_usages.tenant_id 		IS '테넌트 ID - 리소스를 사용하는 테넌트의 식별자 (공통 리소스의 경우 NULL, tenants 테이블 참조)';
COMMENT ON COLUMN ifra.resource_usages.metric_name 		IS '메트릭 이름 - CPU_UTILIZATION(CPU 사용률), MEMORY_USAGE(메모리 사용량), DISK_USAGE(디스크 사용량), NETWORK_IN/OUT(네트워크 입출력), IOPS, LATENCY';
COMMENT ON COLUMN ifra.resource_usages.metric_value 	IS '메트릭 측정값 - 실제 측정된 수치 (음수 불가, 소수점 4자리까지 지원)';
COMMENT ON COLUMN ifra.resource_usages.metric_unit 		IS '메트릭 단위 - PERCENT(백분율), BYTES(바이트), COUNT(개수), MBPS(메가비트/초), MILLISECONDS(밀리초)';
COMMENT ON COLUMN ifra.resource_usages.measure_time 	IS '실제 측정 시점 - 메트릭이 실제로 측정된 정확한 시간 (집계 데이터의 경우 집계 기간 종료 시점)';
COMMENT ON COLUMN ifra.resource_usages.summary_period 	IS '집계 주기 - MINUTE(분별), HOURLY(시간별), DAILY(일별), MONTHLY(월별) 집계 단위';

-- 인덱스 생성
-- 리소스별 메트릭 조회 최적화
CREATE INDEX IF NOT EXISTS ix_resource_usages__resource_id
    ON ifra.resource_usages (resource_id);

-- 테넌트별 사용량 조회 최적화
CREATE INDEX IF NOT EXISTS ix_resource_usages__tenant_id
    ON ifra.resource_usages (tenant_id)
 WHERE tenant_id IS NOT NULL;

-- 메트릭 유형별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_resource_usages__metric_name
    ON ifra.resource_usages (metric_name);

-- 시계열 데이터 조회 최적화
CREATE INDEX IF NOT EXISTS ix_resource_usages__measure_time
    ON ifra.resource_usages (measure_time DESC);

-- 집계 주기별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_resource_usages__summary_period
    ON ifra.resource_usages (summary_period);

-- 리소스별 특정 메트릭 시계열 조회 최적화
CREATE INDEX IF NOT EXISTS ix_resource_usages__resource_metric_time
    ON ifra.resource_usages (resource_id, metric_name, measure_time DESC);

-- 테넌트별 메트릭 시계열 조회 최적화
CREATE INDEX IF NOT EXISTS ix_resource_usages__tenant_metric_time
    ON ifra.resource_usages (tenant_id, metric_name, measure_time DESC)
 WHERE tenant_id IS NOT NULL;

-- 높은 사용률 메트릭 조회 최적화 (알람용)
CREATE INDEX IF NOT EXISTS ix_resource_usages__high_usage
    ON ifra.resource_usages (metric_name, metric_value DESC, measure_time DESC);

-- 일별 집계 데이터 조회 최적화
CREATE INDEX IF NOT EXISTS ix_resource_usages__daily_aggregation
    ON ifra.resource_usages (summary_period, measure_time DESC)
 WHERE summary_period = 'DAILY';

-- 시간별 집계 데이터 조회 최적화
CREATE INDEX IF NOT EXISTS ix_resource_usages__hourly_aggregation
    ON ifra.resource_usages (summary_period, measure_time DESC)
 WHERE summary_period = 'HOURLY';

-- 최신 수집 메트릭 조회 최적화
CREATE INDEX IF NOT EXISTS ix_resource_usages__created_at
    ON ifra.resource_usages (created_at DESC);
