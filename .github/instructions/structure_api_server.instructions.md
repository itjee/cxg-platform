---
applyTo: '**'
---
Provide project context and coding guidelines that AI should follow when generating code, answering questions, or reviewing changes.

# Backend API Development Instructions

## 파일 및 폴더 구조

apps/api/
└── src/
    ├── main.py
    ├── core/
    │   ├── __init__.py
    │   ├── config.py
    │   ├── database.py
    │   ├── security.py
    │   ├── tenant_resolver.py
    │   ├── exceptions.py
    │   ├── middleware.py
    │   ├── logging.py
    │   ├── opentelemetry.py
    │   ├── deps.py
    │   └── ai_integration.py
    ├── models/
    │   ├── __init__.py
    │   ├── base.py
    │   ├── manager/
    │   │   ├── __init__.py
    │   │   ├── tnnt/
    │   │   │   ├── __init__.py
    │   │   │   ├── tenant.py
    │   │   │   ├── subscription.py
    │   │   │   ├── onboarding.py
    │   │   │   └── user.py
    │   │   ├── ifra/
    │   │   │   ├── __init__.py
    │   │   │   ├── resource.py
    │   │   │   └── usage.py
    │   │   ├── idam/
    │   │   │   ├── __init__.py
    │   │   │   ├── user.py
    │   │   │   ├── role.py
    │   │   │   ├── permission.py
    │   │   │   └── session.py
    │   │   ├── bill/
    │   │   │   ├── __init__.py
    │   │   │   ├── plan.py
    │   │   │   ├── invoice.py
    │   │   │   └── transaction.py
    │   │   ├── mntr/
    │   │   │   ├── __init__.py
    │   │   │   ├── health_check.py
    │   │   │   ├── incident.py
    │   │   │   └── metric.py
    │   │   ├── audt/
    │   │   │   ├── __init__.py
    │   │   │   ├── audit_log.py
    │   │   │   ├── assessment.py
    │   │   │   └── policy.py
    │   │   ├── stat/
    │   │   │   ├── __init__.py
    │   │   │   ├── tenant_stat.py
    │   │   │   └── usage_stat.py
    │   │   ├── supt/
    │   │   │   ├── __init__.py
    │   │   │   ├── ticket.py
    │   │   │   ├── comment.py
    │   │   │   └── feedback.py
    │   │   ├── cnfg/
    │   │   │   ├── __init__.py
    │   │   │   ├── configuration.py
    │   │   │   ├── feature_flag.py
    │   │   │   └── quota.py
    │   │   ├── bkup/
    │   │   │   ├── __init__.py
    │   │   │   ├── execution.py
    │   │   │   ├── schedule.py
    │   │   │   └── recovery_plan.py
    │   │   ├── noti/
    │   │   │   ├── __init__.py
    │   │   │   ├── notification.py
    │   │   │   ├── template.py
    │   │   │   └── campaign.py
    │   │   ├── intg/
    │   │   │   ├── __init__.py
    │   │   │   ├── api.py
    │   │   │   ├── webhook.py
    │   │   │   └── rate_limit.py
    │   │   └── auto/
    │   │       ├── __init__.py
    │   │       ├── workflow.py
    │   │       ├── execution.py
    │   │       └── task.py
    │   └── tenant/
    │       ├── __init__.py
    │       ├── adm/
    │       │   ├── __init__.py
    │       │   ├── company.py
    │       │   ├── department.py
    │       │   ├── employee.py
    │       │   ├── customer.py
    │       │   ├── vendor.py
    │       │   ├── product.py
    │       │   ├── warehouse.py
    │       │   └── common_code.py
    │       ├── psm/
    │       │   ├── __init__.py
    │       │   ├── purchase_request.py
    │       │   ├── purchase_order.py
    │       │   ├── purchase_receipt.py
    │       │   ├── purchase_return.py
    │       │   └── accounts_payable.py
    │       ├── srm/
    │       │   ├── __init__.py
    │       │   ├── quotation.py
    │       │   ├── opportunity.py
    │       │   ├── sales_order.py
    │       │   ├── sales_invoice.py
    │       │   └── accounts_receivable.py
    │       ├── ivm/
    │       │   ├── __init__.py
    │       │   ├── inventory_balance.py
    │       │   ├── inventory_transaction.py
    │       │   ├── inventory_adjustment.py
    │       │   └── inventory_reservation.py
    │       ├── lwm/
    │       │   ├── __init__.py
    │       │   ├── delivery_order.py
    │       │   ├── warehouse_receipt.py
    │       │   └── shipping.py
    │       ├── csm/
    │       │   ├── __init__.py
    │       │   ├── service_request.py
    │       │   ├── ticket.py
    │       │   └── knowledge_base.py
    │       ├── asm/
    │       │   ├── __init__.py
    │       │   ├── service_order.py
    │       │   ├── warranty.py
    │       │   └── service_history.py
    │       ├── fim/
    │       │   ├── __init__.py
    │       │   ├── credit_limit.py
    │       │   ├── bank_transaction.py
    │       │   └── tax_invoice.py
    │       ├── bim/
    │       │   ├── __init__.py
    │       │   ├── kpi.py
    │       │   ├── dashboard.py
    │       │   └── analytics.py
    │       ├── com/
    │       │   ├── __init__.py
    │       │   ├── approval_document.py
    │       │   ├── calendar.py
    │       │   ├── attachment.py
    │       │   └── notice.py
    │       └── sys/
    │           ├── __init__.py
    │           ├── user.py
    │           ├── role.py
    │           ├── menu.py
    │           └── audit_log.py
    ├── modules/
    │   ├── mgmt/
    │   │   ├── auth/
    │   │   │   ├── router.py
    │   │   │   ├── schemas.py
    │   │   │   ├── schemas_v2.py
    │   │   │   ├── services.py
    │   │   │   ├── services_v2.py
    │   │   │   └── repository.py
    │   │   ├── tnnt/
    │   │   │   ├── router.py
    │   │   │   ├── schemas_v1.py
    │   │   │   └── services_v1.py
    │   │   ├── ifra/
    │   │   │   ├── router.py
    │   │   │   ├── schemas.py
    │   │   │   └── services_v1.py
    │   │   ├── idam/
    │   │   │   ├── router.py
    │   │   │   ├── schemas.py
    │   │   │   └── services.py
    │   │   ├── bill/
    │   │   │   ├── router.py
    │   │   │   ├── schemas_v1.py
    │   │   │   └── services_v1.py
    │   │   ├── mntr/
    │   │   │   ├── router.py
    │   │   │   ├── schemas.py
    │   │   │   └── services.py
    │   │   ├── audt/
    │   │   │   ├── router.py
    │   │   │   ├── schemas.py
    │   │   │   └── services.py
    │   │   ├── stat/
    │   │   │   ├── router.py
    │   │   │   ├── schemas.py
    │   │   │   └── services.py
    │   │   ├── supt/
    │   │   │   ├── router.py
    │   │   │   ├── schemas.py
    │   │   │   └── services.py
    │   │   ├── cnfg/
    │   │   │   ├── router.py
    │   │   │   ├── schemas.py
    │   │   │   └── services.py
    │   │   ├── bkup/
    │   │   │   ├── router.py
    │   │   │   ├── schemas.py
    │   │   │   └── services.py
    │   │   ├── noti/
    │   │   │   ├── router.py
    │   │   │   ├── schemas.py
    │   │   │   └── services.py
    │   │   ├── intg/
    │   │   │   ├── router.py
    │   │   │   ├── schemas.py
    │   │   │   └── services.py
    │   │   └── auto/
    │   │       ├── router.py
    │   │       ├── schemas.py
    │   │       └── services.py
    │   └── tnnt/
    │       ├── adm/
    │       │   ├── router.py
    │       │   ├── schemas.py
    │       │   ├── services.py
    │       │   └── repository.py
    │       ├── psm/
    │       │   ├── router.py
    │       │   ├── schemas.py
    │       │   └── services.py
    │       ├── srm/
    │       │   ├── router.py
    │       │   ├── schemas.py
    │       │   └── services.py
    │       ├── ivm/
    │       │   ├── router.py
    │       │   ├── schemas.py
    │       │   └── services.py
    │       ├── lwm/
    │       │   ├── router.py
    │       │   ├── schemas.py
    │       │   └── services.py
    │       ├── csm/
    │       │   ├── router.py
    │       │   ├── schemas.py
    │       │   └── services.py
    │       ├── asm/
    │       │   ├── router.py
    │       │   ├── schemas.py
    │       │   └── services.py
    │       ├── fim/
    │       │   ├── router.py
    │       │   ├── schemas.py
    │       │   └── services.py
    │       ├── bim/
    │       │   ├── router.py
    │       │   ├── schemas.py
    │       │   └── services.py
    │       ├── esm/
    │       │   ├── router.py
    │       │   ├── schemas.py
    │       │   └── services.py
    │       ├── sys/
    │       │   ├── router.py
    │       │   ├── schemas.py
    │       │   └── services.py
    │       └── aix/
    │           ├── router.py
    │           ├── schemas.py
    │           └── services.py
    ├── api/
    │   ├── __init__.py
    │   ├── deps.py
    │   ├── mgmt/
    │   │   ├── __init__.py
    │   │   └── v1.py
    │   └── tnnt/
    │       ├── __init__.py
    │       └── v1.py
    ├── services/
    │   ├── __init__.py
    │   ├── base_service.py
    │   ├── manager/
    │   │   ├── __init__.py
    │   │   ├── tnnt_service.py
    │   │   ├── bill_service.py
    │   │   ├── mntr_service.py
    │   │   ├── noti_service.py
    │   │   └── stat_service.py
    │   ├── tenant/
    │   │   ├── __init__.py
    │   │   ├── adm_service.py
    │   │   ├── psm_service.py
    │   │   ├── srm_service.py
    │   │   ├── ivm_service.py
    │   │   ├── fim_service.py
    │   │   ├── esm_service.py
    │   │   └── aix_service.py
    │   └── shared/
    │       ├── __init__.py
    │       ├── auth_service.py
    │       ├── email_service.py
    │       ├── file_service.py
    │       └── cache_service.py
    ├── ai/
    │   ├── __init__.py
    │   ├── agents/
    │   │   ├── __init__.py
    │   │   ├── base_agent.py
    │   │   ├── psm_agent.py
    │   │   ├── srm_agent.py
    │   │   ├── ivm_agent.py
    │   │   ├── fim_agent.py
    │   │   └── bim_agent.py
    │   ├── chains/
    │   │   ├── __init__.py
    │   │   ├── analysis_chain.py
    │   │   ├── report_chain.py
    │   │   └── recommendation_chain.py
    │   ├── embeddings/
    │   │   ├── __init__.py
    │   │   ├── document_embedder.py
    │   │   └── vector_store.py
    │   ├── prompts/
    │   │   ├── __init__.py
    │   │   ├── system_prompts.py
    │   │   └── business_prompts.py
    │   └── tools/
    │       ├── __init__.py
    │       ├── data_query_tool.py
    │       ├── report_generator_tool.py
    │       └── excel_analyzer_tool.py
    ├── utils/
    │   ├── __init__.py
    │   ├── logger.py
    │   ├── validators.py
    │   ├── helpers.py
    │   ├── excel_processor.py
    │   ├── report_generator.py
    │   └── data_validator.py
    ├── openapi/
    │   ├── openapi-mgmt-v1.json
    │   └── openapi-tnnt-v1.json
    ├── clients/
    │   ├── mgmt-v1/
    │   └── tnnt-v1/
    ├── ci/
    │   ├── gen_openapi.sh
    │   └── gen_clients.sh
    ├── tests/
    │   ├── __init__.py
    │   ├── conftest.py
    │   ├── test_manager/
    │   │   ├── test_tnnt_api.py
    │   │   ├── test_bill_api.py
    │   │   └── test_mntr_api.py
    │   ├── test_tenant/
    │   │   ├── test_adm_api.py
    │   │   ├── test_psm_api.py
    │   │   ├── test_srm_api.py
    │   │   ├── test_ivm_api.py
    │   │   └── test_aix.py
    │   └── test_shared/
    │       ├── test_auth_service.py
    │       └── test_utils.py
    ├── alembic/
    │   ├── versions/
    │   ├── env.py
    │   └── script.py.mako
    ├── docker/
    │   ├── Dockerfile
    │   └── docker-compose.dev.yml
    ├── scripts/
    │   ├── migrate.sh
    │   ├── seed_sample_data.sh
    │   └── run_local.sh
    ├── docs/
    │   ├── ARCHITECTURE.md
    │   ├── API_VERSIONING.md
    │   └── MODULE_GUIDE.md
    ├── README.md
    ├── requirements.txt
    ├── requirements-dev.txt
    ├── pyproject.toml
    └── .env.example


