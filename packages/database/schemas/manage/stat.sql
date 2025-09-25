-- ============================================================================
-- 7. 성능 및 분석 (Analytics) -> stat
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS stat;

COMMENT ON SCHEMA stat
IS 'stat: 분석/쿼터 스키마: 테넌트별 이용현황 및 할당량, 집계 통계를 제공.';

-- ============================================================================
-- 테넌트 분석 데이터
-- ============================================================================
CREATE TABLE IF NOT EXISTS stat.tenant_stats
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),    	-- 테넌트 분석 데이터 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,                   	-- 분석 데이터 생성 일시
    created_by                  UUID,                                                              	-- 분석 데이터 생성자 UUID (시스템 또는 분석 엔진)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 분석 데이터 수정 일시
    updated_by                  UUID,                                                              	-- 분석 데이터 수정자 UUID

	-- 분석 대상
    tenant_id                   UUID                     NOT NULL,                                 	-- 분석 대상 테넌트 ID

	-- 분석 기간 정보
    analysis_date               DATE                     NOT NULL,                                 	-- 분석 기준일
    analysis_period             VARCHAR(20)              NOT NULL DEFAULT 'DAILY',                	-- 분석 주기 (DAILY/WEEKLY/MONTHLY/YEARLY)

	-- 사용자 활동 지표
    active_users_count          INTEGER                  DEFAULT 0,                               	-- 활성 사용자 수 (해당 기간 중 로그인한 사용자)
    new_users_count             INTEGER                  DEFAULT 0,                               	-- 신규 사용자 수 (해당 기간 중 신규 가입)
    login_count                 INTEGER                  DEFAULT 0,                               	-- 총 로그인 횟수
    avg_session_duration        NUMERIC(18,4)            DEFAULT 0,                               	-- 평균 세션 시간 (분 단위)

	-- 기능 사용 지표
    api_calls_count             INTEGER                  DEFAULT 0,                               	-- API 호출 총 횟수
    uploads_count               INTEGER                  DEFAULT 0,                               	-- 문서 업로드 횟수
    executions_count            INTEGER                  DEFAULT 0,                               	-- 워크플로우/작업 실행 횟수
    ai_requests_count           INTEGER                  DEFAULT 0,                               	-- AI 서비스 요청 횟수

	-- 스토리지 사용량 지표
    used_storage             	NUMERIC(18,4)            DEFAULT 0,                               	-- 사용 중인 스토리지 (GB 단위)
    grow_storage           		NUMERIC(18,4)            DEFAULT 0,                               	-- 스토리지 증가량 (GB 단위)

	-- 성능 지표
    avg_response_time        	NUMERIC(18,4)            DEFAULT 0,                               	-- 평균 응답 시간 (밀리초)
    error_rate          		NUMERIC(5,2)             DEFAULT 0,                               	-- 오류율 (0-100%)
    uptime_rate         		NUMERIC(5,2)             DEFAULT 100,                             	-- 가동률 (0-100%)

	-- 비즈니스 지표
    feature_adoption_rate       NUMERIC(5,2)             DEFAULT 0,                               	-- 신규 기능 도입률 (0-100%)
    user_satisfaction_score     NUMERIC(3,1),                                                     	-- 사용자 만족도 점수 (1-5점)

	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- 분석 데이터 상태 (ACTIVE/ARCHIVED/OBSOLETE)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT fk_tenant_stats__tenant_id 				FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,

    CONSTRAINT ck_tenant_stats__analysis_period 		CHECK (analysis_period IN ('DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY')),
    CONSTRAINT ck_tenant_stats__status 					CHECK (status IN ('ACTIVE', 'ARCHIVED', 'OBSOLETE')),
    CONSTRAINT ck_tenant_stats__active_users_count 		CHECK (active_users_count >= 0),
    CONSTRAINT ck_tenant_stats__new_users_count 		CHECK (new_users_count >= 0),
    CONSTRAINT ck_tenant_stats__login_count 			CHECK (login_count >= 0),
    CONSTRAINT ck_tenant_stats__avg_session_duration 	CHECK (avg_session_duration >= 0),
    CONSTRAINT ck_tenant_stats__api_calls_count 		CHECK (api_calls_count >= 0),
    CONSTRAINT ck_tenant_stats__uploads_count 			CHECK (uploads_count >= 0),
    CONSTRAINT ck_tenant_stats__executions_count 		CHECK (executions_count >= 0),
    CONSTRAINT ck_tenant_stats__ai_requests_count 		CHECK (ai_requests_count >= 0),
    CONSTRAINT ck_tenant_stats__used_storage 			CHECK (used_storage >= 0),
    CONSTRAINT ck_tenant_stats__avg_response_time 		CHECK (avg_response_time >= 0),
    CONSTRAINT ck_tenant_stats__error_rate 				CHECK (error_rate >= 0 AND error_rate <= 100),
    CONSTRAINT ck_tenant_stats__uptime_rate 			CHECK (uptime_rate >= 0 AND uptime_rate <= 100),
    CONSTRAINT ck_tenant_stats__feature_adoption_rate 	CHECK (feature_adoption_rate >= 0 AND feature_adoption_rate <= 100),
    CONSTRAINT ck_tenant_stats__user_satisfaction_score CHECK (user_satisfaction_score IS NULL OR (user_satisfaction_score >= 1 AND user_satisfaction_score <= 5))
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  stat.tenant_stats							IS '테넌트 분석 데이터 - 각 테넌트의 사용 패턴, 성능 지표, 비즈니스 메트릭을 종합 분석하여 서비스 개선과 비즈니스 인사이트 제공';
COMMENT ON COLUMN stat.tenant_stats.id 						IS '테넌트 분석 데이터 고유 식별자 - UUID 형태의 기본키, 각 분석 데이터를 구분하는 고유값';
COMMENT ON COLUMN stat.tenant_stats.created_at 				IS '분석 데이터 생성 일시 - 분석 데이터가 시스템에 저장된 시점의 타임스탬프';
COMMENT ON COLUMN stat.tenant_stats.created_by 				IS '분석 데이터 생성자 UUID - 분석을 수행한 시스템 또는 분석 엔진의 식별자';
COMMENT ON COLUMN stat.tenant_stats.updated_at 				IS '분석 데이터 수정 일시 - 분석 데이터가 재계산되거나 수정된 시점의 타임스탬프';
COMMENT ON COLUMN stat.tenant_stats.updated_by 				IS '분석 데이터 수정자 UUID - 분석 데이터를 수정한 시스템 또는 관리자의 식별자';
COMMENT ON COLUMN stat.tenant_stats.tenant_id 				IS '분석 대상 테넌트 ID - 분석 데이터의 대상이 되는 테넌트의 고유 식별자 (tenants 테이블 참조)';
COMMENT ON COLUMN stat.tenant_stats.analysis_date 			IS '분석 기준일 - 분석 데이터가 기준으로 하는 날짜 (일별은 해당일, 주별은 주 시작일, 월별은 월 시작일)';
COMMENT ON COLUMN stat.tenant_stats.analysis_period 		IS '분석 주기 - DAILY(일별), WEEKLY(주별), MONTHLY(월별), YEARLY(연별) 분석 집계 단위';
COMMENT ON COLUMN stat.tenant_stats.active_users_count 		IS '활성 사용자 수 - 해당 분석 기간 중 시스템에 로그인하거나 활동한 고유 사용자의 수';
COMMENT ON COLUMN stat.tenant_stats.new_users_count 		IS '신규 사용자 수 - 해당 분석 기간 중 새로 가입한 사용자의 수';
COMMENT ON COLUMN stat.tenant_stats.login_count 			IS '총 로그인 횟수 - 해당 분석 기간 중 발생한 모든 로그인 시도의 총 횟수';
COMMENT ON COLUMN stat.tenant_stats.avg_session_duration 	IS '평균 세션 시간 - 해당 기간 중 사용자 세션의 평균 지속 시간 (분 단위)';
COMMENT ON COLUMN stat.tenant_stats.api_calls_count 		IS 'API 호출 총 횟수 - 해당 기간 중 테넌트가 수행한 모든 API 요청의 총 횟수';
COMMENT ON COLUMN stat.tenant_stats.uploads_count 			IS '문서 업로드 횟수 - 해당 기간 중 사용자가 업로드한 파일이나 문서의 총 횟수';
COMMENT ON COLUMN stat.tenant_stats.executions_count 		IS '워크플로우/작업 실행 횟수 - 해당 기간 중 실행된 자동화 작업, 워크플로우, 배치 작업의 총 횟수';
COMMENT ON COLUMN stat.tenant_stats.ai_requests_count 		IS 'AI 서비스 요청 횟수 - 해당 기간 중 AI 기능(챗봇, 분석, 추천 등)을 사용한 총 요청 횟수';
COMMENT ON COLUMN stat.tenant_stats.used_storage 			IS '사용 중인 스토리지 - 해당 시점에서 테넌트가 사용하고 있는 총 저장공간 크기 (GB 단위)';
COMMENT ON COLUMN stat.tenant_stats.grow_storage 			IS '스토리지 증가량 - 이전 분석 기간 대비 증가한 저장공간 크기 (GB 단위, 음수 가능)';
COMMENT ON COLUMN stat.tenant_stats.avg_response_time 		IS '평균 응답 시간 - 해당 기간 중 API 요청에 대한 평균 응답 시간 (밀리초 단위)';
COMMENT ON COLUMN stat.tenant_stats.error_rate 				IS '오류율 - 해당 기간 중 전체 요청 대비 오류가 발생한 요청의 비율 (0-100%)';
COMMENT ON COLUMN stat.tenant_stats.uptime_rate 			IS '가동률 - 해당 기간 중 서비스가 정상적으로 작동한 시간의 비율 (0-100%)';
COMMENT ON COLUMN stat.tenant_stats.feature_adoption_rate 	IS '신규 기능 도입률 - 새로 출시된 기능을 사용하는 사용자의 비율 (0-100%)';
COMMENT ON COLUMN stat.tenant_stats.user_satisfaction_score IS '사용자 만족도 점수 - 설문조사나 피드백을 통해 수집된 사용자 만족도 (1-5점 척도)';
COMMENT ON COLUMN stat.tenant_stats.status 					IS '분석 데이터 상태 - ACTIVE(현재 유효), ARCHIVED(보관), OBSOLETE(구버전) 데이터 생명주기 관리';
COMMENT ON COLUMN stat.tenant_stats.deleted 				IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 테넌트별 분석 데이터 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenant_stats__tenant_id
    ON stat.tenant_stats (tenant_id, analysis_date DESC)
 WHERE deleted = FALSE;

