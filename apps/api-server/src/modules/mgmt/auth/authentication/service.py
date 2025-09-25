import logging
import uuid
from datetime import date, datetime, timedelta

from fastapi import Request
from sqlalchemy.orm import Session

from src.core.config import settings
from src.core.security import (
    create_access_token,
    get_password_hash,
    verify_password,
)
from src.models.mgmt.tnnt.tenant_user import TenantUser
from src.modules.mgmt.idam.user.model import User
from src.modules.mgmt.tnnt.tenant.model import Tenant
from src.services.mgmt.login_log_service import LoginLogService
from src.services.mgmt.session_service import SessionService

from .schemas import (
    AuthResponse,
    LoginRequest,
    LogoutRequest,
    SignupRequest,
    UserCreateRequest,
    UserResponse,
)

logger = logging.getLogger(__name__)


class AuthenticationService:
    """인증 관련 비즈니스 로직을 처리하는 서비스 클래스"""

    @staticmethod
    def signup(db: Session, user_data: SignupRequest) -> UserResponse:
        """사용자 유형에 따라 관리자 또는 테넌트 사용자를 생성합니다."""
        logger.info(
            f"회원가입 요청 시작: {user_data.email} (유형: {user_data.user_type})"
        )

        AuthenticationService._validate_user_data(db, user_data)

        try:
            if user_data.user_type == "MASTER":
                user = AuthenticationService._create_master_user(db, user_data)
            elif user_data.user_type == "TENANT":
                user = AuthenticationService._create_tenant_user(db, user_data)
            else:
                raise ValueError(
                    f"유효하지 않은 user_type: {user_data.user_type}"
                )

            return AuthenticationService._create_user_response(user)

        except Exception as e:
            logger.error(f"회원가입 처리 중 예외 발생: {e}", exc_info=True)
            db.rollback()
            raise e

    @staticmethod
    def _validate_user_data(db: Session, user_data: SignupRequest):
        """사용자 데이터 검증"""
        if db.query(User).filter(User.email == user_data.email).first():
            logger.warning(
                f"회원가입 실패: 이미 등록된 이메일 - {user_data.email}"
            )
            raise ValueError("이미 등록된 이메일입니다.")
        if db.query(User).filter(User.username == user_data.username).first():
            logger.warning(
                f"회원가입 실패: 이미 사용 중인 사용자명 - {user_data.username}"
            )
            raise ValueError("이미 사용 중인 사용자명입니다.")

    @staticmethod
    def _create_master_user(db: Session, user_data: SignupRequest) -> User:
        """관리자 사용자 생성"""
        logger.info(f"관리자(MASTER) 사용자 생성: {user_data.email}")
        user = AuthenticationService._create_user_object(user_data, "MASTER")
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(f"관리자(MASTER) 사용자 생성 성공: {user.id}")
        return user

    @staticmethod
    def _create_tenant_user(db: Session, user_data: SignupRequest) -> User:
        """테넌트 사용자 생성"""
        logger.info(f"테넌트(TENANT) 사용자 생성: {user_data.email}")
        tenant = AuthenticationService._handle_tenant(db, user_data)
        user = AuthenticationService._create_user_object(user_data, "TENANT")
        db.add(user)
        db.flush()
        logger.info(f"사용자 객체 생성 성공: {user.id}")

        AuthenticationService._link_tenant_user(
            db, tenant, user, user_data.create_new_tenant
        )
        return user

    @staticmethod
    def _handle_tenant(db: Session, user_data: SignupRequest) -> Tenant:
        """테넌트 생성 또는 조회"""
        if user_data.create_new_tenant:
            return AuthenticationService._create_new_tenant(db, user_data)
        else:
            return AuthenticationService._find_existing_tenant(db, user_data)

    @staticmethod
    def _create_new_tenant(db: Session, user_data: SignupRequest) -> Tenant:
        """새 테넌트 생성"""
        if not user_data.tenant_name:
            raise ValueError("새 테넌트 이름이 필요합니다.")
        if (
            db.query(Tenant)
            .filter(Tenant.tenant_name == user_data.tenant_name)
            .first()
        ):
            raise ValueError("이미 존재하는 테넌트명입니다.")

        tenant_code = f"T{uuid.uuid4().hex[:8].upper()}"
        tenant = Tenant(
            tenant_code=tenant_code,
            tenant_name=user_data.tenant_name,
            tenant_type="STANDARD",
            start_date=date.today(),
            timezone=user_data.timezone,
            locale=user_data.locale,
            status="ACTIVE",
            created_at=datetime.now(),
        )
        db.add(tenant)
        db.flush()
        logger.info(f"새로운 테넌트 생성 성공: {tenant.id}")
        return tenant

    @staticmethod
    def _find_existing_tenant(db: Session, user_data: SignupRequest) -> Tenant:
        """기존 테넌트 조회"""
        if not user_data.invite_token:
            raise ValueError(
                "기존 테넌트에 가입하려면 초대 토큰이 필요합니다."
            )
        # TODO: 초대 토큰 검증 로직 추가
        tenant = (
            db.query(Tenant)
            .filter(Tenant.tenant_name == user_data.tenant_name)
            .first()
        )
        if not tenant:
            raise ValueError("존재하지 않는 테넌트입니다.")
        return tenant

    @staticmethod
    def _create_user_object(user_data: SignupRequest, user_type: str) -> User:
        """사용자 객체 생성"""
        salt = uuid.uuid4().hex
        hashed_password = get_password_hash(user_data.password + salt)
        return User(
            email=str(user_data.email),
            username=user_data.username,
            password=hashed_password,
            salt_key=salt,
            full_name=user_data.full_name,
            user_type=user_type,
            status="ACTIVE",
            timezone=user_data.timezone,
            locale=user_data.locale,
            created_at=datetime.now(),
        )

    @staticmethod
    def _link_tenant_user(
        db: Session, tenant: Tenant, user: User, is_admin: bool
    ):
        """테넌트와 사용자 연결"""
        tenant_user = TenantUser(
            tenant_id=tenant.id,
            user_id=user.id,
            start_date=date.today(),
            status="ACTIVE",
            is_primary=True,
            is_admin=is_admin,
            created_at=datetime.now(),
        )
        db.add(tenant_user)
        db.commit()
        db.refresh(user)
        logger.info(
            f"테넌트-사용자 연결 성공: tenant_id={tenant.id}, user_id={user.id}"
        )

    @staticmethod
    def _create_user_response(user: User) -> UserResponse:
        """사용자 응답 객체 생성"""
        return UserResponse(
            id=str(user.id),
            email=str(user.email),
            username=str(user.username),
            full_name=str(user.full_name),
            created_at=str(user.created_at),
        )

    @staticmethod
    def create_user(db: Session, user_data: UserCreateRequest) -> UserResponse:
        """(내부용) 신규 사용자를 생성합니다."""
        logger.info(f"내부 사용자 생성 요청: {user_data.email}")
        if db.query(User).filter(User.email == user_data.email).first():
            raise ValueError("이미 등록된 이메일입니다.")
        if db.query(User).filter(User.username == user_data.username).first():
            raise ValueError("이미 사용 중인 사용자명입니다.")

        salt = uuid.uuid4().hex
        hashed_password = get_password_hash(user_data.password + salt)
        user = User(
            email=str(user_data.email),
            username=user_data.username,
            password=hashed_password,
            salt_key=salt,
            full_name=user_data.full_name,
            phone=user_data.phone,
            user_type=user_data.user_type,
            department=user_data.department,
            position=user_data.position,
            timezone=user_data.timezone,
            locale=user_data.locale,
            status="ACTIVE",
            created_at=datetime.now(),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(f"내부 사용자 생성 성공: {user.id}")
        return UserResponse(
            id=str(user.id),
            email=str(user.email),
            username=str(user.username),
            full_name=str(user.full_name),
            created_at=str(user.created_at),
        )

    @staticmethod
    def login(
        db: Session,
        login_data: LoginRequest,
        request: Request | None = None,
    ) -> AuthResponse:
        """사용자 로그인 처리 및 인증 토큰 발급"""
        logger.info(f"로그인 요청: {login_data.username}")
        user = (
            db.query(User)
            .filter(
                (User.username == login_data.username)
                | (User.email == login_data.username)
            )
            .first()
        )

        if not user:
            logger.warning(
                f"로그인 실패: 존재하지 않는 사용자 - {login_data.username}"
            )
            LoginLogService.log_failed_login(
                db=db,
                user_id=None,
                username=login_data.username,
                failure_reason="INVALID_USERNAME",
                request=request,
            )
            raise ValueError("아이디 또는 비밀번호가 올바르지 않습니다.")

        salt = str(user.salt_key)
        hashed_pw = str(user.password)

        if not verify_password(login_data.password + salt, hashed_pw):
            logger.warning(f"로그인 실패: 비밀번호 불일치 - {user.username}")
            LoginLogService.log_failed_login(
                db=db,
                user_id=user.id,  # type: ignore
                username=user.username,  # type: ignore
                failure_reason="INVALID_PASSWORD",
                request=request,
            )

            user.failed_login_attempts += 1  # type: ignore

            if user.failed_login_attempts >= 5:  # type: ignore
                user.locked_until = datetime.now() + timedelta(minutes=30)  # type: ignore
                user.status = "LOCKED"  # type: ignore
                logger.warning(f"계정 잠금: {user.username}")
                LoginLogService.log_account_locked(
                    db=db,
                    user_id=user.id,  # type: ignore
                    username=user.username,  # type: ignore
                    request=request,
                )

            db.commit()
            raise ValueError("아이디 또는 비밀번호가 올바르지 않습니다.")

        if user.status == "LOCKED":  # type: ignore
            if user.locked_until and user.locked_until > datetime.now():  # type: ignore
                logger.warning(f"로그인 실패: 잠긴 계정 - {user.username}")
                LoginLogService.log_failed_login(
                    db=db,
                    user_id=user.id,  # type: ignore
                    username=user.username,  # type: ignore
                    failure_reason="ACCOUNT_LOCKED",
                    request=request,
                )
                raise ValueError(
                    "계정이 잠겨있습니다. 잠시 후 다시 시도해주세요."
                )
            else:
                logger.info(f"계정 잠금 해제: {user.username}")
                user.status = "ACTIVE"  # type: ignore
                user.locked_until = None  # type: ignore
                user.failed_login_attempts = 0  # type: ignore

        user.last_login_at = datetime.now()  # type: ignore
        user.failed_login_attempts = 0  # type: ignore

        if request and request.client:
            user.last_login_ip = request.client.host  # type: ignore

        db.commit()

        session_token, session = SessionService.create_session(
            db=db,
            user_id=user.id,  # type: ignore
            request=request,
            expires_in_hours=settings.ACCESS_TOKEN_EXPIRE_MINUTES // 60 or 24,
        )
        logger.info(f"세션 생성 성공: user_id={user.id}")

        access_token = create_access_token(
            data={
                "sub": str(user.username),
                "user_id": str(user.id),
                "session_token": session_token,
            },
            expires_delta=timedelta(
                minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
            ),
        )

        LoginLogService.log_successful_login(
            db=db,
            user_id=user.id,  # type: ignore
            username=user.username,  # type: ignore
            request=request,
            session_id=session_token,
        )
        logger.info(f"로그인 성공: {user.username}")

        return AuthResponse(
            access_token=access_token,
            user_id=str(user.id),
            email=str(user.email),
            username=str(user.username),
            session_token=session_token,
            expires_at=session.expires_at.isoformat(),  # type: ignore
        )

    @staticmethod
    def logout_user(
        db: Session,
        logout_data: LogoutRequest,
        request: Request | None = None,
    ) -> bool:
        """사용자 로그아웃 처리"""
        logger.info(
            f"로그아웃 요청: session_token={logout_data.session_token[:10]}..."
        )
        session = SessionService.validate_session(
            db=db,
            session_token=logout_data.session_token,
            update_activity=False,
        )

        if not session:
            logger.warning("로그아웃 실패: 유효하지 않은 세션 토큰")
            return False

        success = SessionService.revoke_session(
            db=db,
            session_token=logout_data.session_token,
        )

        if success:
            logger.info(f"세션 무효화 성공: user_id={session.user_id}")
            LoginLogService.log_logout(
                db=db,
                user_id=session.user_id,  # type: ignore
                username="",  # username은 별도로 조회해야 함
                request=request,
                session_id=logout_data.session_token,
            )

        return success

    @staticmethod
    def validate_session_token(
        db: Session,
        session_token: str,
    ) -> Session | None:
        """세션 토큰의 유효성을 검증합니다."""
        logger.debug(f"세션 토큰 검증 요청: {session_token[:10]}...")
        return SessionService.validate_session(
            db=db,
            session_token=session_token,
            update_activity=True,
        )
