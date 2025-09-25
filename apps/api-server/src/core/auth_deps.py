from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer
from sqlalchemy.orm import Session

from src.core.database import get_db
from src.modules.mgmt.auth.service import AuthService
from src.modules.mgmt.idam.session.model import Session as SessionModel

security = HTTPBearer()


async def get_current_session(
    token: str = Depends(security),
    db: Session = Depends(get_db),
) -> SessionModel:
    """현재 활성 세션 조회"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid authentication credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        # Bearer 토큰에서 세션 토큰 추출
        session_token = token.credentials

        # 세션 유효성 검증
        session = AuthService.validate_session_token(db, session_token)

        if session is None:
            raise credentials_exception

        return session

    except Exception:
        raise credentials_exception


async def get_optional_session(
    token: str | None = Depends(security),
    db: Session = Depends(get_db),
) -> SessionModel | None:
    """선택적 세션 조회 (인증이 필요 없는 경우)"""
    if not token:
        return None

    try:
        session_token = token.credentials
        return AuthService.validate_session_token(db, session_token)
    except Exception:
        return None