-- 분석 기준일 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenant_stats__analysis_date
    ON stat.tenant_stats (analysis_date DESC);

-- 분석 주기별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenant_stats__analysis_period
    ON stat.tenant_stats (analysis_period, analysis_date DESC)
 WHERE deleted = FALSE;

-- 활성 사용자 수 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenant_stats__active_users
    ON stat.tenant_stats (active_users_count DESC, analysis_date DESC)
 WHERE deleted = FALSE;

-- API 사용량 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenant_stats__api_usage
    ON stat.tenant_stats (api_calls_count DESC, analysis_date DESC)
 WHERE deleted = FALSE;

-- 스토리지 사용량 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenant_stats__storage_usage
    ON stat.tenant_stats (used_storage DESC, analysis_date DESC)
 WHERE deleted = FALSE;

-- 성능 지표 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenant_stats__performance
    ON stat.tenant_stats (avg_response_time DESC, error_rate DESC, analysis_date DESC)
 WHERE deleted = FALSE;

-- 만족도 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenant_stats__satisfaction
    ON stat.tenant_stats (user_satisfaction_score DESC, analysis_date DESC)
 WHERE user_satisfaction_score IS NOT NULL AND deleted = FALSE;

-- 테넌트별 주기 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenant_stats__tenant_period
    ON stat.tenant_stats (tenant_id, analysis_period, analysis_date DESC)
 WHERE deleted = FALSE;

