-- ============================================================================
-- 13. 운영 자동화 (Automation) -> auto
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS auto;

COMMENT ON SCHEMA auto
IS 'AUTO: 운영 자동화 스키마: 오케스트레이션/잡 스케줄링/실행 이력 관리.';

-- ============================================================================
-- 자동화 워크플로우
-- ============================================================================
CREATE TABLE IF NOT EXISTS auto.workflows
(
   id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 워크플로우 고유 식별자
   created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,         -- 워크플로우 생성 일시
   created_by                  UUID,                                                              	-- 워크플로우 생성자 UUID
   updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 워크플로우 수정 일시
   updated_by                  UUID,                                                              	-- 워크플로우 수정자 UUID

   -- 워크플로우 기본 정보
   workflow_name               VARCHAR(200)             NOT NULL,                                 	-- 워크플로우 이름
   workflow_type               VARCHAR(50)              NOT NULL,                                 	-- 워크플로우 유형
   description                 TEXT,                                                              	-- 워크플로우 설명
   category                    VARCHAR(50)              NOT NULL,                                 	-- 워크플로우 카테고리

   -- 트리거 설정
   trigger_type                VARCHAR(50)              NOT NULL,                                 	-- 트리거 유형
   trigger_config              JSONB                    NOT NULL,                                 	-- 트리거 상세 설정 (JSON)

   -- 워크플로우 정의
   workflow_definition         JSONB                    NOT NULL,                                 	-- 워크플로우 단계별 작업 정의 (JSON)
   input_schema                JSONB                    DEFAULT '{}',                             	-- 입력 데이터 스키마 (JSON)
   output_schema               JSONB                    DEFAULT '{}',                             	-- 출력 데이터 스키마 (JSON)

   -- 실행 설정
   max_concurrent_executions   INTEGER                  DEFAULT 1,                                	-- 최대 동시 실행 수
   execution_timeout           INTEGER                  DEFAULT 60,                               	-- 실행 타임아웃 (분)
   retry_policy                JSONB                    DEFAULT '{}',                             	-- 재시도 정책 (JSON)

   -- 권한 설정
   required_permissions        TEXT[],                                                            	-- 필요한 권한 목록 (배열)
   execution_context           VARCHAR(50)              DEFAULT 'SYSTEM',                         	-- 실행 컨텍스트

   -- 알림 설정
   notify_success              BOOLEAN                  DEFAULT FALSE,                            	-- 성공 시 알림 여부
   notify_failure              BOOLEAN                  DEFAULT TRUE,                             	-- 실패 시 알림 여부
   notification_channels       TEXT[],                                                            	-- 알림 채널 목록 (배열)

   -- 실행 통계
   total_executions            INTEGER                  DEFAULT 0,                                	-- 총 실행 횟수
   successful_executions       INTEGER                  DEFAULT 0,                                	-- 성공 실행 횟수
   failed_executions           INTEGER                  DEFAULT 0,                                	-- 실패 실행 횟수
   last_execution_at           TIMESTAMP WITH TIME ZONE,                                          	-- 마지막 실행 시각

   -- 버전 관리
   version                     VARCHAR(20)              DEFAULT '1.0',                            	-- 워크플로우 버전
   previous_version_id         UUID,                                                              	-- 이전 버전 워크플로우 ID

   -- 상태 관리
   enabled                     BOOLEAN                  DEFAULT TRUE,                             	-- 워크플로우 활성화 여부
   deleted                     BOOLEAN                  NOT NULL DEFAULT FALSE,                   	-- 논리적 삭제 여부

   CONSTRAINT fk_workflows__previous_version_id			FOREIGN KEY (previous_version_id) REFERENCES auto.workflows(id)	ON DELETE CASCADE,

   CONSTRAINT ck_workflows__trigger_type        		CHECK (trigger_type IN ('SCHEDULED', 'EVENT_DRIVEN', 'MANUAL', 'WEBHOOK')),
   CONSTRAINT ck_workflows__workflow_type       		CHECK (workflow_type IN ('SYSTEM_MAINTENANCE', 'TENANT_PROVISIONING', 'BILLING_AUTOMATION', 'MONITORING_ALERT')),
   CONSTRAINT ck_workflows__category        			CHECK (category IN ('OPERATIONAL', 'BUSINESS', 'SECURITY', 'MAINTENANCE')),
   CONSTRAINT ck_workflows__execution_context   		CHECK (execution_context IN ('SYSTEM', 'TENANT', 'USER'))
);

