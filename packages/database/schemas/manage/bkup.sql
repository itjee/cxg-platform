-- ============================================================================
-- 10. 백업 및 복구 (Backup & Recovery) -> bkup
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS bkup;

COMMENT ON SCHEMA bkup
IS 'BKUP: 백업/복구(BC/DR) 스키마: 스케줄/실행 기록과 DR 계획 관리.';

-- ============================================================================
-- 백업 작업 관리 테이블
-- ============================================================================
CREATE TABLE IF NOT EXISTS bkup.executions
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 백업 작업 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 백업 작업 생성 일시
    created_by                  UUID,                                                              	-- 백업 작업 생성자 UUID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 백업 작업 수정 일시
    updated_by                  UUID,                                                              	-- 백업 작업 수정자 UUID

    -- 백업 대상 정보
    backup_type                 VARCHAR(50)              NOT NULL,                                 	-- 백업 유형 (FULL_SYSTEM/TENANT_DATA/DATABASE/FILES/CONFIGURATION)
    backup_tenant_id            UUID,                                                              	-- 특정 테넌트 백업 대상 ID
    backup_database             VARCHAR(100),                                                      	-- 대상 데이터베이스명
    backup_schema               VARCHAR(100),                                                      	-- 대상 스키마명

    -- 백업 기본 정보
    backup_name                 VARCHAR(200)             NOT NULL,                                 	-- 백업 작업명
    backup_method               VARCHAR(50)              NOT NULL DEFAULT 'AUTOMATED',            	-- 백업 방식 (AUTOMATED/MANUAL/SCHEDULED)
    backup_format               VARCHAR(20)              NOT NULL DEFAULT 'COMPRESSED',           	-- 백업 형식 (COMPRESSED/UNCOMPRESSED/ENCRYPTED)

    -- 스케줄 관련 정보
    schedule_id                 UUID,                                                              	-- 백업 스케줄 참조 ID
    scheduled_at                TIMESTAMP WITH TIME ZONE,                                          	-- 예약 실행 시각

    -- 실행 관련 정보
    started_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 백업 시작 일시
    completed_at                TIMESTAMP WITH TIME ZONE,                                          	-- 백업 완료 일시
    duration            		INTEGER,                                                           	-- 백업 소요 시간 (초)

    -- 백업 결과 정보
    backup_size          	 	BIGINT,                                                            	-- 백업 파일 크기 (바이트)
    backup_file            		VARCHAR(500),                                                      	-- 백업 파일 저장 경로
    backup_checksum             VARCHAR(255),                                                      	-- 백업 파일 무결성 체크섬

    -- 압축 관련 정보
    original_size         		BIGINT,                                                            	-- 원본 데이터 크기 (바이트)
    compression_rate           	NUMERIC(5,2),                                                      	-- 압축률 (백분율)

    -- 상태 및 오류 정보
    status                      VARCHAR(20)              NOT NULL DEFAULT 'PENDING',              	-- 백업 작업 상태
    error_message               TEXT,                                                              	-- 실패 시 오류 메시지
    retry_count                 INTEGER                  NOT NULL DEFAULT 0,                      	-- 재시도 횟수

    -- 보관 관리 정보
    retention_days              INTEGER                  NOT NULL DEFAULT 30,                     	-- 백업 보관 기간 (일)
    expires_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 백업 만료 일시

    -- 논리적 삭제 플래그
    deleted                     BOOLEAN                  NOT NULL DEFAULT FALSE,                   	-- 논리적 삭제 플래그

    -- 제약조건
    CONSTRAINT fk_executions__backup_tenant_id			FOREIGN KEY (backup_tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,

    CONSTRAINT ck_executions__backup_type 				CHECK (backup_type IN ('FULL_SYSTEM', 'TENANT_DATA', 'DATABASE', 'FILES', 'CONFIGURATION')),
    CONSTRAINT ck_executions__backup_method 			CHECK (backup_method IN ('AUTOMATED', 'MANUAL', 'SCHEDULED')),
    CONSTRAINT ck_executions__backup_format 			CHECK (backup_format IN ('COMPRESSED', 'UNCOMPRESSED', 'ENCRYPTED')),
    CONSTRAINT ck_executions__status 					CHECK (status IN ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELED')),
    CONSTRAINT ck_executions__retry_count 				CHECK (retry_count >= 0),
    CONSTRAINT ck_executions__retention_days 			CHECK (retention_days > 0),
    CONSTRAINT ck_executions__size_consistency 			CHECK (backup_size IS NULL OR backup_size >= 0),
    CONSTRAINT ck_executions__original_size_consistency CHECK (original_size IS NULL OR original_size >= 0),
    CONSTRAINT ck_executions__compression_rate_range 	CHECK (compression_rate IS NULL OR (compression_rate >= 0 AND compression_rate <= 100)),
    CONSTRAINT ck_executions__execution_time_logic 		CHECK (completed_at IS NULL OR started_at IS NULL OR completed_at >= started_at)
);

-- 컬럼별 코멘트 추가
COMMENT ON TABLE bkup.executions
IS '백업 작업 관리 - 시스템 및 테넌트 데이터 백업 작업 실행 이력 및 상태 관리';

COMMENT ON COLUMN bkup.executions.id 					IS '백업 작업 고유 식별자 (UUID)';
COMMENT ON COLUMN bkup.executions.created_at 			IS '백업 작업 생성 일시';
COMMENT ON COLUMN bkup.executions.created_by 			IS '백업 작업 생성자 UUID (관리자 또는 시스템)';
COMMENT ON COLUMN bkup.executions.updated_at 			IS '백업 작업 수정 일시';
COMMENT ON COLUMN bkup.executions.updated_by 			IS '백업 작업 수정자 UUID';
COMMENT ON COLUMN bkup.executions.backup_type 			IS '백업 유형 - 전체 시스템, 테넌트 데이터, 데이터베이스, 파일, 설정 중 선택';
COMMENT ON COLUMN bkup.executions.backup_tenant_id 		IS '특정 테넌트 백업 대상 ID - 테넌트별 백업인 경우에만 설정';
COMMENT ON COLUMN bkup.executions.backup_database 		IS '대상 데이터베이스명 - 데이터베이스 백업인 경우 대상 DB';
COMMENT ON COLUMN bkup.executions.backup_schema 		IS '대상 스키마명 - 스키마 단위 백업인 경우 대상 스키마';
COMMENT ON COLUMN bkup.executions.backup_name 			IS '백업 작업명 - 백업을 식별하기 위한 사용자 친화적 이름';
COMMENT ON COLUMN bkup.executions.backup_method 		IS '백업 방식 - 자동, 수동, 예약 백업 중 선택';
COMMENT ON COLUMN bkup.executions.backup_format 		IS '백업 형식 - 압축, 비압축, 암호화 중 선택';
COMMENT ON COLUMN bkup.executions.schedule_id 			IS '백업 스케줄 참조 ID - 예약된 백업인 경우 스케줄 테이블 참조';
COMMENT ON COLUMN bkup.executions.scheduled_at 			IS '예약 실행 시각 - 백업이 실행되도록 예약된 시간';
COMMENT ON COLUMN bkup.executions.started_at 			IS '백업 시작 일시 - 실제 백업 작업이 시작된 시간';
COMMENT ON COLUMN bkup.executions.completed_at 			IS '백업 완료 일시 - 백업 작업이 완료된 시간';
COMMENT ON COLUMN bkup.executions.duration 				IS '백업 소요 시간 (초) - 시작부터 완료까지의 총 소요 시간';
COMMENT ON COLUMN bkup.executions.backup_size 			IS '백업 파일 크기 (바이트) - 생성된 백업 파일의 크기';
COMMENT ON COLUMN bkup.executions.backup_file 			IS '백업 파일 저장 경로 - 백업 파일이 저장된 물리적 경로';
COMMENT ON COLUMN bkup.executions.backup_checksum 		IS '백업 파일 무결성 체크섬 - 파일 손상 여부 확인용 해시값';
COMMENT ON COLUMN bkup.executions.original_size 		IS '원본 데이터 크기 (바이트) - 압축 전 원본 데이터의 크기';
COMMENT ON COLUMN bkup.executions.compression_rate 		IS '압축률 (백분율) - 원본 대비 압축 후 크기 비율';
COMMENT ON COLUMN bkup.executions.status 				IS '백업 작업 상태 - 대기, 실행중, 완료, 실패, 취소 중 하나';
COMMENT ON COLUMN bkup.executions.error_message 		IS '실패 시 오류 메시지 - 백업 실패 원인에 대한 상세 설명';
COMMENT ON COLUMN bkup.executions.retry_count 			IS '재시도 횟수 - 실패 후 재시도한 횟수';
COMMENT ON COLUMN bkup.executions.retention_days 		IS '백업 보관 기간 (일) - 백업 파일을 보관할 일수';
COMMENT ON COLUMN bkup.executions.expires_at 			IS '백업 만료 일시 - 백업이 자동 삭제될 예정 시간';
COMMENT ON COLUMN bkup.executions.deleted 				IS '논리적 삭제 플래그 - 실제 삭제 대신 사용하는 소프트 딜리트';

-- 인덱스 생성
-- 상태별 백업 작업 조회용 인덱스 (모니터링 및 관리용)
CREATE INDEX IF NOT EXISTS ix_executions__status_monitoring
    ON bkup.executions (status, created_at DESC)
 WHERE deleted = FALSE;

-- 백업 유형별 조회용 인덱스 (백업 유형별 통계 및 관리)
CREATE INDEX IF NOT EXISTS ix_executions__type_analysis
    ON bkup.executions (backup_type, completed_at DESC, status)
 WHERE deleted = FALSE;

-- 테넌트별 백업 이력 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__tenant_history
    ON bkup.executions (backup_tenant_id, created_at DESC)
 WHERE deleted = FALSE
   AND backup_tenant_id IS NOT NULL;

-- 스케줄별 백업 작업 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__schedule_tracking
    ON bkup.executions (schedule_id, scheduled_at DESC, status)
 WHERE deleted = FALSE
   AND schedule_id IS NOT NULL;

-- 만료 관리용 인덱스 (만료된 백업 정리 작업용)
CREATE INDEX IF NOT EXISTS ix_executions__expiration_management
    ON bkup.executions (expires_at, status)
 WHERE deleted = FALSE
   AND expires_at IS NOT NULL;

-- 실행 시간 분석용 인덱스 (성능 모니터링용)
CREATE INDEX IF NOT EXISTS ix_executions__performance_analysis
    ON bkup.executions (backup_type, duration, backup_size)
 WHERE deleted = FALSE
   AND status = 'COMPLETED';

-- 실패한 백업 분석용 인덱스 (오류 분석 및 재시도 관리)
CREATE INDEX IF NOT EXISTS ix_executions__failure_analysis
    ON bkup.executions (status, retry_count, created_at DESC)
 WHERE deleted = FALSE
   AND status IN ('FAILED', 'CANCELED');

-- 백업 방식별 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__method_tracking
    ON bkup.executions (backup_method, created_at DESC, status)
 WHERE deleted = FALSE;

-- 생성일자 기준 조회용 인덱스 (최근 백업 이력 조회)
CREATE INDEX IF NOT EXISTS ix_executions__created_at
    ON bkup.executions (created_at DESC)
 WHERE deleted = FALSE;

-- 현재 실행 중인 백업 조회용 인덱스
CREATE INDEX IF NOT EXISTS ix_executions__currently_running
    ON bkup.executions (started_at DESC, backup_type)
 WHERE deleted = FALSE
   AND status = 'RUNNING';


-- ============================================================================
-- 백업 스케줄 정의 테이블
-- ============================================================================
CREATE TABLE IF NOT EXISTS bkup.schedules
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 백업 스케줄 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 스케줄 생성 일시
    created_by                  UUID,                                                              	-- 스케줄 생성자 UUID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 스케줄 수정 일시
    updated_by                  UUID,                                                              	-- 스케줄 수정자 UUID

    -- 스케줄 기본 정보
    schedule_name               VARCHAR(200)             NOT NULL,                                 	-- 스케줄 이름
    backup_type                 VARCHAR(50)              NOT NULL,                                 	-- 백업 유형 (FULL_SYSTEM/TENANT_DATA/DATABASE/FILES)

    -- 백업 대상 설정
    target_scope                VARCHAR(50)              NOT NULL DEFAULT 'ALL_TENANTS',          	-- 백업 대상 범위
    target_tenants           	UUID[],                                                            	-- 특정 테넌트 대상 ID 배열
    target_databases            TEXT[],                                                            	-- 대상 데이터베이스 목록

    -- 스케줄 실행 설정
    frequency                   VARCHAR(20)              NOT NULL,                                 	-- 실행 주기 (DAILY/WEEKLY/MONTHLY/QUARTERLY)
    schedule_time               TIME                     NOT NULL,                                 	-- 실행 시각
    schedule_days               INTEGER[],                                                         	-- 실행 요일 또는 날짜 배열
    timezone                    VARCHAR(50)              NOT NULL DEFAULT 'Asia/Seoul',           	-- 시간대 설정

    -- 백업 옵션 설정
    backup_format               VARCHAR(20)              NOT NULL DEFAULT 'COMPRESSED',           	-- 백업 형식
    retention_days              INTEGER                  NOT NULL DEFAULT 30,                     	-- 백업 보관 기간 (일)
    max_parallel_jobs           INTEGER                  NOT NULL DEFAULT 1,                      	-- 동시 실행 가능한 백업 작업 수

    -- 알림 설정
    notify_success           	BOOLEAN                  NOT NULL DEFAULT FALSE,                  	-- 성공 시 알림 여부
    notify_failure           	BOOLEAN                  NOT NULL DEFAULT TRUE,                   	-- 실패 시 알림 여부
    notify_emails         		TEXT[],                                                            	-- 알림 받을 이메일 목록

    -- 실행 이력 정보
    next_run_at                 TIMESTAMP WITH TIME ZONE,                                          	-- 다음 실행 예정 시각
    last_run_at                 TIMESTAMP WITH TIME ZONE,                                          	-- 마지막 실행 시각

    -- 스케줄 상태 관리
    enabled                  	BOOLEAN                  NOT NULL DEFAULT TRUE,                   	-- 스케줄 활성화 여부

    -- 논리적 삭제 플래그
    deleted                     BOOLEAN                  NOT NULL DEFAULT FALSE,                   	-- 논리적 삭제 플래그

    -- 제약조건
    CONSTRAINT ck_schedules__backup_type				CHECK (backup_type IN ('FULL_SYSTEM', 'TENANT_DATA', 'DATABASE', 'FILES', 'CONFIGURATION')),
    CONSTRAINT ck_schedules__frequency					CHECK (frequency IN ('DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY')),
    CONSTRAINT ck_schedules__target_scope				CHECK (target_scope IN ('ALL_TENANTS', 'SPECIFIC_TENANTS', 'SYSTEM_ONLY')),
    CONSTRAINT ck_schedules__retention_days				CHECK (retention_days > 0),
    CONSTRAINT ck_schedules__max_parallel_jobs			CHECK (max_parallel_jobs > 0),
    CONSTRAINT ck_schedules__backup_format				CHECK (backup_format IN ('COMPRESSED', 'UNCOMPRESSED', 'ENCRYPTED'))
--    CONSTRAINT ck_schedules__schedule_days_range 		CHECK (schedule_days IS NULL OR (
--															CASE
--																WHEN frequency = 'WEEKLY' THEN
--																	(SELECT bool_and(day >= 1 AND day <= 7) FROM unnest(schedule_days) AS day)
--																WHEN frequency = 'MONTHLY' THEN
--																	(SELECT bool_and(day >= 1 AND day <= 31) FROM unnest(schedule_days) AS day)
--																ELSE TRUE
--															END
--														))
);

