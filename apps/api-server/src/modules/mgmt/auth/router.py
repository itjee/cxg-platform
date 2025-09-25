from fastapi import APIRouter

from .authentication.router import router as auth_router

router = APIRouter(prefix="/api/v1/mgmt/auth")

# 서브 라우터 등록
router.include_router(auth_router)
