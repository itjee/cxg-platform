from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from strawberry.fastapi import GraphQLRouter
from src.api.v1.router import api_router
from src.core.config import settings
from src.graphql.schema import schema
from src.trpc.router import trpc_router

app = FastAPI(
    title="CXG Platform API",
    description="API for CXG Platform Management System",
    version="1.0.0",
)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# REST API 라우터 등록
app.include_router(api_router, prefix="/api/v1")

# GraphQL 엔드포인트 등록
graphql_app = GraphQLRouter(schema)
app.include_router(graphql_app, prefix="/graphql")

# tRPC 엔드포인트 등록 (관리자용)
app.include_router(trpc_router, prefix="/trpc")

@app.get("/")
async def root():
    return {"message": "CXG Platform API Server"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "version": "1.0.0"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8100, reload=True)