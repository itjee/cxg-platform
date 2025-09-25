---
applyTo: '**'
---
Provide project context and coding guidelines that AI should follow when generating code, answering questions, or reviewing changes.

# CXG Platform Development Instructions
- mgmt_modules.md guideline: # 관리자 시스템 (web-tnnt) 기본 모듈
- tnnt_modules.md guideline: # 사용자 시스템 (web-tnnt) 기본 모듈
- structure_web_mgmt.md guideline: # 관리자 웹 프론트엔드 (apps/mgmt-web) 구조도

apps/mgmt-web/
├── src/
│   ├── app/
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── (auth)/
│   │   │   ├── login/
│   │   │   │   └── page.tsx
│   │   │   └── register/
│   │   │       └── page.tsx
│   │   ├── dashboard/
│   │   │   ├── page.tsx
│   │   │   └── components/
│   │   │       ├── DashboardCards.tsx
│   │   │       ├── SystemMetrics.tsx
│   │   │       └── RecentActivity.tsx
│   │   ├── tnnt/
│   │   │   ├── page.tsx
│   │   │   ├── [id]/
│   │   │   │   ├── page.tsx
│   │   │   │   ├── settings/
│   │   │   │   └── billing/
│   │   │   └── components/
│   │   │       ├── TenantTable.tsx
│   │   │       ├── TenantForm.tsx
│   │   │       └── TenantDetails.tsx
│   │   ├── bill/
│   │   │   ├── page.tsx
│   │   │   ├── plans/
│   │   │   ├── invoices/
│   │   │   └── components/
│   │   │       ├── BillingOverview.tsx
│   │   │       ├── PlanManagement.tsx
│   │   │       └── InvoiceList.tsx
│   │   ├── mntr/
│   │   │   ├── page.tsx
│   │   │   ├── infrastructure/
│   │   │   ├── alerts/
│   │   │   └── components/
│   │   │       ├── SystemStatus.tsx
│   │   │       ├── PerformanceCharts.tsx
│   │   │       └── AlertsPanel.tsx
│   │   ├── supt/
│   │   │   ├── page.tsx
│   │   │   ├── tickets/
│   │   │   └── components/
│   │   │       ├── TicketList.tsx
│   │   │       ├── TicketDetails.tsx
│   │   │       └── SupportDashboard.tsx
│   │   ├── analytics/
│   │   │   ├── page.tsx
│   │   │   ├── usage/
│   │   │   ├── revenue/
│   │   │   └── components/
│   │   │       ├── UsageAnalytics.tsx
│   │   │       ├── RevenueCharts.tsx
│   │   │       └── TenantGrowth.tsx
│   │   └── settings/
│   │       ├── page.tsx
│   │       ├── users/
│   │       ├── system/
│   │       └── components/
│   │           ├── UserManagement.tsx
│   │           ├── SystemConfig.tsx
│   │           └── SecuritySettings.tsx
│   ├── components/
│   │   ├── ui/                   # shadcn/ui 컴포넌트
│   │   │   ├── button.tsx
│   │   │   ├── input.tsx
│   │   │   ├── table.tsx
│   │   │   ├── modal.tsx
│   │   │   ├── chart.tsx
│   │   │   └── form.tsx
│   │   ├── layout/
│   │   │   ├── Header.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Breadcrumb.tsx
│   │   │   └── Footer.tsx
│   │   ├── forms/
│   │   │   ├── TenantForm.tsx
│   │   │   ├── BillingForm.tsx
│   │   │   └── UserForm.tsx
│   │   ├── charts/
│   │   │   ├── RevenueChart.tsx
│   │   │   ├── UsageChart.tsx
│   │   │   └── GrowthChart.tsx
│   │   ├── tables/
│   │   │   ├── TenantsTable.tsx
│   │   │   ├── BillingTable.tsx
│   │   │   └── UsersTable.tsx
│   │   └── modals/
│   │       ├── ConfirmModal.tsx
│   │       ├── TenantModal.tsx
│   │       └── SettingsModal.tsx
│   ├── lib/
│   │   ├── api.ts               # API 클라이언트
│   │   ├── auth.ts              # 인증 관리
│   │   ├── utils.ts
│   │   └── validations.ts
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useTenants.ts
│   │   ├── useBilling.ts
│   │   ├── useMonitoring.ts
│   │   ├── useSupport.ts
│   │   └── useAnalytics.ts
│   ├── store/
│   │   ├── authStore.ts         # Zustand 스토어
│   │   ├── tenantStore.ts
│   │   ├── billingStore.ts
│   │   ├── monitoringStore.ts
│   │   └── globalStore.ts
│   ├── types/
│   │   ├── api.ts
│   │   ├── auth.ts
│   │   ├── tenant.ts
│   │   ├── billing.ts
│   │   ├── monitoring.ts
│   │   └── support.ts
│   └── styles/
│       └── globals.css
├── public/
│   ├── icons/
│   └── images/
├── package.json
├── next.config.js
├── tailwind.config.js
├── tsconfig.json
├── components.json              # shadcn/ui 설정
├── Dockerfile
└── .env.example

