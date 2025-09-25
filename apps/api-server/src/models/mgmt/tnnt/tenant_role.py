from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import TIMESTAMP, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class TenantRole(BaseModel):
    """
    tnnt.tenant_roles: 테넌트-역할 연결 관리 (테넌트별 역할 커스터마이징)
    """

    __tablename__ = "tenant_roles"
    __table_args__ = {"schema": "tnnt"}

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="테넌트 ID",
    )
    role_id = Column(
        UUID(as_uuid=True),
        ForeignKey("idam.roles.id", ondelete="CASCADE"),
        nullable=False,
        comment="역할 ID",
    )
    role_name = Column(
        String(100), nullable=True, comment="테넌트별 역할명 재정의"
    )
    description = Column(
        Text, nullable=True, comment="테넌트별 역할 설명 재정의"
    )
    is_default = Column(
        Boolean,
        nullable=False,
        default=False,
        comment="테넌트 내 기본 역할 여부",
    )
    priority = Column(Integer, nullable=True, comment="테넌트 내 우선순위")
    enabled = Column(
        Boolean,
        nullable=False,
        default=True,
        comment="테넌트 내 역할 활성화 여부",
    )
    enabled_at = Column(
        TIMESTAMP(timezone=True), nullable=True, comment="활성화 일시"
    )
    disabled_at = Column(
        TIMESTAMP(timezone=True), nullable=True, comment="비활성화 일시"
    )
    max_users = Column(
        Integer, nullable=True, comment="이 역할을 가질 수 있는 최대 사용자 수"
    )
    current_users = Column(
        Integer,
        nullable=False,
        default=0,
        comment="현재 이 역할을 가진 사용자 수",
    )

    # 관계: 테넌트, 역할
    tenant = relationship("Tenant", back_populates="tenant_roles")
    role = relationship("Role", back_populates="tenant_roles")

    def __repr__(self):
        return (
            f"<TenantRole tenant_id={self.tenant_id} "
            f"role_id={self.role_id} enabled={self.enabled}>"
        )
