import logging
from datetime import datetime

from sqlalchemy import and_, desc, func
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from ..user.model import User
from .model import Session as SessionModel
from .schemas import (
    SessionCreate,
    SessionCreateRequest,
    SessionFilterRequest,
    SessionListResponse,
    SessionResponse,
    SessionStatsResponse,
    SessionUpdate,
    SessionUpdateRequest,
)

# 로거 초기화
logger = logging.getLogger(__name__)


class SessionService:
    """세션 관련 비즈니스 로직을 처리하는 서비스"""

    @staticmethod
    def get_sessions(
        db: Session,
        filters: SessionFilterRequest,
    ) -> SessionListResponse:
        """세션 목록 조회"""
        try:
            query = db.query(SessionModel)

            # 필터 적용
            conditions = []

            if filters.user_id:
                conditions.append(SessionModel.user_id == filters.user_id)

            if filters.username:
                # 서브쿼리를 사용하여 사용자명으로 필터링
                user_subquery = (
                    db.query(User.id)
                    .filter(User.username.ilike(f"%{filters.username}%"))
                    .subquery()
                )
                conditions.append(
                    SessionModel.user_id.in_(db.query(user_subquery.c.id))
                )

            if filters.status:
                conditions.append(SessionModel.status == filters.status)

            if filters.ip_address:
                conditions.append(
                    SessionModel.ip_address.like(f"{filters.ip_address}%")
                )

            if filters.start_date:
                conditions.append(
                    SessionModel.created_at >= filters.start_date
                )

            if filters.end_date:
                conditions.append(SessionModel.created_at <= filters.end_date)

            if conditions:
                query = query.filter(and_(*conditions))

            # 전체 개수 조회
            total = query.count()

            # 페이징 적용
            offset = (filters.page - 1) * filters.size
            items_query = (
                query.order_by(desc(SessionModel.last_activity_at))
                .offset(offset)
                .limit(filters.size)
            )

            items = items_query.all()

            # 응답 데이터 생성
            sessions = []
            for session in items:
                # User 정보 조회
                user = (
                    db.query(User).filter(User.id == session.user_id).first()
                )

                sessions.append(
                    SessionResponse(
                        id=session.id,
                        created_at=session.created_at,
                        updated_at=session.updated_at,
                        created_by=session.created_by,
                        updated_by=session.updated_by,
                        session_id=(
                            session.session_id[:20] + "..."
                            if session.session_id
                            and len(session.session_id) > 20
                            else session.session_id
                        ),
                        user_id=session.user_id,
                        fingerprint=session.fingerprint,
                        user_agent=session.user_agent,
                        ip_address=str(session.ip_address),
                        country_code=session.country_code,
                        city=session.city,
                        status=session.status,
                        expires_at=session.expires_at,
                        last_activity_at=session.last_activity_at,
                        mfa_verified=session.mfa_verified,
                        mfa_verified_at=session.mfa_verified_at,
                        username=user.username if user else None,
                        email=user.email if user else None,
                        full_name=user.full_name if user else None,
                    )
                )

            pages = (total + filters.size - 1) // filters.size

            return SessionListResponse(
                items=sessions,
                total=total,
                page=filters.page,
                size=filters.size,
                pages=pages,
            )
        except SQLAlchemyError as e:
            logger.error(f"세션 목록 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def get_session_by_id(db: Session, session_id: str) -> SessionModel | None:
        """
        ID로 특정 세션을 조회합니다.
        """
        try:
            session = (
                db.query(SessionModel)
                .filter(SessionModel.id == session_id)
                .first()
            )
            return session
        except SQLAlchemyError as e:
            logger.error(f"세션 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def create_session(
        db: Session, session_data: SessionCreate | SessionCreateRequest
    ) -> SessionModel:
        """
        새로운 세션을 생성합니다.
        """
        try:
            db_session = SessionModel(
                session_id=session_data.session_id,
                user_id=session_data.user_id,
                fingerprint=session_data.fingerprint,
                user_agent=session_data.user_agent,
                ip_address=session_data.ip_address,
                country_code=session_data.country_code,
                city=session_data.city,
                status=session_data.status,
                expires_at=session_data.expires_at,
                last_activity_at=session_data.last_activity_at,
                mfa_verified=session_data.mfa_verified,
                mfa_verified_at=session_data.mfa_verified_at,
            )
            db.add(db_session)
            db.commit()
            db.refresh(db_session)
            return db_session
        except SQLAlchemyError as e:
            logger.error(f"세션 생성 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def update_session(
        db: Session,
        session_id: str,
        session_data: SessionUpdate | SessionUpdateRequest,
    ) -> SessionModel | None:
        """
        세션 정보를 수정합니다.
        """
        try:
            db_session = (
                db.query(SessionModel)
                .filter(SessionModel.id == session_id)
                .first()
            )
            if not db_session:
                return None

            update_data = session_data.model_dump(exclude_unset=True)
            for field, value in update_data.items():
                setattr(db_session, field, value)

            db.commit()
            db.refresh(db_session)
            return db_session
        except SQLAlchemyError as e:
            logger.error(f"세션 수정 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def delete_session(db: Session, session_id: str) -> bool:
        """
        세션을 삭제합니다.
        """
        try:
            db_session = (
                db.query(SessionModel)
                .filter(SessionModel.id == session_id)
                .first()
            )
            if not db_session:
                return False

            db.delete(db_session)
            db.commit()
            return True
        except SQLAlchemyError as e:
            logger.error(f"세션 삭제 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def get_session_stats(db: Session) -> SessionStatsResponse:
        """세션 통계 조회"""
        try:
            # 활성 세션 수
            active_sessions = (
                db.query(func.count(SessionModel.id))
                .filter(SessionModel.status == "ACTIVE")
                .scalar()
            )

            # 만료된 세션 수
            expired_sessions = (
                db.query(func.count(SessionModel.id))
                .filter(SessionModel.status == "EXPIRED")
                .scalar()
            )

            # 무효화된 세션 수
            revoked_sessions = (
                db.query(func.count(SessionModel.id))
                .filter(SessionModel.status == "REVOKED")
                .scalar()
            )

            # 고유 사용자 수 (활성 세션 기준)
            unique_users = (
                db.query(func.count(func.distinct(SessionModel.user_id)))
                .filter(SessionModel.status == "ACTIVE")
                .scalar()
            )

            # 고유 IP 수 (활성 세션 기준)
            unique_ips = (
                db.query(func.count(func.distinct(SessionModel.ip_address)))
                .filter(SessionModel.status == "ACTIVE")
                .scalar()
            )

            # MFA 인증된 세션 수
            mfa_verified_sessions = (
                db.query(func.count(SessionModel.id))
                .filter(
                    SessionModel.status == "ACTIVE",
                    SessionModel.mfa_verified == True,  # noqa: E712
                )
                .scalar()
            )

            return SessionStatsResponse(
                active_sessions=active_sessions or 0,
                expired_sessions=expired_sessions or 0,
                revoked_sessions=revoked_sessions or 0,
                unique_users=unique_users or 0,
                unique_ips=unique_ips or 0,
                mfa_verified_sessions=mfa_verified_sessions or 0,
            )
        except SQLAlchemyError as e:
            logger.error(f"세션 통계 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def revoke_sessions(db: Session, session_ids: list[str]) -> int:
        """세션 무효화"""
        try:
            revoked_count = 0
            for session_id in session_ids:
                # session_id는 실제로는 DB의 id이므로 해당 세션 조회
                session = (
                    db.query(SessionModel)
                    .filter(
                        SessionModel.id == session_id,
                        SessionModel.status == "ACTIVE",
                    )
                    .first()
                )

                if session:
                    session.status = "REVOKED"  # type: ignore
                    session.updated_at = datetime.utcnow()  # type: ignore
                    revoked_count += 1

            db.commit()
            return revoked_count
        except SQLAlchemyError as e:
            logger.error(f"세션 무효화 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def cleanup_expired_sessions(db: Session) -> int:
        """만료된 세션 정리"""
        try:
            from src.services.mgmt.session_service import (
                SessionService as SharedSessionService,
            )

            return SharedSessionService.cleanup_expired_sessions(db)
        except SQLAlchemyError as e:
            logger.error(f"세션 정리 중 데이터베이스 에러: {e}")
            db.rollback()
            raise