## 1. 기준정보 (adm: Master Data Management)

### 조직 관리
	- 회사, 사업부, 부서, 팀 단위의 조직 계층을 관리
	- 사용자 계정 및 권한(Role, RBAC) 설정
	- 조직별 KPI/예산 연결 가능

### 거래처 관리 (고객/벤더)
	- 고객/벤더 등록 및 수정
	- 거래 조건(결제조건, 세금코드, 신용한도) 관리
	- 등급, 거래이력, 평가(벤더평가/고객등급) 관리

### 제품 관리
	- 품목 마스터 등록 (SKU, 제품군, 옵션)
	- 가격/할인 규칙 관리 (단가표, 시즌별 가격)
	- 제품 대체 코드, 단종 관리

### 창고/위치 관리
	- 창고코드, 로케이션(랙/빈 단위) 등록
	- 3PL 창고 연동 코드 관리
	- 창고별 가용 용량 관리

### 기준 코드 관리
	- 공통 코드(세금코드, 통화코드, 결제조건 코드) 관리
	- 시스템 전역에서 사용하는 기준값 관리

### 여신 관리
	- 거래처별 신용한도 설정
	- 신용 사용 현황/초과 알림
	- ERP FI(재무)와 연동

## 2. 구매/조달 관리 (psm: Procurement & Sourcing)

### 구매요청 (PR: Purchase Requisition)
	- 부서/사용자의 구매 요청 등록
	- 결재/승인 프로세스 관리
	- ERP 예산 관리와 연계

### 발주관리 (PO: Purchase Order)
	- 구매 발주서 생성, 승인, 변경, 취소
	- 벤더별 주문 단가, 납기 관리
	- ERP AP(매입채무), WMS 입고와 연계

### 매입관리
	- 입고 시 매입 전표 자동 생성
	- 세금계산서/송장 처리
	- 매입 리포트 제공

### 매입채무 (AP)
	- 미지급금 관리
	- 지급 스케줄, 지급 실행
	- 벤더 정산 및 회계 반영

### 반품관리
	- 불량/과납/오납 발생 시 반품 처리
	- 벤더 크레딧 메모 생성

### RMA 관리 (Return Material Authorization)
	- 고객/벤더 반품 프로세스 등록
	- 반품 사유 관리 (불량, 오배송 등)
	- CS 모듈과 연계

### 벤더 관리
	- 신규 벤더 등록, 계약 관리
	- 평가 지표 관리 (납기, 품질, 가격 경쟁력)
	- 벤더별 SLA 관리

## 3. 영업/매출 관리 (srm: Sales & Receivables)

### 견적/영업 기회 관리
	- 영업 기회(Lead) 등록 및 진행 상태 관리
	- 견적서 생성/발행, CRM 연동

### 판매오더 관리 (SO: Sales Order)
	- 판매 주문 입력/승인/변경
	- 고객 주문 상태 추적
	- ERP 재고 및 물류 출고 연계

