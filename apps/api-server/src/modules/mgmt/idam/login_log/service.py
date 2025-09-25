import logging
from datetime import datetime

from sqlalchemy import and_, desc, func
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from .model import LoginLog as LoginLogModel
from .schemas import (
    LoginLogCreate,
    LoginLogFilterRequest,
    LoginLogListResponse,
    LoginLogResponse,
    LoginLogUpdate,
)

logger = logging.getLogger(__name__)


class LoginLogService:
    """로그인 로그 관련 비즈니스 로직을 처리하는 서비스"""

    @staticmethod
    def get_login_logs(  # noqa: C901
        db: Session,
        filters: LoginLogFilterRequest,
    ) -> LoginLogListResponse:
        """로그인 로그 목록을 조회합니다.

        Args:
            db (Session): 데이터베이스 세션.
            filters (LoginLogFilterRequest): 로그인 로그 필터링을 위한 요청 객체.

        Returns:
            LoginLogListResponse: 필터링된 로그인 로그 목록과 페이징 정보를 포함하는 응답 객체.
        """
        logger.info(f"[get_login_logs] 로그인 로그 조회 시작. 필터: {filters}")
        try:
            # Construct the base query with all columns from LoginLog
            query = db.query(
                LoginLogModel.id,
                func.timezone(
                    "Asia/Seoul",
                    func.timezone("UTC", LoginLogModel.created_at),
                ).label("created_at"),
                func.timezone(
                    "Asia/Seoul",
                    func.timezone("UTC", LoginLogModel.updated_at),
                ).label("updated_at"),
                LoginLogModel.created_by,
                LoginLogModel.updated_by,
                LoginLogModel.user_id,
                LoginLogModel.user_type,
                LoginLogModel.tenant_context,
                LoginLogModel.username,
                LoginLogModel.attempt_type,
                LoginLogModel.success,
                LoginLogModel.failure_reason,
                LoginLogModel.session_id,
                LoginLogModel.ip_address,
                LoginLogModel.user_agent,
                LoginLogModel.country_code,
                LoginLogModel.city,
                LoginLogModel.mfa_used,
                LoginLogModel.mfa_method,
            )

            # 필터 적용
            conditions = []

            if filters.user_id:
                conditions.append(LoginLogModel.user_id == filters.user_id)

            if filters.username:
                conditions.append(
                    LoginLogModel.username.ilike(f"%{filters.username}%")
                )

            if filters.attempt_type:
                conditions.append(
                    LoginLogModel.attempt_type == filters.attempt_type
                )

            if filters.success is not None:
                conditions.append(LoginLogModel.success == filters.success)

            if filters.ip_address:
                conditions.append(
                    LoginLogModel.ip_address.like(f"{filters.ip_address}%")
                )

            if filters.start_date:
                conditions.append(
                    LoginLogModel.created_at >= filters.start_date
                )

            if filters.end_date:
                conditions.append(LoginLogModel.created_at <= filters.end_date)

            if conditions:
                query = query.filter(and_(*conditions))

            # 전체 개수 조회
            # When using labels, query.count() does not work as expected.
            # We need a separate query for counting.
            count_query = db.query(func.count(LoginLogModel.id))
            if conditions:
                count_query = count_query.filter(and_(*conditions))
            total = count_query.scalar()
            logger.info(f"[get_login_logs] 총 {total}개의 로그인 로그 발견.")

            # 페이징 적용
            offset = (filters.page - 1) * filters.size
            items_query = (
                query.order_by(desc(LoginLogModel.created_at))
                .offset(offset)
                .limit(filters.size)
            )

            items = items_query.all()

            # 응답 데이터 생성
            login_logs = []
            for item in items:
                login_logs.append(
                    LoginLogResponse(
                        id=item.id,
                        created_at=item.created_at,
                        updated_at=item.updated_at,
                        created_by=item.created_by,
                        updated_by=item.updated_by,
                        user_id=item.user_id,
                        user_type=item.user_type,
                        tenant_context=item.tenant_context,
                        username=item.username,
                        attempt_type=item.attempt_type,
                        success=item.success,
                        failure_reason=item.failure_reason,
                        session_id=item.session_id,
                        ip_address=str(item.ip_address),
                        user_agent=item.user_agent,
                        country_code=item.country_code,
                        city=item.city,
                        mfa_used=item.mfa_used,
                        mfa_method=item.mfa_method,
                    )
                )

            pages = (total + filters.size - 1) // filters.size
            logger.info(
                f"[get_login_logs] 로그인 로그 조회 성공. {len(login_logs)}개 반환."
            )
            return LoginLogListResponse(
                items=login_logs,
                total=total,
                page=filters.page,
                size=filters.size,
                pages=pages,
            )
        except Exception as e:
            logger.error(
                f"[get_login_logs] 로그인 로그 조회 중 오류 발생: {e}",
                exc_info=True,
            )
            raise

    @staticmethod
    def get_login_stats(db: Session, days: int = 7) -> dict:
        """지정된 기간 동안의 로그인 통계를 조회합니다.

        Args:
            db (Session): 데이터베이스 세션.
            days (int, optional): 통계를 조회할 기간 (일 단위). 기본값은 7일.

        Returns:
            dict: 로그인 통계 데이터.
        """
        logger.info(f"[get_login_stats] 로그인 통계 조회 시작. 기간: {days}일")
        try:
            from datetime import timedelta

            start_date = datetime.now() - timedelta(days=days)

            # 총 로그인 시도 수
            total_attempts = (
                db.query(func.count(LoginLogModel.id))
                .filter(LoginLogModel.created_at >= start_date)
                .scalar()
            )

            # 성공한 로그인 수
            successful_logins = (
                db.query(func.count(LoginLogModel.id))
                .filter(
                    LoginLogModel.created_at >= start_date,
                    LoginLogModel.success == True,  # noqa: E712
                    LoginLogModel.attempt_type == "LOGIN",
                )
                .scalar()
            )

            # 실패한 로그인 수
            failed_logins = (
                db.query(func.count(LoginLogModel.id))
                .filter(
                    LoginLogModel.created_at >= start_date,
                    LoginLogModel.success == False,  # noqa: E712
                    LoginLogModel.attempt_type == "LOGIN",
                )
                .scalar()
            )

            # 고유 사용자 수
            unique_users = (
                db.query(func.count(func.distinct(LoginLogModel.user_id)))
                .filter(
                    LoginLogModel.created_at >= start_date,
                    LoginLogModel.success == True,  # noqa: E712
                    LoginLogModel.attempt_type == "LOGIN",
                )
                .scalar()
            )

            # 고유 IP 수
            unique_ips = (
                db.query(func.count(func.distinct(LoginLogModel.ip_address)))
                .filter(LoginLogModel.created_at >= start_date)
                .scalar()
            )

            # 실패 사유별 통계
            failure_reasons = (
                db.query(
                    LoginLogModel.failure_reason, func.count(LoginLogModel.id)
                )
                .filter(
                    LoginLogModel.created_at >= start_date,
                    LoginLogModel.success == False,  # noqa: E712
                    LoginLogModel.failure_reason.isnot(None),
                )
                .group_by(LoginLogModel.failure_reason)
                .all()
            )

            stats = {
                "period_days": days,
                "total_attempts": total_attempts or 0,
                "successful_logins": successful_logins or 0,
                "failed_logins": failed_logins or 0,
                "unique_users": unique_users or 0,
                "unique_ips": unique_ips or 0,
                "success_rate": (
                    (successful_logins / total_attempts * 100)
                    if total_attempts > 0
                    else 0
                ),
                "failure_reasons": {
                    reason: count for reason, count in failure_reasons
                },
            }
            logger.info(
                f"[get_login_stats] 로그인 통계 조회 성공. 통계: {stats}"
            )
            return stats
        except Exception as e:
            logger.error(
                f"[get_login_stats] 로그인 통계 조회 중 오류 발생: {e}",
                exc_info=True,
            )
            raise

    @staticmethod
    def get_login_logs_list(
        db: Session, skip: int = 0, limit: int = 100
    ) -> list[LoginLogModel]:
        """
        로그인 로그 목록을 조회합니다.
        """
        try:
            login_logs = (
                db.query(LoginLogModel).offset(skip).limit(limit).all()
            )
            return login_logs
        except SQLAlchemyError as e:
            logger.error(f"로그인 로그 목록 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def get_login_log_by_id(
        db: Session, login_log_id: str
    ) -> LoginLogModel | None:
        """
        ID로 특정 로그인 로그를 조회합니다.
        """
        try:
            login_log = (
                db.query(LoginLogModel)
                .filter(LoginLogModel.id == login_log_id)
                .first()
            )
            return login_log
        except SQLAlchemyError as e:
            logger.error(f"로그인 로그 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def create_login_log(
        db: Session, login_log_data: LoginLogCreate
    ) -> LoginLogModel:
        """
        새로운 로그인 로그를 생성합니다.
        """
        try:
            db_login_log = LoginLogModel(
                user_id=login_log_data.user_id,
                user_type=login_log_data.user_type,
                tenant_context=login_log_data.tenant_context,
                username=login_log_data.username,
                attempt_type=login_log_data.attempt_type,
                success=login_log_data.success,
                failure_reason=login_log_data.failure_reason,
                session_id=login_log_data.session_id,
                ip_address=login_log_data.ip_address,
                user_agent=login_log_data.user_agent,
                country_code=login_log_data.country_code,
                city=login_log_data.city,
                mfa_used=login_log_data.mfa_used,
                mfa_method=login_log_data.mfa_method,
            )
            db.add(db_login_log)
            db.commit()
            db.refresh(db_login_log)
            return db_login_log
        except SQLAlchemyError as e:
            logger.error(f"로그인 로그 생성 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def update_login_log(
        db: Session,
        login_log_id: str,
        login_log_data: LoginLogUpdate,
    ) -> LoginLogModel | None:
        """
        로그인 로그 정보를 수정합니다.
        """
        try:
            db_login_log = (
                db.query(LoginLogModel)
                .filter(LoginLogModel.id == login_log_id)
                .first()
            )
            if not db_login_log:
                return None

            update_data = login_log_data.model_dump(exclude_unset=True)
            for field, value in update_data.items():
                setattr(db_login_log, field, value)

            db.commit()
            db.refresh(db_login_log)
            return db_login_log
        except SQLAlchemyError as e:
            logger.error(f"로그인 로그 수정 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def delete_login_log(db: Session, login_log_id: str) -> bool:
        """
        로그인 로그를 삭제합니다.
        """
        try:
            db_login_log = (
                db.query(LoginLogModel)
                .filter(LoginLogModel.id == login_log_id)
                .first()
            )
            if not db_login_log:
                return False

            db.delete(db_login_log)
            db.commit()
            return True
        except SQLAlchemyError as e:
            logger.error(f"로그인 로그 삭제 중 데이터베이스 에러: {e}")
            db.rollback()
            raise
