-- ============================================================================
-- 11. 알림 및 커뮤니케이션 (Notifications) -> noti
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS noti;

COMMENT ON SCHEMA noti
IS 'NOTI: 알림/커뮤니케이션 스키마: 멀티채널 알림/캠페인 전송 메타.';

-- ============================================================================
-- 알림 관리 테이블
-- ============================================================================
CREATE TABLE IF NOT EXISTS noti.notifications
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 알림 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 알림 생성 일시
    created_by                  UUID,                                                              	-- 알림 생성자 UUID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 알림 수정 일시
    updated_by                  UUID,                                                              	-- 알림 수정자 UUID

    -- 알림 대상 정보
    tenant_id                   UUID,                                                              	-- 특정 테넌트 대상 ID
    user_id                     UUID,                                                              	-- 특정 사용자 대상 ID
    target_type                 VARCHAR(20)              NOT NULL DEFAULT 'USER',                 	-- 대상 유형 (USER/TENANT/ADMIN/SYSTEM)

    -- 알림 내용 정보
    notify_type                 VARCHAR(50)              NOT NULL,                                 	-- 알림 유형 (SYSTEM_ALERT/BILLING_NOTICE/FEATURE_UPDATE 등)
    title                       VARCHAR(200)             NOT NULL,                                 	-- 알림 제목
    message                     TEXT                     NOT NULL,                                 	-- 알림 메시지 내용
    priority                    VARCHAR(20)              NOT NULL DEFAULT 'MEDIUM',               	-- 알림 우선순위 (LOW/MEDIUM/HIGH/URGENT)

    -- 전송 채널 설정
    channels                    TEXT[]                   NOT NULL DEFAULT ARRAY['IN_APP'],        	-- 전송 채널 목록

    -- 전송 관리 정보
    scheduled_at                TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,                  	-- 예약 발송 시각
    sent_at                     TIMESTAMP WITH TIME ZONE,                                          	-- 실제 발송 시각
    delivery_attempts           INTEGER                  NOT NULL DEFAULT 0,                      	-- 전송 시도 횟수

    -- 수신 확인 정보
    read_at                     TIMESTAMP WITH TIME ZONE,                                          	-- 알림 읽은 시각
    acknowledged_at             TIMESTAMP WITH TIME ZONE,                                          	-- 알림 확인 시각

    -- 액션 관리 정보
    action_required             BOOLEAN                  NOT NULL DEFAULT FALSE,                  	-- 사용자 액션 필요 여부
    action_url                  VARCHAR(500),                                                      	-- 액션 수행을 위한 URL
    action_deadline             TIMESTAMP WITH TIME ZONE,                                          	-- 액션 수행 마감일

    -- 만료 관리
    expires_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 알림 만료 일시

    -- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'PENDING',              	-- 알림 상태
    delivery_status             JSONB                    NOT NULL DEFAULT '{}',                   	-- 채널별 전송 상태

    -- 논리적 삭제 플래그
    deleted                     BOOLEAN                  NOT NULL DEFAULT FALSE,                   	-- 논리적 삭제 플래그

    -- 제약조건
    CONSTRAINT fk_notifications__tenant_id 		        	FOREIGN KEY (tenant_id) REFERENCES tnnt.tenants(id)	ON DELETE CASCADE,
    CONSTRAINT fk_notifications__user_id 		        	FOREIGN KEY (user_id) 	REFERENCES tnnt.users(id)	ON DELETE CASCADE,

    CONSTRAINT ck_notifications__target_type 	        	CHECK (target_type IN ('USER', 'TENANT', 'ADMIN', 'SYSTEM')),
    CONSTRAINT ck_notifications__notify_type 	        	CHECK (notify_type IN ('SYSTEM_ALERT', 'BILLING_NOTICE', 'FEATURE_UPDATE', 'MAINTENANCE', 'SECURITY_ALERT', 'USER_NOTIFICATION', 'ADMIN_ALERT')),
    CONSTRAINT ck_notifications__priority 		       	 	CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    CONSTRAINT ck_notifications__status 		        	CHECK (status IN ('PENDING', 'SENT', 'DELIVERED', 'FAILED', 'EXPIRED')),
    CONSTRAINT ck_notifications__delivery_attempts_positive	CHECK (delivery_attempts >= 0),
    CONSTRAINT ck_notifications__channels_not_empty 	    CHECK (array_length(channels, 1) > 0),
    CONSTRAINT ck_notifications__action_deadline_logic      CHECK (action_deadline IS NULL OR action_required = TRUE),
    CONSTRAINT ck_notifications__target_consistency         CHECK (
																	(target_type = 'USER' AND user_id IS NOT NULL) OR
																	(target_type = 'TENANT' AND tenant_id IS NOT NULL) OR
																	(target_type IN ('ADMIN', 'SYSTEM'))
															)
);