### 매출 관리
	- 출고 지시 및 출고 완료 처리
	- 송장 발행/세금계산서 처리

### - 수출 관리
	- 수출 주문 등록 및 통관 문서 관리
	- 환율 관리, 인코텀즈 적용

### 매출채권 (AR)
	- 고객 채권 관리
	- 연체 관리 및 독촉 알림
	- ERP FI(AR)와 연동

### 수금/입금 관리
    - 고객 입금 처리, 미수금 회수 현황
	- 은행 입출금 자동 대사

### 정산 관리
	- 거래처, 대리점/파트너 정산
	- 수수료 계산/지급

### 현황조회
	- 영업 Dashboard (매출 추세, 채권 회수율, 수주현황)

## 4. 재고/자재 관리 (ivm: Inventory & Materials)

### 재고 현황
	- 품목별, 창고별, 위치별 재고 조회
	- 가용재고/예약재고 구분

### 재고 예약
	- 고객 오더, 프로젝트 기반 예약
	- 우선순위/예약 취소 관리

### 재고 속성 관리
	- Lot, Batch, Serial 번호 등록/추적
	- 유통기한, 품질 속성 관리

### 재고 이동/조정
	- 창고 간 이동, 내부 로케이션 변경
	- 분실, 파손 등 재고 차이 조정

### 재구성 관리
	- 세트/번들 상품 구성
	- 재포장, 분해 처리

### 타계정 대체
    - 부서 간 재고 전환 처리
	- 계정 대체 전환 (비품, 비용 전환 등)
	- 회계 반영 (Transfer Posting)

### 재고 Aging/월령 관리
	- 재고 월령 분석 (Dead Stock 식별)
	- 재고 회전율 관리

### 현황조회
	- 재고 Dashboard (실시간 가용재고, Aging Report)

## 5. 물류/창고 관리 (lwm: Logistics & WMS)

### 입고 관리
	- 입고 예정/실제 입고 처리
	- 검수, 불량 등록

### 출고 관리
	- 출고 지시/피킹/패킹 처리
	- 배송 등록/추적

### 출고 지시/피킹/패킹 처리
	- 배송 등록/추적

### 위치 관리
	- Bin/Rack 기반 위치 관리
	- 자동 로케이션 추천

### 물류 이동/배송 관리
	- 배송 배차 계획
	- 택배/3PL 송장 연동

### 3PL 관리
	- 외부 물류센터 재고 연동
	- 재고/배송 상태 실시간 조회

### 현황조회
	- 물류 Dashboard (입출고 추세, 3PL 사용 현황)

## 6. 고객지원 (csm: Customer Service Management)

### 서비스 요청 관리
	- 고객 문의/요청 등록 (전화, 메일, 웹, 챗봇 등 채널 통합)
	- 요청 분류(기술 지원, 주문 관련, 불만/컴플레인)
	- SLA 기준에 따른 처리 우선순위 관리

### 티켓 관리
	- 고객 요청 건별 티켓 발행 및 추적
	- 처리 상태(신규, 진행중, 완료, 보류) 관리
	- 담당자 배정 및 이관

### FAQ/지식 베이스 관리
	- 자주 묻는 질문(FAQ) 등록
	- 내부 매뉴얼, 기술 문서, 가이드 관리
	- 검색 기반 고객 응대 지원

### 옴니채널 관리
	- 전화, 이메일, 웹, 채팅, 메신저 등 채널 통합 관리
	- 대화 로그/이력 조회
	- 고객 만족도 조사(CSAT)

### 고객 불만/클레임 관리
	- 클레임 접수/처리 현황 관리
	- 보상 정책(환불/포인트/쿠폰) 적용

### 현황조회/Dashboard
	- 티켓 현황(진행, SLA 준수율)
	- CS 처리 리드타임, 고객만족도 지표

## 7. A/S 관리 (asm: After Sales Service)

