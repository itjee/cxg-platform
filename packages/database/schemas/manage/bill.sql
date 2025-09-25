-- ============================================================================
-- 4. 요금 및 청구 관리 (Billing Management) -> bill
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS bill;

COMMENT ON SCHEMA bill
IS 'BILL: 요금/청구 스키마: 과금 기준과 청구/결제 이력을 관리. 회계/세무 대응 고려.';

-- ============================================================================
-- 요금제 마스터
-- ============================================================================
CREATE TABLE IF NOT EXISTS bill.plans
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 요금제 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,                   	-- 요금제 생성 일시
    created_by                  UUID,                                                              	-- 요금제 생성자 UUID (관리자)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 요금제 수정 일시
    updated_by                  UUID,                                                              	-- 요금제 수정자 UUID

	-- 요금제 기본 정보
    plan_code                   VARCHAR(50)              NOT NULL,		                          	-- 요금제 식별 코드 (PLAN_TRIAL, PLAN_STD 등)
    plan_name                   VARCHAR(100)             NOT NULL,                                 	-- 요금제 이름 (체험판, 스탠다드, 프리미엄 등)
    plan_type                   VARCHAR(20)              NOT NULL DEFAULT 'STANDARD',             	-- 요금제 유형 (TRIAL/STANDARD/PREMIUM/ENTERPRISE)
    description                 TEXT,                                                              	-- 요금제 상세 설명

	-- 가격 정보
    base_price                  NUMERIC(18,4)            NOT NULL,                                 	-- 기본 요금 (월/분기/년 단위)
    user_price                  NUMERIC(18,4)            DEFAULT 0,                               	-- 사용자당 추가 요금
    currency                    CHAR(3)                  NOT NULL DEFAULT 'KRW',                  	-- 통화 단위 (ISO 4217)
    billing_cycle               VARCHAR(20)              NOT NULL DEFAULT 'MONTHLY',              	-- 청구 주기 (MONTHLY/QUARTERLY/YEARLY)

	-- 사용량 제한 정보
    max_users                   INTEGER                  DEFAULT 50,                              	-- 최대 사용자 수 제한
    max_storage                 INTEGER                  DEFAULT 100,                             	-- 최대 스토리지 용량 (GB)
    max_api_calls               INTEGER                  DEFAULT 10000,                           	-- 월간 최대 API 호출 수

	-- 기능 제한 정보
    features                    JSONB                    DEFAULT '{}',                            	-- 포함된 기능 목록 (JSON 형태)

	-- 유효 기간 관리
	start_time                  DATE                     NOT NULL,                                 	-- 요금제 적용 시작일
    close_time                    DATE,                                                             -- 요금제 적용 종료일 (NULL: 무기한)

	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'ACTIVE',              	-- 요금제 상태 (ACTIVE/INACTIVE/ARCHIVED)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
	CONSTRAINT uk_plans__plan_code			UNIQUE (plan_code),

    CONSTRAINT ck_plans__plan_type 			CHECK (plan_type IN ('TRIAL', 'STANDARD', 'PREMIUM', 'ENTERPRISE')),
    CONSTRAINT ck_plans__billing_cycle 		CHECK (billing_cycle IN ('MONTHLY', 'QUARTERLY', 'YEARLY')),
    CONSTRAINT ck_plans__status 			CHECK (status IN ('ACTIVE', 'INACTIVE', 'ARCHIVED')),
    CONSTRAINT ck_plans__base_price 		CHECK (base_price >= 0),
    CONSTRAINT ck_plans__user_price 		CHECK (user_price >= 0),
    CONSTRAINT ck_plans__max_users 			CHECK (max_users IS NULL OR max_users > 0),
    CONSTRAINT ck_plans__max_storage 		CHECK (max_storage IS NULL OR max_storage > 0),
    CONSTRAINT ck_plans__max_api_calls 		CHECK (max_api_calls IS NULL OR max_api_calls > 0),
    CONSTRAINT ck_plans__valid_period 		CHECK (close_time IS NULL OR close_time >= start_time)
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  bill.plans					IS '요금제 마스터 - 서비스 요금제의 가격 정책, 사용량 제한, 포함 기능을 정의하는 핵심 테이블';
COMMENT ON COLUMN bill.plans.id 				IS '요금제 고유 식별자 - UUID 형태의 기본키, 시스템 내에서 각 요금제를 구분하는 고유값';
COMMENT ON COLUMN bill.plans.created_at 		IS '요금제 생성 일시 - 요금제가 시스템에 등록된 시점의 타임스탬프';
COMMENT ON COLUMN bill.plans.created_by 		IS '요금제 생성자 UUID - 요금제를 생성한 관리자 또는 시스템의 식별자';
COMMENT ON COLUMN bill.plans.updated_at 		IS '요금제 수정 일시 - 요금제 정보가 최종 변경된 시점의 타임스탬프';
COMMENT ON COLUMN bill.plans.updated_by 		IS '요금제 수정자 UUID - 요금제를 최종 수정한 관리자 또는 시스템의 식별자';
COMMENT ON COLUMN bill.plans.plan_code 			IS '요금제 식별 코드 - 시스템에서 사용하는 고유한 요금제 코드 (예: PLAN_TRIAL, PLAN_STD, PLAN_PRO)';
COMMENT ON COLUMN bill.plans.plan_name 			IS '요금제 이름 - 사용자에게 표시되는 요금제명 (예: 체험판, 스탠다드, 프리미엄, 엔터프라이즈)';
COMMENT ON COLUMN bill.plans.plan_type 			IS '요금제 유형 - TRIAL(체험판), STANDARD(표준), PREMIUM(프리미엄), ENTERPRISE(기업용) 분류';
COMMENT ON COLUMN bill.plans.description 		IS '요금제 상세 설명 - 요금제의 특징, 대상 고객, 주요 기능 등에 대한 마케팅 문구';
COMMENT ON COLUMN bill.plans.base_price 		IS '기본 요금 - 요금제의 월/분기/연 단위 기본 구독료 (최소 청구 금액)';
COMMENT ON COLUMN bill.plans.user_price 		IS '사용자당 추가 요금 - 기본 사용자 수를 초과하는 각 사용자에 대한 추가 과금액';
COMMENT ON COLUMN bill.plans.currency 			IS '통화 단위 - 요금 표시 및 청구에 사용할 통화 (ISO 4217 코드, 예: KRW, USD, EUR)';
COMMENT ON COLUMN bill.plans.billing_cycle 		IS '청구 주기 - MONTHLY(월별), QUARTERLY(분기별), YEARLY(연별) 청구 주기 설정';
COMMENT ON COLUMN bill.plans.max_users 			IS '최대 사용자 수 제한 - 이 요금제에서 허용하는 최대 활성 사용자 수 (라이선스 한도)';
COMMENT ON COLUMN bill.plans.max_storage 		IS '최대 스토리지 용량 - 이 요금제에서 허용하는 최대 저장공간 크기 (GB 단위)';
COMMENT ON COLUMN bill.plans.max_api_calls 		IS '월간 최대 API 호출 수 - 이 요금제에서 허용하는 월간 API 요청 한도';
COMMENT ON COLUMN bill.plans.features 			IS '포함된 기능 목록 - 이 요금제에서 사용 가능한 기능들의 상세 설정 (JSON 형태, 기능별 on/off 및 제한값 포함)';
COMMENT ON COLUMN bill.plans.start_time 		IS '요금제 적용 시작일 - 이 요금제가 유효해지는 날짜 (신규 가입 시 적용 기준일)';
COMMENT ON COLUMN bill.plans.close_time 		IS '요금제 적용 종료일 - 이 요금제의 유효 기간 만료일 (NULL인 경우 무기한 유효)';
COMMENT ON COLUMN bill.plans.status 			IS '요금제 상태 - ACTIVE(활성, 신규가입가능), INACTIVE(비활성, 신규가입불가), ARCHIVED(보관, 기존가입자만유지)';
COMMENT ON COLUMN bill.plans.deleted 			IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 요금제 코드 고유성 보장
CREATE UNIQUE INDEX IF NOT EXISTS ux_plans__plan_code
    ON bill.plans (plan_code)
 WHERE deleted = FALSE;

