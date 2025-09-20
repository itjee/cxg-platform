from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.v1.router import api_router
import uvicorn

app = FastAPI(
    title="CXG 플랫폼 API",
    description="""
    ## 50인 미만 소기업을 위한 AI 기반 업무지원 플랫폼

    ### 주요 기능
    - **사용자 인증**: 회원가입, 로그인, JWT 토큰 기반 인증
    - **테넌트 관리**: 멀티 테넌트 환경 지원
    - **AI 통합**: OpenAI API 연동
    - **벡터 검색**: Pinecone 연동

    ### 인증
    Bearer 토큰을 사용하여 인증합니다.
    1. `/api/v1/auth/login` 또는 `/api/v1/auth/register`로 인증
    2. 반환된 `access_token`을 `Authorization: Bearer <token>` 헤더에 포함
    """,
    version="0.1.0",
    contact={
        "name": "CXG Platform Team",
        "email": "admin@cxg-platform.com",
    },
    license_info={
        "name": "MIT License",
        "url": "https://opensource.org/licenses/MIT",
    },
    servers=[
        {"url": "http://localhost:8100", "description": "개발 서버"},
        {"url": "https://api.cxg-platform.com", "description": "운영 서버"},
    ],
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3100",
        "http://localhost:3200",
        "http://192.168.0.200:3100",
        "http://192.168.0.200:3200",
        "*"  # 개발용 - 운영에서는 특정 도메인으로 제한
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API 라우터 등록
app.include_router(api_router, prefix="/api/v1")

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
        reload=True,
        log_level="info"
    )
