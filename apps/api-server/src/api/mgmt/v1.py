from fastapi import APIRouter

from ...modules.mgmt.auth.router import router as auth_router
from ...modules.mgmt.idam.router import router as idam_router
from ...modules.mgmt.tnnt.router import router as tnnt_router

# ... import other module routers

router = APIRouter()
# Note: Each module router already includes its own prefix
router.include_router(idam_router)  # Now includes logs and sessions
router.include_router(tnnt_router)
router.include_router(auth_router)