-- 컬럼별 코멘트 추가
COMMENT ON TABLE  bkup.schedules 						IS '백업 스케줄 정의 - 자동 백업 작업의 주기적 실행 설정 및 관리';
COMMENT ON COLUMN bkup.schedules.id 					IS '백업 스케줄 고유 식별자 (UUID)';
COMMENT ON COLUMN bkup.schedules.created_at 			IS '스케줄 생성 일시';
COMMENT ON COLUMN bkup.schedules.created_by 			IS '스케줄 생성자 UUID (관리자 또는 시스템)';
COMMENT ON COLUMN bkup.schedules.updated_at 			IS '스케줄 수정 일시';
COMMENT ON COLUMN bkup.schedules.updated_by 			IS '스케줄 수정자 UUID';
COMMENT ON COLUMN bkup.schedules.schedule_name 			IS '스케줄 이름 - 관리자가 식별하기 위한 친숙한 이름';
COMMENT ON COLUMN bkup.schedules.backup_type 			IS '백업 유형 - 전체 시스템, 테넌트 데이터, 데이터베이스, 파일 중 선택';
COMMENT ON COLUMN bkup.schedules.target_scope 			IS '백업 대상 범위 - 모든 테넌트, 특정 테넌트, 시스템만 중 선택';
COMMENT ON COLUMN bkup.schedules.target_tenants 		IS '특정 테넌트 대상 ID 배열 - target_scope가 SPECIFIC_TENANTS인 경우 사용';
COMMENT ON COLUMN bkup.schedules.target_databases 		IS '대상 데이터베이스 목록 - 백업할 데이터베이스명 배열';
COMMENT ON COLUMN bkup.schedules.frequency 				IS '실행 주기 - 일간, 주간, 월간, 분기별 중 선택';
COMMENT ON COLUMN bkup.schedules.schedule_time 			IS '실행 시각 - 백업이 실행될 시간 (HH:MM 형식)';
COMMENT ON COLUMN bkup.schedules.schedule_days 			IS '실행 요일 또는 날짜 배열 - 주간(1-7), 월간(1-31) 실행 날짜';
COMMENT ON COLUMN bkup.schedules.timezone 				IS '시간대 설정 - 스케줄 실행 시 적용할 시간대';
COMMENT ON COLUMN bkup.schedules.backup_format 			IS '백업 형식 - 압축, 비압축, 암호화 중 선택';
COMMENT ON COLUMN bkup.schedules.retention_days 		IS '백업 보관 기간 (일) - 백업 파일을 보관할 일수';
COMMENT ON COLUMN bkup.schedules.max_parallel_jobs 		IS '동시 실행 가능한 백업 작업 수 - 병렬 처리 제한';
COMMENT ON COLUMN bkup.schedules.notify_success 		IS '성공 시 알림 여부 - 백업 성공 시 이메일 알림 발송';
COMMENT ON COLUMN bkup.schedules.notify_failure 		IS '실패 시 알림 여부 - 백업 실패 시 이메일 알림 발송';
COMMENT ON COLUMN bkup.schedules.notify_emails 			IS '알림 받을 이메일 목록 - 백업 결과 통지를 받을 이메일 주소들';
COMMENT ON COLUMN bkup.schedules.next_run_at 			IS '다음 실행 예정 시각 - 스케줄에 따른 다음 백업 실행 시간';
COMMENT ON COLUMN bkup.schedules.last_run_at 			IS '마지막 실행 시각 - 가장 최근에 스케줄이 실행된 시간';
COMMENT ON COLUMN bkup.schedules.enabled 				IS '스케줄 활성화 여부 - 스케줄의 활성/비활성 상태';
COMMENT ON COLUMN bkup.schedules.deleted 				IS '논리적 삭제 플래그 - 실제 삭제 대신 사용하는 소프트 딜리트';

