# 사용자 세션 관리 모델
# 로그인 세션, MFA 인증, 만료/활성 상태 등 관리
from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    ForeignKey,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import INET, TIMESTAMP, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Session(BaseModel):
    """
    idam.sessions: 사용자 세션 관리
    - 로그인 세션, MFA 인증, 만료/활성 상태 등 관리
    """

    __tablename__ = "sessions"
    __table_args__ = {"schema": "idam"}

    session_id = Column(
        String(255), unique=True, nullable=False, comment="세션 고유 ID"
    )
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("idam.users.id", ondelete="CASCADE"),
        nullable=False,
        comment="세션 소유 사용자 ID",
    )

    tenant_context = Column(
        UUID(as_uuid=True),
        nullable=True,
        comment="현재 세션의 테넌트 컨텍스트",
    )
    session_type = Column(
        String(20),
        nullable=False,
        default="WEB",
        comment="세션 타입(WEB/API/MOBILE)",
    )
    fingerprint = Column(
        String(255), nullable=True, comment="클라이언트 지문 정보"
    )
    user_agent = Column(Text, nullable=True, comment="User-Agent 정보")
    ip_address = Column(INET, nullable=False, comment="접속 IP 주소")
    country_code = Column(String(2), nullable=True, comment="국가 코드")
    city = Column(String(100), nullable=True, comment="도시명")
    status = Column(
        String(20),
        default="ACTIVE",
        nullable=False,
        comment="세션 상태(ACTIVE/EXPIRED/REVOKED)",
    )
    expires_at = Column(
        TIMESTAMP(timezone=True), nullable=False, comment="세션 만료 시각"
    )
    last_activity_at = Column(
        TIMESTAMP(timezone=True),
        default=datetime.utcnow,
        nullable=False,
        comment="마지막 활동 시각",
    )
    mfa_verified = Column(
        Boolean, default=False, nullable=False, comment="MFA 인증 여부"
    )
    mfa_verified_at = Column(
        TIMESTAMP(timezone=True), nullable=True, comment="MFA 인증 시각"
    )

    # 관계
    user = relationship("User", back_populates="sessions")

    def __repr__(self):
        return (
            f"<Session user_id={self.user_id} "
            f"ip={self.ip_address} status={self.status}>"
        )


__all__ = ["Session"]
