-- ============================================================================
-- 6. 보안 및 감사 (Security & Audit) -> audt
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS audt;

COMMENT ON SCHEMA audt
IS 'AUDT: 보안/감사 스키마: 보안 이벤트 기록과 규정 준수 산출물을 저장(append-only 권장).';

-- ============================================================================
-- 보안 감사 로그
-- ============================================================================
CREATE TABLE IF NOT EXISTS audt.audit_logs
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 감사 로그 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,                   	-- 감사 로그 생성 일시
    created_by                  UUID,                                                              	-- 감사 로그 생성자 UUID (시스템 또는 프로세스)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 감사 로그 수정 일시
    updated_by                  UUID,                                                              	-- 감사 로그 수정자 UUID
    -- 관련 엔티티 연결
    tenant_id                   UUID,                                                              	-- 테넌트별 이벤트인 경우 테넌트 ID
    user_id                     UUID,                                                              	-- 사용자별 이벤트인 경우 사용자 ID
    -- 이벤트 분류 및 정보
    event_type                  VARCHAR(50)              NOT NULL,                                 	-- 이벤트 유형 (LOGIN/LOGOUT/API_CALL/DATA_ACCESS/ADMIN_ACTION)
    event_category              VARCHAR(50)              NOT NULL,                                 	-- 이벤트 분류 (AUTHENTICATION/AUTHORIZATION/DATA_MODIFICATION/SYSTEM_CHANGE)
    description                 TEXT                     NOT NULL,                                 	-- 이벤트 상세 설명
    -- 클라이언트 접근 정보
    source_ip                   VARCHAR(45),                                                       	-- 클라이언트 IP 주소 (IPv4/IPv6 지원)
    user_agent                  TEXT,                                                              	-- 브라우저/클라이언트 정보
    session_id                  VARCHAR(255),                                                      	-- 세션 ID
    -- 대상 리소스 정보
    resource_type               VARCHAR(50),                                                       	-- 리소스 유형 (TABLE/API_ENDPOINT/FILE/CONFIGURATION)
    resource_id                 VARCHAR(255),                                                      	-- 접근한 리소스 식별자
    action_performed            VARCHAR(50),                                                       	-- 수행된 작업 (CREATE/READ/UPDATE/DELETE/EXECUTE)
    -- 결과 및 위험도 정보
    result                      VARCHAR(20)              NOT NULL,                                 	-- 이벤트 결과 (SUCCESS/FAILURE/BLOCKED)
    failure_reason              TEXT,                                                              	-- 실패 사유 (실패 시 상세 이유)
    risk_level                  VARCHAR(20)              NOT NULL DEFAULT 'LOW',                  	-- 위험도 (HIGH/MEDIUM/LOW)
    -- 확장 메타데이터
    extra_data             		JSONB                    DEFAULT '{}',                            	-- 추가 데이터 (JSON 형태)
    -- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- 감사 로그 상태 (ACTIVE/ARCHIVED/PURGED)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT fk_audit_logs__tenant_id 			FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,
    CONSTRAINT fk_audit_logs__user_id 				FOREIGN KEY (user_id) 	REFERENCES tnnt.users(id)	ON DELETE CASCADE,

    CONSTRAINT ck_audit_logs__event_type 			CHECK (event_type IN ('LOGIN', 'LOGOUT', 'API_CALL', 'DATA_ACCESS', 'ADMIN_ACTION', 'PASSWORD_CHANGE', 'PERMISSION_CHANGE')),
    CONSTRAINT ck_audit_logs__event_category 		CHECK (event_category IN ('AUTHENTICATION', 'AUTHORIZATION', 'DATA_MODIFICATION', 'SYSTEM_CHANGE', 'SECURITY_VIOLATION')),
    CONSTRAINT ck_audit_logs__resource_type 		CHECK (resource_type IN ('TABLE', 'API_ENDPOINT', 'FILE', 'CONFIGURATION', 'USER_ACCOUNT', 'TENANT_SETTINGS')),
    CONSTRAINT ck_audit_logs__action_performed 		CHECK (action_performed IN ('CREATE', 'READ', 'UPDATE', 'DELETE', 'EXECUTE', 'LOGIN', 'LOGOUT')),
    CONSTRAINT ck_audit_logs__result 				CHECK (result IN ('SUCCESS', 'FAILURE', 'BLOCKED')),
    CONSTRAINT ck_audit_logs__risk_level 			CHECK (risk_level IN ('HIGH', 'MEDIUM', 'LOW')),
    CONSTRAINT ck_audit_logs__status 				CHECK (status IN ('ACTIVE', 'ARCHIVED', 'PURGED'))
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  audt.audit_logs					IS '보안 감사 로그 - 모든 보안 관련 이벤트와 중요한 비즈니스 액션의 상세 기록을 통한 컴플라이언스 및 보안 모니터링';
COMMENT ON COLUMN audt.audit_logs.id 				IS '감사 로그 고유 식별자 - UUID 형태의 기본키, 각 감사 이벤트를 구분하는 고유값';
COMMENT ON COLUMN audt.audit_logs.created_at 		IS '감사 로그 생성 일시 - 감사 이벤트가 발생한 시점의 타임스탬프';
COMMENT ON COLUMN audt.audit_logs.created_by 		IS '감사 로그 생성자 UUID - 감사 이벤트를 기록한 시스템 프로세스 또는 서비스의 식별자';
COMMENT ON COLUMN audt.audit_logs.updated_at 		IS '감사 로그 수정 일시 - 감사 로그 정보가 수정된 시점의 타임스탬프 (일반적으로 수정되지 않음)';
COMMENT ON COLUMN audt.audit_logs.updated_by 		IS '감사 로그 수정자 UUID - 감사 로그를 수정한 시스템 또는 관리자의 식별자';
COMMENT ON COLUMN audt.audit_logs.tenant_id 		IS '테넌트별 이벤트인 경우 테넌트 ID - 특정 테넌트와 관련된 이벤트의 테넌트 식별자 (tenants 테이블 참조)';
COMMENT ON COLUMN audt.audit_logs.user_id 			IS '사용자별 이벤트인 경우 사용자 ID - 특정 사용자가 수행한 액션의 사용자 식별자 (users 테이블 참조)';
COMMENT ON COLUMN audt.audit_logs.event_type 		IS '이벤트 유형 - LOGIN(로그인), LOGOUT(로그아웃), API_CALL(API호출), DATA_ACCESS(데이터접근), ADMIN_ACTION(관리자작업), PASSWORD_CHANGE(비밀번호변경)';
COMMENT ON COLUMN audt.audit_logs.event_category 	IS '이벤트 분류 - AUTHENTICATION(인증), AUTHORIZATION(권한부여), DATA_MODIFICATION(데이터수정), SYSTEM_CHANGE(시스템변경), SECURITY_VIOLATION(보안위반)';
COMMENT ON COLUMN audt.audit_logs.description 		IS '이벤트 상세 설명 - 수행된 액션의 구체적인 내용과 맥락 정보';
COMMENT ON COLUMN audt.audit_logs.source_ip 		IS '클라이언트 IP 주소 - 요청을 보낸 클라이언트의 IP 주소 (IPv4/IPv6 지원, 최대 45자)';
COMMENT ON COLUMN audt.audit_logs.user_agent 		IS '브라우저/클라이언트 정보 - HTTP User-Agent 헤더 또는 클라이언트 애플리케이션 정보';
COMMENT ON COLUMN audt.audit_logs.session_id 		IS '세션 ID - 이벤트가 발생한 사용자 세션의 식별자 (세션 추적용)';
COMMENT ON COLUMN audt.audit_logs.resource_type 	IS '리소스 유형 - TABLE(테이블), API_ENDPOINT(API엔드포인트), FILE(파일), CONFIGURATION(설정), USER_ACCOUNT(사용자계정), TENANT_SETTINGS(테넌트설정)';
COMMENT ON COLUMN audt.audit_logs.resource_id 		IS '접근한 리소스 식별자 - 액션의 대상이 된 구체적인 리소스의 ID 또는 경로';
COMMENT ON COLUMN audt.audit_logs.action_performed 	IS '수행된 작업 - CREATE(생성), READ(조회), UPDATE(수정), DELETE(삭제), EXECUTE(실행), LOGIN(로그인), LOGOUT(로그아웃)';
COMMENT ON COLUMN audt.audit_logs.result 			IS '이벤트 결과 - SUCCESS(성공), FAILURE(실패), BLOCKED(차단) 액션 수행 결과';
COMMENT ON COLUMN audt.audit_logs.failure_reason 	IS '실패 사유 - 액션이 실패하거나 차단된 경우의 구체적인 이유와 오류 메시지';
COMMENT ON COLUMN audt.audit_logs.risk_level 		IS '위험도 - HIGH(높음, 민감한 작업), MEDIUM(보통, 일반적 작업), LOW(낮음, 단순 조회) 보안 위험도 평가';
COMMENT ON COLUMN audt.audit_logs.extra_data 		IS '추가 감사 데이터 - 이벤트와 관련된 추가 정보 (JSON 형태, 변경 전후 값, 요청 파라미터 등)';
COMMENT ON COLUMN audt.audit_logs.status 			IS '감사 로그 상태 - ACTIVE(활성), ARCHIVED(보관), PURGED(삭제예정) 로그 관리 상태';
COMMENT ON COLUMN audt.audit_logs.deleted 			IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 시간 기준 감사 로그 조회 최적화 (가장 중요)
CREATE INDEX IF NOT EXISTS ix_audit_logs__created_at
    ON audt.audit_logs (created_at DESC);