-- 성장 분석 최적화
CREATE INDEX IF NOT EXISTS ix_tenant_stats__growth_analysis
    ON stat.tenant_stats (tenant_id, new_users_count DESC, grow_storage DESC, analysis_date DESC)
 WHERE deleted = FALSE;

-- 사용량 트렌드 분석 최적화
CREATE INDEX IF NOT EXISTS ix_tenant_stats__usage_trends
    ON stat.tenant_stats (tenant_id, uploads_count, executions_count, ai_requests_count, analysis_date DESC)
 WHERE deleted = FALSE;

-- 월별 보고서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenant_stats__monthly_reports
    ON stat.tenant_stats (analysis_period, analysis_date DESC)
 WHERE analysis_period = 'MONTHLY' AND deleted = FALSE;

-- 생성 시간 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tenant_stats__created_at
    ON stat.tenant_stats (created_at DESC);


-- ============================================================================
-- 사용량 요약 통계
-- ============================================================================
CREATE TABLE IF NOT EXISTS stat.usage_stats
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 사용량 요약 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 사용량 요약 생성 일시
    created_by                  UUID,                                                              	-- 사용량 요약 생성자 UUID (시스템 또는 분석 엔진)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 사용량 요약 수정 일시
    updated_by                  UUID,                                                              	-- 사용량 요약 수정자 UUID

	-- 요약 대상
    tenant_id                   UUID,                                                              	-- 테넌트 ID (NULL인 경우 전체 플랫폼 통계)

	-- 요약 기간 정보
    summary_date                DATE                     NOT NULL,                                 	-- 요약 기준일
    summary_type                VARCHAR(20)              NOT NULL,                                 	-- 요약 주기 (DAILY/WEEKLY/MONTHLY/QUARTERLY/YEARLY)

	-- 사용자 통계
    total_users                 INTEGER                  DEFAULT 0,                               	-- 총 사용자 수
    active_users                INTEGER                  DEFAULT 0,                               	-- 활성 사용자 수
    new_users                   INTEGER                  DEFAULT 0,                               	-- 신규 사용자 수
    churned_users               INTEGER                  DEFAULT 0,                               	-- 이탈 사용자 수

	-- 활동 통계
    total_logins                INTEGER                  DEFAULT 0,                               	-- 총 로그인 횟수
    total_api_calls             INTEGER                  DEFAULT 0,                               	-- 총 API 호출 횟수
    total_ai_requests           INTEGER                  DEFAULT 0,                               	-- 총 AI 요청 횟수
    total_storage_used       	NUMERIC(18,4)            DEFAULT 0,                               	-- 총 스토리지 사용량 (GB)

	-- 비즈니스 통계
    revenue              		NUMERIC(18,4)            DEFAULT 0,                               	-- 매출액
    churn_rate          		NUMERIC(5,2)             DEFAULT 0,                               	-- 고객 이탈률 (%)
    acquisition_cost   			NUMERIC(18,4)            DEFAULT 0,                               	-- 고객 획득 비용 (CAC)
    lifetime_value              NUMERIC(18,4)            DEFAULT 0,                               	-- 고객 생애 가치 (CLV)

	-- 성능 통계
    avg_response_time        	NUMERIC(18,4)            DEFAULT 0,                               	-- 평균 응답 시간 (밀리초)
    error_count                 INTEGER                  DEFAULT 0,                               	-- 오류 발생 횟수
    uptime_minutes              INTEGER                  DEFAULT 0,                               	-- 정상 가동 시간 (분)
    downtime_minutes            INTEGER                  DEFAULT 0,                               	-- 장애 시간 (분)

	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- 요약 데이터 상태 (ACTIVE/ARCHIVED/RECALCULATING)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT fk_usage_stats__tenant_id 				FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,

    CONSTRAINT ck_usage_stats__summary_type 			CHECK (summary_type IN ('DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY')),
    CONSTRAINT ck_usage_stats__status 					CHECK (status IN ('ACTIVE', 'ARCHIVED', 'RECALCULATING')),
    CONSTRAINT ck_usage_stats__total_users 				CHECK (total_users >= 0),
    CONSTRAINT ck_usage_stats__active_users 			CHECK (active_users >= 0),
    CONSTRAINT ck_usage_stats__new_users 				CHECK (new_users >= 0),
    CONSTRAINT ck_usage_stats__churned_users 			CHECK (churned_users >= 0),
    CONSTRAINT ck_usage_stats__total_logins 			CHECK (total_logins >= 0),
    CONSTRAINT ck_usage_stats__total_api_calls 			CHECK (total_api_calls >= 0),
    CONSTRAINT ck_usage_stats__total_ai_requests 		CHECK (total_ai_requests >= 0),
    CONSTRAINT ck_usage_stats__total_storage_used 		CHECK (total_storage_used >= 0),
    CONSTRAINT ck_usage_stats__revenue 					CHECK (revenue >= 0),
    CONSTRAINT ck_usage_stats__churn_rate 				CHECK (churn_rate >= 0 AND churn_rate <= 100),
    CONSTRAINT ck_usage_stats__acquisition_cost 		CHECK (acquisition_cost >= 0),
    CONSTRAINT ck_usage_stats__lifetime_value 			CHECK (lifetime_value >= 0),
    CONSTRAINT ck_usage_stats__avg_response_time 		CHECK (avg_response_time >= 0),
    CONSTRAINT ck_usage_stats__error_count 				CHECK (error_count >= 0),
    CONSTRAINT ck_usage_stats__uptime_minutes 			CHECK (uptime_minutes >= 0),
    CONSTRAINT ck_usage_stats__downtime_minutes 		CHECK (downtime_minutes >= 0),
    CONSTRAINT ck_usage_stats__user_logic 				CHECK (active_users <= total_users)
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  stat.usage_stats						IS '사용량 요약 통계 - 주기별로 집계된 사용량, 비즈니스 지표, 성능 데이터를 통한 종합적인 서비스 운영 분석';
COMMENT ON COLUMN stat.usage_stats.id 					IS '사용량 요약 고유 식별자 - UUID 형태의 기본키, 각 요약 통계를 구분하는 고유값';
COMMENT ON COLUMN stat.usage_stats.created_at 			IS '사용량 요약 생성 일시 - 요약 데이터가 계산되고 저장된 시점의 타임스탬프';
COMMENT ON COLUMN stat.usage_stats.created_by 			IS '사용량 요약 생성자 UUID - 요약 통계를 생성한 시스템 또는 분석 엔진의 식별자';
COMMENT ON COLUMN stat.usage_stats.updated_at 			IS '사용량 요약 수정 일시 - 요약 데이터가 재계산되거나 수정된 시점의 타임스탬프';
COMMENT ON COLUMN stat.usage_stats.updated_by 			IS '사용량 요약 수정자 UUID - 요약 통계를 수정한 시스템 또는 관리자의 식별자';
COMMENT ON COLUMN stat.usage_stats.tenant_id 			IS '테넌트 ID - 요약 대상 테넌트의 고유 식별자 (NULL인 경우 전체 플랫폼 통계, tenants 테이블 참조)';
COMMENT ON COLUMN stat.usage_stats.summary_date 		IS '요약 기준일 - 통계 데이터의 기준 날짜 (일별은 해당일, 주별은 주 시작일, 월별은 월 시작일)';
COMMENT ON COLUMN stat.usage_stats.summary_type 		IS '요약 주기 - DAILY(일별), WEEKLY(주별), MONTHLY(월별), QUARTERLY(분기별), YEARLY(연별) 집계 단위';
COMMENT ON COLUMN stat.usage_stats.total_users 			IS '총 사용자 수 - 해당 기간 기준 누적된 전체 사용자 수 (탈퇴 사용자 제외)';
COMMENT ON COLUMN stat.usage_stats.active_users 		IS '활성 사용자 수 - 해당 기간 중 실제로 시스템을 사용한 사용자 수';
COMMENT ON COLUMN stat.usage_stats.new_users 			IS '신규 사용자 수 - 해당 기간 중 새로 가입한 사용자 수';
COMMENT ON COLUMN stat.usage_stats.churned_users 		IS '이탈 사용자 수 - 해당 기간 중 서비스를 중단하거나 탈퇴한 사용자 수';
COMMENT ON COLUMN stat.usage_stats.total_logins 		IS '총 로그인 횟수 - 해당 기간 중 발생한 모든 로그인 시도의 총 횟수';
COMMENT ON COLUMN stat.usage_stats.total_api_calls 		IS '총 API 호출 횟수 - 해당 기간 중 수행된 모든 API 요청의 총 횟수';
COMMENT ON COLUMN stat.usage_stats.total_ai_requests 	IS '총 AI 요청 횟수 - 해당 기간 중 AI 서비스에 대한 모든 요청의 총 횟수';
COMMENT ON COLUMN stat.usage_stats.total_storage_used 	IS '총 스토리지 사용량 - 해당 기간 말 기준 사용 중인 총 저장공간 크기 (GB 단위)';
COMMENT ON COLUMN stat.usage_stats.revenue 				IS '매출액 - 해당 기간 중 발생한 총 매출 (구독료, 사용량 기반 요금, 추가 서비스 등 포함)';
COMMENT ON COLUMN stat.usage_stats.churn_rate 			IS '고객 이탈률 - 해당 기간 중 이탈한 고객의 비율 (0-100%, 이탈고객수/전체고객수*100)';
COMMENT ON COLUMN stat.usage_stats.acquisition_cost 	IS '고객 획득 비용 - 신규 고객 한 명을 획득하는 데 소요된 평균 마케팅 비용 (CAC)';
COMMENT ON COLUMN stat.usage_stats.lifetime_value 		IS '고객 생애 가치 - 고객 한 명이 생애주기 동안 가져다줄 것으로 예상되는 총 수익 (CLV)';
COMMENT ON COLUMN stat.usage_stats.avg_response_time 	IS '평균 응답 시간 - 해당 기간 중 API 요청에 대한 평균 응답 시간 (밀리초 단위)';
COMMENT ON COLUMN stat.usage_stats.error_count 			IS '오류 발생 횟수 - 해당 기간 중 발생한 시스템 오류, API 오류 등의 총 횟수';
COMMENT ON COLUMN stat.usage_stats.uptime_minutes 		IS '정상 가동 시간 - 해당 기간 중 시스템이 정상적으로 작동한 총 시간 (분 단위)';
COMMENT ON COLUMN stat.usage_stats.downtime_minutes 	IS '장애 시간 - 해당 기간 중 시스템 장애나 점검으로 인한 서비스 중단 시간 (분 단위)';
COMMENT ON COLUMN stat.usage_stats.status 				IS '요약 데이터 상태 - ACTIVE(현재 유효), ARCHIVED(보관), RECALCULATING(재계산 중) 데이터 생명주기 관리';
COMMENT ON COLUMN stat.usage_stats.deleted 				IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 요약 기준일 조회 최적화
CREATE INDEX IF NOT EXISTS ix_usage_stats__summary_date
    ON stat.usage_stats (summary_date DESC);

