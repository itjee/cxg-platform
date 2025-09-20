from fastapi import APIRouter
from src.api.v1.endpoints import users, tenants, auth

api_router = APIRouter()

api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(tenants.router)