import hashlib
import secrets
import uuid
from datetime import datetime, timedelta

from fastapi import Request
from sqlalchemy.orm import Session as DBSession

from src.modules.mgmt.idam.session.model import Session


class SessionService:
    @staticmethod
    def generate_session_token() -> str:
        """보안 세션 토큰 생성"""
        return secrets.token_urlsafe(32)

    @staticmethod
    def hash_session_token(token: str) -> str:
        """세션 토큰 해시화 (저장용)"""
        return hashlib.sha256(token.encode()).hexdigest()

    @staticmethod
    def generate_device_fingerprint(
        request: Request | None = None,
    ) -> str | None:
        """디바이스 핑거프린트 생성"""
        if not request:
            return None

        components = []

        # User-Agent
        user_agent = request.headers.get("User-Agent", "")
        components.append(user_agent)

        # Accept headers
        accept = request.headers.get("Accept", "")
        accept_language = request.headers.get("Accept-Language", "")
        accept_encoding = request.headers.get("Accept-Encoding", "")

        components.extend([accept, accept_language, accept_encoding])

        # IP 주소
        ip_address = request.client.host if request.client else ""
        if not ip_address or ip_address == "127.0.0.1":
            forwarded_for = request.headers.get("X-Forwarded-For")
            if forwarded_for:
                ip_address = forwarded_for.split(",")[0].strip()

        components.append(ip_address)

        # 핑거프린트 해시 생성
        fingerprint_string = "|".join(components)
        fingerprint = hashlib.md5(fingerprint_string.encode()).hexdigest()

        return fingerprint

    @staticmethod
    def create_session(
        db: DBSession,
        user_id: uuid.UUID,
        request: Request | None = None,
        expires_in_hours: int = 24,
        mfa_verified: bool = False,
    ) -> tuple[str, Session]:
        """새 세션 생성"""
        # 세션 토큰 생성
        session_token = SessionService.generate_session_token()
        session_id_hash = SessionService.hash_session_token(session_token)

        # 요청 정보 추출
        ip_address = None
        user_agent = None
        fingerprint = None

        if request:
            # IP 주소 추출
            ip_address = request.client.host if request.client else None
            if not ip_address or ip_address == "127.0.0.1":
                forwarded_for = request.headers.get("X-Forwarded-For")
                if forwarded_for:
                    ip_address = forwarded_for.split(",")[0].strip()

            # User-Agent 추출
            user_agent = request.headers.get("User-Agent")

            # 디바이스 핑거프린트 생성
            fingerprint = SessionService.generate_device_fingerprint(request)

        # 만료 시간 설정
        expires_at = datetime.now() + timedelta(hours=expires_in_hours)

        # 세션 생성
        session = Session(
            session_id=session_id_hash,
            user_id=user_id,
            fingerprint=fingerprint,
            user_agent=user_agent,
            ip_address=ip_address,
            status="ACTIVE",
            expires_at=expires_at,
            last_activity_at=datetime.now(),
            mfa_verified=mfa_verified,
            mfa_verified_at=datetime.now() if mfa_verified else None,
            created_at=datetime.now(),
        )

        db.add(session)
        db.commit()
        db.refresh(session)

        return session_token, session

    @staticmethod
    def validate_session(
        db: DBSession,
        session_token: str,
        update_activity: bool = True,
    ) -> Session | None:
        """세션 유효성 검증"""
        session_id_hash = SessionService.hash_session_token(session_token)

        session = (
            db.query(Session)
            .filter(
                Session.session_id == session_id_hash,
                Session.status == "ACTIVE",
            )
            .first()
        )

        if not session:
            return None

        # 만료 시간 체크
        if session.expires_at < datetime.now():  # type: ignore
            session.status = "EXPIRED"  # type: ignore
            db.commit()
            return None

        # 마지막 활동 시간 업데이트
        if update_activity:
            session.last_activity_at = datetime.now()  # type: ignore
            db.commit()

        return session

    @staticmethod
    def revoke_session(
        db: DBSession,
        session_token: str,
    ) -> bool:
        """세션 무효화"""
        session_id_hash = SessionService.hash_session_token(session_token)

        session = (
            db.query(Session)
            .filter(
                Session.session_id == session_id_hash,
                Session.status == "ACTIVE",
            )
            .first()
        )

        if not session:
            return False

        session.status = "REVOKED"  # type: ignore
        session.updated_at = datetime.now()  # type: ignore
        db.commit()

        return True

    @staticmethod
    def revoke_user_sessions(
        db: DBSession,
        user_id: uuid.UUID,
        exclude_session_token: str | None = None,
    ) -> int:
        """사용자의 모든 세션 무효화 (현재 세션 제외 가능)"""
        query = db.query(Session).filter(
            Session.user_id == user_id,
            Session.status == "ACTIVE",
        )

        # 현재 세션 제외
        if exclude_session_token:
            exclude_hash = SessionService.hash_session_token(
                exclude_session_token
            )
            query = query.filter(Session.session_id != exclude_hash)

        sessions = query.all()
        revoked_count = 0

        for session in sessions:
            session.status = "REVOKED"  # type: ignore
            session.updated_at = datetime.now()  # type: ignore
            revoked_count += 1

        db.commit()
        return revoked_count

    @staticmethod
    def cleanup_expired_sessions(db: DBSession) -> int:
        """만료된 세션 정리"""
        expired_sessions = (
            db.query(Session)
            .filter(
                Session.status == "ACTIVE",
                Session.expires_at < datetime.now(),
            )
            .all()
        )

        cleaned_count = 0
        for session in expired_sessions:
            session.status = "EXPIRED"  # type: ignore
            session.updated_at = datetime.now()  # type: ignore
            cleaned_count += 1

        db.commit()
        return cleaned_count

    @staticmethod
    def extend_session(
        db: DBSession,
        session_token: str,
        extend_hours: int = 24,
    ) -> bool:
        """세션 만료 시간 연장"""
        session = SessionService.validate_session(
            db, session_token, update_activity=False
        )

        if not session:
            return False

        new_expires_at = datetime.now() + timedelta(hours=extend_hours)
        session.expires_at = new_expires_at  # type: ignore
        session.last_activity_at = datetime.now()  # type: ignore
        session.updated_at = datetime.now()  # type: ignore

        db.commit()
        return True

    @staticmethod
    def get_user_active_sessions(
        db: DBSession,
        user_id: uuid.UUID,
    ) -> list[Session]:
        """사용자의 활성 세션 목록 조회"""
        return (
            db.query(Session)
            .filter(
                Session.user_id == user_id,
                Session.status == "ACTIVE",
                Session.expires_at > datetime.now(),
            )
            .order_by(Session.last_activity_at.desc())
            .all()
        )

    @staticmethod
    def verify_mfa_for_session(
        db: DBSession,
        session_token: str,
    ) -> bool:
        """세션의 MFA 인증 상태 업데이트"""
        session = SessionService.validate_session(
            db, session_token, update_activity=False
        )

        if not session:
            return False

        session.mfa_verified = True  # type: ignore
        session.mfa_verified_at = datetime.now()  # type: ignore
        session.updated_at = datetime.now()  # type: ignore

        db.commit()
        return True
