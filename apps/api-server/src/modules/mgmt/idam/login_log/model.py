# 로그인 이력 관리 모델
# 사용자별 로그인 시도, 성공/실패, MFA 등 관리
from sqlalchemy import (
    Boolean,
    Column,
    ForeignKey,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import INET, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class LoginLog(BaseModel):
    """
    idam.login_logs: 로그인 이력 관리
    - 사용자별 로그인 시도, 성공/실패, MFA 등 관리
    """

    __tablename__ = "login_logs"
    __table_args__ = {"schema": "idam"}

    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("idam.users.id", ondelete="SET NULL"),
        nullable=True,
        comment="로그인 사용자 ID (존재하지 않는 사용자의 경우 NULL)",
    )
    user_type = Column(
        String(20), nullable=True, comment="사용자 타입(로그 보존용)"
    )
    tenant_context = Column(
        UUID(as_uuid=True), nullable=True, comment="로그인 시 테넌트 컨텍스트"
    )

    username = Column(
        String(100),
        nullable=True,
        comment="로그인 사용자명(삭제된 사용자 이력 보존용)",
    )
    attempt_type = Column(
        String(20), nullable=False, comment="로그인 시도 유형"
    )
    success = Column(Boolean, nullable=False, comment="로그인 성공 여부")
    failure_reason = Column(String(100), nullable=True, comment="실패 사유")
    session_id = Column(String(255), nullable=True, comment="세션 ID")
    ip_address = Column(INET, nullable=False, comment="로그인 IP 주소")
    user_agent = Column(Text, nullable=True, comment="User-Agent 정보")
    country_code = Column(String(2), nullable=True, comment="국가 코드")
    city = Column(String(100), nullable=True, comment="도시명")
    mfa_used = Column(
        Boolean, nullable=False, default=False, comment="MFA 사용 여부"
    )
    mfa_method = Column(String(50), nullable=True, comment="MFA 인증 방식")

    # 관계
    user = relationship("User", back_populates="login_logs")

    def __repr__(self):
        return (
            f"<LoginLog user={self.username} "
            f"success={self.success} ip={self.ip_address}>"
        )


__all__ = ["LoginLog"]
