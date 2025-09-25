from fastapi import APIRouter

from ...modules.tnnt.auth.router import router as auth_router

# ... import other module routers

router = APIRouter()
# Note: no version prefix here, main.py attaches prefix '/api/v1/tnnt'
router.include_router(auth_router, prefix="/api/v1/tnnt/auth")