-- 컬럼별 코멘트 추가
COMMENT ON TABLE  noti.notifications 					IS '알림 관리 - 시스템, 청구, 보안 등 모든 유형의 알림 통합 관리';
COMMENT ON COLUMN noti.notifications.id 				IS '알림 고유 식별자 (UUID)';
COMMENT ON COLUMN noti.notifications.created_at 		IS '알림 생성 일시';
COMMENT ON COLUMN noti.notifications.created_by 		IS '알림 생성자 UUID (시스템 또는 관리자)';
COMMENT ON COLUMN noti.notifications.updated_at 		IS '알림 수정 일시';
COMMENT ON COLUMN noti.notifications.updated_by 		IS '알림 수정자 UUID';
COMMENT ON COLUMN noti.notifications.tenant_id 			IS '특정 테넌트 대상 ID - 테넌트별 알림인 경우 설정';
COMMENT ON COLUMN noti.notifications.user_id 			IS '특정 사용자 대상 ID - 개별 사용자 알림인 경우 설정';
COMMENT ON COLUMN noti.notifications.target_type 		IS '대상 유형 - 사용자, 테넌트, 관리자, 시스템 중 선택';
COMMENT ON COLUMN noti.notifications.notify_type 		IS '알림 유형 - 시스템 경고, 청구 안내, 기능 업데이트, 유지보수, 보안 경고 등';
COMMENT ON COLUMN noti.notifications.title 				IS '알림 제목 - 사용자에게 표시될 알림의 제목';
COMMENT ON COLUMN noti.notifications.message 			IS '알림 메시지 내용 - 알림의 상세 내용';
COMMENT ON COLUMN noti.notifications.priority 			IS '알림 우선순위 - 낮음, 보통, 높음, 긴급 중 선택';
COMMENT ON COLUMN noti.notifications.channels 			IS '전송 채널 목록 - 앱 내, 이메일, SMS, 푸시, 웹훅 등 전송 방법';
COMMENT ON COLUMN noti.notifications.scheduled_at 		IS '예약 발송 시각 - 알림이 발송되도록 예약된 시간';
COMMENT ON COLUMN noti.notifications.sent_at 			IS '실제 발송 시각 - 알림이 실제로 발송된 시간';
COMMENT ON COLUMN noti.notifications.delivery_attempts 	IS '전송 시도 횟수 - 알림 전송을 시도한 총 횟수';
COMMENT ON COLUMN noti.notifications.read_at 			IS '알림 읽은 시각 - 사용자가 알림을 읽은 시간';
COMMENT ON COLUMN noti.notifications.acknowledged_at 	IS '알림 확인 시각 - 사용자가 알림을 확인 처리한 시간';
COMMENT ON COLUMN noti.notifications.action_required 	IS '사용자 액션 필요 여부 - 알림에 대한 사용자의 응답이나 조치가 필요한지 여부';
COMMENT ON COLUMN noti.notifications.action_url 		IS '액션 수행을 위한 URL - 사용자가 조치를 취할 수 있는 링크';
COMMENT ON COLUMN noti.notifications.action_deadline 	IS '액션 수행 마감일 - 사용자 조치가 필요한 경우의 마감 시한';
COMMENT ON COLUMN noti.notifications.expires_at 		IS '알림 만료 일시 - 알림이 자동으로 만료되어 숨겨질 시간';
COMMENT ON COLUMN noti.notifications.status 			IS '알림 상태 - 대기, 발송, 전달, 실패, 만료 중 하나';
COMMENT ON COLUMN noti.notifications.delivery_status 	IS '채널별 전송 상태 - JSON 형태로 각 채널별 전송 결과 저장';
COMMENT ON COLUMN noti.notifications.deleted 			IS '논리적 삭제 플래그 - 실제 삭제 대신 사용하는 소프트 딜리트';

-- ======================================================
-- noti.notifications 테이블 인덱스 정의
-- 목적: 알림 조회, 모니터링, 발송 관리 최적화
-- ======================================================

-- 사용자별 알림 조회용 인덱스
-- 설명: 특정 사용자가 받은 알림 조회 최적화 (가장 빈번한 조회 패턴)
CREATE INDEX IF NOT EXISTS ix_notifications__user_notifications
    ON noti.notifications (user_id, created_at DESC, status)
 WHERE deleted = FALSE
   AND target_type = 'USER';

-- 테넌트별 알림 조회용 인덱스
-- 설명: 특정 테넌트가 받은 알림 조회 최적화
CREATE INDEX IF NOT EXISTS ix_notifications__tenant_notifications
    ON noti.notifications (tenant_id, created_at DESC, priority)
 WHERE deleted = FALSE
   AND target_type = 'TENANT';

-- 알림 상태별 조회용 인덱스
-- 설명: 관리자 모니터링용, 상태별 알림 조회 최적화
CREATE INDEX IF NOT EXISTS ix_notifications__status_management
    ON noti.notifications (status, priority, created_at DESC)
 WHERE deleted = FALSE;

-- 예약 발송 관리용 인덱스
-- 설명: 스케줄러가 사용할 발송 대기 중인 알림 조회 최적화
CREATE INDEX IF NOT EXISTS ix_notifications__scheduled_delivery
    ON noti.notifications (scheduled_at, status)
 WHERE deleted = FALSE
   AND status = 'PENDING';

-- 알림 유형별 조회용 인덱스
-- 설명: 알림 유형별 조회 및 분석 최적화
CREATE INDEX IF NOT EXISTS ix_notifications__notification_type
    ON noti.notifications (notify_type, priority, created_at DESC)
 WHERE deleted = FALSE;