### A/S 요청 관리
	- 제품별 A/S 신청 접수(고객/대리점)
	- 보증기간, 계약 조건 자동 검증
	- 접수번호 발급 및 추적

### A/S 처리 관리
	- 수리 요청/작업 오더 생성
	- 수리/교체 진행 상태 관리
	- 외부 서비스 센터/파트너 연계

### 부품/소모품 관리
	- 수리용 부품 재고 관리
	- 소모품 교체 이력 추적

### 서비스 이력 관리
	- 고객별/제품별 A/S 이력 조회
	- 보증 내/외 수리 기록
	- 반복 이슈 분석

### 보증/계약 관리
	- 제품별 보증기간/유형 관리
	- 서비스 계약(유상/무상) 관리
	- 계약 만료 알림

### 비용/청구 관리
	- 유상 A/S 비용 산정/청구
	- ERP FI(AR/AP) 연계

### 현황조회/Dashboard
	- A/S 요청 건수, 처리 리드타임
	- 부품 소요 현황, 서비스 비용 분석

## 8. 재무/관리회계 (fim: Finance & Controlling)

### 총계정원장 (GL)
	- 분개 입력, 자동전표 처리
	- 마감/결산

### 매출채권 (AR)
	- 채권 대장 관리
	- 미수금 회수, 연체 관리

### 매입채무 (AP)
	- 미지급금 관리
	- 지급 스케줄, 실행

### 고정자산 관리
	- 자산 등록/이력 관리
	- 감가상각 처리

### 원가 관리
	- 제품별, 부서별 원가 배부
	- COGS 계산

### 손익 관리 (P&L)
	- 손익 계산서 자동 생성
	- 거래처/제품/부서별 손익분석

### 결제 관리
	- 고객/벤더 결제 처리
	- 계좌이체, 카드, 현금 등 수단 관리

### 연체 관리
	- 연체 채권/채무 모니터링
	- 독촉/알림 자동화

## 9. 경영분석 (bim: Business Intelligence & EPM)

### KPI/지표 분석
	- 조직/개인 KPI Dashboard
	- 목표 대비 실적 분석

### 목표 관리
	- 전략목표 등록/배정
	- 달성 현황 모니터링

### 매출 분석
	- 제품, 고객, 채널별 분석
	- 기간별 매출 추이

### 매입 분석
	- 벤더별 매입 현황
	- 구매 비용 구조 분석

### 이익 분석
	- 손익 시뮬레이션
	- 거래처별/상품별 수익성 분석

### 예측/시뮬레이션
	- 수요예측, 재고/매출 시뮬레이션
	- AI 기반 Forecasting

## 10. 공통/지원 모듈 (com: Enterprise Services)

### 전자결재 (Workflow)
	- 결재선 설정, 결재 요청/승인/반려
	- 문서이력 관리

### 일정/캘린더
	- 개인 일정 관리
	- 팀/조직 캘린더 공유

### 지식관리 (Knowledge Management)
	- 업무 매뉴얼, FAQ 관리
	- 검색 기능, 문서 버전 관리

### 법무/계약 관리
	- 계약 등록, 만료 알림
	- 규정/정책 문서 관리

### 자동화 (RPA/Trigger)
	- 알림/메일/메신저 트리거
	- 정기 보고서 자동 발송
	- 반복업무 자동화

## 1. 테넌트 관리 (Tenant Management) → tnnt

- tenants : 테넌트 마스터 정보
- subscriptions : 구독 및 요금제 관리
- onboarding : 온보딩 프로세스 추적
- users : 테넌트 사용자 정보
- api_keys : API 키 관리
- sessions : 사용자 세션 추적
- login_logs : 테넌트 사용자 로그인 로그

## 2. 인프라 및 리소스 관리 (Infrastructure Management) → ifra

- resources : 클라우드 리소스 관리
- resource_usages : 리소스 사용량 메트릭

## 3. 사용자 및 접근 관리 (User & Access Management) → idam