-- 테넌트별 요약 조회 최적화
CREATE INDEX IF NOT EXISTS ix_usage_stats__tenant_id
    ON stat.usage_stats (tenant_id, summary_date DESC)
 WHERE tenant_id IS NOT NULL AND deleted = FALSE;

-- 요약 주기별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_usage_stats__summary_type
    ON stat.usage_stats (summary_type, summary_date DESC)
 WHERE deleted = FALSE;

-- 전체 플랫폼 통계 조회 최적화
CREATE INDEX IF NOT EXISTS ix_usage_stats__platform_stats
    ON stat.usage_stats (summary_type, summary_date DESC)
 WHERE tenant_id IS NULL AND deleted = FALSE;

-- 매출 분석 최적화
CREATE INDEX IF NOT EXISTS ix_usage_stats__revenue_analysis
    ON stat.usage_stats (revenue DESC, summary_date DESC)
 WHERE deleted = FALSE;

-- 사용자 성장 분석 최적화
CREATE INDEX IF NOT EXISTS ix_usage_stats__user_growth
    ON stat.usage_stats (new_users DESC, active_users DESC, summary_date DESC)
 WHERE deleted = FALSE;

-- 이탈률 분석 최적화
CREATE INDEX IF NOT EXISTS ix_usage_stats__churn_analysis
    ON stat.usage_stats (churn_rate DESC, churned_users DESC, summary_date DESC)
 WHERE deleted = FALSE;