-- 우선순위별 조회용 인덱스
-- 설명: 긴급 알림(HIGH, URGENT) 관리 최적화
CREATE INDEX IF NOT EXISTS ix_notifications__priority_management
    ON noti.notifications (priority, status, scheduled_at)
 WHERE deleted = FALSE
   AND priority IN ('HIGH', 'URGENT');

-- 읽지 않은 알림 조회용 인덱스
-- 설명: 읽지 않은 알림 조회 최적화
CREATE INDEX IF NOT EXISTS ix_notifications__unread_notifications
    ON noti.notifications (user_id, target_type, created_at DESC)
 WHERE deleted = FALSE
   AND read_at IS NULL;

-- 액션 필요 알림 조회용 인덱스
-- 설명: 사용자가 처리해야 하는 알림 조회 최적화
CREATE INDEX IF NOT EXISTS ix_notifications__action_required
    ON noti.notifications (action_required, action_deadline, user_id)
 WHERE deleted = FALSE
   AND action_required = TRUE;

-- 만료 관리용 인덱스
-- 설명: 만료 시간이 있는 알림 조회 및 정리 최적화
CREATE INDEX IF NOT EXISTS ix_notifications__expiration_management
    ON noti.notifications (expires_at, status)
 WHERE deleted = FALSE
   AND expires_at IS NOT NULL;

-- 전송 실패 관리용 인덱스
-- 설명: 전송 실패한 알림 조회 및 재전송 관리 최적화
CREATE INDEX IF NOT EXISTS ix_notifications__delivery_failures
    ON noti.notifications (status, delivery_attempts, scheduled_at)
 WHERE deleted = FALSE
   AND status = 'FAILED';

-- 대상 유형별 조회용 인덱스
-- 설명: 알림 대상 유형(USER, TENANT)별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_notifications__target_type_analysis
    ON noti.notifications (target_type, notify_type, created_at DESC)
 WHERE deleted = FALSE;

-- 생성일자 기준 조회용 인덱스
-- 설명: 최근 생성된 알림 조회 최적화
CREATE INDEX IF NOT EXISTS ix_notifications__created_at
    ON noti.notifications (created_at DESC)
 WHERE deleted = FALSE;

-- 확인되지 않은 알림 조회용 인덱스
-- 설명: 액션 필요 알림 중 확인되지 않은 알림 조회 최적화
CREATE INDEX IF NOT EXISTS ix_notifications__unacknowledged
    ON noti.notifications (acknowledged_at, action_deadline, user_id)
 WHERE deleted = FALSE
   AND acknowledged_at IS NULL
   AND action_required = TRUE;

-- GIN 인덱스: 전송 채널 배열 검색용
-- 설명: 알림 전송 채널 검색 최적화
CREATE INDEX IF NOT EXISTS ix_notifications__channels_gin
    ON noti.notifications USING GIN (channels)
 WHERE deleted = FALSE;

-- GIN 인덱스: 전송 상태 JSON 검색용
-- 설명: delivery_status JSON 검색 최적화
CREATE INDEX IF NOT EXISTS ix_notifications__delivery_status_gin
    ON noti.notifications USING GIN (delivery_status)
 WHERE deleted = FALSE
   AND delivery_status != '{}';


-- ============================================================================
-- 알림 템플릿 테이블
-- ============================================================================
CREATE TABLE IF NOT EXISTS noti.templates
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 알림 템플릿 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 템플릿 생성 일시
    created_by                  UUID,                                                              	-- 템플릿 생성자 UUID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 템플릿 수정 일시
    updated_by                  UUID,                                                              	-- 템플릿 수정자 UUID

    -- 템플릿 기본 정보
    template_code               VARCHAR(100)             UNIQUE NOT NULL,                          	-- 템플릿 식별 코드
    template_name               VARCHAR(200)             NOT NULL,                                 	-- 템플릿 이름
    description                 TEXT,                                                              	-- 템플릿 설명

    -- 템플릿 분류 정보
    category                    VARCHAR(50)              NOT NULL,                                 	-- 템플릿 카테고리 (SYSTEM/BILLING/SECURITY/MARKETING/SUPPORT)
    notify_type                 VARCHAR(50)              NOT NULL,                                 	-- 알림 유형

    -- 채널별 템플릿 내용
    email_subject               VARCHAR(500),                                                      	-- 이메일 제목 템플릿
    email_body                  TEXT,                                                              	-- 이메일 본문 템플릿 (HTML)
    sms_message                 VARCHAR(1000),                                                     	-- SMS 메시지 템플릿
    push_title                  VARCHAR(200),                                                      	-- 푸시 알림 제목 템플릿
    push_body                   VARCHAR(500),                                                      	-- 푸시 알림 본문 템플릿
    in_app_title                VARCHAR(200),                                                      	-- 앱 내 알림 제목 템플릿
    in_app_message              TEXT,                                                              	-- 앱 내 알림 메시지 템플릿

    -- 템플릿 메타데이터
    template_variables          JSONB                    NOT NULL DEFAULT '{}',                   	-- 사용 가능한 변수 정의

    -- 다국어 지원
    locale                      VARCHAR(10)              NOT NULL DEFAULT 'ko-KR',                	-- 언어 로케일

    -- 버전 관리
    version                     VARCHAR(20)              NOT NULL DEFAULT '1.0',                  	-- 템플릿 버전
    previous_version_id         UUID,                                                              	-- 이전 버전 템플릿 ID

    -- 테스트 지원
    test_data                   JSONB                    NOT NULL DEFAULT '{}',                   	-- 테스트용 샘플 데이터

    -- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',               	-- 템플릿 상태

    -- 논리적 삭제 플래그
    deleted                     BOOLEAN                  NOT NULL DEFAULT FALSE,                   	-- 논리적 삭제 플래그

    -- 제약조건
    CONSTRAINT fk_templates__previous_version_id        FOREIGN KEY (previous_version_id) REFERENCES noti.templates(id),

    CONSTRAINT ck_templates__category 			        CHECK (category IN ('SYSTEM', 'BILLING', 'SECURITY', 'MARKETING', 'SUPPORT', 'MAINTENANCE', 'USER_ACCOUNT')),
    CONSTRAINT ck_templates__notify_type 		        CHECK (notify_type IN ('SYSTEM_ALERT', 'BILLING_NOTICE', 'FEATURE_UPDATE', 'MAINTENANCE', 'SECURITY_ALERT', 'USER_NOTIFICATION', 'ADMIN_ALERT')),
    CONSTRAINT ck_templates__status 			        CHECK (status IN ('DRAFT', 'ACTIVE', 'ARCHIVED')),
    CONSTRAINT ck_templates__sms_length 		        CHECK (sms_message IS NULL OR length(sms_message) <= 1000),
    CONSTRAINT ck_templates__push_title_length 	        CHECK (push_title IS NULL OR length(push_title) <= 200),
    CONSTRAINT ck_templates__push_body_length 	        CHECK (push_body IS NULL OR length(push_body) <= 500),
    CONSTRAINT ck_templates__has_content 		        CHECK (	email_subject 	IS NOT NULL OR
																email_body 		IS NOT NULL OR
																sms_message 	IS NOT NULL OR
																push_title 		IS NOT NULL OR
																push_body 		IS NOT NULL OR
																in_app_title 	IS NOT NULL OR
																in_app_message 	IS NOT NULL
														)
);