- **users :** 운영자 사용자 정보
- **api_keys** : API 키 관리
- **sessions** : 운영자 사용자 세션 추적
- permissions : 운영자 권한 카탈로그
- roles : 운영자 역할 정의
- role_permissions : 역할-권한 매핑 관리
- user_roles : 사용자-역할 매핑 관리
- login_logs : 운영자 사용자 로그인 로그

## 4. 요금 및 청구 관리 (Billing Management) → bill

- plans : 요금제 마스터
- invoices : 청구서 관리
- transactions : 결제 거래 내역

## 5. 시스템 모니터링 (System Monitoring) → mntr

- health_checks : 시스템 헬스체크
- incidents : 장애 및 인시던트 관리
- system_metrics : 시스템 성능 메트릭

## 6. 보안 및 감사 (Security & Audit) → audt

- **audit_logs** : 보안 감사 로그
- **assessments** : 컴플라이언스 보고서
- **policies** : 보안 정책 관리

## 7. 성능 및 분석 (Analytics) → stat

- tenant_stats : 테넌트 분석 데이터
- usage_stats : 사용량 요약 통계

## 8. 지원 및 고객 관리 (Support Management) → supt

- tickets : 고객 지원 티켓
- ticket_comments : 티켓 댓글 및 대화
- feedbacks : 고객 피드백

## 9. 시스템 설정 (Configuration Management) → cnfg

- configurations : 시스템 구성 관리
- feature_flags : 기능 플래그 관리
- tenant_features : 테넌트별 기능 오버라이드
- service_quotas - 서비스 할당량 관리

## 10. 백업 및 복구 (Backup & Recovery) → bkup

- executions : 백업 작업 관리
- schedules : 백업 스케줄 정의
- recovery_plans : 재해복구 계획

## 11. 알림 및 커뮤니케이션 (Notifications) → noti

- notifications : 알림 관리
- templates : 알림 템플릿
- campaigns : 이메일 캠페인

## 12. 외부 연동 (External Integrations) → intg

- apis : 외부 시스템 연동 API
- webhooks : 웹훅 엔드포인트
- rate_limits : API 호출 제한

## 13. 운영 자동화 (Automation) → auto

- workflows : 자동화 워크플로우
- executions : 워크플로우 실행 이력
- tasks : 스케줄된 작업

## 🎯 주요 개발 원칙
1. **타입 안전성 우선**: TypeScript strict 모드 사용
2. **에러 핸들링 필수**: 모든 API와 컴포넌트에 적절한 에러 처리
3. **성능 최적화**: 페이징, 캐싱, 지연 로딩 고려
4. **보안 강화**: 인증/권한 체크, 입력 검증
5. **테스트 커버리지**: 핵심 비즈니스 로직은 반드시 테스트

## 🚀 개발 우선순위
1. 백엔드 API 안정성
2. 프론트엔드 사용자 경험
3. 데이터 일관성
4. 시스템 성능
5. 코드 품질

## 🚫 절대 하지 말 것
- 하드코딩된 설정값 사용
- SQL 인젝션 가능성 있는 코드
- localStorage 사용 (아티팩트에서 미지원)
- 타입 체크 우회 (any 타입 남용)
- 에러 핸들링 생략

## ✅ 반드시 할 것
- 모든 API에 적절한 상태 코드 반환
- 프론트엔드 컴포넌트에 로딩/에러 상태 처리
- 데이터베이스 트랜잭션 관리
- 로깅 및 모니터링 구현
- 문서화 작성

