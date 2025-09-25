import logging

import uvicorn
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response

from src.models.mgmt.tnnt import (  # noqa: F401
    Onboarding,
    Subscription,
    TenantRole,
    TenantUser,
)
from src.modules.mgmt.idam.api_key.model import ApiKey  # noqa: F401
from src.modules.mgmt.idam.login_log.model import LoginLog  # noqa: F401
from src.modules.mgmt.idam.permission.model import Permission  # noqa: F401
from src.modules.mgmt.idam.role.model import Role  # noqa: F401
from src.modules.mgmt.idam.session.model import Session  # noqa: F401

# Import other related models referenced in Tenant relationships
# Temporarily commented out to resolve relationship issues
# from src.models.mgmt.supt.ticket import Ticket  # noqa: F401
# from src.models.mgmt.supt.ticket_comment import TicketComment  # noqa: F401
# from src.models.mgmt.supt.feedback import Feedback  # noqa: F401
# from src.models.mgmt.stat.tenant_stat import TenantStat  # noqa: F401
# from src.models.mgmt.stat.usage_stat import UsageStat  # noqa: F401
# from src.models.mgmt.mntr.system_metric import SystemMetric  # noqa: F401
# from src.models.mgmt.noti.notification import Notification  # noqa: F401
# from src.models.mgmt.intg.rate_limit import RateLimit  # noqa: F401
# from src.models.mgmt.intg.api import Api  # noqa: F401
# from src.models.mgmt.intg.webhook import Webhook  # noqa: F401
# from src.models.mgmt.cnfg.tenant_feature import TenantFeature  # noqa: F401
# from src.models.mgmt.cnfg.feature_flag import FeatureFlag  # noqa: F401
# from src.models.mgmt.cnfg.service_quota import ServiceQuota  # noqa: F401
# from src.models.mgmt.audt.audit_log import AuditLog  # noqa: F401
# from src.models.mgmt.audt.compliance import Compliance  # noqa: F401
# from src.models.mgmt.bkup.execution import Execution  # noqa: F401
# from src.models.mgmt.bkup.schedule import Schedule  # noqa: F401
# from src.models.mgmt.ifra.resource import Resource  # noqa: F401
# from src.models.mgmt.ifra.resource_usage import ResourceUsage  # noqa: F401
# from src.models.mgmt.bill.invoice import Invoice  # noqa: F401
# from src.models.mgmt.bill.transaction import Transaction  # noqa: F401
# from src.models.mgmt.bill.plan import Plan  # noqa: F401
# Import IDAM models - already imported above
# from src.models.mgmt.idam.user import User  # noqa: F401
# from src.models.mgmt.idam.login_log import LoginLog  # noqa: F401
from src.modules.mgmt.idam.user.model import User  # noqa: F401
from src.modules.mgmt.idam.user_role.model import UserRole  # noqa: F401

# 모든 SQLAlchemy 모델을 import하여 관계가 제대로 인식되도록 함
from src.modules.mgmt.tnnt.tenant.model import Tenant  # noqa: F401

from .api.mgmt.v1 import router as mgmt_v1_router
from .api.tnnt.v1 import router as tnnt_v1_router

# from src.api.v1.mgmt.idam.router import router as mgmt_idam_router


# from src.api.v1.tnnt.auth.router import router as tnnt_auth_router

# 필요시 다른 관리자/사용자 모듈 라우터도 import
# from src.api.v1.mgmt.org.router import router as mgmt_org_router
# from src.api.v1.mgmt.tnnt.router import router as mgmt_tnnt_router

logging.basicConfig(level=logging.INFO)
app = FastAPI(
    redirect_slashes=False,  # trailing slash 리다이렉션 비활성화
    title="CXG 플랫폼 API",
    description=(
        """
        ## 50인 미만 소기업을 위한 AI 기반 업무지원 플랫폼

        ### 주요 기능
        - **사용자 인증**: 회원가입, 로그인, JWT 토큰 기반 인증
        - **AI 통합**: OpenAI API 연동
        - **벡터 검색**: Pinecone 연동

        ### API 구조
        - **REST API**: `/api/v1/` - 표준 OAuth2 인증 엔드포인트

        ### 인증
        Bearer 토큰을 사용하여 인증합니다.
        1. `/api/v1/auth/login` 또는 `/api/v1/auth/register`로 인증
        2. 반환된 `access_token`을 `Authorization: Bearer <token>` 헤더에 포함
        """
    ),
    version="0.1.0",
    contact={
        "name": "CXG (Connect & Grow)",
        "email": "admin@cxg.co.kr",
    },
    license_info={
        "name": "MIT License",
        "url": "https://opensource.org/licenses/MIT",
    },
    servers=[
        {
            "url": "http://localhost:8100",
            "description": "개발 서버",
        },
        {
            "url": "https://api.cxg.co.kr",
            "description": "운영 서버",
        },
    ],
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:3100",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:3100",
        "*",  # 개발 환경에서 모든 origin 허용
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=[
        "Accept",
        "Accept-Language",
        "Content-Language",
        "Content-Type",
        "Authorization",
        "X-Requested-With",
        "Origin",
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers",
    ],
    expose_headers=["*"],
)


# OPTIONS 요청 처리 미들웨어
@app.middleware("http")
async def cors_handler(request: Request, call_next):
    if request.method == "OPTIONS":
        response = Response()
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = (
            "GET, POST, PUT, DELETE, OPTIONS, PATCH"
        )
        response.headers["Access-Control-Allow-Headers"] = (
            "Accept, Accept-Language, Content-Language, Content-Type, Authorization, X-Requested-With, Origin, Access-Control-Request-Method, Access-Control-Request-Headers"
        )
        response.headers["Access-Control-Allow-Credentials"] = "true"
        return response

    response = await call_next(request)
    return response


# 관리자 시스템 라우터 등록
app.include_router(mgmt_v1_router)
app.include_router(tnnt_v1_router)

# 사용자 시스템 라우터 등록
# app.include_router(tnnt_auth_router)


@app.get("/")
async def root():
    return {"message": "AI 기반 업무지원 플랫폼 API 서버"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8100,
        log_level="info",
    )
