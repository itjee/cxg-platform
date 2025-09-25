import logging

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from src.core.database import get_db
from src.schemas.common.response import EnvelopeResponse

from .schemas import (
    SessionFilterRequest,
    SessionListResponse,
    SessionRevokeRequest,
    SessionStatsResponse,
)
from .service import SessionService

router = APIRouter(prefix="/sessions", tags=["IDAM - 세션 관리"])
logger = logging.getLogger("sessions-router")


@router.get("/", response_model=EnvelopeResponse[SessionListResponse])
async def get_sessions(
    user_id: str | None = Query(None),
    username: str | None = Query(None),
    status: str | None = Query(None),
    ip_address: str | None = Query(None),
    start_date: str | None = Query(None),
    end_date: str | None = Query(None),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    """
    세션 목록 조회

    시스템의 모든 활성/비활성 세션을 조회합니다. 다양한 필터 조건과 페이지네이션을 지원합니다.

    **매개변수:**
    - **user_id**: 특정 사용자 ID로 필터링 (선택)
    - **username**: 사용자명으로 부분 검색 (선택)
    - **status**: 세션 상태로 필터링 (선택)
      - ACTIVE: 활성 세션
      - EXPIRED: 만료된 세션
      - REVOKED: 무효화된 세션
    - **ip_address**: IP 주소로 필터링 (부분 일치, 선택)
    - **start_date**: 시작 날짜 (ISO 8601 형식, 선택)
    - **end_date**: 종료 날짜 (ISO 8601 형식, 선택)
    - **page**: 페이지 번호 (기본값: 1, 최소: 1)
    - **size**: 페이지당 항목 수 (기본값: 20, 범위: 1-100)

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 페이지네이션된 세션 목록
      - items: 세션 정보 배열
      - total: 전체 세션 수
      - page: 현재 페이지
      - size: 페이지 크기
      - pages: 총 페이지 수
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 400: 잘못된 날짜 형식 또는 매개변수
    - 500: 서버 내부 오류
    """
    logger.info(f"[GET_SESSIONS] 요청: page={page}, size={size}")
    try:
        from datetime import datetime

        # 날짜 파싱
        parsed_start_date = None
        parsed_end_date = None

        if start_date:
            parsed_start_date = datetime.fromisoformat(
                start_date.replace("Z", "+00:00")
            )
        if end_date:
            parsed_end_date = datetime.fromisoformat(
                end_date.replace("Z", "+00:00")
            )

        filters = SessionFilterRequest(
            user_id=user_id,
            username=username,
            status=status,
            ip_address=ip_address,
            start_date=parsed_start_date,
            end_date=parsed_end_date,
            page=page,
            size=size,
        )

        result = SessionService.get_sessions(db, filters)
        logger.info(f"[GET_SESSIONS] 성공: {result.total}개 조회")
        return EnvelopeResponse(success=True, data=result, error=None)

    except Exception as e:
        logger.error(f"[GET_SESSIONS] 예외: {e}")
        return EnvelopeResponse(
            success=False, data=None, error={"message": str(e)}
        )


@router.get("/stats", response_model=EnvelopeResponse[SessionStatsResponse])
async def get_session_stats(
    db: Session = Depends(get_db),
):
    """
    세션 통계 조회

    현재 시스템의 세션 상태별 통계 정보를 제공합니다.

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 세션 통계 정보
      - active_sessions: 활성 세션 수
      - expired_sessions: 만료된 세션 수
      - revoked_sessions: 무효화된 세션 수
      - unique_users: 고유 사용자 수 (활성 세션 기준)
      - unique_ips: 고유 IP 주소 수 (활성 세션 기준)
      - mfa_verified_sessions: MFA 인증된 세션 수
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 500: 서버 내부 오류
    """
    logger.info("[GET_SESSION_STATS] 요청")
    try:
        stats = SessionService.get_session_stats(db)
        logger.info("[GET_SESSION_STATS] 성공")
        return EnvelopeResponse(success=True, data=stats, error=None)

    except Exception as e:
        logger.error(f"[GET_SESSION_STATS] 예외: {e}")
        return EnvelopeResponse(
            success=False, data=None, error={"message": str(e)}
        )


@router.post("/revoke", response_model=EnvelopeResponse[dict])
async def revoke_sessions(
    request: SessionRevokeRequest,
    db: Session = Depends(get_db),
):
    """
    세션 무효화

    지정된 세션들을 강제로 무효화합니다. 관리자가 보안상 위험한 세션을 종료할 때 사용합니다.

    **매개변수:**
    - **request**: 무효화 요청 정보
      - session_ids: 무효화할 세션 ID 배열

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 무효화 결과
      - revoked_count: 실제 무효화된 세션 수
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 400: 잘못된 요청 데이터
    - 500: 서버 내부 오류

    **주의사항:**
    - 이미 만료되거나 무효화된 세션은 카운트되지 않습니다
    - 활성 세션만 무효화됩니다
    """
    logger.info(f"[REVOKE_SESSIONS] 요청: {len(request.session_ids)}개 세션")
    try:
        revoked_count = SessionService.revoke_sessions(db, request.session_ids)
        logger.info(f"[REVOKE_SESSIONS] 성공: {revoked_count}개 무효화")
        return EnvelopeResponse(
            success=True,
            data={"revoked_count": revoked_count},
            error=None,
        )

    except Exception as e:
        logger.error(f"[REVOKE_SESSIONS] 예외: {e}")
        return EnvelopeResponse(
            success=False, data=None, error={"message": str(e)}
        )


@router.post("/cleanup", response_model=EnvelopeResponse[dict])
async def cleanup_expired_sessions(
    db: Session = Depends(get_db),
):
    """
    만료된 세션 정리

    시스템에서 만료된 세션들을 자동으로 정리합니다. 데이터베이스 용량 관리와 성능 최적화를 위해 사용됩니다.

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 정리 결과
      - cleaned_count: 정리된 세션 수
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 500: 서버 내부 오류

    **주의사항:**
    - 만료된 세션만 정리되며, 활성 세션은 영향받지 않습니다
    - 정리된 세션은 복구할 수 없습니다
    - 정기적인 유지보수 작업으로 실행하는 것을 권장합니다
    """
    logger.info("[CLEANUP_SESSIONS] 요청")
    try:
        cleaned_count = SessionService.cleanup_expired_sessions(db)
        logger.info(f"[CLEANUP_SESSIONS] 성공: {cleaned_count}개 정리")
        return EnvelopeResponse(
            success=True,
            data={"cleaned_count": cleaned_count},
            error=None,
        )

    except Exception as e:
        logger.error(f"[CLEANUP_SESSIONS] 예외: {e}")
        return EnvelopeResponse(
            success=False, data=None, error={"message": str(e)}
        )