## 디렉토리/파일 역할 설명 (요약)

  - main.py: 앱 생성, 미들웨어 등록, app.include_router(api.mgmt.v1.router, prefix='/api/v1/mgmt') 등 라우터 등록을 담당.
  - core/: 전역 설정, DB 연결, 인증/권한, 테넌트 해결자, 공통 deps, 로깅/추적, 미들웨어를 포함. 핵심 인프라 코드만 두고 비즈니스 로직은 두지 않음.
  - models/: SQLAlchemy 기반 모델을 보관. 테넌트 스키마 분리/테이블 네이밍 규칙을 문서화.
  - modules/: 도메인(모듈) 중심 코드를 캡슐화. 각 모듈은 router.py, schemas_v1.py, services_v1.py, repository.py, README.md 등을 포함.
  - api/: 실제 엔드포인트 노출을 위한 경량 레이어. api/mgmt/v1.py는 모듈별 router들을 조합해 최종 라우터를 반환.
  - services/: 모듈보다 더 상위 수준(또는 외부 어댑터) 작업을 담당. DB 트랜잭션 경계·사정 의존 로직·외부 연동 조정 등을 둠.
  - ai/: AI 전용 코드(agents, chains, embeddings)를 모아 독립적으로 배포/스케일링 가능하도록 구성.
  - openapi/ & clients/: CI에서 자동 생성된 스펙과 프론트용 타입/SDK를 보관.
  - ci/: 스펙/클라이언트 생성 스크립트, 기타 배포 helper 스크립트.
  - docker/, scripts/: 로컬 개발/배포 편의 스크립트 보관.

