-- ============================================================================
-- 8. 지원 및 고객 관리 (Support Management) -> supt
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS supt;

COMMENT ON SCHEMA supt
IS 'SUPT: 지원/고객 커뮤니케이션 스키마: 고객지원 및 VOC 전용 데이터.';

-- ============================================================================
-- 고객 지원 티켓
-- ============================================================================
CREATE TABLE IF NOT EXISTS supt.tickets
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 지원 티켓 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 티켓 생성 일시
    created_by                  UUID,                                                              	-- 티켓 생성자 UUID (사용자 또는 시스템)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 티켓 수정 일시
    updated_by                  UUID,                                                              	-- 티켓 수정자 UUID
    -- 티켓 소유자 정보
    tenant_id                   UUID                     NOT NULL,                                 	-- 티켓 생성 테넌트 ID
    user_id                     UUID,                                                              	-- 티켓을 생성한 사용자 ID
    -- 티켓 기본 정보
    ticket_no                   VARCHAR(50)              NOT NULL UNIQUE,                          	-- 티켓 번호 (고유 식별용)
    title                       VARCHAR(200)             NOT NULL,                                 	-- 티켓 제목
    description                 TEXT                     NOT NULL,                                 	-- 문제 상세 설명
    category                    VARCHAR(50)              NOT NULL,                                 	-- 티켓 카테고리 (TECHNICAL/BILLING/FEATURE_REQUEST/BUG_REPORT/GENERAL)
    priority                    VARCHAR(20)              NOT NULL DEFAULT 'MEDIUM',               	-- 우선순위 (LOW/MEDIUM/HIGH/URGENT)
    -- 연락처 정보
    contact_email               VARCHAR(255)             NOT NULL,                                 	-- 연락용 이메일 주소
    contact_phone               VARCHAR(20),                                                       	-- 연락용 전화번호
    -- 할당 및 담당자 정보
    assigned_to                 VARCHAR(100),                                                      	-- 담당 지원팀원 또는 팀명
    assigned_at                 TIMESTAMP WITH TIME ZONE,                                          	-- 담당자 할당 일시
    -- SLA 및 응답 시간 관리
    sla_level                   VARCHAR(20)              NOT NULL DEFAULT 'STANDARD',             	-- SLA 수준 (BASIC/STANDARD/PREMIUM/ENTERPRISE)
    first_response_due          TIMESTAMP WITH TIME ZONE,                                          	-- SLA 기준 최초 응답 기한
    resolution_due              TIMESTAMP WITH TIME ZONE,                                          	-- SLA 기준 해결 기한
    first_response_at           TIMESTAMP WITH TIME ZONE,                                          	-- 실제 최초 응답 시각
    resolved_at                 TIMESTAMP WITH TIME ZONE,                                          	-- 실제 해결 완료 시각
    resolution_summary          TEXT,                                                              	-- 해결 요약 및 조치 내용
    -- 고객 만족도 정보
    customer_rating             INTEGER,                                                           	-- 고객 평점 (1-5점)
    customer_feedback          	TEXT,                                                              	-- 고객 피드백 및 의견
    -- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'OPEN',                 	-- 티켓 상태 (OPEN/IN_PROGRESS/PENDING_CUSTOMER/RESOLVED/CLOSED)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT fk_tickets__tenant_id 					FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,
    CONSTRAINT fk_tickets__user_id 						FOREIGN KEY (user_id) 	REFERENCES tnnt.users(id)	ON DELETE CASCADE,

    CONSTRAINT ck_tickets__category 					CHECK (category IN ('TECHNICAL', 'BILLING', 'FEATURE_REQUEST', 'BUG_REPORT', 'GENERAL', 'ACCOUNT_ISSUE')),
    CONSTRAINT ck_tickets__priority 					CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    CONSTRAINT ck_tickets__sla_level 					CHECK (sla_level IN ('BASIC', 'STANDARD', 'PREMIUM', 'ENTERPRISE')),
    CONSTRAINT ck_tickets__status 						CHECK (status IN ('OPEN', 'IN_PROGRESS', 'PENDING_CUSTOMER', 'RESOLVED', 'CLOSED')),
    CONSTRAINT ck_tickets__customer_rating 				CHECK (customer_rating IS NULL OR (customer_rating >= 1 AND customer_rating <= 5)),
    CONSTRAINT ck_tickets__contact_email_format 		CHECK (contact_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT ck_tickets__resolution_logic 			CHECK ((status = 'RESOLVED' AND resolved_at IS NOT NULL) OR (status != 'RESOLVED')),
    CONSTRAINT ck_tickets__assignment_logic 			CHECK ((assigned_to IS NOT NULL AND assigned_at IS NOT NULL) OR (assigned_to IS NULL AND assigned_at IS NULL))
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  supt.tickets							IS '고객 지원 티켓 - 고객 문의, 기술 지원, 버그 리포트 등 모든 지원 요청의 생명주기 관리와 SLA 추적';
COMMENT ON COLUMN supt.tickets.id 						IS '지원 티켓 고유 식별자 - UUID 형태의 기본키, 각 지원 요청을 구분하는 고유값';
COMMENT ON COLUMN supt.tickets.created_at 				IS '티켓 생성 일시 - 고객이 지원 요청을 제출한 시점의 타임스탬프';
COMMENT ON COLUMN supt.tickets.created_by 				IS '티켓 생성자 UUID - 티켓을 생성한 사용자 또는 시스템의 식별자';
COMMENT ON COLUMN supt.tickets.updated_at 				IS '티켓 수정 일시 - 티켓 정보가 최종 변경된 시점의 타임스탬프';
COMMENT ON COLUMN supt.tickets.updated_by 				IS '티켓 수정자 UUID - 티켓을 최종 수정한 지원팀원 또는 시스템의 식별자';
COMMENT ON COLUMN supt.tickets.tenant_id 				IS '티켓 생성 테넌트 ID - 지원 요청을 제출한 테넌트의 고유 식별자 (tenants 테이블 참조)';
COMMENT ON COLUMN supt.tickets.user_id 					IS '티켓을 생성한 사용자 ID - 실제 지원 요청을 제출한 사용자의 식별자 (users 테이블 참조, 익명 요청시 NULL)';
COMMENT ON COLUMN supt.tickets.ticket_no 				IS '티켓 번호 - 고객과 지원팀이 참조하는 고유한 티켓 식별번호 (예: TK-2024-001, SUPPORT-20241201-001)';
COMMENT ON COLUMN supt.tickets.title 					IS '티켓 제목 - 문제나 요청의 간략한 요약 제목';
COMMENT ON COLUMN supt.tickets.description 				IS '문제 상세 설명 - 고객이 제공한 문제 상황, 오류 메시지, 재현 단계 등의 상세 내용';
COMMENT ON COLUMN supt.tickets.category 				IS '티켓 카테고리 - TECHNICAL(기술지원), BILLING(결제문의), FEATURE_REQUEST(기능요청), BUG_REPORT(버그신고), GENERAL(일반문의), ACCOUNT_ISSUE(계정문제)';
COMMENT ON COLUMN supt.tickets.priority 				IS '우선순위 - LOW(낮음), MEDIUM(보통), HIGH(높음), URGENT(긴급) 처리 우선도 구분';
COMMENT ON COLUMN supt.tickets.contact_email 			IS '연락용 이메일 주소 - 티켓 업데이트 알림을 받을 고객의 이메일 주소';
COMMENT ON COLUMN supt.tickets.contact_phone 			IS '연락용 전화번호 - 긴급한 경우 직접 연락 가능한 고객의 전화번호';
COMMENT ON COLUMN supt.tickets.assigned_to 				IS '담당 지원팀원 또는 팀명 - 이 티켓을 처리하는 담당자나 팀의 이름';
COMMENT ON COLUMN supt.tickets.assigned_at 				IS '담당자 할당 일시 - 티켓이 특정 담당자에게 할당된 시점';
COMMENT ON COLUMN supt.tickets.sla_level 				IS 'SLA 수준 - BASIC(기본), STANDARD(표준), PREMIUM(프리미엄), ENTERPRISE(기업) 고객 등급에 따른 지원 수준';
COMMENT ON COLUMN supt.tickets.first_response_due 		IS 'SLA 기준 최초 응답 기한 - 고객 등급에 따른 최초 응답 목표 시간';
COMMENT ON COLUMN supt.tickets.resolution_due 			IS 'SLA 기준 해결 기한 - 고객 등급에 따른 문제 해결 목표 시간';
COMMENT ON COLUMN supt.tickets.first_response_at 		IS '실제 최초 응답 시각 - 지원팀이 고객에게 첫 번째 응답을 보낸 실제 시점';
COMMENT ON COLUMN supt.tickets.resolved_at 				IS '실제 해결 완료 시각 - 문제가 완전히 해결된 실제 시점';
COMMENT ON COLUMN supt.tickets.resolution_summary 		IS '해결 요약 및 조치 내용 - 문제 해결을 위해 취한 조치와 최종 결과의 요약';
COMMENT ON COLUMN supt.tickets.customer_rating 			IS '고객 평점 - 지원 서비스에 대한 고객 만족도 평가 (1-5점, 5점이 최고)';
COMMENT ON COLUMN supt.tickets.customer_feedback		IS '고객 피드백 및 의견 - 지원 서비스에 대한 고객의 추가 의견이나 개선 제안';
COMMENT ON COLUMN supt.tickets.status 					IS '티켓 상태 - OPEN(접수), IN_PROGRESS(처리중), PENDING_CUSTOMER(고객대기), RESOLVED(해결완료), CLOSED(종료) 처리 단계';
COMMENT ON COLUMN supt.tickets.deleted 					IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 티켓 번호 고유성 보장
CREATE UNIQUE INDEX IF NOT EXISTS ux_tickets__ticket_no
	ON supt.tickets (ticket_no)
 WHERE deleted = FALSE;

-- 테넌트별 티켓 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tickets__tenant_id
	ON supt.tickets (tenant_id, created_at DESC)
 WHERE deleted = FALSE;

-- 사용자별 티켓 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tickets__user_id
	ON supt.tickets (user_id, created_at DESC)
 WHERE user_id IS NOT NULL
   AND deleted = FALSE;

-- 상태별 티켓 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tickets__status
	ON supt.tickets (status, created_at DESC)
 WHERE deleted = FALSE;

-- 카테고리별 티켓 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tickets__category
	ON supt.tickets (category, created_at DESC)
 WHERE deleted = FALSE;

-- 우선순위별 티켓 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tickets__priority
	ON supt.tickets (priority, created_at DESC)
 WHERE deleted = FALSE;

-- 담당자별 티켓 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tickets__assigned_to
	ON supt.tickets (assigned_to, status, created_at DESC)
 WHERE assigned_to IS NOT NULL
   AND deleted = FALSE;

-- SLA 수준별 티켓 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tickets__sla_level
	ON supt.tickets (sla_level, created_at DESC)
 WHERE deleted = FALSE;

-- 진행중인 티켓 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tickets__open_tickets
	ON supt.tickets (status, priority, created_at DESC)
 WHERE status IN ('OPEN', 'IN_PROGRESS')
   AND deleted = FALSE;

-- 긴급 티켓 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tickets__urgent_tickets
	ON supt.tickets (priority, created_at DESC)
 WHERE priority = 'URGENT'
   AND status != 'CLOSED'
   AND deleted = FALSE;

-- SLA 추적 최적화
CREATE INDEX IF NOT EXISTS ix_tickets__sla_tracking
	ON supt.tickets (first_response_due, resolution_due, created_at DESC)
 WHERE status NOT IN ('RESOLVED', 'CLOSED')
   AND deleted = FALSE;

--CREATE INDEX IF NOT EXISTS ix_tickets__overdue_response 		ON supt.tickets (first_response_due, first_response_at) WHERE first_response_at IS NULL AND first_response_due < NOW() AND deleted = FALSE;	-- 응답 지연 티켓 조회 최적화
--CREATE INDEX IF NOT EXISTS ix_tickets__overdue_resolution 		ON supt.tickets (resolution_due, resolved_at) WHERE resolved_at IS NULL AND resolution_due < NOW() AND deleted = FALSE; 						-- 해결 지연 티켓 조회 최적화

-- 만족도 분석 최적화
CREATE INDEX IF NOT EXISTS ix_tickets__customer_satisfaction
 	ON supt.tickets (customer_rating DESC, created_at DESC)
 WHERE customer_rating IS NOT NULL
   AND deleted = FALSE;

-- 연락처로 티켓 검색 최적화
CREATE INDEX IF NOT EXISTS ix_tickets__contact_email
	ON supt.tickets (contact_email)
 WHERE deleted = FALSE;

-- 생성 시간 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_tickets__created_at
	ON supt.tickets (created_at DESC);


-- ============================================================================
-- 티켓 댓글 및 대화
-- ============================================================================
CREATE TABLE IF NOT EXISTS supt.ticket_comments
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 티켓 댓글 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 댓글 생성 일시
    created_by                  UUID,                                                              	-- 댓글 생성자 UUID (사용자 또는 시스템)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 댓글 수정 일시
    updated_by                  UUID,                                                              	-- 댓글 수정자 UUID

	-- 관련 엔티티 연결
    ticket_id                   UUID                     NOT NULL,                                 	-- 소속 티켓 ID
    user_id                     UUID,                                                              	-- 댓글 작성자 ID (고객 또는 지원팀원)

	-- 댓글 내용 정보
    comment_text                TEXT                     NOT NULL,                                 	-- 댓글 본문 내용
    comment_type                VARCHAR(20)              NOT NULL DEFAULT 'COMMENT',              	-- 댓글 유형 (COMMENT/INTERNAL_NOTE/STATUS_CHANGE/RESOLUTION)
    is_internal                 BOOLEAN                  DEFAULT FALSE,                           	-- 내부 댓글 여부 (고객에게 비공개)

	-- 첨부파일 정보
    files           	 		JSONB                    DEFAULT '[]',                            	-- 첨부 파일 목록 (JSON 배열)

	-- 자동화 정보
    automated                	BOOLEAN                  DEFAULT FALSE,                           	-- 시스템 자동 생성 여부
    automation_source           VARCHAR(50),                                                       	-- 자동화 소스 (EMAIL/CHATBOT/WORKFLOW/API)

	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- 댓글 상태 (ACTIVE/HIDDEN/DELETED)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT fk_ticket_comments__ticket_id 				FOREIGN KEY (ticket_id) REFERENCES supt.tickets(id)	ON DELETE CASCADE,
    CONSTRAINT fk_ticket_comments__user_id 					FOREIGN KEY (user_id) 	REFERENCES tnnt.users(id)	ON DELETE CASCADE,

    CONSTRAINT ck_ticket_comments__comment_type 			CHECK (comment_type IN ('COMMENT', 'INTERNAL_NOTE', 'STATUS_CHANGE', 'RESOLUTION', 'SYSTEM_UPDATE')),
    CONSTRAINT ck_ticket_comments__automation_source 		CHECK (automation_source IN ('EMAIL', 'CHATBOT', 'WORKFLOW', 'API', 'ESCALATION', 'SLA_ALERT')),
    CONSTRAINT ck_ticket_comments__status 					CHECK (status IN ('ACTIVE', 'HIDDEN', 'DELETED')),
    CONSTRAINT ck_ticket_comments__automation_logic 		CHECK ((automated = TRUE AND automation_source IS NOT NULL) OR (automated = FALSE))
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  supt.ticket_comments						IS '티켓 댓글 및 대화 - 지원 티켓의 모든 의사소통 기록, 내부 노트, 상태 변경 이력을 관리';
COMMENT ON COLUMN supt.ticket_comments.id 					IS '티켓 댓글 고유 식별자 - UUID 형태의 기본키, 각 댓글을 구분하는 고유값';
COMMENT ON COLUMN supt.ticket_comments.created_at 			IS '댓글 생성 일시 - 댓글이 작성된 시점의 타임스탬프';
COMMENT ON COLUMN supt.ticket_comments.created_by 			IS '댓글 생성자 UUID - 댓글을 작성한 사용자 또는 시스템의 식별자';
COMMENT ON COLUMN supt.ticket_comments.updated_at 			IS '댓글 수정 일시 - 댓글이 최종 수정된 시점의 타임스탬프';
COMMENT ON COLUMN supt.ticket_comments.updated_by 			IS '댓글 수정자 UUID - 댓글을 최종 수정한 사용자 또는 시스템의 식별자';
COMMENT ON COLUMN supt.ticket_comments.ticket_id 			IS '소속 티켓 ID - 이 댓글이 속한 지원 티켓의 고유 식별자 (support_tickets 테이블 참조)';
COMMENT ON COLUMN supt.ticket_comments.user_id 				IS '댓글 작성자 ID - 댓글을 작성한 고객 또는 지원팀원의 식별자 (users 테이블 참조, 시스템 자동 댓글시 NULL)';
COMMENT ON COLUMN supt.ticket_comments.comment_text 		IS '댓글 본문 내용 - 실제 댓글 텍스트, 답변, 설명, 또는 상태 변경 사유 등';
COMMENT ON COLUMN supt.ticket_comments.comment_type 		IS '댓글 유형 - COMMENT(일반댓글), INTERNAL_NOTE(내부메모), STATUS_CHANGE(상태변경), RESOLUTION(해결방안), SYSTEM_UPDATE(시스템업데이트)';
COMMENT ON COLUMN supt.ticket_comments.is_internal 			IS '내부 댓글 여부 - TRUE(지원팀 내부용, 고객에게 비공개), FALSE(고객과 공유되는 공개 댓글)';
COMMENT ON COLUMN supt.ticket_comments.files 				IS '첨부 파일 목록 - 댓글과 함께 첨부된 파일들의 정보 (JSON 배열, 파일명, 경로, 크기 등 포함)';
COMMENT ON COLUMN supt.ticket_comments.automated 			IS '시스템 자동 생성 여부 - TRUE(시스템이 자동으로 생성), FALSE(사용자가 직접 작성)';
COMMENT ON COLUMN supt.ticket_comments.automation_source 	IS '자동화 소스 - EMAIL(이메일연동), CHATBOT(챗봇), WORKFLOW(워크플로우), API(API호출), ESCALATION(에스컬레이션), SLA_ALERT(SLA알림)';
COMMENT ON COLUMN supt.ticket_comments.status 				IS '댓글 상태 - ACTIVE(활성), HIDDEN(숨김), DELETED(삭제) 댓글 표시 상태';
COMMENT ON COLUMN supt.ticket_comments.deleted 				IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 티켓별 댓글 조회 최적화
CREATE INDEX IF NOT EXISTS ix_ticket_comments__ticket_id
    ON supt.ticket_comments (ticket_id, created_at DESC)
 WHERE deleted = FALSE;

-- 사용자별 댓글 조회 최적화
CREATE INDEX IF NOT EXISTS ix_ticket_comments__user_id
    ON supt.ticket_comments (user_id, created_at DESC)
 WHERE user_id IS NOT NULL AND deleted = FALSE;

-- 댓글 유형별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_ticket_comments__comment_type
    ON supt.ticket_comments (comment_type, created_at DESC)
 WHERE deleted = FALSE;

-- 내부/공개 댓글 구분 조회 최적화
CREATE INDEX IF NOT EXISTS ix_ticket_comments__is_internal
    ON supt.ticket_comments (is_internal, ticket_id, created_at DESC)
 WHERE deleted = FALSE;

-- 시간 기준 댓글 조회 최적화
CREATE INDEX IF NOT EXISTS ix_ticket_comments__created_at
    ON supt.ticket_comments (created_at DESC);

-- 자동 생성 댓글 조회 최적화
CREATE INDEX IF NOT EXISTS ix_ticket_comments__automated
    ON supt.ticket_comments (automated, automation_source, created_at DESC)
 WHERE automated = TRUE AND deleted = FALSE;

-- 고객 공개 댓글 조회 최적화
CREATE INDEX IF NOT EXISTS ix_ticket_comments__public_comments
    ON supt.ticket_comments (ticket_id, is_internal, created_at DESC)
 WHERE is_internal = FALSE AND deleted = FALSE;

-- 내부 노트 조회 최적화
CREATE INDEX IF NOT EXISTS ix_ticket_comments__internal_notes
    ON supt.ticket_comments (ticket_id, is_internal, created_at DESC)
 WHERE is_internal = TRUE AND deleted = FALSE;

-- 상태 변경 이력 조회 최적화
CREATE INDEX IF NOT EXISTS ix_ticket_comments__status_changes
    ON supt.ticket_comments (comment_type, ticket_id, created_at DESC)
 WHERE comment_type = 'STATUS_CHANGE' AND deleted = FALSE;

-- 첨부파일 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_ticket_comments__files
    ON supt.ticket_comments USING GIN (files)
 WHERE deleted = FALSE;

-- 티켓별 대화 이력 조회 최적화
CREATE INDEX IF NOT EXISTS ix_ticket_comments__ticket_conversation
    ON supt.ticket_comments (ticket_id, comment_type, is_internal, created_at)
 WHERE deleted = FALSE;


-- ============================================================================
-- 고객 피드백
-- ============================================================================
CREATE TABLE IF NOT EXISTS supt.feedbacks
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 고객 피드백 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 피드백 생성 일시
    created_by                  UUID,                                                              	-- 피드백 생성자 UUID (고객 또는 시스템)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 피드백 수정 일시
    updated_by                  UUID,                                                              	-- 피드백 수정자 UUID

	-- 피드백 제공자 정보
    tenant_id                   UUID                     NOT NULL,                                 	-- 피드백 제공 테넌트 ID
    user_id                     UUID,                                                              	-- 피드백 제공자 사용자 ID

	-- 피드백 기본 정보
    feedback_type               VARCHAR(50)              NOT NULL,                                 	-- 피드백 유형 (FEATURE_REQUEST/BUG_REPORT/IMPROVEMENT/COMPLIMENT/COMPLAINT)
    title                       VARCHAR(200)             NOT NULL,                                 	-- 피드백 제목
    description                 TEXT                     NOT NULL,                                 	-- 피드백 상세 내용

	-- 만족도 평가 정보
    overall_rating              INTEGER,                                                           	-- 전체 만족도 (1-5점)
    feature_ratings             JSONB                    DEFAULT '{}',                            	-- 기능별 상세 평점 (JSON 형태)

	-- 피드백 분류 정보
    product_area                VARCHAR(50),                                                       	-- 관련 제품 영역 (UI, API, DATABASE 등)
    urgency               		VARCHAR(20)              DEFAULT 'MEDIUM',                        	-- 긴급도 (LOW/MEDIUM/HIGH)

	-- 검토 및 처리 정보
    reviewed_by                 VARCHAR(100),                                                      	-- 피드백 검토자 (제품 관리자, 개발팀 등)
    reviewed_at                 TIMESTAMP WITH TIME ZONE,                                          	-- 검토 완료 일시
    implement_priority     		INTEGER,                                                           	-- 구현 우선순위 (1-10, 1이 최고 우선순위)
    implement_status       		VARCHAR(20)              DEFAULT 'SUBMITTED',                     	-- 구현 상태 (SUBMITTED/REVIEWING/PLANNED/IN_PROGRESS/COMPLETED/REJECTED)

	-- 고객 응답 정보
    response_message            TEXT,                                                              	-- 피드백에 대한 회사 측 응답
    response_sent_at            TIMESTAMP WITH TIME ZONE,                                          	-- 응답 발송 일시

	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- 피드백 상태 (ACTIVE/ARCHIVED/SPAM)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT fk_feedbacks__tenant_id 					FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,
    CONSTRAINT fk_feedbacks__user_id 					FOREIGN KEY (user_id) 	REFERENCES tnnt.users(id)	ON DELETE CASCADE,

    CONSTRAINT ck_feedbacks__feedback_type 				CHECK (feedback_type IN ('FEATURE_REQUEST', 'BUG_REPORT', 'IMPROVEMENT', 'COMPLIMENT', 'COMPLAINT', 'GENERAL')),
    CONSTRAINT ck_feedbacks__urgency 					CHECK (urgency IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    CONSTRAINT ck_feedbacks__implement_status 			CHECK (implement_status IN ('SUBMITTED', 'REVIEWING', 'PLANNED', 'IN_PROGRESS', 'COMPLETED', 'REJECTED', 'DEFERRED')),
    CONSTRAINT ck_feedbacks__status 					CHECK (status IN ('ACTIVE', 'ARCHIVED', 'SPAM')),
    CONSTRAINT ck_feedbacks__overall_rating 			CHECK (overall_rating IS NULL OR (overall_rating >= 1 AND overall_rating <= 5)),
    CONSTRAINT ck_feedbacks__implement_priority 		CHECK (implement_priority IS NULL OR (implement_priority >= 1 AND implement_priority <= 10)),
    CONSTRAINT ck_feedbacks__review_logic 				CHECK ((reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL) OR (reviewed_by IS NULL AND reviewed_at IS NULL)),
    CONSTRAINT ck_feedbacks__response_logic 			CHECK ((response_message IS NOT NULL AND response_sent_at IS NOT NULL) OR (response_message IS NULL AND response_sent_at IS NULL))
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  supt.feedbacks						IS '고객 피드백 - 제품 개선 요청, 버그 신고, 만족도 조사 결과를 체계적으로 수집하고 관리하여 제품 개발과 고객 만족도 향상에 활용';
COMMENT ON COLUMN supt.feedbacks.id 					IS '고객 피드백 고유 식별자 - UUID 형태의 기본키, 각 피드백을 구분하는 고유값';
COMMENT ON COLUMN supt.feedbacks.created_at 			IS '피드백 생성 일시 - 고객이 피드백을 제출한 시점의 타임스탬프';
COMMENT ON COLUMN supt.feedbacks.created_by 			IS '피드백 생성자 UUID - 피드백을 제출한 고객 또는 시스템의 식별자';
COMMENT ON COLUMN supt.feedbacks.updated_at 			IS '피드백 수정 일시 - 피드백 정보가 최종 변경된 시점의 타임스탬프';
COMMENT ON COLUMN supt.feedbacks.updated_by 			IS '피드백 수정자 UUID - 피드백을 최종 수정한 사용자 또는 관리자의 식별자';
COMMENT ON COLUMN supt.feedbacks.tenant_id 				IS '피드백 제공 테넌트 ID - 피드백을 제공한 테넌트의 고유 식별자 (tenants 테이블 참조)';
COMMENT ON COLUMN supt.feedbacks.user_id 				IS '피드백 제공자 사용자 ID - 실제 피드백을 작성한 사용자의 식별자 (users 테이블 참조, 익명 피드백시 NULL)';
COMMENT ON COLUMN supt.feedbacks.feedback_type 			IS '피드백 유형 - FEATURE_REQUEST(기능요청), BUG_REPORT(버그신고), IMPROVEMENT(개선제안), COMPLIMENT(칭찬), COMPLAINT(불만), GENERAL(일반의견)';
COMMENT ON COLUMN supt.feedbacks.title 					IS '피드백 제목 - 피드백의 요약이나 핵심 내용을 나타내는 제목';
COMMENT ON COLUMN supt.feedbacks.description 			IS '피드백 상세 내용 - 고객이 제공한 구체적인 피드백 내용, 개선 제안, 문제 상황 등의 상세 설명';
COMMENT ON COLUMN supt.feedbacks.overall_rating 		IS '전체 만족도 - 제품이나 서비스에 대한 전반적인 만족도 평가 (1-5점, 5점이 최고)';
COMMENT ON COLUMN supt.feedbacks.feature_ratings 		IS '기능별 상세 평점 - 개별 기능이나 영역에 대한 세부적인 평가 (JSON 형태, 기능명과 점수 매핑)';
COMMENT ON COLUMN supt.feedbacks.product_area 			IS '관련 제품 영역 - 피드백이 관련된 제품의 특정 영역 (UI, API, DATABASE, SECURITY, PERFORMANCE 등)';
COMMENT ON COLUMN supt.feedbacks.urgency 				IS '긴급도 - LOW(낮음), MEDIUM(보통), HIGH(높음), CRITICAL(심각) 피드백 처리의 긴급성 수준';
COMMENT ON COLUMN supt.feedbacks.reviewed_by 			IS '피드백 검토자 - 피드백을 검토한 제품 관리자, 개발팀 리더, 또는 고객 성공팀의 이름';
COMMENT ON COLUMN supt.feedbacks.reviewed_at 			IS '검토 완료 일시 - 피드백에 대한 내부 검토가 완료된 시점';
COMMENT ON COLUMN supt.feedbacks.implement_priority 	IS '구현 우선순위 - 개발팀에서 정한 구현 우선순위 (1-10, 1이 최고 우선순위, 10이 최저)';
COMMENT ON COLUMN supt.feedbacks.implement_status 		IS '구현 상태 - SUBMITTED(제출됨), REVIEWING(검토중), PLANNED(계획됨), IN_PROGRESS(진행중), COMPLETED(완료), REJECTED(거부), DEFERRED(연기)';
COMMENT ON COLUMN supt.feedbacks.response_message 		IS '피드백에 대한 회사 측 응답 - 고객의 피드백에 대한 공식적인 답변이나 조치 계획';
COMMENT ON COLUMN supt.feedbacks.response_sent_at 		IS '응답 발송 일시 - 고객에게 피드백 응답이 전달된 시점';
COMMENT ON COLUMN supt.feedbacks.status 				IS '피드백 상태 - ACTIVE(활성), ARCHIVED(보관), SPAM(스팸) 피드백의 관리 상태';
COMMENT ON COLUMN supt.feedbacks.deleted 				IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성

-- 테넌트별 피드백 조회 최적화
CREATE INDEX IF NOT EXISTS ix_feedbacks__tenant_id
    ON supt.feedbacks (tenant_id, created_at DESC)
 WHERE deleted = FALSE;

-- 사용자별 피드백 조회 최적화
CREATE INDEX IF NOT EXISTS ix_feedbacks__user_id
    ON supt.feedbacks (user_id, created_at DESC)
 WHERE user_id IS NOT NULL AND deleted = FALSE;

-- 피드백 유형별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_feedbacks__feedback_type
    ON supt.feedbacks (feedback_type, created_at DESC)
 WHERE deleted = FALSE;

-- 구현 상태별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_feedbacks__implement_status
    ON supt.feedbacks (implement_status, created_at DESC)
 WHERE deleted = FALSE;

-- 긴급도별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_feedbacks__urgency
    ON supt.feedbacks (urgency, created_at DESC)
 WHERE deleted = FALSE;

-- 만족도별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_feedbacks__overall_rating
    ON supt.feedbacks (overall_rating DESC, created_at DESC)
 WHERE overall_rating IS NOT NULL AND deleted = FALSE;

-- 제품 영역별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_feedbacks__product_area
    ON supt.feedbacks (product_area, created_at DESC)
 WHERE product_area IS NOT NULL AND deleted = FALSE;

-- 우선순위별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_feedbacks__implement_priority
    ON supt.feedbacks (implement_priority, created_at DESC)
 WHERE implement_priority IS NOT NULL AND deleted = FALSE;

-- 검토 대기 피드백 최적화
CREATE INDEX IF NOT EXISTS ix_feedbacks__pending_review
    ON supt.feedbacks (implement_status, created_at DESC)
 WHERE implement_status = 'SUBMITTED' AND deleted = FALSE;

-- 기능 요청 관리 최적화
CREATE INDEX IF NOT EXISTS ix_feedbacks__feature_requests
    ON supt.feedbacks (feedback_type, implement_status, implement_priority, created_at DESC)
 WHERE feedback_type = 'FEATURE_REQUEST' AND deleted = FALSE;

-- 버그 신고 처리 최적화
CREATE INDEX IF NOT EXISTS ix_feedbacks__bug_reports
    ON supt.feedbacks (feedback_type, urgency, created_at DESC)
 WHERE feedback_type = 'BUG_REPORT' AND deleted = FALSE;

-- 검토자별 피드백 조회 최적화
CREATE INDEX IF NOT EXISTS ix_feedbacks__reviewed_feedback
    ON supt.feedbacks (reviewed_by, reviewed_at DESC)
 WHERE reviewed_by IS NOT NULL AND deleted = FALSE;

-- 응답 대기 피드백 최적화
CREATE INDEX IF NOT EXISTS ix_feedbacks__response_pending
    ON supt.feedbacks (implement_status, response_sent_at)
 WHERE response_sent_at IS NULL
   AND implement_status IN ('REVIEWING', 'PLANNED', 'COMPLETED', 'REJECTED')
   AND deleted = FALSE;

-- 기능별 평점 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_feedbacks__feature_ratings
    ON supt.feedbacks USING GIN (feature_ratings)
 WHERE deleted = FALSE;

-- 생성 시간 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_feedbacks__created_at
    ON supt.feedbacks (created_at DESC);