-- ======================================================
-- bkup.schedules 테이블 인덱스 정의
-- 목적: 스케줄러 관련 조회 및 모니터링 최적화
-- ======================================================

-- 활성화된 스케줄 조회용 인덱스
-- 설명: 스케줄러가 실행할 활성화된 작업 조회 최적화
CREATE INDEX IF NOT EXISTS ix_schedules__active_schedules
    ON bkup.schedules (enabled, next_run_at)
 WHERE deleted = FALSE
   AND enabled = TRUE;

-- 다음 실행 시간 기준 조회용 인덱스
-- 설명: 스케줄러 실행 순서 관리용, 예약된 실행이 있는 활성 스케줄 조회 최적화
CREATE INDEX IF NOT EXISTS ix_schedules__next_execution
    ON bkup.schedules (next_run_at ASC, backup_type)
 WHERE deleted = FALSE
   AND enabled = TRUE
   AND next_run_at IS NOT NULL;

-- 백업 유형별 조회용 인덱스
-- 설명: 백업 유형별 스케줄 관리 및 통계 조회 최적화
CREATE INDEX IF NOT EXISTS ix_schedules__type_management
    ON bkup.schedules (backup_type, frequency, enabled)
 WHERE deleted = FALSE;

-- 주기별 조회용 인덱스
-- 설명: 실행 주기별 스케줄 분석 및 관리 최적화
CREATE INDEX IF NOT EXISTS ix_schedules__frequency_analysis
    ON bkup.schedules (frequency, schedule_time, timezone)
 WHERE deleted = FALSE
   AND enabled = TRUE;