-- 요금제 유형별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_plans__plan_type
    ON bill.plans (plan_type)
 WHERE deleted = FALSE;

-- 상태별 요금제 조회 최적화
CREATE INDEX IF NOT EXISTS ix_plans__status_active
    ON bill.plans (status)
 WHERE deleted = FALSE;

-- 청구 주기별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_plans__billing_cycle
    ON bill.plans (billing_cycle)
 WHERE deleted = FALSE;

-- 가격 범위별 요금제 분석 최적화
CREATE INDEX IF NOT EXISTS ix_plans__price_range
    ON bill.plans (base_price, user_price)
 WHERE deleted = FALSE;

-- 유효 기간 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_plans__valid_period
    ON bill.plans (start_time, close_time)
 WHERE deleted = FALSE;

-- 현재 활성 요금제 조회 최적화
CREATE INDEX IF NOT EXISTS ix_plans__active_valid
    ON bill.plans (status, start_time, close_time)
 WHERE status = 'ACTIVE' AND deleted = FALSE;

-- 유형별 가격 비교 최적화
CREATE INDEX IF NOT EXISTS ix_plans__type_price
    ON bill.plans (plan_type, base_price)
 WHERE deleted = FALSE;

-- 기능 검색을 위한 GIN 인덱스
CREATE INDEX IF NOT EXISTS ix_plans__features
    ON bill.plans USING GIN (features)
 WHERE deleted = FALSE;

