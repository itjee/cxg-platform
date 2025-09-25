from fastapi import APIRouter

from .api_key import router as api_key_router
from .login_log import router as login_log_router
from .permission import router as permission_router
from .role import router as role_router
from .role_permission import router as role_permission_router
from .session import router as session_router
from .user import router as user_router
from .user_role import router as user_role_router

router = APIRouter(prefix="/api/v1/mgmt/idam")

# 서브 라우터 등록 (새로운 co-located 구조)
router.include_router(user_router)
router.include_router(role_router)
router.include_router(permission_router)
router.include_router(session_router)
router.include_router(login_log_router)
router.include_router(api_key_router)
router.include_router(user_role_router)
router.include_router(role_permission_router)