-- 대상 범위별 조회용 인덱스
-- 설명: 백업 대상별 스케줄 관리 최적화
CREATE INDEX IF NOT EXISTS ix_schedules__target_scope
    ON bkup.schedules (target_scope, backup_type)
 WHERE deleted = FALSE;

-- 마지막 실행 시간 기준 조회용 인덱스
-- 설명: 최근 실행 이력 조회 및 분석 최적화
CREATE INDEX IF NOT EXISTS ix_schedules__execution_history
    ON bkup.schedules (last_run_at DESC, backup_type)
 WHERE deleted = FALSE;

-- 알림 설정별 조회용 인덱스
-- 설명: 알림이 설정된 스케줄만 조회 최적화 (notify_failure, notify_success)
CREATE INDEX IF NOT EXISTS ix_schedules__notification_management
    ON bkup.schedules (notify_failure, notify_success)
 WHERE deleted = FALSE
   AND (notify_failure = TRUE OR notify_success = TRUE);

-- 생성일자 기준 조회용 인덱스
-- 설명: 최근 생성된 스케줄 조회 최적화
CREATE INDEX IF NOT EXISTS ix_schedules__created_at
    ON bkup.schedules (created_at DESC)
 WHERE deleted = FALSE;

-- 스케줄명 검색용 인덱스
-- 설명: 스케줄명으로 검색할 때 조회 최적화
CREATE INDEX IF NOT EXISTS ix_schedules__schedule_name
    ON bkup.schedules (schedule_name)
 WHERE deleted = FALSE;

