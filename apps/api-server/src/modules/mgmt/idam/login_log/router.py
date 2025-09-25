import logging

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from src.core.database import get_db
from src.schemas.common.response import EnvelopeResponse

from .schemas import LoginLogFilterRequest, LoginLogListResponse
from .service import LoginLogService

router = APIRouter(prefix="/login-logs", tags=["IDAM - 로그인 로그 관리"])
logger = logging.getLogger("login-logs-router")


@router.get("/", response_model=EnvelopeResponse[LoginLogListResponse])
async def get_login_logs(
    user_id: str | None = Query(None),
    username: str | None = Query(None),
    attempt_type: str | None = Query(None),
    success: bool | None = Query(None),
    ip_address: str | None = Query(None),
    start_date: str | None = Query(None),
    end_date: str | None = Query(None),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    """
    로그인 로그 목록 조회

    시스템의 모든 로그인 시도 기록을 조회합니다. 다양한 필터 조건과 페이지네이션을 지원합니다.

    **매개변수:**
    - **user_id**: 특정 사용자 ID로 필터링 (선택)
    - **username**: 사용자명으로 부분 검색 (선택)
    - **attempt_type**: 로그인 시도 유형 필터링 (선택)
      - LOGIN: 일반 로그인
      - LOGOUT: 로그아웃
      - FAILED_LOGIN: 실패한 로그인
    - **success**: 성공/실패 여부로 필터링 (선택)
      - true: 성공한 시도만
      - false: 실패한 시도만
    - **ip_address**: IP 주소로 필터링 (부분 일치, 선택)
    - **start_date**: 시작 날짜 (ISO 8601 형식, 선택)
    - **end_date**: 종료 날짜 (ISO 8601 형식, 선택)
    - **page**: 페이지 번호 (기본값: 1, 최소: 1)
    - **size**: 페이지당 항목 수 (기본값: 20, 범위: 1-100)

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 페이지네이션된 로그인 로그 목록
      - items: 로그인 로그 배열
      - total: 전체 로그 수
      - page: 현재 페이지
      - size: 페이지 크기
      - pages: 총 페이지 수
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 400: 잘못된 날짜 형식 또는 매개변수
    - 500: 서버 내부 오류
    """
    logger.info(f"[GET_LOGIN_LOGS] 요청: page={page}, size={size}")
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

        filters = LoginLogFilterRequest(
            user_id=user_id,
            username=username,
            attempt_type=attempt_type,
            success=success,
            ip_address=ip_address,
            start_date=parsed_start_date,
            end_date=parsed_end_date,
            page=page,
            size=size,
        )

        result = LoginLogService.get_login_logs(db, filters)
        logger.info(f"[GET_LOGIN_LOGS] 성공: {result.total}개 조회")
        return EnvelopeResponse(success=True, data=result, error=None)

    except Exception as e:
        logger.error(f"[GET_LOGIN_LOGS] 예외: {e}")
        return EnvelopeResponse(
            success=False, data=None, error={"message": str(e)}
        )


@router.get("/stats", response_model=EnvelopeResponse[dict])
async def get_login_stats(
    days: int = Query(7, ge=1, le=90),
    db: Session = Depends(get_db),
):
    """
    로그인 통계 조회

    지정된 기간 동안의 로그인 시도에 대한 통계 정보를 제공합니다.

    **매개변수:**
    - **days**: 통계 조회 기간 (일 단위, 기본값: 7, 범위: 1-90)

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 로그인 통계 정보
      - period_days: 조회 기간 (일)
      - total_attempts: 총 로그인 시도 수
      - successful_logins: 성공한 로그인 수
      - failed_logins: 실패한 로그인 수
      - unique_users: 고유 사용자 수
      - unique_ips: 고유 IP 주소 수
      - success_rate: 성공률 (백분율)
      - failure_reasons: 실패 사유별 통계
        - {실패_사유}: 발생 횟수
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 400: 잘못된 기간 설정
    - 500: 서버 내부 오류

    **사용 예시:**
    - 최근 7일 통계: `GET /stats`
    - 최근 30일 통계: `GET /stats?days=30`
    """
    logger.info(f"[GET_LOGIN_STATS] 요청: days={days}")
    try:
        stats = LoginLogService.get_login_stats(db, days)
        logger.info("[GET_LOGIN_STATS] 성공")
        return EnvelopeResponse(success=True, data=stats, error=None)

    except Exception as e:
        logger.error(f"[GET_LOGIN_STATS] 예외: {e}")
        return EnvelopeResponse(
            success=False, data=None, error={"message": str(e)}
        )