-- 테넌트별 감사 로그 조회 최적화
CREATE INDEX IF NOT EXISTS ix_audit_logs__tenant_id
    ON audt.audit_logs (tenant_id, created_at DESC)
 WHERE tenant_id IS NOT NULL
   AND deleted = FALSE;

-- 사용자별 감사 로그 조회 최적화
CREATE INDEX IF NOT EXISTS ix_audit_logs__user_id
    ON audt.audit_logs (user_id, created_at DESC)
 WHERE user_id IS NOT NULL
   AND deleted = FALSE;

-- 이벤트 유형별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_audit_logs__event_type
    ON audt.audit_logs (event_type, created_at DESC)
 WHERE deleted = FALSE;

-- 이벤트 분류별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_audit_logs__event_category
    ON audt.audit_logs (event_category, created_at DESC)
 WHERE deleted = FALSE;

-- 위험도별 감사 로그 조회 최적화
CREATE INDEX IF NOT EXISTS ix_audit_logs__risk_level
    ON audt.audit_logs (risk_level, created_at DESC)
 WHERE deleted = FALSE;

-- 결과별 감사 로그 조회 최적화
CREATE INDEX IF NOT EXISTS ix_audit_logs__result
    ON audt.audit_logs (result, created_at DESC)
 WHERE deleted = FALSE;