-- GIN 인덱스: 특정 테넌트 대상 스케줄 조회용
-- 설명: target_scope가 'SPECIFIC_TENANTS'인 스케줄의 대상 테넌트 배열 검색 최적화
CREATE INDEX IF NOT EXISTS ix_schedules__target_tenants_gin
    ON bkup.schedules USING GIN (target_tenants)
 WHERE deleted = FALSE
   AND target_scope = 'SPECIFIC_TENANTS';

-- GIN 인덱스: 대상 데이터베이스 배열 검색용
-- 설명: target_databases 배열이 설정된 스케줄 조회 최적화
CREATE INDEX IF NOT EXISTS ix_schedules__target_databases_gin
    ON bkup.schedules USING GIN (target_databases)
 WHERE deleted = FALSE
   AND target_databases IS NOT NULL;

-- GIN 인덱스: 알림 이메일 배열 검색용
-- 설명: notify_emails 배열이 설정된 스케줄 조회 최적화
CREATE INDEX IF NOT EXISTS ix_schedules__notify_emails_gin
    ON bkup.schedules USING GIN (notify_emails)
 WHERE deleted = FALSE
   AND notify_emails IS NOT NULL;


-- ============================================================================
-- 재해복구 계획 테이블
-- ============================================================================
CREATE TABLE IF NOT EXISTS bkup.recovery_plans
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 복구 계획 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 계획 생성 일시
    created_by                  UUID,                                                              	-- 계획 생성자 UUID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 계획 수정 일시
    updated_by                  UUID,                                                              	-- 계획 수정자 UUID

    -- 계획 기본 정보
    plan_name                   VARCHAR(200)             NOT NULL,                                 	-- 복구 계획명
    plan_type                   VARCHAR(50)              NOT NULL,                                 	-- 계획 유형 (FULL_RECOVERY/PARTIAL_RECOVERY/TENANT_RECOVERY)
	description            		TEXT,                                                              	-- 계획 상세 설명


    -- 복구 대상 설정
    recovery_scope              VARCHAR(50)              NOT NULL,                                 	-- 복구 범위 (ALL_SYSTEMS/SPECIFIC_SERVICES/TENANT_DATA)
    target_services             TEXT[],                                                            	-- 복구 대상 서비스 목록
    target_tenants           	UUID[],                                                            	-- 복구 대상 테넌트 ID 목록

    -- 복구 목표 설정
    recovery_time               INTEGER                  NOT NULL,                                 	-- 복구 목표 시간 (분단위)
    recovery_point              INTEGER                  NOT NULL,                                 	-- 복구 목표 시점 (분단위)

    -- 복구 절차 정의
    recovery_steps              JSONB                    NOT NULL,                                 	-- 전체 복구 단계별 절차
    automated_steps             JSONB                    NOT NULL DEFAULT '[]',                   	-- 자동화된 복구 단계
    manual_steps                JSONB                    NOT NULL DEFAULT '[]',                   	-- 수동 복구 단계

    -- 백업 요구사항
    required_backup_types       TEXT[],                                                            	-- 필요한 백업 유형 목록
    minimum_backup_age          INTEGER                  NOT NULL DEFAULT 24,                     	-- 최소 백업 보관 시간 (시간)

    -- 테스트 관리 정보
    last_tested_at              TIMESTAMP WITH TIME ZONE,                                          	-- 마지막 테스트 실행 일시
    test_frequency_days         INTEGER                  NOT NULL DEFAULT 90,                     	-- 테스트 주기 (일)
    test_results                JSONB                    NOT NULL DEFAULT '{}',                   	-- 마지막 테스트 결과

    -- 담당자 정보
    primary_contact             VARCHAR(100),                                                      	-- 1차 담당자 연락처
    secondary_contact           VARCHAR(100),                                                      	-- 2차 담당자 연락처
    escalation_contacts         TEXT[],                                                            	-- 에스컬레이션 담당자 목록

    -- 승인 관리 정보
    approved_by                 VARCHAR(100),                                                      	-- 계획 승인자
    approved_at                 TIMESTAMP WITH TIME ZONE,                                          	-- 계획 승인 일시

    -- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'DRAFT',                	-- 계획 상태

    -- 논리적 삭제 플래그
    deleted                     BOOLEAN                  NOT NULL DEFAULT FALSE,                   	-- 논리적 삭제 플래그

    -- 제약조건
    CONSTRAINT ck_recovery_plans__plan_type        			CHECK (plan_type IN ('FULL_RECOVERY', 'PARTIAL_RECOVERY', 'TENANT_RECOVERY')),
    CONSTRAINT ck_recovery_plans__recovery_scope   			CHECK (recovery_scope IN ('ALL_SYSTEMS', 'SPECIFIC_SERVICES', 'TENANT_DATA')),
    CONSTRAINT ck_recovery_plans__status 	        		CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'ARCHIVED')),
    CONSTRAINT ck_recovery_plans__recovery_time_positive    CHECK (recovery_time > 0),
    CONSTRAINT ck_recovery_plans__recovery_point_positive   CHECK (recovery_point >= 0),
    CONSTRAINT ck_recovery_plans__test_frequency_positive   CHECK (test_frequency_days > 0),
    CONSTRAINT ck_recovery_plans__backup_age_positive       CHECK (minimum_backup_age > 0),
    CONSTRAINT ck_recovery_plans__rto_rpo_logic         	CHECK (recovery_time >= recovery_point)
);