-- 테이블 및 컬럼 주석
COMMENT ON TABLE  auto.workflows 							IS '자동화 워크플로우 - 시스템 운영, 테넌트 관리 등의 자동화 프로세스 정의';
COMMENT ON COLUMN auto.workflows.id                         IS '워크플로우 고유 식별자';
COMMENT ON COLUMN auto.workflows.created_at                 IS '워크플로우 생성 일시';
COMMENT ON COLUMN auto.workflows.created_by                 IS '워크플로우 생성자 UUID';
COMMENT ON COLUMN auto.workflows.updated_at                 IS '워크플로우 수정 일시';
COMMENT ON COLUMN auto.workflows.updated_by                 IS '워크플로우 수정자 UUID';
COMMENT ON COLUMN auto.workflows.workflow_name              IS '워크플로우 이름';
COMMENT ON COLUMN auto.workflows.description                IS '워크플로우 설명';
COMMENT ON COLUMN auto.workflows.workflow_type              IS '워크플로우 유형 (SYSTEM_MAINTENANCE, TENANT_PROVISIONING, BILLING_AUTOMATION, MONITORING_ALERT)';
COMMENT ON COLUMN auto.workflows.category                   IS '워크플로우 카테고리 (OPERATIONAL, BUSINESS, SECURITY, MAINTENANCE)';
COMMENT ON COLUMN auto.workflows.trigger_type               IS '트리거 유형 (SCHEDULED, EVENT_DRIVEN, MANUAL, WEBHOOK)';
COMMENT ON COLUMN auto.workflows.trigger_config             IS '트리거 상세 설정 (스케줄, 이벤트 조건 등)';
COMMENT ON COLUMN auto.workflows.workflow_definition        IS '워크플로우 단계별 작업 정의 (JSON 형태)';
COMMENT ON COLUMN auto.workflows.input_schema               IS '입력 데이터 스키마 (JSON 형태)';
COMMENT ON COLUMN auto.workflows.output_schema              IS '출력 데이터 스키마 (JSON 형태)';
COMMENT ON COLUMN auto.workflows.max_concurrent_executions  IS '최대 동시 실행 수';
COMMENT ON COLUMN auto.workflows.execution_timeout          IS '실행 타임아웃 (분 단위)';
COMMENT ON COLUMN auto.workflows.retry_policy               IS '재시도 정책 (횟수, 간격 등)';
COMMENT ON COLUMN auto.workflows.required_permissions       IS '실행에 필요한 권한 목록';
COMMENT ON COLUMN auto.workflows.execution_context          IS '실행 컨텍스트 (SYSTEM, TENANT, USER)';
COMMENT ON COLUMN auto.workflows.notify_success           	IS '성공 시 알림 발송 여부';
COMMENT ON COLUMN auto.workflows.notify_failure           	IS '실패 시 알림 발송 여부';
COMMENT ON COLUMN auto.workflows.notification_channels      IS '알림 채널 목록 (이메일, 슬랙 등)';
COMMENT ON COLUMN auto.workflows.total_executions           IS '총 실행 횟수 (누적 통계)';
COMMENT ON COLUMN auto.workflows.successful_executions      IS '성공 실행 횟수 (누적 통계)';
COMMENT ON COLUMN auto.workflows.failed_executions          IS '실패 실행 횟수 (누적 통계)';
COMMENT ON COLUMN auto.workflows.last_execution_at          IS '마지막 실행 시각';
COMMENT ON COLUMN auto.workflows.version                    IS '워크플로우 버전';
COMMENT ON COLUMN auto.workflows.previous_version_id        IS '이전 버전 워크플로우 참조 ID';
COMMENT ON COLUMN auto.workflows.enabled                    IS '워크플로우 활성화 여부';
COMMENT ON COLUMN auto.workflows.deleted                    IS '논리적 삭제 여부';