-- 고위험 이벤트 조회 최적화
CREATE INDEX IF NOT EXISTS ix_audit_logs__high_risk_audit_logs
    ON audt.audit_logs (risk_level, event_type, created_at DESC)
 WHERE risk_level = 'HIGH'
   AND deleted = FALSE;

-- 실패/차단 이벤트 조회 최적화
CREATE INDEX IF NOT EXISTS ix_audit_logs__failed_audit_logs
    ON audt.audit_logs (result, event_type, created_at DESC)
 WHERE result IN ('FAILURE', 'BLOCKED')
   AND deleted = FALSE;

-- IP별 감사 로그 조회 최적화
CREATE INDEX IF NOT EXISTS ix_audit_logs__source_ip
    ON audt.audit_logs (source_ip, created_at DESC)
 WHERE source_ip IS NOT NULL
   AND deleted = FALSE;

-- 세션별 감사 로그 추적 최적화
CREATE INDEX IF NOT EXISTS ix_audit_logs__session_id
    ON audt.audit_logs (session_id, created_at DESC)
 WHERE session_id IS NOT NULL
   AND deleted = FALSE;

-- 리소스별 접근 기록 조회 최적화
CREATE INDEX IF NOT EXISTS ix_audit_logs__resource_access
    ON audt.audit_logs (resource_type, resource_id, created_at DESC)
 WHERE resource_type IS NOT NULL
   AND deleted = FALSE;

-- 사용자별 액션 조회 최적화
CREATE INDEX IF NOT EXISTS ix_audit_logs__user_actions
    ON audt.audit_logs (user_id, action_performed, created_at DESC)
 WHERE user_id IS NOT NULL
   AND deleted = FALSE;

-- 테넌트별 보안 이벤트 조회 최적화
CREATE INDEX IF NOT EXISTS ix_audit_logs__tenant_security
    ON audt.audit_logs (tenant_id, risk_level, event_category, created_at DESC)
 WHERE tenant_id IS NOT NULL
   AND deleted = FALSE;

-- 추가 데이터 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_audit_logs__extra_data
    ON audt.audit_logs USING GIN (extra_data)
 WHERE deleted = FALSE;


