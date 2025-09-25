import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from src.core.database import get_db
from src.schemas.common.response import EnvelopeResponse

from .schemas import (
    AuthResponse,
    LoginRequest,
    LogoutRequest,
    SignupRequest,
    UserResponse,
)
from .service import AuthenticationService

# 로거 설정
logger = logging.getLogger(__name__)

# API 라우터 설정
router = APIRouter(tags=["관리자 - 인증"])


@router.post(
    "/signup",
    response_model=EnvelopeResponse[UserResponse],
    status_code=status.HTTP_201_CREATED,
    summary="통합 회원가입 (관리자/테넌트)",
)
async def signup(
    user_data: SignupRequest,
    db: Session = Depends(get_db),
):
    """
    **통합 회원가입 엔드포인트입니다.**

    `user_type` 값에 따라 관리자(MASTER) 또는 테넌트 사용자(TENANT) 계정을 생성합니다.

    - **성공 시**: `201 CREATED` 상태 코드와 함께 생성된 사용자 정보를 반환합니다.
    - **실패 시**: 이메일/사용자명 중복 시 `409 CONFLICT`, 잘못된 요청 시 `400 BAD REQUEST`,
      서버 오류 시 `500 INTERNAL_SERVER_ERROR` 상태 코드를 반환합니다.
    """
    logger.info(
        f"회원가입 요청 수신: {user_data.email} (유형: {user_data.user_type})"
    )
    try:
        user = AuthenticationService.signup(db, user_data)
        logger.info(f"회원가입 성공: {user.username} (ID: {user.id})")
        return EnvelopeResponse(success=True, data=user)
    except ValueError as e:
        logger.warning(f"회원가입 실패 (잘못된 값): {user_data.email} - {e}")
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail=str(e)
        )
    except Exception as e:
        logger.error(
            f"회원가입 중 예외 발생: {user_data.email} - {e}", exc_info=True
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="서버 내부 오류가 발생했습니다.",
        )


@router.post(
    "/login",
    response_model=EnvelopeResponse[AuthResponse],
    summary="사용자 로그인",
)
async def login(
    login_data: LoginRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    """
    **로그인 엔드포인트입니다.**

    사용자 자격 증명(아이디/비밀번호)을 확인하고, 성공 시 API 접근 토큰과 세션 토큰을 발급합니다.

    - **로그인 성공**: `200 OK` 상태 코드와 함께 인증 토큰 정보를 반환합니다.
    - **로그인 실패**:
        - 잘못된 자격 증명: `401 UNAUTHORIZED`
        - 계정 잠금: `423 LOCKED`
    """
    logger.info(f"로그인 요청 수신: {login_data.username}")
    try:
        auth_response = AuthenticationService.login(db, login_data, request)
        logger.info(f"로그인 성공: {login_data.username}")
        return EnvelopeResponse(success=True, data=auth_response)
    except ValueError as e:
        logger.warning(f"로그인 실패: {login_data.username} - {e}")
        # 실패 유형에 따라 다른 상태 코드 반환
        if "잠겨있습니다" in str(e):
            raise HTTPException(
                status_code=status.HTTP_423_LOCKED, detail=str(e)
            )
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e)
            )
    except Exception as e:
        logger.error(
            f"로그인 처리 중 예외 발생: {login_data.username} - {e}",
            exc_info=True,
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="로그인 처리 중 오류가 발생했습니다.",
        )


@router.post(
    "/logout", response_model=EnvelopeResponse[dict], summary="사용자 로그아웃"
)
async def logout(
    logout_data: LogoutRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    """
    **로그아웃 엔드포인트입니다.**

    클라이언트로부터 받은 세션 토큰을 무효화하여 사용자를 로그아웃 처리합니다.

    - **성공 시**: `200 OK`와 함께 성공 메시지를 반환합니다.
    - **실패 시**: 유효하지 않은 토큰일 경우 `401 UNAUTHORIZED`를 반환합니다.
    """
    logger.info(
        f"로그아웃 요청 수신: session_token={logout_data.session_token[:10]}..."
    )
    try:
        success = AuthenticationService.logout_user(db, logout_data, request)
        if success:
            logger.info(
                f"로그아웃 성공: session_token={logout_data.session_token[:10]}..."
            )
            return EnvelopeResponse(
                success=True, data={"message": "로그아웃되었습니다"}
            )
        else:
            logger.warning("로그아웃 실패: 유효하지 않은 세션 토큰")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="유효하지 않은 세션입니다.",
            )
    except Exception as e:
        logger.error(f"로그아웃 처리 중 예외 발생: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="로그아웃 처리 중 오류가 발생했습니다.",
        )