-- 활동 지표 분석 최적화
CREATE INDEX IF NOT EXISTS ix_usage_stats__activity_metrics
    ON stat.usage_stats (total_api_calls DESC, total_ai_requests DESC, summary_date DESC)
 WHERE deleted = FALSE;

-- 성능 지표 분석 최적화
CREATE INDEX IF NOT EXISTS ix_usage_stats__performance_metrics
    ON stat.usage_stats (avg_response_time DESC, error_count DESC, summary_date DESC)
 WHERE deleted = FALSE;

-- 월별 보고서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_usage_stats__monthly_reports
    ON stat.usage_stats (summary_type, summary_date DESC)
 WHERE summary_type = 'MONTHLY' AND deleted = FALSE;

-- 비즈니스 지표 분석 최적화
CREATE INDEX IF NOT EXISTS ix_usage_stats__business_metrics
    ON stat.usage_stats (acquisition_cost, lifetime_value, summary_date DESC)
 WHERE deleted = FALSE;

-- 테넌트별 주기 조회 최적화
CREATE INDEX IF NOT EXISTS ix_usage_stats__tenant_summary_type
    ON stat.usage_stats (tenant_id, summary_type, summary_date DESC)
 WHERE deleted = FALSE;

-- 생성 시간 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_usage_stats__created_at
    ON stat.usage_stats (created_at DESC);