-- ============================================================================
-- 컴플라이언스 보고서
-- ============================================================================
CREATE TABLE IF NOT EXISTS audt.compliances
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 컴플라이언스 보고서 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 보고서 생성 일시
    created_by                  UUID,                                                              	-- 보고서 생성자 UUID (시스템 또는 관리자)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 보고서 수정 일시
    updated_by                  UUID,                                                              	-- 보고서 수정자 UUID
    -- 보고서 기본 정보
    report_type                 VARCHAR(50)              NOT NULL,                                 	-- 보고서 유형 (GDPR/SOX/HIPAA/ISO27001/CUSTOM)
    report_name                 VARCHAR(200)             NOT NULL,                                 	-- 보고서 이름
    start_date                  DATE                     NOT NULL,                                 	-- 보고서 대상 기간 시작일
    close_date                  DATE                     NOT NULL,                                 	-- 보고서 대상 기간 종료일
    -- 보고서 생성 정보
    generated_at                TIMESTAMP WITH TIME ZONE NOT NULL,                                 	-- 보고서 실제 생성 일시
    generated_by                UUID,                                                              	-- 보고서 생성 담당자 UUID
    -- 보고서 범위 정보
    scope                       VARCHAR(50)              NOT NULL DEFAULT 'ALL_TENANTS',          	-- 보고서 적용 범위 (ALL_TENANTS/SPECIFIC_TENANT/SYSTEM_WIDE)
    tenant_ids                  UUID[],                                                            	-- 특정 테넌트 대상인 경우 테넌트 ID 배열
    -- 컴플라이언스 결과 정보
    compliance_status           VARCHAR(20)              NOT NULL,                                 	-- 컴플라이언스 상태 (COMPLIANT/NON_COMPLIANT/PARTIAL/PENDING)
    findings_count              INTEGER                  DEFAULT 0,                               	-- 발견된 총 이슈 수
    critical_count     			INTEGER                  DEFAULT 0,                               	-- 심각한 이슈 수
    -- 보고서 파일 정보
    file_path                   VARCHAR(500),                                                      	-- 보고서 파일 저장 경로
    file_size                   INTEGER,                                                           	-- 파일 크기 (bytes)
    file_type                   VARCHAR(20)              DEFAULT 'PDF',                           	-- 파일 형식 (PDF/EXCEL/JSON/HTML)
    -- 승인 정보
    approved_at                 TIMESTAMP WITH TIME ZONE,                                          	-- 보고서 승인 일시
    approved_by                 VARCHAR(100),                                                      	-- 승인자 (관리자 또는 감사관)
    -- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'DRAFT',                	-- 보고서 상태 (DRAFT/PENDING_REVIEW/APPROVED/PUBLISHED)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT fk_compliances__generated_by 			FOREIGN KEY (generated_by) REFERENCES tnnt.users(id)	ON DELETE CASCADE,

    CONSTRAINT ck_compliances__report_type 				CHECK (report_type IN ('GDPR', 'SOX', 'HIPAA', 'ISO27001', 'PCI_DSS', 'CCPA', 'CUSTOM')),
    CONSTRAINT ck_compliances__compliance_status 		CHECK (compliance_status IN ('COMPLIANT', 'NON_COMPLIANT', 'PARTIAL', 'PENDING')),
    CONSTRAINT ck_compliances__scope 					CHECK (scope IN ('ALL_TENANTS', 'SPECIFIC_TENANT', 'SYSTEM_WIDE')),
    CONSTRAINT ck_compliances__file_type 				CHECK (file_type IN ('PDF', 'EXCEL', 'JSON', 'HTML', 'CSV')),
    CONSTRAINT ck_compliances__status 					CHECK (status IN ('DRAFT', 'PENDING_REVIEW', 'APPROVED', 'PUBLISHED')),
    CONSTRAINT ck_compliances__findings_count 			CHECK (findings_count >= 0),
    CONSTRAINT ck_compliances__critical_count 			CHECK (critical_count >= 0),
    CONSTRAINT ck_compliances__critical_vs_total 		CHECK (critical_count <= findings_count),
    CONSTRAINT ck_compliances__date_range 				CHECK (close_date >= start_date),
    CONSTRAINT ck_compliances__file_size 				CHECK (file_size IS NULL OR file_size > 0)
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  audt.compliances						IS '컴플라이언스 보고서 - GDPR, SOX, HIPAA 등 각종 규정 준수 보고서의 생성, 승인, 관리를 통한 법적 요구사항 충족';
COMMENT ON COLUMN audt.compliances.id 					IS '컴플라이언스 보고서 고유 식별자 - UUID 형태의 기본키, 각 보고서를 구분하는 고유값';
COMMENT ON COLUMN audt.compliances.created_at 			IS '보고서 생성 일시 - 보고서 레코드가 시스템에 생성된 시점의 타임스탬프';
COMMENT ON COLUMN audt.compliances.created_by 			IS '보고서 생성자 UUID - 보고서를 생성한 시스템 또는 관리자의 식별자';
COMMENT ON COLUMN audt.compliances.updated_at 			IS '보고서 수정 일시 - 보고서 정보가 최종 변경된 시점의 타임스탬프';
COMMENT ON COLUMN audt.compliances.updated_by 			IS '보고서 수정자 UUID - 보고서를 최종 수정한 관리자 또는 시스템의 식별자';
COMMENT ON COLUMN audt.compliances.report_type 			IS '보고서 유형 - GDPR(개인정보보호), SOX(재무투명성), HIPAA(의료정보), ISO27001(정보보안), PCI_DSS(결제정보), CCPA(캘리포니아개인정보), CUSTOM(맞춤형)';
COMMENT ON COLUMN audt.compliances.report_name 			IS '보고서 이름 - 보고서의 제목 또는 설명적 이름 (예: 2024년 Q4 GDPR 준수 보고서)';
COMMENT ON COLUMN audt.compliances.start_date 			IS '보고서 대상 기간 시작일 - 컴플라이언스 검토 대상 기간의 시작 날짜';
COMMENT ON COLUMN audt.compliances.close_date 			IS '보고서 대상 기간 종료일 - 컴플라이언스 검토 대상 기간의 종료 날짜';
COMMENT ON COLUMN audt.compliances.generated_at 		IS '보고서 실제 생성 일시 - 보고서가 실제로 생성되고 완료된 시점';
COMMENT ON COLUMN audt.compliances.generated_by 		IS '보고서 생성 담당자 UUID - 보고서 생성을 담당한 사용자의 식별자 (users 테이블 참조)';
COMMENT ON COLUMN audt.compliances.scope 				IS '보고서 적용 범위 - ALL_TENANTS(전체 테넌트), SPECIFIC_TENANT(특정 테넌트), SYSTEM_WIDE(시스템 전체) 보고 범위 구분';
COMMENT ON COLUMN audt.compliances.tenant_ids 			IS '특정 테넌트 대상인 경우 테넌트 ID 배열 - scope가 SPECIFIC_TENANT일 때 대상 테넌트들의 UUID 배열';
COMMENT ON COLUMN audt.compliances.compliance_status 	IS '컴플라이언스 상태 - COMPLIANT(준수), NON_COMPLIANT(미준수), PARTIAL(부분준수), PENDING(검토중) 규정 준수 결과';
COMMENT ON COLUMN audt.compliances.findings_count 		IS '발견된 총 이슈 수 - 컴플라이언스 검토 과정에서 발견된 모든 문제점의 개수';
COMMENT ON COLUMN audt.compliances.critical_count 		IS '심각한 이슈 수 - 즉시 조치가 필요한 중대한 컴플라이언스 위반 사항의 개수';
COMMENT ON COLUMN audt.compliances.file_path 			IS '보고서 파일 저장 경로 - 생성된 보고서 파일의 서버 또는 클라우드 스토리지 경로';
COMMENT ON COLUMN audt.compliances.file_size 			IS '파일 크기 - 보고서 파일의 크기 (바이트 단위)';
COMMENT ON COLUMN audt.compliances.file_type 			IS '파일 형식 - PDF(일반문서), EXCEL(스프레드시트), JSON(구조화데이터), HTML(웹문서), CSV(데이터파일) 보고서 형식';
COMMENT ON COLUMN audt.compliances.approved_at 			IS '보고서 승인 일시 - 관리자나 감사관이 보고서를 최종 승인한 시점';
COMMENT ON COLUMN audt.compliances.approved_by 			IS '승인자 - 보고서를 최종 승인한 관리자, 감사관, 또는 외부 기관의 이름';
COMMENT ON COLUMN audt.compliances.status 				IS '보고서 상태 - DRAFT(초안), PENDING_REVIEW(검토대기), APPROVED(승인완료), PUBLISHED(공개/제출완료) 처리 단계';
COMMENT ON COLUMN audt.compliances.deleted 				IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 보고서 유형별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_compliances__report_type
    ON audt.compliances (report_type, created_at DESC)
 WHERE deleted = FALSE;