-- 최신 생성 요금제 조회 최적화
CREATE INDEX IF NOT EXISTS ix_plans__created_at
    ON bill.plans (created_at DESC);

-- 사용량 제한별 요금제 분석 최적화
CREATE INDEX IF NOT EXISTS ix_plans__usage_limits
    ON bill.plans (max_users, max_storage, max_api_calls)
 WHERE deleted = FALSE;

-- 통화별 청구 주기 조회 최적화
CREATE INDEX IF NOT EXISTS ix_plans__currency_cycle
    ON bill.plans (currency, billing_cycle)
 WHERE deleted = FALSE;


-- ============================================================================
-- 청구서 관리
-- ============================================================================
CREATE TABLE IF NOT EXISTS bill.invoices
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 청구서 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,                   	-- 청구서 생성 일시
    created_by                  UUID,                                                              	-- 청구서 생성자 UUID (시스템 또는 관리자)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 청구서 수정 일시
    updated_by                  UUID,                                                              	-- 청구서 수정자 UUID

	-- 관련 테이블 연결
    tenant_id                   UUID                     NOT NULL,                                 	-- 청구 대상 테넌트 ID
    subscription_id             UUID                     NOT NULL,                                 	-- 구독 계약 ID

	-- 청구서 기본 정보
    invoice_no                  VARCHAR(50)              NOT NULL,		                          	-- 청구서 번호 (시스템 내 고유)
    invoice_date                DATE                     NOT NULL,                                 	-- 청구서 발행일
    due_date                    DATE                     NOT NULL,                                 	-- 결제 만료일
    start_date                  DATE                     NOT NULL,                                 	-- 청구 기간 시작일
    close_date                  DATE                     NOT NULL,                                 	-- 청구 기간 종료일

	-- 청구 금액 정보
    base_amount                 NUMERIC(18,4)            NOT NULL,                                 	-- 기본 구독 요금
    usage_amount                NUMERIC(18,4)            DEFAULT 0,                               	-- 사용량 기반 추가 요금 (초과 사용자, API 호출 등)
    discount_amount             NUMERIC(18,4)            DEFAULT 0,                               	-- 할인 금액 (프로모션, 쿠폰 등)
    tax_amount                  NUMERIC(18,4)            DEFAULT 0,                               	-- 세금 (VAT, 부가세 등)
    total_amount                NUMERIC(18,4)            NOT NULL,                                	-- 총 청구 금액 (최종 결제 금액)
    currency                    CHAR(3)                  NOT NULL DEFAULT 'KRW',                  	-- 통화 단위 (ISO 4217)

	-- 사용량 상세 정보
    user_count                  INTEGER                  NOT NULL,                                	-- 청구 기간 중 평균/최대 사용자 수
    used_storage                NUMERIC(18,4)            DEFAULT 0,                               	-- 스토리지 사용량 (GB)
    api_calls                   INTEGER                  DEFAULT 0,                               	-- 총 API 호출 횟수

	-- 결제 정보
    paid_at                     TIMESTAMP WITH TIME ZONE,                                          	-- 결제 완료 일시
    payment_method              VARCHAR(50),                                                       	-- 결제 수단 (CREDIT_CARD/BANK_TRANSFER/PAYPAL 등)

	-- 상태 관리
    status                      VARCHAR(20)              NOT NULL DEFAULT 'PENDING',              	-- 청구서 상태 (PENDING/SENT/PAID/OVERDUE/CANCELED)
    deleted                 	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그

	-- 제약조건
    CONSTRAINT fk_invoices__tenant_id 			FOREIGN KEY (tenant_id) 		REFERENCES tnnt.tenants(id)			ON DELETE CASCADE,
    CONSTRAINT fk_invoices__subscription_id 	FOREIGN KEY (subscription_id) 	REFERENCES tnnt.subscriptions(id)	ON DELETE CASCADE,

	CONSTRAINT uk_invoices__invoice_no			UNIQUE (invoice_no),

    CONSTRAINT ck_invoices__status 				CHECK (status IN ('PENDING', 'SENT', 'PAID', 'OVERDUE', 'CANCELED')),
    CONSTRAINT ck_invoices__payment_method 		CHECK (payment_method IN ('CREDIT_CARD', 'BANK_TRANSFER', 'PAYPAL', 'WIRE_TRANSFER', 'CHECK')),
    CONSTRAINT ck_invoices__base_amount 		CHECK (base_amount >= 0),
    CONSTRAINT ck_invoices__usage_amount 		CHECK (usage_amount >= 0),
    CONSTRAINT ck_invoices__discount_amount 	CHECK (discount_amount >= 0),
    CONSTRAINT ck_invoices__tax_amount 			CHECK (tax_amount >= 0),
    CONSTRAINT ck_invoices__total_amount 		CHECK (total_amount >= 0),
    CONSTRAINT ck_invoices__user_count 			CHECK (user_count > 0),
    CONSTRAINT ck_invoices__used_storage 		CHECK (used_storage >= 0),
    CONSTRAINT ck_invoices__api_calls 			CHECK (api_calls >= 0),
    CONSTRAINT ck_invoices__date_sequence 		CHECK (due_date >= invoice_date AND close_date >= start_date)
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  bill.invoices					IS '청구서 관리 - 테넌트별 월간/주기별 청구서 생성, 발송, 결제 추적을 관리하는 핵심 과금 테이블';
COMMENT ON COLUMN bill.invoices.id 				IS '청구서 고유 식별자 - UUID 형태의 기본키, 시스템 내에서 각 청구서를 구분하는 고유값';
COMMENT ON COLUMN bill.invoices.created_at 		IS '청구서 생성 일시 - 청구서가 시스템에서 생성된 시점의 타임스탬프';
COMMENT ON COLUMN bill.invoices.created_by 		IS '청구서 생성자 UUID - 청구서를 생성한 시스템 프로세스 또는 관리자의 식별자';
COMMENT ON COLUMN bill.invoices.updated_at 		IS '청구서 수정 일시 - 청구서 정보가 최종 변경된 시점의 타임스탬프';
COMMENT ON COLUMN bill.invoices.updated_by 		IS '청구서 수정자 UUID - 청구서를 최종 수정한 시스템 또는 관리자의 식별자';
COMMENT ON COLUMN bill.invoices.tenant_id 		IS '청구 대상 테넌트 ID - 이 청구서의 수신자인 테넌트의 고유 식별자 (tenants 테이블 참조)';
COMMENT ON COLUMN bill.invoices.subscription_id IS '구독 계약 ID - 이 청구서의 근거가 되는 구독 계약의 고유 식별자 (subscriptions 테이블 참조)';
COMMENT ON COLUMN bill.invoices.invoice_no 		IS '청구서 번호 - 시스템에서 발급하는 고유한 청구서 식별번호 (예: INV-2024-001, 2024120001)';
COMMENT ON COLUMN bill.invoices.invoice_date 	IS '청구서 발행일 - 청구서가 공식적으로 발행된 날짜 (회계 기준일)';
COMMENT ON COLUMN bill.invoices.due_date 		IS '결제 만료일 - 고객이 결제를 완료해야 하는 최종 기한 (연체 판단 기준)';
COMMENT ON COLUMN bill.invoices.start_date 		IS '청구 기간 시작일 - 이 청구서가 적용되는 서비스 이용 기간의 시작날짜';
COMMENT ON COLUMN bill.invoices.close_date 		IS '청구 기간 종료일 - 이 청구서가 적용되는 서비스 이용 기간의 종료날짜';
COMMENT ON COLUMN bill.invoices.base_amount 	IS '기본 구독 요금 - 구독 계획에 따른 고정 월/분기/연 요금';
COMMENT ON COLUMN bill.invoices.usage_amount 	IS '사용량 기반 추가 요금 - 초과 사용자, 추가 스토리지, API 호출 등에 따른 변동 요금';
COMMENT ON COLUMN bill.invoices.discount_amount IS '할인 금액 - 프로모션, 쿠폰, 계약 할인 등으로 감액된 금액';
COMMENT ON COLUMN bill.invoices.tax_amount 		IS '세금 - 부가세, VAT 등 법정 세금 (지역별 세율 적용)';
COMMENT ON COLUMN bill.invoices.total_amount 	IS '총 청구 금액 - 고객이 실제로 결제해야 하는 최종 금액 (base + usage - discount + tax)';
COMMENT ON COLUMN bill.invoices.currency 		IS '통화 단위 - 청구서에 표시되는 통화 (ISO 4217 코드, 예: KRW, USD, EUR)';
COMMENT ON COLUMN bill.invoices.user_count 		IS '청구 기간 중 사용자 수 - 해당 기간 동안의 평균 또는 최대 활성 사용자 수 (과금 기준)';
COMMENT ON COLUMN bill.invoices.used_storage 	IS '스토리지 사용량 - 청구 기간 중 실제 사용한 저장공간 크기 (GB 단위)';
COMMENT ON COLUMN bill.invoices.api_calls 		IS '총 API 호출 횟수 - 청구 기간 중 발생한 누적 API 요청 수';
COMMENT ON COLUMN bill.invoices.paid_at 		IS '결제 완료 일시 - 고객이 실제로 결제를 완료한 시점의 타임스탬프';
COMMENT ON COLUMN bill.invoices.payment_method 	IS '결제 수단 - CREDIT_CARD(신용카드), BANK_TRANSFER(계좌이체), PAYPAL, WIRE_TRANSFER(전신송금), CHECK(수표)';
COMMENT ON COLUMN bill.invoices.status 			IS '청구서 상태 - PENDING(대기), SENT(발송완료), PAID(결제완료), OVERDUE(연체), CANCELED(취소)';
COMMENT ON COLUMN bill.invoices.deleted 		IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 청구서 번호 고유성 보장
CREATE UNIQUE INDEX IF NOT EXISTS ux_invoices__invoice_no
    ON bill.invoices (invoice_no)
 WHERE deleted = FALSE;