## 통신 규칙
- 모든 API 응답은 다음과 같은 envelope 구조를 가져야 합니다:
```typescript
interface Envelope<T = any> {
  success: boolean;
  data: T | null;
  error: {
    code?: string;
    message: string;
    detail?: any;
  } | null;
}
```
- 성공 시 `success: true`, 실패 시 `success: false`와 함께 `error` 필드에 상세 정보 포함
- 프론트엔드에서는 이 구조를 기반으로 응답 처리 및 에러 핸들링
- API 문서에 각 엔드포인트의 응답 구조 명시
- API 요청 시 필요한 인증 토큰은 HTTP 헤더 `Authorization`에 포함
- 모든 API 요청과 응답은 JSON 형식 사용
- 페이징이 필요한 리스트 조회 API는 `page`와 `size` 쿼리 파라미터를 사용
- 민감한 정보는 절대 응답에 포함하지 않음 (예: 비밀번호, 토큰)
- CORS 정책을 준수하여 클라이언트 도메인에서만 API 접근 허용
- API 버전 관리를 위해 URL에 버전 정보 포함 (예: `/api/v1/resource`)
- API 변경 시 반드시 문서 업데이트 및 팀원에게 공지
- 모든 API는 적절한 상태 코드(200, 201, 400, 401, 403, 404, 500 등)를 반환
- 프론트엔드에서는 API 호출 시 로딩 상태와 에러 상태를 명확히 구분하여 사용자에게 피드백 제공
- API 호출 시 네트워크 오류, 타임아웃 등 예외 상황에 대한 핸들링 구현
- API 응답 시간이 500ms를 초과하지 않도록 최적화
- API 요청 시 불필요한 데이터 전송을 피하고, 필요한 데이터만 요청
- API 응답 데이터는 가능한 한 최소화하여 네트워크 부하 감소
- 모든 API는 HTTPS를 통해 통신하여 데이터 보안 유지
- API 요청과 응답에 대한 로깅을 통해 문제 발생 시 추적 가능하도록 구현
- API 테스트 자동화를 통해 주요 기능이 정상 동작하는지 지속적으로 검증
- API 문서화 도구(Swagger, Postman 등)를 사용하여 최신 API 문서 유지
- API 응답에 타임스탬프나 요청 ID를 포함하여 문제 추적 용이
- API 응답에 메타데이터(예: 페이징 정보, 총 아이템 수 등)를 포함하여 클라이언트에서 활용 가능하도록 함
- API 응답에 데이터 변경 시각(예: `updatedAt`)을 포함하여 클라이언트에서 최신 데이터 여부 판단 가능하도록 함
- API 응답에 데이터 버전 정보를 포함하여 클라이언트에서 캐싱 및 동기화에 활용 가능하도록 함
- API 응답에 관련 리소스의 링크(예: HATEOAS)를 포함하여 클라이언트에서 추가 작업 가능하도록 함
- API 응답에 사용자 맞춤형 메시지(예: 환영 메시지, 공지사항 등)를 포함하여 사용자 경험 향상

## 통신 흐름
- 프론트엔드에서 API 호출 시 로딩 상태 표시
- API 호출 성공 시 데이터 렌더링
- API 호출 실패 시 에러 메시지 표시
- 인증이 필요한 API 호출 시 토큰 만료 시 재로그인 유도
- 네트워크 오류 시 재시도 로직 구현 (최대 3회)
- API 응답 시간이 길어질 경우 타임아웃 처리 및 사용자에게 알림
- API 호출 전후로 필요한 전처리/후처리 로직 구현 (예: 데이터 포맷 변환, 상태 업데이트 등)
- API 호출 시 필요한 헤더(예: 인증 토큰, 콘텐츠 타입 등) 설정
- API 호출 시 쿼리 파라미터 및 바디 데이터 적절히 구성
- API 호출 시 취소 가능한 요청 구현 (예: 사용자가 페이지를 떠날 때)
- API 호출 시 로컬 캐싱 전략 구현 (예: SWR, React Query 등 사용)
- API 호출 시 사용자 권한에 따른 접근 제어 구현
- API 호출 시 다국어 지원을 위한 언어 헤더 설정
- API 호출 시 사용자 행동 분석을 위한 이벤트 로깅 구현
- API 호출 시 성능 모니터링을 위한 타이밍 측정 구현
- API 호출 시 보안 강화를 위한 CSRF 토큰 사용
- API 호출 시 데이터 무결성 검증을 위한 체크섬 사용
- 백엔드 흐름은 router -> service -> repository 패턴 준수
- 프론트엔드 흐름은 component -> store(Zustand 등)를 통한 API 통신 패턴 준수