-- 워크플로우 이름 검색용 인덱스
CREATE INDEX IF NOT EXISTS ix_workflows__workflow_name
	ON auto.workflows (workflow_name)
 WHERE deleted = FALSE;

-- 워크플로우 유형별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_workflows__workflow_type
	ON auto.workflows (workflow_type)
 WHERE deleted = FALSE;

-- 워크플로우 카테고리별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_workflows__category
	ON auto.workflows (category)
 WHERE deleted = FALSE;

-- 트리거 유형별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_workflows__trigger_type
	ON auto.workflows (trigger_type)
 WHERE deleted = FALSE;

-- 활성화된 워크플로우 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_workflows__enabled_deleted
	ON auto.workflows (enabled, deleted);

-- 실행 컨텍스트별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_workflows__execution_context
	ON auto.workflows (execution_context)
 WHERE deleted = FALSE;

-- 마지막 실행 시각 기준 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_workflows__last_execution_at
	ON auto.workflows (last_execution_at)
 WHERE deleted = FALSE;

-- 버전 관리용 인덱스
CREATE INDEX IF NOT EXISTS ix_workflows__version
	ON auto.workflows (version)
 WHERE deleted = FALSE;

-- 이전 버전 참조용 인덱스
CREATE INDEX IF NOT EXISTS ix_workflows__previous_version_id
	ON auto.workflows (previous_version_id)
 WHERE deleted = FALSE;

-- 복합 조회용 인덱스 (카테고리 + 트리거 유형)
CREATE INDEX IF NOT EXISTS ix_workflows__category_trigger_type
	ON auto.workflows (category, trigger_type)
 WHERE deleted = FALSE;

-- 알림 설정 기준 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_workflows__notify_failure
	ON auto.workflows (notify_failure)
 WHERE deleted = FALSE
   AND notify_failure = TRUE;

-- 트리거 설정 검색용 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_workflows__trigger_config
	ON auto.workflows USING GIN (trigger_config)
 WHERE deleted = FALSE;

-- ============================================================================
-- 워크플로우 실행 이력
-- ============================================================================
CREATE TABLE IF NOT EXISTS auto.executions
(
   id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),    -- 워크플로우 실행 고유 식별자
   created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,       -- 실행 기록 생성 일시
   created_by                  UUID,                                                              -- 실행 기록 생성자 UUID
   updated_at                  TIMESTAMP WITH TIME ZONE,                                          -- 실행 기록 수정 일시
   updated_by                  UUID,                                                              -- 실행 기록 수정자 UUID
   workflow_id                 UUID                     NOT NULL,                                 -- 실행된 워크플로우 ID
   tenant_id                   UUID,                                                              -- 테넌트별 실행 대상 ID

   -- 실행 식별 정보
   execution_id                VARCHAR(100)             UNIQUE NOT NULL,                          -- 워크플로우 실행 고유 식별자
   trigger_source              VARCHAR(100),                                                      -- 트리거 소스 (스케줄, 이벤트, 수동 등)
   triggered_by                VARCHAR(100),                                                      -- 트리거 실행자 (사용자/시스템)

   -- 입출력 데이터
   input_data                  JSONB                    DEFAULT '{}',                             -- 워크플로우 입력 데이터 (JSON)
   output_data                 JSONB                    DEFAULT '{}',                             -- 워크플로우 출력 데이터 (JSON)

   -- 실행 상태 추적
   status                      VARCHAR(20)              NOT NULL DEFAULT 'PENDING',               -- 워크플로우 실행 상태
   current_step                VARCHAR(100),                                                      -- 현재 실행 중인 워크플로우 단계
   completed_steps             TEXT[],                                                            -- 완료된 워크플로우 단계 목록
   failed_step                 VARCHAR(100),                                                      -- 실패한 워크플로우 단계명

   -- 실행 시간 정보
   started_at                  TIMESTAMP WITH TIME ZONE,                                          -- 워크플로우 실행 시작 시각
   completed_at                TIMESTAMP WITH TIME ZONE,                                          -- 워크플로우 실행 완료 시각
   duration                    INTEGER,                                                           -- 총 실행 시간 (초)

   -- 오류 및 재시도 정보
   error_message               TEXT,                                                              -- 실행 오류 메시지
   error_details               JSONB                    DEFAULT '{}',                             -- 상세 오류 정보 (JSON)
   retry_count                 INTEGER                  DEFAULT 0,                                -- 재시도 횟수

   -- 실행 로그
   execution_logs              JSONB                    DEFAULT '[]',                             -- 워크플로우 실행 로그 (JSON 배열)

   -- 리소스 사용량 통계
   cpu_usage           		   NUMERIC(18,4),                                                     -- CPU 사용 시간 (초)
   memory_usage                NUMERIC(18,4),                                                     -- 메모리 사용량 (MB)

   -- 상태 관리
   deleted                     BOOLEAN                  NOT NULL DEFAULT FALSE,                   -- 논리적 삭제 여부

   CONSTRAINT fk_executions__workflow_id       	FOREIGN KEY (workflow_id) 	REFERENCES auto.workflows(id)	ON DELETE CASCADE,
   CONSTRAINT fk_executions__tenant_id         	FOREIGN KEY (tenant_id) 	REFERENCES tnnt.tenants(id)		ON DELETE CASCADE,

   CONSTRAINT ck_executions__status       		CHECK (status IN ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELED', 'TIMEOUT'))
);