-- 상태별 보고서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_compliances__status
    ON audt.compliances (status, created_at DESC)
 WHERE deleted = FALSE;

-- 컴플라이언스 상태별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_compliances__compliance_status
    ON audt.compliances (compliance_status, created_at DESC)
 WHERE deleted = FALSE;

-- 생성일 기준 보고서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_compliances__generated_at
    ON audt.compliances (generated_at DESC);

-- 보고 기간별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_compliances__report_period
    ON audt.compliances (start_date, close_date, created_at DESC)
 WHERE deleted = FALSE;

-- 생성자별 보고서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_compliances__generated_by
    ON audt.compliances (generated_by, created_at DESC)
 WHERE generated_by IS NOT NULL AND deleted = FALSE;

-- 범위별 보고서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_compliances__scope
    ON audt.compliances (scope, created_at DESC)
 WHERE deleted = FALSE;

-- 미준수 보고서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_compliances__non_compliant
    ON audt.compliances (compliance_status, findings_count DESC, created_at DESC)
 WHERE compliance_status = 'NON_COMPLIANT' AND deleted = FALSE;

-- 심각한 이슈 보고서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_compliances__critical_findings
    ON audt.compliances (critical_count DESC, created_at DESC)
 WHERE critical_count > 0 AND deleted = FALSE;

