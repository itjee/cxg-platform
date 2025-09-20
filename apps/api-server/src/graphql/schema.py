import strawberry
from typing import List, Optional
from datetime import datetime


@strawberry.type
class User:
    id: str
    email: str
    username: str
    created_at: datetime
    is_active: bool


@strawberry.type
class Tenant:
    id: str
    name: str
    domain: str
    created_at: datetime
    is_active: bool


@strawberry.input
class CreateUserInput:
    email: str
    username: str
    password: str


@strawberry.input
class LoginInput:
    email: str
    password: str


@strawberry.type
class AuthPayload:
    access_token: str
    user: User


@strawberry.type
class Query:
    @strawberry.field
    def users(self) -> List[User]:
        # TODO: 실제 데이터베이스에서 사용자 조회
        return []

    @strawberry.field
    def user(self, id: str) -> Optional[User]:
        # TODO: 실제 데이터베이스에서 특정 사용자 조회
        return None

    @strawberry.field
    def tenants(self) -> List[Tenant]:
        # TODO: 실제 데이터베이스에서 테넌트 조회
        return []


@strawberry.type
class Mutation:
    @strawberry.field
    def create_user(self, input: CreateUserInput) -> User:
        from src.core.security import get_password_hash
        from src.api.v1.endpoints.auth import fake_users_db

        # 이메일 중복 체크
        if input.email in fake_users_db:
            raise Exception("이미 등록된 이메일입니다")

        # 새 사용자 생성
        user_id = str(len(fake_users_db) + 1)
        hashed_password = get_password_hash(input.password)

        new_user = {
            "id": user_id,
            "email": input.email,
            "username": input.username,
            "hashed_password": hashed_password,
            "created_at": datetime.now().isoformat(),
            "is_active": True,
        }

        fake_users_db[input.email] = new_user

        return User(
            id=user_id,
            email=input.email,
            username=input.username,
            created_at=datetime.now(),
            is_active=True
        )

    @strawberry.field
    def login(self, input: LoginInput) -> AuthPayload:
        from src.core.security import verify_password, create_access_token
        from src.api.v1.endpoints.auth import fake_users_db
        from datetime import timedelta
        from src.core.config import settings

        # 사용자 인증
        user_data = fake_users_db.get(input.email)
        if not user_data or not verify_password(input.password, user_data["hashed_password"]):
            raise Exception("이메일 또는 비밀번호가 올바르지 않습니다")

        # 토큰 생성
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user_data["email"]},
            expires_delta=access_token_expires
        )

        user = User(
            id=user_data["id"],
            email=user_data["email"],
            username=user_data.get("username", user_data.get("name", "")),
            created_at=datetime.fromisoformat(user_data["created_at"]),
            is_active=user_data["is_active"]
        )

        return AuthPayload(
            access_token=access_token,
            user=user
        )


schema = strawberry.Schema(query=Query, mutation=Mutation)