-- 테이블 및 컬럼 주석
COMMENT ON TABLE  auto.executions					IS '워크플로우 실행 이력 - 각 워크플로우 실행의 상세 기록 및 결과';
COMMENT ON COLUMN auto.executions.id                IS '워크플로우 실행 고유 식별자';
COMMENT ON COLUMN auto.executions.created_at        IS '실행 기록 생성 일시';
COMMENT ON COLUMN auto.executions.created_by        IS '실행 기록 생성자 UUID';
COMMENT ON COLUMN auto.executions.updated_at        IS '실행 기록 수정 일시';
COMMENT ON COLUMN auto.executions.updated_by        IS '실행 기록 수정자 UUID';
COMMENT ON COLUMN auto.executions.workflow_id       IS '실행된 워크플로우 ID';
COMMENT ON COLUMN auto.executions.tenant_id         IS '테넌트별 실행 대상 ID';
COMMENT ON COLUMN auto.executions.execution_id      IS '워크플로우 실행 고유 식별자 (외부 참조용)';
COMMENT ON COLUMN auto.executions.trigger_source    IS '트리거 소스 (SCHEDULED, EVENT, MANUAL, WEBHOOK)';
COMMENT ON COLUMN auto.executions.triggered_by      IS '트리거 실행자 (사용자 ID 또는 시스템명)';
COMMENT ON COLUMN auto.executions.input_data        IS '워크플로우 입력 데이터 (JSON 형태)';
COMMENT ON COLUMN auto.executions.output_data       IS '워크플로우 출력 데이터 (JSON 형태)';
COMMENT ON COLUMN auto.executions.status            IS '워크플로우 실행 상태 (PENDING, RUNNING, COMPLETED, FAILED, CANCELED, TIMEOUT)';
COMMENT ON COLUMN auto.executions.current_step      IS '현재 실행 중인 워크플로우 단계';
COMMENT ON COLUMN auto.executions.completed_steps   IS '완료된 워크플로우 단계 목록';
COMMENT ON COLUMN auto.executions.failed_step       IS '실패한 워크플로우 단계명';
COMMENT ON COLUMN auto.executions.started_at        IS '워크플로우 실행 시작 시각';
COMMENT ON COLUMN auto.executions.completed_at      IS '워크플로우 실행 완료 시각';
COMMENT ON COLUMN auto.executions.duration          IS '총 실행 시간 (초 단위)';
COMMENT ON COLUMN auto.executions.error_message     IS '실행 오류 메시지';
COMMENT ON COLUMN auto.executions.error_details     IS '상세 오류 정보 (스택 트레이스, 컨텍스트 등)';
COMMENT ON COLUMN auto.executions.retry_count       IS '재시도 횟수';
COMMENT ON COLUMN auto.executions.execution_logs    IS '워크플로우 실행 과정의 상세 로그 (JSON 배열)';
COMMENT ON COLUMN auto.executions.cpu_usage 		IS 'CPU 사용 시간 (초 단위)';
COMMENT ON COLUMN auto.executions.memory_usage   	IS '메모리 사용량 (MB 단위)';
COMMENT ON COLUMN auto.executions.deleted           IS '논리적 삭제 여부';