-- 테넌트별 청구서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_invoices__tenant_id
    ON bill.invoices (tenant_id)
 WHERE deleted = FALSE;

-- 구독별 청구서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_invoices__subscription_id
    ON bill.invoices (subscription_id)
 WHERE deleted = FALSE;

-- 상태별 청구서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_invoices__status
    ON bill.invoices (status)
 WHERE deleted = FALSE;

-- 발행일 기준 정렬 조회 최적화
CREATE INDEX IF NOT EXISTS ix_invoices__invoice_date
    ON bill.invoices (invoice_date DESC);

-- 결제 만료일 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_invoices__due_date
    ON bill.invoices (due_date)
 WHERE deleted = FALSE;

-- 결제 완료 청구서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_invoices__paid_status
    ON bill.invoices (status, paid_at DESC)
 WHERE status = 'PAID' AND deleted = FALSE;

-- 연체 청구서 관리 최적화
CREATE INDEX IF NOT EXISTS ix_invoices__overdue
    ON bill.invoices (status, due_date)
 WHERE status = 'OVERDUE' AND deleted = FALSE;

-- 테넌트별 기간 조회 최적화
CREATE INDEX IF NOT EXISTS ix_invoices__tenant_period
    ON bill.invoices (tenant_id, start_date, close_date)
 WHERE deleted = FALSE;