## 네이밍/버전 정책(간단 규칙)

### 라우터 등록(버전)
  - main.py에서 시스템 단위로 등록:
    - app.include_router(mgmt_v1.router, prefix="/api/v1/mgmt")
    - app.include_router(tnnt_v1.router, prefix="/api/v1/tnnt")
### 모듈 내부 버전 관리
  - 기본: schemas_v1.py, services_v1.py. 브레이킹 시 schemas_v2.py 추가.
  - 큰 변경이면 모듈을 modules/.../<module>/v2/{...}로 물리 분리.
### OpenAPI 파일
  - openapi-mgmt-v1.json, openapi-tnnt-v1.json 등 시스템·버전별로 생성.
### TS 클라이언트 위치
  - clients/mgmt-v1/, clients/tnnt-v1/ 등으로 나눠 저장.

## 권장 개발/운영 워크플로(요약)
  - 로컬 개발: docker-compose.dev.yml로 Postgres/Redis/Chroma(또는 Pinecone 모의) 실행. scripts/run_local.sh로 서비스 띄우기.
  - CI: PR에서 테스트 수행 -> 통과 시 gen_openapi.sh 실행 -> gen_clients.sh로 클라이언트 갱신(옵션: 자동 커밋 또는 artifact 저장).
  - 배포: staging/production 분리. managed DB 사용 권장. 초기에는 단일 컨테이너(모듈형 monolith)로 배포, 필요 시 AI/Vector DB/Worker를 분리.
  - 마이그레이션: Alembic 사용. DB 변경은 expand -> migrate -> shrink 패턴으로 적용.

