from datetime import datetime, timedelta
import uuid
import secrets

from src.core.config import settings
from src.core.db import get_db
from src.core.security import create_access_token, get_password_hash, verify_password
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from src.models.user import User as UserModel, UserStatus
from src.schemas.user import Token, User, UserCreate, UserLogin
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

router = APIRouter(tags=["인증"], prefix="/auth")

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/login")

def get_user_by_email(db: Session, email: str):
    return db.query(UserModel).filter(UserModel.email == email).first()


def get_user_by_username(db: Session, username: str):
    return db.query(UserModel).filter(UserModel.username == username).first()


def create_user(db: Session, user_data: UserCreate):
    # Generate salt and hash password
    salt = secrets.token_hex(16)
    hashed_password = get_password_hash(user_data.password + salt)

    db_user = UserModel(
        username=user_data.username,
        email=user_data.email,
        full_name=user_data.full_name,
        password=hashed_password,
        salt_key=salt,
        phone=user_data.phone,
        department=user_data.department,
        position=user_data.position,
        status=UserStatus.ACTIVE,
        created_at=datetime.now(),
        password_changed_at=datetime.now()
    )

    try:
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user
    except IntegrityError:
        db.rollback()
        return None


def authenticate_user(username_or_email: str, password: str, db: Session, request: Request):
    # Try to find user by username or email
    user = get_user_by_username(db, username_or_email)
    if not user:
        user = get_user_by_email(db, username_or_email)

    if not user:
        return None

    # Check if account is locked
    if user.locked_until and user.locked_until > datetime.now():
        return None

    # Check if account is active
    if user.status != UserStatus.ACTIVE:
        return None

    # Verify password with salt
    if not verify_password(password + user.salt_key, user.password):
        # Increment failed login attempts
        user.failed_login_attempts += 1
        if user.failed_login_attempts >= 5:
            user.locked_until = datetime.now() + timedelta(minutes=30)
        db.commit()
        return None

    # Reset failed login attempts on successful login
    user.failed_login_attempts = 0
    user.last_login_at = datetime.now()
    user.last_login_ip = request.client.host if request.client else None
    user.locked_until = None
    db.commit()

    return user


@router.post("/login", response_model=Token, summary="로그인", description="사용자명 또는 이메일과 비밀번호로 로그인합니다.")
async def login(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    user = authenticate_user(form_data.username, form_data.password, db, request)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="사용자명/이메일 또는 비밀번호가 올바르지 않습니다",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email, "user_id": str(user.id)},
        expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/register", response_model=User, summary="회원가입", description="새 사용자 계정을 생성합니다.")
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    # Check if username already exists
    if get_user_by_username(db, user_data.username):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="이미 사용 중인 사용자명입니다"
        )

    # Check if email already exists
    if get_user_by_email(db, user_data.email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="이미 등록된 이메일입니다"
        )

    # Create new user
    db_user = create_user(db, user_data)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="사용자 생성에 실패했습니다"
        )

    # Return user without password
    return User(
        id=db_user.id,
        username=db_user.username,
        email=db_user.email,
        full_name=db_user.full_name,
        phone=db_user.phone,
        department=db_user.department,
        position=db_user.position,
        status=db_user.status,
        created_at=db_user.created_at,
        last_login_at=db_user.last_login_at
    )


@router.get("/me", response_model=User, summary="현재 사용자 정보", description="JWT 토큰을 사용하여 현재 로그인한 사용자의 정보를 조회합니다.")
async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    from src.core.security import verify_token

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="토큰을 검증할 수 없습니다",
        headers={"WWW-Authenticate": "Bearer"},
    )

    payload = verify_token(token)
    if payload is None:
        raise credentials_exception

    email: str = payload.get("sub")
    if email is None:
        raise credentials_exception

    user = get_user_by_email(db, email)
    if user is None or user.status != UserStatus.ACTIVE:
        raise credentials_exception

    return User(
        id=user.id,
        username=user.username,
        email=user.email,
        full_name=user.full_name,
        phone=user.phone,
        department=user.department,
        position=user.position,
        status=user.status,
        created_at=user.created_at,
        last_login_at=user.last_login_at
    )