-- 청구 금액별 분석 최적화
CREATE INDEX IF NOT EXISTS ix_invoices__amount_range
    ON bill.invoices (total_amount DESC)
 WHERE deleted = FALSE;

-- 청구 기간별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_invoices__billing_period
    ON bill.invoices (start_date, close_date)
 WHERE deleted = FALSE;

-- 결제 수단별 통계 최적화
CREATE INDEX IF NOT EXISTS ix_invoices__payment_method
    ON bill.invoices (payment_method, paid_at DESC)
 WHERE payment_method IS NOT NULL AND deleted = FALSE;

-- 최신 생성 청구서 조회 최적화
CREATE INDEX IF NOT EXISTS ix_invoices__created_at
    ON bill.invoices (created_at DESC);


-- ============================================================================
-- 결제 거래 내역
-- ============================================================================
CREATE TABLE IF NOT EXISTS bill.transactions
(
    -- 기본 식별자 및 감사 필드
    id                          UUID                     PRIMARY KEY DEFAULT gen_random_uuid(),		-- 결제 거래 고유 식별자 (UUID)
    created_at                  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,                   	-- 거래 생성 일시
    created_by                  UUID,                                                              	-- 거래 생성자 UUID (시스템 또는 관리자)
    updated_at                  TIMESTAMP WITH TIME ZONE,                                          	-- 거래 수정 일시
    updated_by                  UUID,                                                              	-- 거래 수정자 UUID

	-- 관련 테이블 연결
    tenant_id                   UUID                     NOT NULL,                                 	-- 결제 주체 테넌트 ID
    invoice_id                  UUID,                                                              	-- 연관 청구서 ID (청구서 결제인 경우)

    -- 거래 식별 정보 및 유형
    transaction_no              VARCHAR(100)             NOT NULL,                          		-- 거래 번호 (시스템 내 고유)
    transaction_type            VARCHAR(20)              NOT NULL DEFAULT 'PAYMENT',              	-- 거래 유형 (PAYMENT/REFUND/CHARGEBACK)

    payment_gateway             VARCHAR(50),                                                       	-- 결제 게이트웨이 (STRIPE/PAYPAL/TOSS/KAKAOPAY 등)
    payment_gateway_id      	VARCHAR(255),                                                      	-- 결제 게이트웨이에서 생성한 거래 ID

	-- 결제 금액 정보
    amount                      NUMERIC(18,4)            NOT NULL,                                 	-- 결제 금액
    currency                    CHAR(3)                  NOT NULL DEFAULT 'KRW',                  	-- 통화 단위 (ISO 4217)
    exchange_rate               NUMERIC(18,6),                                                     	-- 환율 (외화 결제 시 적용)

	-- 결제 수단 정보
    payment_method              VARCHAR(50)              NOT NULL,                                 	-- 결제 수단 (CREDIT_CARD/BANK_TRANSFER/VIRTUAL_ACCOUNT 등)
    card_digits            		VARCHAR(4),                                                        	-- 카드 마지막 4자리 (보안상 부분 정보만)

    -- 처리 시간 정보
    processed_at                TIMESTAMP WITH TIME ZONE,                                          	-- 결제 처리 완료 일시
    failed_at                   TIMESTAMP WITH TIME ZONE,                                          	-- 결제 실패 일시
    failure_reason              TEXT,                                                              	-- 결제 실패 사유

	-- 상태 관리
	status                      VARCHAR(20)              NOT NULL DEFAULT 'PENDING',              	-- 거래 상태 (PENDING/SUCCESS/FAILED/CANCELED)
    deleted                  	BOOLEAN                  NOT NULL DEFAULT FALSE,                 	-- 논리적 삭제 플래그
    -- 제약조건
    CONSTRAINT fk_transactions__tenant_id 				FOREIGN KEY (tenant_id) 	REFERENCES tnnt.tenants(id)		ON DELETE CASCADE,
    CONSTRAINT fk_transactions__invoice_id 				FOREIGN KEY (invoice_id) 	REFERENCES bill.invoices(id)	ON DELETE CASCADE,

	CONSTRAINT uk_transactions__transaction_no 			UNIQUE (transaction_no),

    CONSTRAINT ck_transactions__transaction_type 		CHECK (transaction_type IN ('PAYMENT', 'REFUND', 'CHARGEBACK')),
    CONSTRAINT ck_transactions__status 					CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED', 'CANCELED')),
    CONSTRAINT ck_transactions__payment_method 			CHECK (payment_method IN ('CREDIT_CARD', 'BANK_TRANSFER', 'VIRTUAL_ACCOUNT', 'PAYPAL', 'KAKAOPAY', 'NAVERPAY')),
    CONSTRAINT ck_transactions__amount 					CHECK (amount > 0),
    CONSTRAINT ck_transactions__exchange_rate 			CHECK (exchange_rate IS NULL OR exchange_rate > 0),
    CONSTRAINT ck_transactions__failure_logic 			CHECK ((status = 'FAILED' AND failed_at IS NOT NULL) OR (status != 'FAILED')),
    CONSTRAINT ck_transactions__success_logic 			CHECK ((status = 'SUCCESS' AND processed_at IS NOT NULL) OR (status != 'SUCCESS'))
);