-- 컬럼별 코멘트 추가
COMMENT ON TABLE  noti.templates 						IS '알림 템플릿 - 각종 알림의 다국어 템플릿 및 버전 관리';
COMMENT ON COLUMN noti.templates.id 					IS '알림 템플릿 고유 식별자 (UUID)';
COMMENT ON COLUMN noti.templates.created_at 			IS '템플릿 생성 일시';
COMMENT ON COLUMN noti.templates.created_by 			IS '템플릿 생성자 UUID (개발자 또는 관리자)';
COMMENT ON COLUMN noti.templates.updated_at 			IS '템플릿 수정 일시';
COMMENT ON COLUMN noti.templates.updated_by 			IS '템플릿 수정자 UUID';
COMMENT ON COLUMN noti.templates.template_code 			IS '템플릿 식별 코드 - 애플리케이션에서 템플릿을 참조하는 고유 키';
COMMENT ON COLUMN noti.templates.template_name 			IS '템플릿 이름 - 관리자가 식별하기 위한 친숙한 이름';
COMMENT ON COLUMN noti.templates.description 			IS '템플릿 설명 - 템플릿의 용도와 사용 목적에 대한 설명';
COMMENT ON COLUMN noti.templates.category 				IS '템플릿 카테고리 - 시스템, 청구, 보안, 마케팅, 지원 등으로 분류';
COMMENT ON COLUMN noti.templates.notify_type 			IS '알림 유형 - 시스템 경고, 청구 안내, 기능 업데이트 등 구체적인 알림 타입';
COMMENT ON COLUMN noti.templates.email_subject 			IS '이메일 제목 템플릿 - 이메일 발송 시 사용할 제목 템플릿';
COMMENT ON COLUMN noti.templates.email_body 			IS '이메일 본문 템플릿 (HTML) - 이메일 발송 시 사용할 HTML 본문';
COMMENT ON COLUMN noti.templates.sms_message 			IS 'SMS 메시지 템플릿 - SMS 발송 시 사용할 메시지 (최대 1000자)';
COMMENT ON COLUMN noti.templates.push_title 			IS '푸시 알림 제목 템플릿 - 푸시 알림 발송 시 사용할 제목';
COMMENT ON COLUMN noti.templates.push_body 				IS '푸시 알림 본문 템플릿 - 푸시 알림 발송 시 사용할 본문';
COMMENT ON COLUMN noti.templates.in_app_title 			IS '앱 내 알림 제목 템플릿 - 앱 내 알림 표시 시 사용할 제목';
COMMENT ON COLUMN noti.templates.in_app_message 		IS '앱 내 알림 메시지 템플릿 - 앱 내 알림 표시 시 사용할 메시지';
COMMENT ON COLUMN noti.templates.template_variables 	IS '템플릿에서 사용 가능한 변수 정의 - JSON 형태로 치환 가능한 변수 목록';
COMMENT ON COLUMN noti.templates.locale 				IS '언어 로케일 - 템플릿이 작성된 언어 (ko-KR, en-US 등)';
COMMENT ON COLUMN noti.templates.version 				IS '템플릿 버전 - 템플릿의 버전 관리를 위한 버전 번호';
COMMENT ON COLUMN noti.templates.previous_version_id 	IS '이전 버전 템플릿 ID - 버전 히스토리 추적을 위한 이전 버전 참조';
COMMENT ON COLUMN noti.templates.test_data 				IS '테스트용 샘플 데이터 - 템플릿 테스트 시 사용할 변수 값들';
COMMENT ON COLUMN noti.templates.status 				IS '템플릿 상태 - 초안, 활성, 보관 중 하나';
COMMENT ON COLUMN noti.templates.deleted 				IS '논리적 삭제 플래그 - 실제 삭제 대신 사용하는 소프트 딜리트';