-- 워크플로우별 실행 이력 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__workflow_id
	ON auto.executions (workflow_id)
 WHERE deleted = FALSE;

-- 테넌트별 실행 이력 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__tenant_id
	ON auto.executions (tenant_id)
 WHERE deleted = FALSE;

-- 실행 상태별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__status
	ON auto.executions (status)
 WHERE deleted = FALSE;

-- 실행 시작 시각 기준 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__started_at
	ON auto.executions (started_at)
 WHERE deleted = FALSE;

-- 실행 완료 시각 기준 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__completed_at
	ON auto.executions (completed_at)
 WHERE deleted = FALSE;

-- 트리거 소스별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__trigger_source
	ON auto.executions (trigger_source)
 WHERE deleted = FALSE;

-- 실행 ID 검색용 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__execution_id
	ON auto.executions (execution_id)
 WHERE deleted = FALSE;

-- 실패한 실행 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__failed_step
	ON auto.executions (failed_step)
 WHERE deleted = FALSE
   AND failed_step IS NOT NULL;

-- 복합 조회용 인덱스 (워크플로우 + 상태)
CREATE INDEX IF NOT EXISTS ix_executions__workflow_status
	ON auto.executions (workflow_id, status)
 WHERE deleted = FALSE;

-- 복합 조회용 인덱스 (워크플로우 + 시작시각)
CREATE INDEX IF NOT EXISTS ix_executions__workflow_started
	ON auto.executions (workflow_id, started_at)
 WHERE deleted = FALSE;

-- 재시도 횟수 기준 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__retry_count
	ON auto.executions (retry_count)
 WHERE deleted = FALSE
   AND retry_count > 0;

-- 실행 시간 통계용 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__duration
	ON auto.executions (duration)
 WHERE deleted = FALSE
   AND duration IS NOT NULL;

-- 실행 로그 검색용 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__execution_logs
	ON auto.executions USING GIN (execution_logs)
 WHERE deleted = FALSE;