## 테스트/모니터링/관찰성
  - 테스트: 모듈별 단위 테스트(모의 DB), 통합 테스트는 최소한의 핵심 시나리오(인증, 핵심 CRUD, AI 연동). 테스트는 tests/ 폴더 모듈별로 구성.
  - 로깅/Tracing: structured JSON logs + OpenTelemetry tracing + Sentry for errors.
  - 메트릭: Prometheus exporter 적용(요청 라우트별 latency, error rate, tenant별 usage).

## 보안/멀티테넌시 요령(간단 체크리스트)
  - Tenant resolution: tenant_resolver에서 토큰/호스트/헤더 기반 판별. 모든 DB 쿼리에 tenant_id 필터 강제.
  - 권한: core/security에서 role 기반 권한 검사(관리자 vs 테넌트 사용자 분리).
  - Rate limit: Redis 기반 테넌트별 quota 적용.
  - 민감데이터: 필요 시 암호화(필드 레벨) 및 액세스 로그(감사)를 남김.

## 추가 자료(참고 템플릿)
  - modules/*/README.md 템플릿 (책임, API 목록, 스키마 예시, migration notes)
  - ci/gen_openapi.sh 예시
  - ci/gen_clients.sh 예시 (openapi-typescript-codegen 사용 권장)
  - scripts/migrate.sh (alembic upgrade + DB sanity checks)
