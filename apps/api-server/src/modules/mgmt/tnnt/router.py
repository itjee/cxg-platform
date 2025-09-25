from fastapi import APIRouter

from .tenant import router as tenant_router

router = APIRouter(prefix="/api/v1/mgmt/tnnt")

# 서브 라우터 등록 (새로운 co-located 구조)
router.include_router(tenant_router)