-- 컬럼별 코멘트 추가
COMMENT ON TABLE  bkup.recovery_plans 							IS '재해복구 계획 - 시스템 장애 및 재해 상황에서의 복구 절차와 목표 정의';
COMMENT ON COLUMN bkup.recovery_plans.id 						IS '복구 계획 고유 식별자 (UUID)';
COMMENT ON COLUMN bkup.recovery_plans.created_at 				IS '계획 생성 일시';
COMMENT ON COLUMN bkup.recovery_plans.created_by 				IS '계획 생성자 UUID (IT 관리자 또는 시스템)';
COMMENT ON COLUMN bkup.recovery_plans.updated_at 				IS '계획 수정 일시';
COMMENT ON COLUMN bkup.recovery_plans.updated_by 				IS '계획 수정자 UUID';
COMMENT ON COLUMN bkup.recovery_plans.plan_name 				IS '복구 계획명 - 계획을 식별하기 위한 이름';
COMMENT ON COLUMN bkup.recovery_plans.description 				IS '계획 상세 설명 - 계획의 목적과 적용 범위에 대한 설명';
COMMENT ON COLUMN bkup.recovery_plans.plan_type 				IS '계획 유형 - 전체 복구, 부분 복구, 테넌트 복구 중 선택';
COMMENT ON COLUMN bkup.recovery_plans.recovery_scope 			IS '복구 범위 - 전체 시스템, 특정 서비스, 테넌트 데이터 중 선택';
COMMENT ON COLUMN bkup.recovery_plans.target_services 			IS '복구 대상 서비스 목록 - 복구할 서비스명 배열';
COMMENT ON COLUMN bkup.recovery_plans.target_tenants 			IS '복구 대상 테넌트 ID 목록 - 테넌트별 복구 시 대상 테넌트들';
COMMENT ON COLUMN bkup.recovery_plans.recovery_time 			IS 'RTO (복구 목표 시간) - 서비스 복구까지 허용되는 최대 시간 (분)';
COMMENT ON COLUMN bkup.recovery_plans.recovery_point 			IS 'RPO (복구 목표 시점) - 허용 가능한 최대 데이터 손실 시간 (분)';
COMMENT ON COLUMN bkup.recovery_plans.recovery_steps 			IS '전체 복구 단계별 절차 - JSON 형태의 상세 복구 절차';
COMMENT ON COLUMN bkup.recovery_plans.automated_steps 			IS '자동화된 복구 단계 - 시스템이 자동으로 수행할 복구 작업';
COMMENT ON COLUMN bkup.recovery_plans.manual_steps 				IS '수동 복구 단계 - 담당자가 직접 수행해야 할 복구 작업';
COMMENT ON COLUMN bkup.recovery_plans.required_backup_types 	IS '필요한 백업 유형 목록 - 복구에 필요한 백업의 종류들';
COMMENT ON COLUMN bkup.recovery_plans.minimum_backup_age 		IS '최소 백업 보관 시간 (시간) - 복구에 필요한 백업의 최소 보관 기간';
COMMENT ON COLUMN bkup.recovery_plans.last_tested_at 			IS '마지막 테스트 실행 일시 - 가장 최근에 DR 테스트를 수행한 시간';
COMMENT ON COLUMN bkup.recovery_plans.test_frequency_days 		IS '테스트 주기 (일) - DR 계획을 테스트해야 하는 주기';
COMMENT ON COLUMN bkup.recovery_plans.test_results 				IS '마지막 테스트 결과 - JSON 형태의 테스트 결과 및 개선사항';
COMMENT ON COLUMN bkup.recovery_plans.primary_contact 			IS '1차 담당자 연락처 - 재해 상황 시 1차 연락할 담당자';
COMMENT ON COLUMN bkup.recovery_plans.secondary_contact 		IS '2차 담당자 연락처 - 1차 담당자 연락 불가 시 연락할 담당자';
COMMENT ON COLUMN bkup.recovery_plans.escalation_contacts 		IS '에스컬레이션 담당자 목록 - 심각한 상황 시 연락할 상급자들';
COMMENT ON COLUMN bkup.recovery_plans.approved_by 				IS '계획 승인자 - DR 계획을 최종 승인한 관리자';
COMMENT ON COLUMN bkup.recovery_plans.approved_at 				IS '계획 승인 일시 - DR 계획이 승인된 시간';
COMMENT ON COLUMN bkup.recovery_plans.status 					IS '계획 상태 - 초안, 승인대기, 승인완료, 보관 중 하나';
COMMENT ON COLUMN bkup.recovery_plans.deleted 					IS '논리적 삭제 플래그 - 실제 삭제 대신 사용하는 소프트 딜리트';