## 백엔드 개발 가이드
- FastAPI 프레임워크 사용
- SQLAlchemy ORM 사용
- Pydantic 모델로 데이터 검증
- Alembic으로 데이터베이스 마이그레이션 관리
- OAuth2 및 JWT로 인증/권한 관리
- pytest로 단위 및 통합 테스트 작성
- 로깅은 Python logging 모듈 사용
- 환경 변수로 설정 관리 (dotenv 사용 권장)

## 프론트엔드 개발 가이드
- Next.js 프레임워크 사용
- TypeScript strict 모드 사용
- React Hook과 Context API로 상태 관리
- Axios로 API 통신
- React Query로 서버 상태 관리
- React Router로 라우팅 관리
- React Hook Form으로 폼 관리
- Tailwind CSS로 스타일링
- Jest와 React Testing Library로 테스트 작성
- ESLint와 Prettier로 코드 스타일 일관성 유지
- 환경 변수로 설정 관리 (Next.js 환경 변수 사용)

## 🐍 Python (백엔드)
```python
# 파일명: kebab-case
# user-service.py, order-management.py

# 함수/변수: snake_case
def get_user_by_id(user_id: str) -> Optional[User]:
    pass

# 클래스: PascalCase
class UserService:
    pass

# 상수: UPPER_SNAKE_CASE
MAX_RETRY_COUNT = 3
DEFAULT_PAGE_SIZE = 20

# API 엔드포인트: snake_case + _endpoint
async def create_user_endpoint(user_data: UserCreate):
    pass
```

## 📱 TypeScript (프론트엔드)
```typescript
// 파일명: PascalCase (컴포넌트)
// UserProfile.tsx, OrderHistory.tsx

// 변수/함수: camelCase
const getUserData = async (userId: string) => {};

// 타입/인터페이스: PascalCase
interface UserProfile {
  id: string;
  name: string;
}

// 상수: UPPER_SNAKE_CASE
const API_BASE_URL = '/api/v1';
```

## 🗄️ 데이터베이스
```sql
-- 테이블명: snake_case, 단수형
CREATE TABLE customer (
    id UUID PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    -- ...
);

-- 외래키: {entity}_id
customer_id UUID REFERENCES customer(id)

-- 인덱스: ix_{table}_{columns}
CREATE INDEX ix_customer_email ON customer(email);
```

## 🏗️ 전체 시스템 아키텍처

### 관리자 시스템 (apps/web-mgmt)
- **API 방식**: REST (기본) + GraphQL (복잡한 쿼리)
- **실시간**: WebSocket + Server-Sent Events
- **오프라인**: Service Worker + IndexedDB
- **상태 관리**: Zustand + TanStack Query
- **UI**: Next.js + shadcn/ui + Tailwind CSS

### 사용자 시스템 (apps/web-tnnt)
- **API 방식**: REST (기본) + GraphQL (복잡한 쿼리)
- **실시간**: WebSocket + Server-Sent Events
- **오프라인**: Service Worker + IndexedDB
- **상태 관리**: Zustand + TanStack Query
- **UI**: Next.js + shadcn/ui + Tailwind CSS

### 백엔드 (apps/api)
- **프레임워크**: FastAPI + SQLAlchemy
- **데이터베이스**: PostgreSQL (멀티테넌트)
- **캐싱**: Redis
- **메시지큐**: Redis Streams / RabbitMQ

## 🔄 데이터 플로우
```
Frontend → API Gateway → Business Logic → Database
    ↓           ↓              ↓           ↓
  Cache ←   Auth/Valid   →  Events   →  Logs
```

## 📊 모니터링 스택
- **APM**: OpenTelemetry
- **메트릭**: Prometheus + Grafana
- **로그**: ELK Stack
- **알림**: PagerDuty / Slack

## 색상 시스템 (Color System)