-- 인덱스 생성
-- 활성 템플릿 조회 최적화 (가장 빈번한 조회 패턴)
CREATE INDEX IF NOT EXISTS ix_templates__active_lookup
    ON noti.templates (template_code, status, locale)
 WHERE deleted = FALSE
   AND status = 'ACTIVE';

-- 카테고리별 템플릿 조회 최적화
CREATE INDEX IF NOT EXISTS ix_templates__category_management
    ON noti.templates (category, notify_type, status)
 WHERE deleted = FALSE;

-- 알림 유형별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_templates__notification_type
    ON noti.templates (notify_type, locale, status)
 WHERE deleted = FALSE;

-- 로케일별 조회 최적화 (다국어 지원)
CREATE INDEX IF NOT EXISTS ix_templates__locale_management
    ON noti.templates (locale, category, status)
 WHERE deleted = FALSE;

-- 버전 관리용 조회 최적화 (버전 히스토리 추적)
CREATE INDEX IF NOT EXISTS ix_templates__version_history
    ON noti.templates (template_code, version, created_at DESC)
 WHERE deleted = FALSE;

-- 상태별 관리용 조회 최적화 (템플릿 상태 관리)
CREATE INDEX IF NOT EXISTS ix_templates__status_management
    ON noti.templates (status, updated_at DESC)
 WHERE deleted = FALSE;

-- 템플릿명 검색 최적화
CREATE INDEX IF NOT EXISTS ix_templates__template_name
    ON noti.templates (template_name)
 WHERE deleted = FALSE;

-- 생성일자 기준 조회 최적화 (최근 생성된 템플릿 조회)
CREATE INDEX IF NOT EXISTS ix_templates__created_at
    ON noti.templates (created_at DESC)
 WHERE deleted = FALSE;

-- 생성자별 조회 최적화 (작성자별 템플릿 관리)
CREATE INDEX IF NOT EXISTS ix_templates__creator_management
    ON noti.templates (created_by, created_at DESC)
 WHERE deleted = FALSE;

-- 이전 버전 추적용 조회 최적화
CREATE INDEX IF NOT EXISTS ix_templates__previous_version_tracking
    ON noti.templates (previous_version_id)
 WHERE deleted = FALSE
   AND previous_version_id IS NOT NULL;

-- 초안 템플릿 관리용 조회 최적화 (승인 대기 중인 템플릿)
CREATE INDEX IF NOT EXISTS ix_templates__draft_management
    ON noti.templates (status, created_at DESC, created_by)
 WHERE deleted = FALSE
   AND status = 'DRAFT';

-- GIN 인덱스: JSON 변수 검색 최적화
CREATE INDEX IF NOT EXISTS ix_templates__template_variables_gin
    ON noti.templates USING GIN (template_variables)
 WHERE deleted = FALSE
   AND template_variables != '{}';

-- GIN 인덱스: 테스트 데이터 검색 최적화
CREATE INDEX IF NOT EXISTS ix_templates__test_data_gin
    ON noti.templates USING GIN (test_data)
 WHERE deleted = FALSE
   AND test_data != '{}';

-- 특정 로케일의 활성 템플릿 조회 최적화 (복합 인덱스)
CREATE INDEX IF NOT EXISTS ix_templates__active_by_locale_type
    ON noti.templates (locale, notify_type, template_code)
 WHERE deleted = FALSE
   AND status = 'ACTIVE';


