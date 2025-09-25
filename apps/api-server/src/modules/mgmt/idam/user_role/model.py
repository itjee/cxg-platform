# 사용자-역할 매핑 관리 모델
# 사용자별 역할 부여, 범위, 승인자, 만료 등 관리
from sqlalchemy import Column, ForeignKey, String
from sqlalchemy.dialects.postgresql import TIMESTAMP, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class UserRole(BaseModel):
    """
    idam.user_roles: 사용자-역할 매핑 관리
    - 사용자별 역할 부여, 범위, 승인자, 만료 등 관리
    """

    __tablename__ = "user_roles"
    __table_args__ = {"schema": "idam"}

    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("idam.users.id", ondelete="CASCADE"),
        nullable=False,
        comment="역할이 부여된 사용자 ID",
    )
    role_id = Column(
        UUID(as_uuid=True),
        ForeignKey("idam.roles.id", ondelete="CASCADE"),
        nullable=False,
        comment="부여된 역할 ID",
    )
    scope = Column(
        String(20),
        nullable=False,
        default="GLOBAL",
        comment="권한 범위(GLOBAL/TENANT)",
    )
    tenant_context = Column(
        UUID(as_uuid=True),
        nullable=True,
        comment="권한 적용 테넌트(NULL=글로벌)",
    )
    granted_by = Column(
        UUID(as_uuid=True), nullable=True, comment="역할 부여자 ID"
    )
    granted_at = Column(
        TIMESTAMP(timezone=True), nullable=True, comment="역할 부여 일시"
    )
    expires_at = Column(
        TIMESTAMP(timezone=True), nullable=True, comment="역할 만료 일시"
    )
    status = Column(
        String(20),
        default="ACTIVE",
        nullable=False,
        comment="역할 상태(ACTIVE/INACTIVE/EXPIRED)",
    )

    user = relationship("User", back_populates="roles")
    role = relationship("Role", back_populates="users")

    def __repr__(self) -> str:
        return f"<UserRole user_id={self.user_id} role_id={self.role_id}>"


__all__ = ["UserRole"]