-- 승인 대기 보고서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_compliances__pending_approval
    ON audt.compliances (status, generated_at DESC)
 WHERE status = 'PENDING_REVIEW' AND deleted = FALSE;

-- 승인된 보고서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_compliances__approved_reports
    ON audt.compliances (approved_at DESC, approved_by)
 WHERE approved_at IS NOT NULL AND deleted = FALSE;

-- 특정 테넌트 보고서 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_compliances__tenant_scope
    ON audt.compliances USING GIN (tenant_ids)
 WHERE scope = 'SPECIFIC_TENANT' AND deleted = FALSE;

-- 파일 정보별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_compliances__file_info
    ON audt.compliances (file_type, file_size DESC)
 WHERE file_path IS NOT NULL AND deleted = FALSE;

-- 생성 시간 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_compliances__created_at
    ON audt.compliances (created_at DESC);


-- ============================================================================
-- 보안 정책 관리
-- ============================================================================
CREATE TABLE IF NOT EXISTS audt.policies
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),    	-- 보안 정책 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,                   	-- 보안 정책 생성 일시
    created_by                  UUID,                                                              	-- 보안 정책 생성자 UUID (관리자)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 보안 정책 수정 일시
    updated_by                  UUID,                                                              	-- 보안 정책 수정자 UUID

	-- 정책 기본 정보
    policy_name                 VARCHAR(200)             NOT NULL,                                 	-- 정책 이름
    policy_type                 VARCHAR(50)              NOT NULL,                                 	-- 정책 유형 (PASSWORD/ACCESS_CONTROL/DATA_RETENTION/ENCRYPTION)
    policy_category             VARCHAR(50)              NOT NULL,                                 	-- 정책 분류 (AUTHENTICATION/AUTHORIZATION/DATA_PROTECTION/MONITORING)

	-- 정책 상세 내용
    description                 TEXT,                                                              	-- 정책 설명
    rules                       JSONB                    NOT NULL,                                 	-- 정책 규칙 (JSON 형태)

	-- 정책 적용 범위
    apply_to_all_tenants        BOOLEAN                  DEFAULT TRUE,                            	-- 전체 테넌트 적용 여부
    tenant_ids                  UUID[],                                                            	-- 특정 테넌트만 적용하는 경우 테넌트 ID 배열

	-- 정책 시행 정보
    effective_date              DATE                     NOT NULL,                                 	-- 정책 시행 시작일
    expiry_date                 DATE,                                                             	-- 정책 만료일 (NULL: 무기한)
    enforcement_level           VARCHAR(20)              NOT NULL DEFAULT 'MANDATORY',            	-- 시행 수준 (MANDATORY/RECOMMENDED/OPTIONAL)

	-- 버전 관리
    version                     VARCHAR(20)              NOT NULL,                                 	-- 정책 버전
    previous_version_id         UUID,                                                              	-- 이전 버전 참조

	-- 승인 정보
    approved_at                 TIMESTAMP WITH TIME ZONE,                                          	-- 정책 승인 일시
    approved_by                 VARCHAR(100),                                                      	-- 승인자 (보안 관리자, CISO 등)

	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'DRAFT',                	-- 정책 상태 (DRAFT/PENDING_APPROVAL/ACTIVE/ARCHIVED)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT fk_policies__previous_version_id 		FOREIGN KEY (previous_version_id) REFERENCES audt.policies(id)	ON DELETE CASCADE,

    CONSTRAINT ck_policies__policy_type 				CHECK (policy_type IN ('PASSWORD', 'ACCESS_CONTROL', 'DATA_RETENTION', 'ENCRYPTION', 'AUTHENTICATION', 'NETWORK_SECURITY')),
    CONSTRAINT ck_policies__policy_category 			CHECK (policy_category IN ('AUTHENTICATION', 'AUTHORIZATION', 'DATA_PROTECTION', 'MONITORING', 'INCIDENT_RESPONSE', 'COMPLIANCE')),
    CONSTRAINT ck_policies__enforcement_level 			CHECK (enforcement_level IN ('MANDATORY', 'RECOMMENDED', 'OPTIONAL')),
    CONSTRAINT ck_policies__status 						CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'ARCHIVED')),
    CONSTRAINT ck_policies__effective_date 				CHECK (expiry_date IS NULL OR expiry_date >= effective_date),
    CONSTRAINT ck_policies__tenant_scope_logic 			CHECK ((apply_to_all_tenants = TRUE AND tenant_ids IS NULL) OR (apply_to_all_tenants = FALSE AND tenant_ids IS NOT NULL))
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  audt.policies							IS '보안 정책 관리 - 시스템 전반의 보안 정책 정의, 버전 관리, 승인 프로세스를 통한 일관된 보안 거버넌스';
COMMENT ON COLUMN audt.policies.id 						IS '보안 정책 고유 식별자 - UUID 형태의 기본키, 각 보안 정책을 구분하는 고유값';
COMMENT ON COLUMN audt.policies.created_at 				IS '보안 정책 생성 일시 - 정책이 시스템에 등록된 시점의 타임스탬프';
COMMENT ON COLUMN audt.policies.created_by 				IS '보안 정책 생성자 UUID - 정책을 생성한 관리자 또는 보안 담당자의 식별자';
COMMENT ON COLUMN audt.policies.updated_at 				IS '보안 정책 수정 일시 - 정책이 최종 수정된 시점의 타임스탬프';
COMMENT ON COLUMN audt.policies.updated_by 				IS '보안 정책 수정자 UUID - 정책을 최종 수정한 관리자 또는 보안 담당자의 식별자';
COMMENT ON COLUMN audt.policies.policy_name 			IS '정책 이름 - 보안 정책의 명칭 (예: 비밀번호 복잡도 정책, 접근 제어 정책)';
COMMENT ON COLUMN audt.policies.policy_type 			IS '정책 유형 - PASSWORD(비밀번호), ACCESS_CONTROL(접근제어), DATA_RETENTION(데이터보관), ENCRYPTION(암호화), AUTHENTICATION(인증), NETWORK_SECURITY(네트워크보안)';
COMMENT ON COLUMN audt.policies.policy_category 		IS '정책 분류 - AUTHENTICATION(인증), AUTHORIZATION(권한부여), DATA_PROTECTION(데이터보호), MONITORING(모니터링), INCIDENT_RESPONSE(사고대응), COMPLIANCE(컴플라이언스)';
COMMENT ON COLUMN audt.policies.description 			IS '정책 설명 - 보안 정책의 목적, 적용 범위, 주요 내용에 대한 상세 설명';
COMMENT ON COLUMN audt.policies.rules 					IS '정책 규칙 - 구체적인 보안 규칙과 설정값들을 JSON 형태로 구조화 (예: 비밀번호 최소길이, 암호화 알고리즘 등)';
COMMENT ON COLUMN audt.policies.apply_to_all_tenants 	IS '전체 테넌트 적용 여부 - TRUE(모든 테넌트에 적용), FALSE(특정 테넌트만 적용)';
COMMENT ON COLUMN audt.policies.tenant_ids 				IS '특정 테넌트만 적용하는 경우 테넌트 ID 배열 - apply_to_all_tenants가 FALSE일 때 적용 대상 테넌트들의 UUID 배열';
COMMENT ON COLUMN audt.policies.effective_date 			IS '정책 시행 시작일 - 보안 정책이 실제로 적용되기 시작하는 날짜';
COMMENT ON COLUMN audt.policies.expiry_date 			IS '정책 만료일 - 보안 정책이 만료되는 날짜 (NULL인 경우 무기한 적용)';
COMMENT ON COLUMN audt.policies.enforcement_level 		IS '시행 수준 - MANDATORY(필수, 강제적용), RECOMMENDED(권장, 가이드라인), OPTIONAL(선택, 참고사항)';
COMMENT ON COLUMN audt.policies.version 				IS '정책 버전 - 정책의 버전 정보 (예: 1.0, 2.1, 3.0) 변경 이력 추적용';
COMMENT ON COLUMN audt.policies.previous_version_id 	IS '이전 버전 참조 - 이전 버전의 보안 정책 ID (버전 체인 추적용, self-reference)';
COMMENT ON COLUMN audt.policies.approved_at 			IS '정책 승인 일시 - 보안 정책이 공식적으로 승인된 시점';
COMMENT ON COLUMN audt.policies.approved_by 			IS '승인자 - 보안 정책을 최종 승인한 보안 관리자, CISO, 또는 경영진의 이름';
COMMENT ON COLUMN audt.policies.status 					IS '정책 상태 - DRAFT(초안), PENDING_APPROVAL(승인대기), ACTIVE(활성), ARCHIVED(보관) 정책 생명주기 단계';
COMMENT ON COLUMN audt.policies.deleted 				IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 정책 유형별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_policies__policy_type
    ON audt.policies (policy_type, created_at DESC)
 WHERE deleted = FALSE;