-- ============================================================================
-- 스케줄된 작업
-- ============================================================================
CREATE TABLE IF NOT EXISTS auto.tasks
(
   id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),    -- 스케줄된 작업 고유 식별자
   created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,       -- 작업 생성 일시
   created_by                  UUID,                                                              -- 작업 생성자 UUID
   updated_at                  TIMESTAMP WITH TIME ZONE,                                          -- 작업 수정 일시
   updated_by                  UUID,                                                              -- 작업 수정자 UUID

   -- 작업 기본 정보
   task_name                   VARCHAR(200)             NOT NULL,                                 -- 스케줄된 작업 이름
   task_type                   VARCHAR(50)              NOT NULL,                                 -- 작업 유형
   description                 TEXT,                                                              -- 작업 설명

   -- 스케줄 설정
   schedule_expression         VARCHAR(100)             NOT NULL,                                 -- CRON 표현식
   timezone                    VARCHAR(50)              DEFAULT 'Asia/Seoul',                     -- 실행 시간대

   -- 실행 설정
   command                     VARCHAR(1000),                                                     -- 실행할 명령어
   parameters                  JSONB                    DEFAULT '{}',                             -- 작업 실행 매개변수 (JSON)
   working_directory           VARCHAR(500),                                                      -- 작업 실행 디렉터리 경로
   environment_variables       JSONB                    DEFAULT '{}',                             -- 환경 변수 설정 (JSON)

   -- 실행 제한 설정
   max_execution_time          INTEGER                  DEFAULT 60,                               -- 최대 실행 시간 (분)
   max_instances    		   INTEGER                  DEFAULT 1,                                -- 최대 동시 실행 인스턴스 수

   -- 알림 설정
   notify_success              BOOLEAN                  DEFAULT FALSE,                            -- 성공 시 알림 여부
   notify_failure              BOOLEAN                  DEFAULT TRUE,                             -- 실패 시 알림 여부
   notify_emails               TEXT[],                                                            -- 알림 이메일 주소 목록

   -- 실행 스케줄 정보
   next_run_at                 TIMESTAMP WITH TIME ZONE,                                          -- 다음 실행 예정 시각
   last_run_at                 TIMESTAMP WITH TIME ZONE,                                          -- 마지막 실행 시각
   last_run_status             VARCHAR(20),                                                       -- 마지막 실행 상태
   last_run_duration           INTEGER,                                                           -- 마지막 실행 시간 (초)

   -- 실행 통계
   total_runs                  INTEGER                  DEFAULT 0,                                -- 총 실행 횟수
   successful_runs             INTEGER                  DEFAULT 0,                                -- 성공 실행 횟수
   failed_runs                 INTEGER                  DEFAULT 0,                                -- 실패 실행 횟수

   -- 상태 관리
   enabled                     BOOLEAN                  DEFAULT TRUE,                             -- 작업 활성화 여부
   deleted                     BOOLEAN                  DEFAULT FALSE NOT NULL,                   -- 논리적 삭제 여부

   CONSTRAINT ck_tasks__task_type       	CHECK (task_type IN ('SYSTEM_CLEANUP', 'DATA_SYNC', 'REPORT_GENERATION', 'BACKUP', 'MAINTENANCE', 'MONITORING')),
   CONSTRAINT ck_tasks__last_run_status     CHECK (last_run_status IN ('SUCCESS', 'FAILED', 'TIMEOUT', 'CANCELED'))
);

-- 테이블 및 컬럼 주석
COMMENT ON TABLE  auto.tasks 						IS '스케줄된 작업 - 정기적으로 실행되는 시스템 작업 및 유지보수 스케줄';
COMMENT ON COLUMN auto.tasks.id                    	IS '스케줄된 작업 고유 식별자';
COMMENT ON COLUMN auto.tasks.created_at            	IS '작업 생성 일시';
COMMENT ON COLUMN auto.tasks.created_by            	IS '작업 생성자 UUID';
COMMENT ON COLUMN auto.tasks.updated_at            	IS '작업 수정 일시';
COMMENT ON COLUMN auto.tasks.updated_by            	IS '작업 수정자 UUID';
COMMENT ON COLUMN auto.tasks.task_name             	IS '스케줄된 작업 이름';
COMMENT ON COLUMN auto.tasks.task_type             	IS '작업 유형 (SYSTEM_CLEANUP, DATA_SYNC, REPORT_GENERATION, BACKUP, MAINTENANCE, MONITORING)';
COMMENT ON COLUMN auto.tasks.description           	IS '작업 설명';
COMMENT ON COLUMN auto.tasks.schedule_expression   	IS 'CRON 표현식 (예: 0 2 * * * = 매일 오전 2시)';
COMMENT ON COLUMN auto.tasks.timezone              	IS '실행 시간대 (예: Asia/Seoul)';
COMMENT ON COLUMN auto.tasks.command               	IS '실행할 명령어 또는 스크립트';
COMMENT ON COLUMN auto.tasks.parameters            	IS '작업 실행 매개변수 (JSON 형태)';
COMMENT ON COLUMN auto.tasks.working_directory     	IS '작업 실행 디렉터리 경로';
COMMENT ON COLUMN auto.tasks.environment_variables 	IS '작업 실행 시 필요한 환경 변수 (JSON 형태)';
COMMENT ON COLUMN auto.tasks.max_execution_time    	IS '최대 실행 시간 (분 단위)';
COMMENT ON COLUMN auto.tasks.max_instances 			IS '최대 동시 실행 인스턴스 수';
COMMENT ON COLUMN auto.tasks.notify_success     	IS '성공 시 알림 발송 여부';
COMMENT ON COLUMN auto.tasks.notify_failure     	IS '실패 시 알림 발송 여부';
COMMENT ON COLUMN auto.tasks.notify_emails   		IS '알림 이메일 주소 목록';
COMMENT ON COLUMN auto.tasks.next_run_at           	IS '다음 실행 예정 시각';
COMMENT ON COLUMN auto.tasks.last_run_at           	IS '마지막 실행 시각';
COMMENT ON COLUMN auto.tasks.last_run_status       	IS '마지막 실행 상태 (SUCCESS, FAILED, TIMEOUT, CANCELED)';
COMMENT ON COLUMN auto.tasks.last_run_duration     	IS '마지막 실행 시간 (초 단위)';
COMMENT ON COLUMN auto.tasks.total_runs            	IS '총 실행 횟수 (누적 통계)';
COMMENT ON COLUMN auto.tasks.successful_runs       	IS '성공 실행 횟수 (누적 통계)';
COMMENT ON COLUMN auto.tasks.failed_runs           	IS '실패 실행 횟수 (누적 통계)';
COMMENT ON COLUMN auto.tasks.enabled               	IS '작업 활성화 여부';
COMMENT ON COLUMN auto.tasks.deleted               	IS '논리적 삭제 여부';

