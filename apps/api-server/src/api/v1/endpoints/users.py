import uuid
from typing import List

from src.core.db import get_db
from src.core.security import get_password_hash
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from src.models.user import User as UserModel
from src.schemas.user import User, UserCreate, UserUpdate
from sqlalchemy.orm import Session

router = APIRouter(tags=["사용자 관리"], prefix="/users")

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/login")

# 임시 사용자 데이터 (실제로는 데이터베이스에서 가져와야 함)
fake_users_db = {
    "1": {
        "id": "1",
        "email": "admin@example.com",
        "name": "관리자",
        "role": "admin",
        "status": "active",
        "organization": "CXG Platform",
        "last_login": "2024-01-15T10:30:00",
        "created_at": "2024-01-01T00:00:00",
        "updated_at": "2024-01-01T00:00:00",
    },
    "2": {
        "id": "2",
        "email": "manager@example.com",
        "name": "매니저",
        "role": "manager",
        "status": "active",
        "organization": "Test Corp",
        "last_login": "2024-01-14T15:20:00",
        "created_at": "2024-01-02T00:00:00",
        "updated_at": "2024-01-02T00:00:00",
    },
    "3": {
        "id": "3",
        "email": "user@example.com",
        "name": "일반 사용자",
        "role": "user",
        "status": "pending",
        "organization": "Another Corp",
        "last_login": None,
        "created_at": "2024-01-03T00:00:00",
        "updated_at": "2024-01-03T00:00:00",
    },
}


async def get_current_user(token: str = Depends(oauth2_scheme)):
    # 토큰 검증 로직 (간단화)
    return {"email": "admin@example.com", "role": "admin"}


@router.get("/", response_model=List[User])
async def get_users(
    current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)
):
    users = db.query(UserModel).all()
    return users


@router.get("/{user_id}", response_model=User)
async def get_user(user_id: str, current_user: dict = Depends(get_current_user)):
    if user_id not in fake_users_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="사용자를 찾을 수 없습니다"
        )
    return User(**fake_users_db[user_id])


@router.post("/", response_model=User)
async def create_user(
    user_data: UserCreate, current_user: dict = Depends(get_current_user)
):
    # 이메일 중복 체크
    for user in fake_users_db.values():
        if user["email"] == user_data.email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미 등록된 이메일입니다",
            )

    # 새 사용자 생성
    user_id = str(uuid.uuid4())
    new_user = {
        "id": user_id,
        "email": user_data.email,
        "name": user_data.name,
        "role": user_data.role,
        "status": user_data.status,
        "organization": user_data.organization,
        "last_login": None,
        "created_at": "2024-01-01T00:00:00",
        "updated_at": "2024-01-01T00:00:00",
    }

    fake_users_db[user_id] = new_user
    return User(**new_user)


@router.put("/{user_id}", response_model=User)
async def update_user(
    user_id: str, user_data: UserUpdate, current_user: dict = Depends(get_current_user)
):
    if user_id not in fake_users_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="사용자를 찾을 수 없습니다"
        )

    user = fake_users_db[user_id]
    update_data = user_data.model_dump(exclude_unset=True)

    for field, value in update_data.items():
        if value is not None:
            user[field] = value

    user["updated_at"] = "2024-01-01T00:00:00"  # 실제로는 현재 시간

    return User(**user)


@router.delete("/{user_id}")
async def delete_user(user_id: str, current_user: dict = Depends(get_current_user)):
    if user_id not in fake_users_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="사용자를 찾을 수 없습니다"
        )

    del fake_users_db[user_id]
    return {"message": "사용자가 삭제되었습니다"}
