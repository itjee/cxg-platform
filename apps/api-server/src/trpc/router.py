from trpc_python import Router, Procedure
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime


class UserModel(BaseModel):
    id: str
    email: str
    username: str
    created_at: datetime
    is_active: bool


class TenantModel(BaseModel):
    id: str
    name: str
    domain: str
    created_at: datetime
    is_active: bool


class CreateUserInput(BaseModel):
    email: str
    username: str
    password: str


class LoginInput(BaseModel):
    email: str
    password: str


class AuthResponse(BaseModel):
    access_token: str
    user: UserModel


# 사용자 관련 tRPC 프로시저
async def get_users() -> List[UserModel]:
    # TODO: 실제 데이터베이스에서 사용자 조회
    return []


async def get_user(user_id: str) -> Optional[UserModel]:
    # TODO: 실제 데이터베이스에서 특정 사용자 조회
    return None


async def create_user(input_data: CreateUserInput) -> UserModel:
    from src.core.security import get_password_hash
    from src.api.v1.endpoints.auth import fake_users_db

    # 이메일 중복 체크
    if input_data.email in fake_users_db:
        raise Exception("이미 등록된 이메일입니다")

    # 새 사용자 생성
    user_id = str(len(fake_users_db) + 1)
    hashed_password = get_password_hash(input_data.password)

    new_user = {
        "id": user_id,
        "email": input_data.email,
        "username": input_data.username,
        "hashed_password": hashed_password,
        "created_at": datetime.now().isoformat(),
        "is_active": True,
    }

    fake_users_db[input_data.email] = new_user

    return UserModel(
        id=user_id,
        email=input_data.email,
        username=input_data.username,
        created_at=datetime.now(),
        is_active=True
    )


async def login_user(input_data: LoginInput) -> AuthResponse:
    from src.core.security import verify_password, create_access_token
    from src.api.v1.endpoints.auth import fake_users_db
    from datetime import timedelta
    from src.core.config import settings

    # 사용자 인증
    user_data = fake_users_db.get(input_data.email)
    if not user_data or not verify_password(input_data.password, user_data["hashed_password"]):
        raise Exception("이메일 또는 비밀번호가 올바르지 않습니다")

    # 토큰 생성
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user_data["email"]},
        expires_delta=access_token_expires
    )

    user = UserModel(
        id=user_data["id"],
        email=user_data["email"],
        username=user_data.get("username", user_data.get("name", "")),
        created_at=datetime.fromisoformat(user_data["created_at"]),
        is_active=user_data["is_active"]
    )

    return AuthResponse(
        access_token=access_token,
        user=user
    )


# 테넌트 관련 tRPC 프로시저
async def get_tenants() -> List[TenantModel]:
    # TODO: 실제 데이터베이스에서 테넌트 조회
    return []


async def create_tenant(name: str, domain: str) -> TenantModel:
    # TODO: 실제 테넌트 생성 로직
    return TenantModel(
        id="new_tenant_id",
        name=name,
        domain=domain,
        created_at=datetime.now(),
        is_active=True
    )


# tRPC 라우터 생성
trpc_router = Router()

# 사용자 관련 프로시저 등록
trpc_router.query("users", get_users)
trpc_router.query("user", get_user)
trpc_router.mutation("createUser", create_user)
trpc_router.mutation("login", login_user)

# 테넌트 관련 프로시저 등록
trpc_router.query("tenants", get_tenants)
trpc_router.mutation("createTenant", create_tenant)