-- 테이블 및 컬럼 코멘트
COMMENT ON TABLE  bill.transactions						IS '결제 거래 내역 - 모든 결제, 환불, 지불거절 거래의 상세 기록과 결제 게이트웨이 연동 정보를 관리';
COMMENT ON COLUMN bill.transactions.id 					IS '결제 거래 고유 식별자 - UUID 형태의 기본키, 시스템 내에서 각 거래를 구분하는 고유값';
COMMENT ON COLUMN bill.transactions.created_at 			IS '거래 생성 일시 - 거래가 시스템에 등록된 시점의 타임스탬프';
COMMENT ON COLUMN bill.transactions.created_by 			IS '거래 생성자 UUID - 거래를 생성한 시스템 프로세스 또는 관리자의 식별자';
COMMENT ON COLUMN bill.transactions.updated_at 			IS '거래 수정 일시 - 거래 정보가 최종 변경된 시점의 타임스탬프';
COMMENT ON COLUMN bill.transactions.updated_by 			IS '거래 수정자 UUID - 거래 정보를 최종 수정한 시스템 또는 관리자의 식별자';
COMMENT ON COLUMN bill.transactions.tenant_id 			IS '결제 주체 테넌트 ID - 이 거래를 수행한 테넌트의 고유 식별자 (tenants 테이블 참조)';
COMMENT ON COLUMN bill.transactions.invoice_id 			IS '연관 청구서 ID - 이 거래와 연결된 청구서의 고유 식별자 (invoices 테이블 참조, 수동결제시 NULL)';
COMMENT ON COLUMN bill.transactions.transaction_no 		IS '거래 번호 - 시스템에서 발급하는 고유한 거래 식별번호 (예: TXN-2024-001, PAY20241201001)';
COMMENT ON COLUMN bill.transactions.transaction_type 	IS '거래 유형 - PAYMENT(결제), REFUND(환불), CHARGEBACK(지불거절/차지백)';
COMMENT ON COLUMN bill.transactions.payment_gateway 	IS '결제 게이트웨이 - STRIPE(스트라이프), PAYPAL(페이팔), TOSS(토스페이먼츠), KAKAOPAY(카카오페이) 등';
COMMENT ON COLUMN bill.transactions.payment_gateway_id 	IS '결제 게이트웨이에서 생성한 거래 ID - 외부 결제 서비스에서 발급한 고유 거래 식별자 (reconciliation 용)';
COMMENT ON COLUMN bill.transactions.amount 				IS '결제 금액 - 실제 거래된 금액 (양수만 허용, 환불의 경우 별도 거래로 처리)';
COMMENT ON COLUMN bill.transactions.currency 			IS '통화 단위 - 거래에 사용된 통화 (ISO 4217 코드, 예: KRW, USD, EUR)';
COMMENT ON COLUMN bill.transactions.exchange_rate 		IS '환율 - 외화 결제 시 적용된 환율 (기준통화 대비, 예: 1 USD = 1300 KRW)';
COMMENT ON COLUMN bill.transactions.payment_method 		IS '결제 수단 - CREDIT_CARD(신용카드), BANK_TRANSFER(계좌이체), VIRTUAL_ACCOUNT(가상계좌), PAYPAL, KAKAOPAY, NAVERPAY';
COMMENT ON COLUMN bill.transactions.card_digits 		IS '카드 마지막 4자리 - 보안상 카드번호의 마지막 4자리만 저장 (예: 1234)';
COMMENT ON COLUMN bill.transactions.processed_at 		IS '결제 처리 완료 일시 - 결제가 성공적으로 완료된 시점의 타임스탬프';
COMMENT ON COLUMN bill.transactions.failed_at 			IS '결제 실패 일시 - 결제가 실패로 처리된 시점의 타임스탬프';
COMMENT ON COLUMN bill.transactions.failure_reason 		IS '결제 실패 사유 - 결제 실패 시 게이트웨이에서 제공하는 상세 오류 메시지';
COMMENT ON COLUMN bill.transactions.status 				IS '거래 상태 - PENDING(처리중), SUCCESS(성공), FAILED(실패), CANCELED(취소)';
COMMENT ON COLUMN bill.transactions.deleted 			IS '논리적 삭제 플래그 - TRUE(삭제됨), FALSE(활성상태), 물리적 삭제 대신 사용';