-- 인덱스 생성
-- 승인된 활성 계획 조회 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__active_plans
    ON bkup.recovery_plans (status, plan_type)
 WHERE deleted = FALSE
   AND status = 'APPROVED';

-- 계획 유형별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__plan_type_management
    ON bkup.recovery_plans (plan_type, recovery_scope, status)
 WHERE deleted = FALSE;

-- RTO/RPO 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__recovery_objectives
    ON bkup.recovery_plans (recovery_time, recovery_point, plan_type)
 WHERE deleted = FALSE
   AND status = 'APPROVED';

-- 테스트 관리용 조회 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__test_management
    ON bkup.recovery_plans (last_tested_at, test_frequency_days)
 WHERE deleted = FALSE
   AND status = 'APPROVED';

-- 승인 대기 계획 조회 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__approval_pending
    ON bkup.recovery_plans (status, created_at DESC)
 WHERE deleted = FALSE
   AND status IN ('DRAFT', 'PENDING_APPROVAL');

-- 승인 이력 조회 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__approval_history
    ON bkup.recovery_plans (approved_by, approved_at DESC)
 WHERE deleted = FALSE
   AND approved_by IS NOT NULL;

-- 복구 범위별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__recovery_scope
    ON bkup.recovery_plans (recovery_scope, status)
 WHERE deleted = FALSE;