-- 작업 이름 검색용 인덱스
CREATE INDEX ix_tasks__task_name
	ON auto.tasks (task_name)
 WHERE deleted = FALSE;

-- 작업 유형별 조회용 인덱스
CREATE INDEX ix_tasks__task_type
	ON auto.tasks (task_type)
 WHERE deleted = FALSE;

-- 활성화된 작업 조회용 인덱스
CREATE INDEX ix_tasks__enabled_deleted
	ON auto.tasks (enabled, deleted);

-- 다음 실행 시각 기준 조회용 인덱스 (스케줄러 실행 최적화)
CREATE INDEX ix_tasks__next_run_at
	ON auto.tasks (next_run_at)
 WHERE deleted = FALSE AND enabled = TRUE;

-- 마지막 실행 시각 기준 조회용 인덱스
CREATE INDEX ix_tasks__last_run_at
	ON auto.tasks (last_run_at)
 WHERE deleted = FALSE;

-- 마지막 실행 상태별 조회용 인덱스
CREATE INDEX ix_tasks__last_run_status
	ON auto.tasks (last_run_status)
 WHERE deleted = FALSE;

-- 실행 통계 조회용 인덱스 (실패율 분석)
CREATE INDEX ix_tasks__failed_runs
	ON auto.tasks (failed_runs)
 WHERE deleted = FALSE AND failed_runs > 0;

-- 스케줄 표현식 검색용 인덱스
CREATE INDEX ix_tasks__schedule_expression
	ON auto.tasks (schedule_expression)
 WHERE deleted = FALSE;

-- 시간대별 조회용 인덱스
CREATE INDEX ix_tasks__timezone
	ON auto.tasks (timezone)
 WHERE deleted = FALSE;

-- 복합 조회용 인덱스 (작업 유형 + 활성화 상태)
CREATE INDEX ix_tasks__type_enabled
	ON auto.tasks (task_type, enabled)
 WHERE deleted = FALSE;

-- 알림 설정 기준 조회용 인덱스
CREATE INDEX ix_tasks__notify_failure
	ON auto.tasks (notify_failure)
 WHERE deleted = FALSE AND notify_failure = TRUE;

-- 매개변수 검색용 GIN 인덱스
CREATE INDEX ix_tasks__parameters
	ON auto.tasks USING GIN (parameters)
 WHERE deleted = FALSE;

-- 환경변수 검색용 GIN 인덱스
CREATE INDEX ix_tasks__environment_variables
	ON auto.tasks USING GIN (environment_variables)
 WHERE deleted = FALSE;