-- 인덱스 생성
-- 거래 번호 고유성 보장
CREATE UNIQUE INDEX IF NOT EXISTS ux_transactions__transaction_no
    ON bill.transactions (transaction_no)
 WHERE deleted = FALSE;

-- 테넌트별 거래 조회 최적화
CREATE INDEX IF NOT EXISTS ix_transactions__tenant_id
    ON bill.transactions (tenant_id)
 WHERE deleted = FALSE;

-- 청구서별 거래 조회 최적화
CREATE INDEX IF NOT EXISTS ix_transactions__invoice_id
    ON bill.transactions (invoice_id)
 WHERE invoice_id IS NOT NULL AND deleted = FALSE;

-- 상태별 거래 조회 최적화
CREATE INDEX IF NOT EXISTS ix_transactions__status
    ON bill.transactions (status)
 WHERE deleted = FALSE;

-- 게이트웨이별 거래 조회 최적화
CREATE INDEX IF NOT EXISTS ix_transactions__payment_gateway
    ON bill.transactions (payment_gateway)
 WHERE payment_gateway IS NOT NULL AND deleted = FALSE;

-- 외부 거래 ID 검색 최적화
CREATE INDEX IF NOT EXISTS ix_transactions__payment_gateway_id
    ON bill.transactions (payment_gateway_id)
 WHERE payment_gateway_id IS NOT NULL AND deleted = FALSE;