-- 생성일자 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__created_at
    ON bkup.recovery_plans (created_at DESC)
 WHERE deleted = FALSE;

-- 계획명 검색 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__plan_name
    ON bkup.recovery_plans (plan_name)
 WHERE deleted = FALSE;

-- GIN 인덱스: 대상 서비스 검색 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__target_services_gin
    ON bkup.recovery_plans USING GIN (target_services)
 WHERE deleted = FALSE
   AND target_services IS NOT NULL;

-- GIN 인덱스: 대상 테넌트 검색 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__target_tenants_gin
    ON bkup.recovery_plans USING GIN (target_tenants)
 WHERE deleted = FALSE
   AND target_tenants IS NOT NULL;

-- GIN 인덱스: 필요 백업 유형 검색 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__backup_types_gin
    ON bkup.recovery_plans USING GIN (required_backup_types)
 WHERE deleted = FALSE
   AND required_backup_types IS NOT NULL;

-- GIN 인덱스: 에스컬레이션 담당자 검색 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__escalation_contacts_gin
    ON bkup.recovery_plans USING GIN (escalation_contacts)
 WHERE deleted = FALSE
   AND escalation_contacts IS NOT NULL;

-- GIN 인덱스: 복구 절차 검색 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__recovery_steps_gin
    ON bkup.recovery_plans USING GIN (recovery_steps)
 WHERE deleted = FALSE;

-- GIN 인덱스: 테스트 결과 검색 최적화
CREATE INDEX IF NOT EXISTS ix_recovery_plans__test_results_gin
    ON bkup.recovery_plans USING GIN (test_results)
 WHERE deleted = FALSE
   AND test_results != '{}';