-- 정책 분류별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_policies__policy_category
    ON audt.policies (policy_category, created_at DESC)
 WHERE deleted = FALSE;

-- 상태별 정책 조회 최적화
CREATE INDEX IF NOT EXISTS ix_policies__status
    ON audt.policies (status, created_at DESC)
 WHERE deleted = FALSE;

-- 활성 정책 조회 최적화
CREATE INDEX IF NOT EXISTS ix_policies__active_policies
    ON audt.policies (status, effective_date, expiry_date)
 WHERE status = 'ACTIVE' AND deleted = FALSE;

-- 시행 수준별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_policies__enforcement_level
    ON audt.policies (enforcement_level, created_at DESC)
 WHERE deleted = FALSE;

-- 시행일 기준 정책 조회 최적화
CREATE INDEX IF NOT EXISTS ix_policies__effective_date
    ON audt.policies (effective_date DESC);

-- 만료 예정 정책 조회 최적화
CREATE INDEX IF NOT EXISTS ix_policies__expiry_date
    ON audt.policies (expiry_date)
 WHERE expiry_date IS NOT NULL AND deleted = FALSE;

-- 버전 체인 추적 최적화
CREATE INDEX IF NOT EXISTS ix_policies__version_chain
    ON audt.policies (previous_version_id, version)
 WHERE previous_version_id IS NOT NULL AND deleted = FALSE;

-- 승인 대기 정책 조회 최적화
CREATE INDEX IF NOT EXISTS ix_policies__pending_approval
    ON audt.policies (status, created_at DESC)
 WHERE status = 'PENDING_APPROVAL' AND deleted = FALSE;

-- 승인된 정책 조회 최적화
CREATE INDEX IF NOT EXISTS ix_policies__approved_policies
    ON audt.policies (approved_at DESC, approved_by)
 WHERE approved_at IS NOT NULL AND deleted = FALSE;

-- 특정 테넌트 정책 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_policies__tenant_specific
    ON audt.policies USING GIN (tenant_ids)
 WHERE apply_to_all_tenants = FALSE AND deleted = FALSE;

-- 정책 규칙 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_policies__rules
    ON audt.policies USING GIN (rules)
 WHERE deleted = FALSE;

-- 정책 이름으로 검색 최적화
CREATE INDEX IF NOT EXISTS ix_policies__policy_name
    ON audt.policies (policy_name)
 WHERE deleted = FALSE;

-- 생성 시간 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_policies__created_at
    ON audt.policies (created_at DESC);
