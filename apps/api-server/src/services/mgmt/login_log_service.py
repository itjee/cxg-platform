import uuid
from datetime import datetime

from fastapi import Request
from sqlalchemy.orm import Session

from src.modules.mgmt.idam.login_log.model import LoginLog


class LoginLogService:
    @staticmethod
    def create_login_log(
        db: Session,
        user_id: uuid.UUID | None,
        username: str | None,
        attempt_type: str,
        success: bool,
        request: Request | None = None,
        session_id: str | None = None,
        failure_reason: str | None = None,
        mfa_used: bool = False,
        mfa_method: str | None = None,
    ) -> LoginLog:
        """로그인 로그 생성"""
        ip_address = None
        user_agent = None

        if request:
            # FastAPI Request에서 IP 주소 추출
            ip_address = request.client.host if request.client else None
            # X-Forwarded-For 헤더 확인
            if not ip_address or ip_address == "127.0.0.1":
                forwarded_for = request.headers.get("X-Forwarded-For")
                if forwarded_for:
                    ip_address = forwarded_for.split(",")[0].strip()

            # User-Agent 추출
            user_agent = request.headers.get("User-Agent")

        login_log = LoginLog(
            user_id=user_id,
            username=username,
            attempt_type=attempt_type,
            success=success,
            failure_reason=failure_reason,
            session_id=session_id,
            ip_address=ip_address,
            user_agent=user_agent,
            mfa_used=mfa_used,
            mfa_method=mfa_method,
            created_at=datetime.now(),
        )

        db.add(login_log)
        db.commit()
        db.refresh(login_log)

        return login_log

    @staticmethod
    def log_successful_login(
        db: Session,
        user_id: uuid.UUID,
        username: str,
        request: Request | None = None,
        session_id: str | None = None,
        mfa_used: bool = False,
        mfa_method: str | None = None,
    ) -> LoginLog:
        """성공적인 로그인 기록"""
        return LoginLogService.create_login_log(
            db=db,
            user_id=user_id,
            username=username,
            attempt_type="LOGIN",
            success=True,
            request=request,
            session_id=session_id,
            mfa_used=mfa_used,
            mfa_method=mfa_method,
        )

    @staticmethod
    def log_failed_login(
        db: Session,
        user_id: uuid.UUID | None,
        username: str,
        failure_reason: str,
        request: Request | None = None,
    ) -> LoginLog:
        """실패한 로그인 기록"""
        return LoginLogService.create_login_log(
            db=db,
            user_id=user_id,
            username=username,
            attempt_type="FAILED_LOGIN",
            success=False,
            request=request,
            failure_reason=failure_reason,
        )

    @staticmethod
    def log_logout(
        db: Session,
        user_id: uuid.UUID,
        username: str,
        request: Request | None = None,
        session_id: str | None = None,
    ) -> LoginLog:
        """로그아웃 기록"""
        return LoginLogService.create_login_log(
            db=db,
            user_id=user_id,
            username=username,
            attempt_type="LOGOUT",
            success=True,
            request=request,
            session_id=session_id,
        )

    @staticmethod
    def log_account_locked(
        db: Session,
        user_id: uuid.UUID,
        username: str,
        request: Request | None = None,
    ) -> LoginLog:
        """계정 잠금 기록"""
        return LoginLogService.create_login_log(
            db=db,
            user_id=user_id,
            username=username,
            attempt_type="LOCKED",
            success=False,
            request=request,
            failure_reason="ACCOUNT_LOCKED",
        )

    @staticmethod
    def log_password_reset(
        db: Session,
        user_id: uuid.UUID,
        username: str,
        request: Request | None = None,
    ) -> LoginLog:
        """비밀번호 재설정 기록"""
        return LoginLogService.create_login_log(
            db=db,
            user_id=user_id,
            username=username,
            attempt_type="PASSWORD_RESET",
            success=True,
            request=request,
        )