### 기본 원칙
CXG 플랫폼의 기본 색상은 **다크 테마의 색상을 기준**으로 합니다. 모든 디자인과 UI 컴포넌트는 이 색상 체계를 따라야 합니다.

### 주요 색상 팔레트

#### 배경 색상 (Background Colors)
- **Primary Background**: `#0D1023` - 메인 배경색 (진한 보라빛 네이비)
- **Secondary Background**: `#1B1D32` - 사이드바, 카드 배경색 (약간 밝은 보라빛 네이비)
- **Tertiary Background**: `#1e293b` - 팝오버, 카드 등 (slate-800)

#### 텍스트 색상 (Text Colors)
- **Primary Text**: `#f1f5f9` - 주요 텍스트 (slate-100)
- **Secondary Text**: `#94a3b8` - 보조 텍스트 (slate-400)
- **Border/Input**: `#334155` - 테두리, 입력 필드 (slate-700)

#### 액센트 색상 (Accent Colors)
- **핵심 포인트**: `#681ED5` - 메인 브랜드 색상 (보라)
- **보조 포인트**: `#F04064` - 서브 브랜드 색상 (핑크)
- **Secondary**: `#334155` - 보조 UI 요소 (slate-700)
- **Destructive**: `#ef4444` - 에러, 삭제 (red-500)

#### 상태 색상 (Status Colors)
- **Success**: `#10b981` - 성공 상태 (emerald-500)
- **Warning**: `#f59e0b` - 경고 상태 (amber-500)
- **Error**: `#ef4444` - 에러 상태 (red-500)

### 적용 범위

#### 1. 전체 애플리케이션
- 메인 대시보드
- 모든 관리 페이지
- 사이드바 및 네비게이션

#### 2. 인증 페이지
- 로그인 페이지
- 회원가입 페이지
- 비밀번호 재설정 페이지

#### 3. 컴포넌트
- 모든 UI 컴포넌트 (버튼, 카드, 모달 등)
- 폼 요소 (입력 필드, 선택 박스 등)
- 데이터 시각화 요소

### CSS 변수 정의

```css
.dark {
  --background: #0D1023;
  --foreground: #f1f5f9;
  --card: #1B1D32;
  --card-foreground: #f1f5f9;
  --primary: #681ED5;
  --primary-foreground: #f8fafc;
  --secondary: #334155;
  --secondary-foreground: #f1f5f9;
  --secondary-accent: #F04064;
  --muted: #334155;
  --muted-foreground: #94a3b8;
  --border: #334155;
  --input: #334155;
  --ring: #681ED5;
  --sidebar: #1B1D32;
  --sidebar-foreground: #f1f5f9;
}
```

### 사용 지침

1. **일관성 유지**: 모든 페이지와 컴포넌트에서 동일한 색상 체계를 사용해야 합니다.
2. **접근성 고려**: 텍스트와 배경 간 충분한 대비를 유지해야 합니다.
3. **계층 구조**: 색상의 명도를 통해 시각적 계층을 명확히 표현해야 합니다.
4. **상태 표현**: 상태별로 정의된 색상을 일관되게 사용해야 합니다.

### 구현 참고사항

- Tailwind CSS의 색상 클래스보다 CSS 변수를 우선 사용
- 커스텀 색상이 필요한 경우 HEX 코드를 직접 사용 (예: `bg-[#0D1023]`)
- 라이트 테마는 별도로 정의하되, 다크 테마의 색상 관계성을 유지

### 업데이트 이력

- 2025-09-24: 초기 색상 시스템 정의
- 기본 배경색을 `#0D1023`으로, 사이드바를 `#1B1D32`로 설정
- 핵심 포인트 색상을 `#681ED5` (보라)로, 보조 포인트 색상을 `#F04064` (핑크)로 설정
- 버튼에 핵심-보조 포인트 색상 그라디에이션 적용 (`from-[#681ED5] to-[#F04064]`)

---

이 가이드라인은 CXG 플랫폼의 시각적 일관성을 유지하기 위한 기준이며, 모든 개발자와 디자이너가 준수해야 합니다.
