# 운영자/사용자 정보 관리 모델
# 인증, SSO, MFA, 계정상태, 보안정보, 조직정보 등 관리
from sqlalchemy import ARRAY, Boolean, Column, Integer, String, Text
from sqlalchemy.dialects.postgresql import INET, TIMESTAMP
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class User(BaseModel):
    """
    idam.users: 운영자/사용자 정보 관리
    - 인증, SSO, MFA, 계정상태, 보안정보, 조직정보 등 관리
    """

    __tablename__ = "users"
    __table_args__ = {"schema": "idam"}

    user_type = Column(
        String(20),
        default="USER",
        nullable=False,
        comment="사용자 타입(MASTER/TENANT/SYSTEM)",
    )
    full_name = Column(String(100), nullable=False, comment="전체 이름")
    email = Column(
        String(255),
        unique=True,
        index=True,
        nullable=False,
        comment="이메일 주소",
    )
    phone = Column(String(20), nullable=True, comment="전화번호")

    username = Column(
        String(100),
        unique=True,
        index=True,
        nullable=False,
        comment="로그인 계정명",
    )
    password = Column(String(255), nullable=True, comment="암호화된 비밀번호")
    salt_key = Column(
        String(100), nullable=True, comment="비밀번호 암호화용 salt"
    )
    sso_provider = Column(String(50), nullable=True, comment="SSO 제공자")
    sso_subject = Column(String(255), nullable=True, comment="SSO Subject 값")
    mfa_enabled = Column(
        Boolean, default=False, nullable=False, comment="MFA 활성화 여부"
    )
    mfa_secret = Column(String(255), nullable=True, comment="MFA 시크릿 키")
    backup_codes = Column(
        ARRAY(Text), nullable=True, comment="MFA 백업 코드 배열"
    )
    status = Column(
        String(20),
        default="ACTIVE",
        nullable=False,
        comment="계정 상태(ACTIVE/INACTIVE/LOCKED/SUSPENDED)",
    )
    last_login_at = Column(
        TIMESTAMP(timezone=True), nullable=True, comment="마지막 로그인 시각"
    )
    last_login_ip = Column(INET, nullable=True, comment="마지막 로그인 IP")
    failed_login_attempts = Column(
        Integer, default=0, nullable=False, comment="로그인 실패 횟수"
    )
    locked_until = Column(
        TIMESTAMP(timezone=True),
        nullable=True,
        comment="계정 잠금 해제 예정 시각",
    )
    password_changed_at = Column(
        TIMESTAMP(timezone=True), nullable=True, comment="비밀번호 변경 시각"
    )
    force_password_change = Column(
        Boolean,
        default=False,
        nullable=False,
        comment="최초 로그인 시 비밀번호 변경 강제 여부",
    )
    timezone = Column(
        String(50), default="UTC", nullable=False, comment="사용자 타임존"
    )
    locale = Column(
        String(10),
        default="ko-KR",
        nullable=False,
        comment="사용자 언어/로케일",
    )
    department = Column(String(100), nullable=True, comment="부서명")
    position = Column(String(100), nullable=True, comment="직위/직책")

    # 관계
    roles = relationship("UserRole", back_populates="user")
    api_keys = relationship("ApiKey", back_populates="user")
    login_logs = relationship("LoginLog", back_populates="user")
    sessions = relationship("Session", back_populates="user")

    def __repr__(self):
        return (
            f"<User id={self.id} username={self.username} "
            f"email={self.email} status={self.status}>"
        )


__all__ = ["User"]
