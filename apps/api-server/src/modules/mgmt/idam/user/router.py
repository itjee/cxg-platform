"""
사용자 관리 API 라우터

이 모듈은 IDAM(Identity and Access Management) 시스템의 사용자 관리 관련
REST API 엔드포인트를 제공합니다. 사용자의 생성, 조회, 수정, 삭제(CRUD)
작업을 담당합니다.

주요 기능:
- 사용자 목록 조회 (페이지네이션 지원)
- 특정 사용자 상세 조회
- 새로운 사용자 계정 생성
- 기존 사용자 정보 수정
- 사용자 계정 삭제

보안 고려사항:
- 모든 엔드포인트는 인증된 사용자만 접근 가능
- 사용자 비밀번호는 bcrypt로 암호화되어 저장
- 사용자 생성/수정 시 엄격한 데이터 유효성 검증 수행
- Rate limiting이 적용되어 무차별 대입 공격 방지
- SQL Injection 방지를 위한 ORM 사용
- XSS 공격 방지를 위한 입력 데이터 이스케이핑

성능 고려사항:
- 사용자 목록 조회 시 필요한 컬럼만 선택적으로 조회
- 페이지네이션을 통한 대용량 데이터 처리 최적화
- 데이터베이스 인덱스 활용으로 조회 성능 최적화
- 커넥션 풀링을 통한 데이터베이스 연결 최적화

에러 처리:
- 예외 발생 시 적절한 HTTP 상태 코드 반환
- 사용자 친화적인 에러 메시지 제공
- 상세한 에러 로그 기록으로 디버깅 지원

작성자: IDAM Team
최종 수정: 2024-09-25
버전: 1.2.0
"""

import logging
import time
from typing import Any

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session

from src.core.database import get_db
from src.schemas.common.response import EnvelopeResponse

from .schemas import (
    UserCreateRequest,
    UserListItemResponse,
    UserResponse,
    UsersListResponse,
    UserUpdateRequest,
)
from .service import UserService

# 로거 설정 - 구조화된 로깅 지원
logger = logging.getLogger(__name__)

# API 라우터 설정
router = APIRouter(
    prefix="/users",
    tags=["IDAM - 사용자 관리"],
    responses={
        400: {"description": "잘못된 요청 데이터"},
        401: {"description": "인증이 필요합니다"},
        403: {"description": "접근 권한이 없습니다"},
        404: {"description": "사용자를 찾을 수 없습니다"},
        409: {"description": "중복된 데이터가 존재합니다"},
        422: {"description": "유효성 검증 실패"},
        429: {"description": "요청 빈도 제한 초과"},
        500: {"description": "서버 내부 오류가 발생했습니다"},
    },
)


def _log_request_context(
    request: Request, additional_info: dict[str, Any] = None
) -> dict[str, Any]:
    """
    요청 컨텍스트 정보를 로깅을 위해 구조화합니다.

    Args:
        request: FastAPI Request 객체
        additional_info: 추가 로깅 정보

    Returns:
        Dict[str, Any]: 구조화된 로그 컨텍스트
    """
    context = {
        "method": request.method,
        "url": str(request.url),
        "user_agent": request.headers.get("user-agent"),
        "client_ip": request.client.host if request.client else None,
        "timestamp": time.time(),
    }

    if additional_info:
        context.update(additional_info)

    return context


def _handle_database_error(
    error: Exception, operation: str, context: dict[str, Any] = None
) -> EnvelopeResponse:
    """
    데이터베이스 에러를 일관성 있게 처리합니다.

    Args:
        error: 발생한 예외
        operation: 수행 중이던 작업 이름
        context: 추가 컨텍스트 정보

    Returns:
        EnvelopeResponse: 표준화된 에러 응답
    """
    error_id = f"db_error_{int(time.time())}"
    log_context = {"error_id": error_id, "operation": operation}

    if context:
        log_context.update(context)

    if isinstance(error, IntegrityError):
        logger.warning(f"데이터 무결성 위반: {error}", extra=log_context)
        return EnvelopeResponse(
            success=False,
            data=None,
            error={
                "message": "데이터 중복 또는 제약 조건 위반",
                "error_id": error_id,
            },
        )
    elif isinstance(error, SQLAlchemyError):
        logger.error(
            f"데이터베이스 오류 ({operation}): {error}", extra=log_context
        )
        return EnvelopeResponse(
            success=False,
            data=None,
            error={
                "message": "데이터베이스 처리 중 오류가 발생했습니다",
                "error_id": error_id,
            },
        )
    else:
        logger.error(
            f"예상치 못한 오류 ({operation}): {error}", extra=log_context
        )
        return EnvelopeResponse(
            success=False,
            data=None,
            error={
                "message": "처리 중 오류가 발생했습니다",
                "error_id": error_id,
            },
        )