-- ============================================================================
-- 이메일 캠페인 테이블
-- ============================================================================
CREATE TABLE IF NOT EXISTS noti.campaigns
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 캠페인 고유 식별자
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- 캠페인 생성 일시
    created_by                  UUID,                                                              	-- 캠페인 생성자 UUID
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 캠페인 수정 일시
    updated_by                  UUID,                                                              	-- 캠페인 수정자 UUID

    -- 캠페인 기본 정보
    campaign_name               VARCHAR(200)             NOT NULL,                                 	-- 캠페인 이름
    campaign_type               VARCHAR(50)              NOT NULL,                                 	-- 캠페인 유형 (PROMOTIONAL/TRANSACTIONAL/NEWSLETTER/ANNOUNCEMENT)
    description                 TEXT,                                                              	-- 캠페인 설명

    -- 대상 설정
    target_type                 VARCHAR(20)              NOT NULL DEFAULT 'users',         			-- 대상 유형 (ALL_USERS/users/ADMIN_USERS/CUSTOM_LIST)
    target_tenant_types         TEXT[],                                                            	-- 대상 테넌트 유형 목록
    target_user_roles           TEXT[],                                                            	-- 대상 사용자 역할 목록
    custom_recipients           UUID[],                                                            	-- 사용자 정의 수신자 UUID 목록

    -- 이메일 내용
    subject                     VARCHAR(500)             NOT NULL,                                 	-- 이메일 제목
    html_content                TEXT,                                                              	-- HTML 이메일 내용
    text_content                TEXT,                                                              	-- 텍스트 이메일 내용

    -- 발송자 설정
    sender_name                 VARCHAR(100)             NOT NULL DEFAULT 'AI 업무지원 플랫폼',      	-- 발송자 이름
    sender_email                VARCHAR(255)             NOT NULL DEFAULT 'noreply@platform.com', 	-- 발송자 이메일
    reply_to_email              VARCHAR(255),                                                      	-- 답장 이메일 주소

    -- 스케줄링 설정
    send_immediately            BOOLEAN                  NOT NULL DEFAULT FALSE,                  	-- 즉시 발송 여부
    scheduled_send_at           TIMESTAMP WITH TIME ZONE,                                          	-- 예약 발송 시각
    timezone                    VARCHAR(50)              NOT NULL DEFAULT 'Asia/Seoul',           	-- 시간대 설정

    -- 발송 결과 통계
    total_recipients            INTEGER                  NOT NULL DEFAULT 0,                      	-- 총 수신자 수
    sent_count                  INTEGER                  NOT NULL DEFAULT 0,                      	-- 발송 성공 건수
    delivered_count             INTEGER                  NOT NULL DEFAULT 0,                     	-- 전달 성공 건수
    opened_count                INTEGER                  NOT NULL DEFAULT 0,                      	-- 열람 건수
    clicked_count               INTEGER                  NOT NULL DEFAULT 0,                      	-- 클릭 건수
    bounced_count               INTEGER                  NOT NULL DEFAULT 0,                      	-- 반송 건수
    unsubscribed_count          INTEGER                  NOT NULL DEFAULT 0,                      	-- 구독 취소 건수

    -- A/B 테스트 설정
    is_ab_test                  BOOLEAN                  NOT NULL DEFAULT FALSE,                  	-- A/B 테스트 여부
    ab_test_rate                INTEGER,                                                           	-- A 그룹 비율 (백분율)
    ab_subject                  VARCHAR(500),                                                      	-- B 그룹 이메일 제목
    ab_content                  TEXT,                                                              	-- B 그룹 이메일 내용

    -- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'DRAFT',                	-- 캠페인 상태
    sent_at                     TIMESTAMP WITH TIME ZONE,                                          	-- 발송 시작 시각
    completed_at                TIMESTAMP WITH TIME ZONE,                                          	-- 발송 완료 시각

    -- 논리적 삭제 플래그
    deleted                     BOOLEAN                  NOT NULL DEFAULT FALSE,                   	-- 논리적 삭제 플래그

    -- 제약조건
    CONSTRAINT ck_campaigns__campaign_type 		        CHECK (campaign_type IN ('PROMOTIONAL', 'TRANSACTIONAL', 'NEWSLETTER', 'ANNOUNCEMENT', 'SURVEY', 'WELCOME')),
    CONSTRAINT ck_campaigns__target_type 		        CHECK (target_type IN ('ALL_USERS', 'users', 'ADMIN_USERS', 'CUSTOM_LIST')),
    CONSTRAINT ck_campaigns__status 			        CHECK (status IN ('DRAFT', 'SCHEDULED', 'SENDING', 'SENT', 'PAUSED', 'CANCELED')),
    CONSTRAINT ck_campaigns__ab_test_rate 		        CHECK (ab_test_rate IS NULL OR (ab_test_rate BETWEEN 1 AND 99)),
    CONSTRAINT ck_campaigns__statistics_positive        CHECK (total_recipients >= 0 AND sent_count >= 0 AND delivered_count >= 0 AND opened_count >= 0 AND clicked_count >= 0 AND bounced_count >= 0 AND unsubscribed_count >= 0),
    CONSTRAINT ck_campaigns__statistics_logic 	        CHECK (sent_count <= total_recipients AND delivered_count <= sent_count AND opened_count <= delivered_count AND clicked_count <= opened_count),
    CONSTRAINT ck_campaigns__content_required 	        CHECK (html_content IS NOT NULL OR text_content IS NOT NULL),
    CONSTRAINT ck_campaigns__ab_test_logic 		        CHECK ((is_ab_test = FALSE) OR (is_ab_test = TRUE AND ab_test_rate IS NOT NULL AND ab_subject IS NOT NULL)),
    CONSTRAINT ck_campaigns__sender_email_format        CHECK (sender_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT ck_campaigns__reply_to_email_format      CHECK (reply_to_email IS NULL OR reply_to_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- 컬럼별 코멘트 추가
COMMENT ON TABLE  noti.campaigns 						IS '이메일 캠페인 - 마케팅, 공지사항, 뉴스레터 등 대량 이메일 발송 관리';
COMMENT ON COLUMN noti.campaigns.id 					IS '캠페인 고유 식별자 (UUID)';
COMMENT ON COLUMN noti.campaigns.created_at 			IS '캠페인 생성 일시';
COMMENT ON COLUMN noti.campaigns.created_by 			IS '캠페인 생성자 UUID (마케터 또는 관리자)';
COMMENT ON COLUMN noti.campaigns.updated_at 			IS '캠페인 수정 일시';
COMMENT ON COLUMN noti.campaigns.updated_by 			IS '캠페인 수정자 UUID';
COMMENT ON COLUMN noti.campaigns.campaign_name 			IS '캠페인 이름 - 캠페인을 식별하기 위한 이름';
COMMENT ON COLUMN noti.campaigns.campaign_type 			IS '캠페인 유형 - 프로모션, 트랜잭션, 뉴스레터, 공지사항 등';
COMMENT ON COLUMN noti.campaigns.description 			IS '캠페인 설명 - 캠페인의 목적과 내용에 대한 설명';
COMMENT ON COLUMN noti.campaigns.target_type 			IS '대상 유형 - 전체 사용자, 테넌트 사용자, 관리자, 사용자 정의 목록 중 선택';
COMMENT ON COLUMN noti.campaigns.target_tenant_types 	IS '대상 테넌트 유형 목록 - 특정 테넌트 유형에만 발송할 경우 설정';
COMMENT ON COLUMN noti.campaigns.target_user_roles 		IS '대상 사용자 역할 목록 - 특정 역할의 사용자에게만 발송할 경우 설정';
COMMENT ON COLUMN noti.campaigns.custom_recipients 		IS '사용자 정의 수신자 UUID 목록 - 직접 선택한 수신자들';
COMMENT ON COLUMN noti.campaigns.subject 				IS '이메일 제목 - 수신자에게 표시될 이메일 제목';
COMMENT ON COLUMN noti.campaigns.html_content 			IS 'HTML 이메일 내용 - 리치 텍스트 형태의 이메일 본문';
COMMENT ON COLUMN noti.campaigns.text_content 			IS '텍스트 이메일 내용 - 플레인 텍스트 형태의 이메일 본문';
COMMENT ON COLUMN noti.campaigns.sender_name 			IS '발송자 이름 - 수신자에게 표시될 발송자 이름';
COMMENT ON COLUMN noti.campaigns.sender_email 			IS '발송자 이메일 - 이메일 발송에 사용할 발송자 주소';
COMMENT ON COLUMN noti.campaigns.reply_to_email 		IS '답장 이메일 주소 - 수신자가 답장할 때 사용할 이메일 주소';
COMMENT ON COLUMN noti.campaigns.send_immediately 		IS '즉시 발송 여부 - 생성 즉시 발송할지 예약 발송할지 여부';
COMMENT ON COLUMN noti.campaigns.scheduled_send_at 		IS '예약 발송 시각 - 이메일이 발송될 예정 시간';
COMMENT ON COLUMN noti.campaigns.timezone 				IS '시간대 설정 - 예약 발송 시 적용할 시간대';
COMMENT ON COLUMN noti.campaigns.total_recipients 		IS '총 수신자 수 - 이메일을 받을 전체 수신자 수';
COMMENT ON COLUMN noti.campaigns.sent_count 			IS '발송 성공 건수 - 성공적으로 발송된 이메일 수';
COMMENT ON COLUMN noti.campaigns.delivered_count 		IS '전달 성공 건수 - 수신자에게 실제 전달된 이메일 수';
COMMENT ON COLUMN noti.campaigns.opened_count 			IS '열람 건수 - 수신자가 이메일을 열어본 횟수';
COMMENT ON COLUMN noti.campaigns.clicked_count 			IS '클릭 건수 - 이메일 내 링크를 클릭한 횟수';
COMMENT ON COLUMN noti.campaigns.bounced_count 			IS '반송 건수 - 전달 실패로 반송된 이메일 수';
COMMENT ON COLUMN noti.campaigns.unsubscribed_count 	IS '구독 취소 건수 - 이메일을 통해 구독 취소한 수신자 수';
COMMENT ON COLUMN noti.campaigns.is_ab_test 			IS 'A/B 테스트 여부 - 두 가지 버전을 테스트할지 여부';
COMMENT ON COLUMN noti.campaigns.ab_test_rate 			IS 'A 그룹 비율 (백분율) - A/B 테스트 시 A 그룹에 할당할 비율';
COMMENT ON COLUMN noti.campaigns.ab_subject 			IS 'B 그룹 이메일 제목 - A/B 테스트용 대안 제목';
COMMENT ON COLUMN noti.campaigns.ab_content 			IS 'B 그룹 이메일 내용 - A/B 테스트용 대안 내용';
COMMENT ON COLUMN noti.campaigns.status 				IS '캠페인 상태 - 초안, 예약됨, 발송중, 발송완료, 일시중단, 취소 중 하나';
COMMENT ON COLUMN noti.campaigns.sent_at 				IS '발송 시작 시각 - 이메일 발송이 시작된 시간';
COMMENT ON COLUMN noti.campaigns.completed_at 			IS '발송 완료 시각 - 모든 이메일 발송이 완료된 시간';
COMMENT ON COLUMN noti.campaigns.deleted 				IS '논리적 삭제 플래그 - 실제 삭제 대신 사용하는 소프트 딜리트';

-- ======================================================
-- noti.campaigns 테이블 인덱스 정의
-- 목적: 캠페인 조회, 발송 관리, 성과 분석 최적화
-- ======================================================

-- 캠페인 상태별 조회용 인덱스
-- 설명: 캠페인 상태(status)별 조회 최적화, 가장 빈번한 조회 패턴
CREATE INDEX IF NOT EXISTS ix_campaigns__status_management
    ON noti.campaigns (status, created_at DESC)
 WHERE deleted = FALSE;

-- 캠페인 유형별 조회용 인덱스
-- 설명: 캠페인 유형별 조회 및 분석 최적화
CREATE INDEX IF NOT EXISTS ix_campaigns__campaign_type_analysis
    ON noti.campaigns (campaign_type, status, created_at DESC)
 WHERE deleted = FALSE;

-- 예약 발송 관리용 인덱스
-- 설명: 스케줄러가 예약된 캠페인 조회 최적화
CREATE INDEX IF NOT EXISTS ix_campaigns__scheduled_delivery
    ON noti.campaigns (scheduled_send_at, status)
 WHERE deleted = FALSE
   AND status = 'SCHEDULED';

-- 발송 성과 분석용 인덱스
-- 설명: 발송 완료된 캠페인 조회 및 통계 분석 최적화
CREATE INDEX IF NOT EXISTS ix_campaigns__performance_analysis
    ON noti.campaigns (campaign_type, sent_at DESC, total_recipients)
 WHERE deleted = FALSE
   AND status = 'SENT';

-- A/B 테스트 캠페인 조회용 인덱스
-- 설명: A/B 테스트 캠페인 조회 최적화
CREATE INDEX IF NOT EXISTS ix_campaigns__ab_test_management
    ON noti.campaigns (is_ab_test, campaign_type, status)
 WHERE deleted = FALSE
   AND is_ab_test = TRUE;

-- 대상 유형별 조회용 인덱스
-- 설명: 캠페인 대상 유형(USER, TENANT 등)별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_campaigns__target_type_management
    ON noti.campaigns (target_type, campaign_type, created_at DESC)
 WHERE deleted = FALSE;

-- 생성자별 캠페인 조회용 인덱스
-- 설명: 담당자별 캠페인 관리 최적화
CREATE INDEX IF NOT EXISTS ix_campaigns__creator_management
    ON noti.campaigns (created_by, created_at DESC, status)
 WHERE deleted = FALSE;

-- 발송 완료 캠페인 조회용 인덱스
-- 설명: 발송 완료(SENT)된 캠페인 이력 조회 최적화
CREATE INDEX IF NOT EXISTS ix_campaigns__completed_campaigns
    ON noti.campaigns (completed_at DESC, campaign_type)
 WHERE deleted = FALSE
   AND status = 'SENT';

-- 캠페인명 검색용 인덱스
-- 설명: 캠페인명으로 검색 최적화
CREATE INDEX IF NOT EXISTS ix_campaigns__campaign_name
    ON noti.campaigns (campaign_name)
 WHERE deleted = FALSE;

-- 생성일자 기준 조회용 인덱스
-- 설명: 최근 생성된 캠페인 조회 최적화
CREATE INDEX IF NOT EXISTS ix_campaigns__created_at
    ON noti.campaigns (created_at DESC)
 WHERE deleted = FALSE;

-- 오픈율 분석용 인덱스
-- 설명: 이메일 오픈율 분석 최적화, 전달된 캠페인만 대상
CREATE INDEX IF NOT EXISTS ix_campaigns__open_rate_analysis
    ON noti.campaigns (campaign_type, opened_count, delivered_count)
 WHERE deleted = FALSE
   AND status = 'SENT'
   AND delivered_count > 0;

-- 클릭률 분석용 인덱스
-- 설명: 이메일 클릭률 분석 최적화, 열람된 캠페인만 대상
CREATE INDEX IF NOT EXISTS ix_campaigns__click_rate_analysis
    ON noti.campaigns (campaign_type, clicked_count, opened_count)
 WHERE deleted = FALSE
   AND status = 'SENT'
   AND opened_count > 0;

-- 반송률 관리용 인덱스
-- 설명: 높은 반송률 캠페인 모니터링 최적화
CREATE INDEX IF NOT EXISTS ix_campaigns__bounce_rate_monitoring
    ON noti.campaigns (bounced_count, sent_count, campaign_type)
 WHERE deleted = FALSE
   AND status = 'SENT'
   AND bounced_count > 0;

-- GIN 인덱스: 대상 테넌트 유형 검색용
-- 설명: 대상 테넌트 유형 배열 검색 최적화
CREATE INDEX IF NOT EXISTS ix_campaigns__target_tenant_types_gin
    ON noti.campaigns USING GIN (target_tenant_types)
 WHERE deleted = FALSE
   AND target_tenant_types IS NOT NULL;

-- GIN 인덱스: 대상 사용자 역할 검색용
-- 설명: 대상 사용자 역할 배열 검색 최적화
CREATE INDEX IF NOT EXISTS ix_campaigns__target_user_roles_gin
    ON noti.campaigns USING GIN (target_user_roles)
 WHERE deleted = FALSE
   AND target_user_roles IS NOT NULL;

-- GIN 인덱스: 사용자 정의 수신자 검색용
-- 설명: CUSTOM_LIST 대상 캠페인 최적화
CREATE INDEX IF NOT EXISTS ix_campaigns__custom_recipients_gin
    ON noti.campaigns USING GIN (custom_recipients)
 WHERE deleted = FALSE
   AND target_type = 'CUSTOM_LIST';