-- 거래 유형별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_transactions__transaction_type
    ON bill.transactions (transaction_type)
 WHERE deleted = FALSE;

-- 결제 수단별 조회 최적화
CREATE INDEX IF NOT EXISTS ix_transactions__payment_method
    ON bill.transactions (payment_method)
 WHERE deleted = FALSE;

-- 처리 완료 시간 기준 조회 최적화
CREATE INDEX IF NOT EXISTS ix_transactions__processed_at
    ON bill.transactions (processed_at DESC NULLS LAST)
 WHERE deleted = FALSE;

-- 실패 거래 분석 최적화
CREATE INDEX IF NOT EXISTS ix_transactions__failed
    ON bill.transactions (status, failed_at DESC)
 WHERE status = 'FAILED' AND deleted = FALSE;

-- 성공 거래 조회 최적화
CREATE INDEX IF NOT EXISTS ix_transactions__success
    ON bill.transactions (status, processed_at DESC)
 WHERE status = 'SUCCESS' AND deleted = FALSE;

-- 금액별 거래 분석 최적화
CREATE INDEX IF NOT EXISTS ix_transactions__amount_range
    ON bill.transactions (amount DESC)
 WHERE deleted = FALSE;

-- 최신 거래 조회 최적화
CREATE INDEX IF NOT EXISTS ix_transactions__created_at
    ON bill.transactions (created_at DESC);

-- 테넌트별 상태 복합 조회 최적화
CREATE INDEX IF NOT EXISTS ix_transactions__tenant_status
    ON bill.transactions (tenant_id, status, created_at DESC)
 WHERE deleted = FALSE;