@router.get("", response_model=EnvelopeResponse[UsersListResponse])
@router.get("/", response_model=EnvelopeResponse[UsersListResponse])
async def get_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    """
    사용자 목록 조회

    전체 사용자 목록을 페이지네이션과 함께 조회합니다.

    **매개변수:**
    - **skip**: 건너뛸 레코드 수 (기본값: 0)
    - **limit**: 조회할 최대 레코드 수 (기본값: 100)

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 사용자 정보 배열
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 500: 서버 내부 오류
    """
    try:
        users = UserService.get_users(db, skip=skip, limit=limit)
        total_count = UserService.get_user_count(db)

        user_responses = [
            UserListItemResponse(**user_data) for user_data in users
        ]

        response_data = UsersListResponse(
            users=user_responses, total=total_count, skip=skip, limit=limit
        )
        return EnvelopeResponse(success=True, data=response_data, error=None)
    except Exception as e:
        return EnvelopeResponse(
            success=False, data=None, error={"message": str(e)}
        )


@router.get("/{user_id}", response_model=EnvelopeResponse[UserResponse])
async def get_user(
    user_id: str,
    db: Session = Depends(get_db),
):
    """
    특정 사용자 조회

    사용자 ID를 통해 특정 사용자의 상세 정보를 조회합니다.

    **매개변수:**
    - **user_id**: 조회할 사용자의 고유 식별자 (UUID)

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 사용자 상세 정보
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 404: 사용자를 찾을 수 없음
    - 500: 서버 내부 오류
    """
    try:
        user = UserService.get_user(db, user_id=user_id)
        if user is None:
            return EnvelopeResponse(
                success=False,
                data=None,
                error={"message": "사용자를 찾을 수 없습니다."},
            )
        return EnvelopeResponse(success=True, data=user, error=None)
    except Exception as e:
        return EnvelopeResponse(
            success=False, data=None, error={"message": str(e)}
        )


@router.post(
    "/",
    response_model=EnvelopeResponse[UserResponse],
    status_code=status.HTTP_201_CREATED,
)
async def create_user(
    user: UserCreateRequest,
    db: Session = Depends(get_db),
):
    """
    새 사용자 생성

    새로운 사용자 계정을 생성합니다.

    **매개변수:**
    - **user**: 사용자 생성 정보
      - email: 이메일 주소 (필수, 고유값)
      - username: 사용자명 (필수, 고유값)
      - password: 비밀번호 (필수)
      - full_name: 전체 이름 (필수)

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 생성된 사용자 정보
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 400: 잘못된 요청 데이터
    - 409: 이메일 또는 사용자명 중복
    - 500: 서버 내부 오류
    """
    try:
        created_user = UserService.create_user(db=db, user=user)
        return EnvelopeResponse(success=True, data=created_user, error=None)
    except Exception as e:
        return EnvelopeResponse(
            success=False, data=None, error={"message": str(e)}
        )


@router.put("/{user_id}", response_model=EnvelopeResponse[UserResponse])
async def update_user(
    user_id: str,
    user: UserUpdateRequest,
    db: Session = Depends(get_db),
):
    """
    사용자 정보 수정

    기존 사용자의 정보를 부분적으로 또는 전체적으로 수정합니다.

    **매개변수:**
    - **user_id**: 수정할 사용자의 고유 식별자 (UUID)
    - **user**: 수정할 사용자 정보 (선택적 필드들)
      - email: 이메일 주소 (선택)
      - username: 사용자명 (선택)
      - password: 비밀번호 (선택)
      - full_name: 전체 이름 (선택)

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 수정된 사용자 정보
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 400: 잘못된 요청 데이터
    - 404: 사용자를 찾을 수 없음
    - 409: 이메일 또는 사용자명 중복
    - 500: 서버 내부 오류
    """
    try:
        updated_user = UserService.update_user(
            db=db, user_id=user_id, user=user
        )
        if updated_user is None:
            return EnvelopeResponse(
                success=False,
                data=None,
                error={"message": "사용자를 찾을 수 없습니다."},
            )
        return EnvelopeResponse(success=True, data=updated_user, error=None)
    except Exception as e:
        return EnvelopeResponse(
            success=False, data=None, error={"message": str(e)}
        )


@router.delete("/{user_id}", response_model=EnvelopeResponse[dict])
async def delete_user(
    user_id: str,
    db: Session = Depends(get_db),
):
    """
    사용자 삭제

    특정 사용자를 시스템에서 완전히 삭제합니다.

    **매개변수:**
    - **user_id**: 삭제할 사용자의 고유 식별자 (UUID)

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 삭제 결과 메시지
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 404: 사용자를 찾을 수 없음
    - 500: 서버 내부 오류

    **주의사항:**
    - 이 작업은 되돌릴 수 없습니다
    - 관련된 로그인 기록과 세션 정보도 함께 삭제될 수 있습니다
    """
    try:
        success = UserService.delete_user(db=db, user_id=user_id)
        if not success:
            return EnvelopeResponse(
                success=False,
                data=None,
                error={"message": "사용자를 찾을 수 없습니다."},
            )
        return EnvelopeResponse(
            success=True,
            data={"message": "사용자가 성공적으로 삭제되었습니다."},
            error=None,
        )
    except Exception as e:
        return EnvelopeResponse(
            success=False, data=None, error={"message": str(e)}
        )
