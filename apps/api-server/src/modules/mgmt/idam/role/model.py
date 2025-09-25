# 역할 마스터 모델
# 운영자/사용자 역할 정의, 기본 여부, 우선순위 등 관리
from sqlalchemy import Boolean, Column, Integer, String, Text
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Role(BaseModel):
    """
    idam.roles: 역할 마스터
    - 운영자/사용자 역할 정의, 기본 여부, 우선순위 등 관리
    """

    __tablename__ = "roles"
    __table_args__ = {"schema": "idam"}

    role_code = Column(
        String(100), unique=True, nullable=False, comment="역할 코드(고유키)"
    )
    role_name = Column(String(100), nullable=False, comment="역할 이름")
    description = Column(Text, nullable=True, comment="역할 설명")
    role_type = Column(
        String(50),
        default="USER",
        nullable=False,
        comment="역할 유형(SYSTEM/PLATFORM/ADMIN/MANAGER/USER/GUEST)",
    )
    scope = Column(
        String(20),
        nullable=False,
        default="GLOBAL",
        comment="역할 적용 범위(GLOBAL/TENANT)",
    )
    is_default = Column(
        Boolean, default=False, nullable=False, comment="기본 역할 여부"
    )
    priority = Column(
        Integer, default=100, nullable=False, comment="역할 우선순위"
    )
    status = Column(
        String(20),
        default="ACTIVE",
        nullable=False,
        comment="역할 상태(ACTIVE/INACTIVE)",
    )

    users = relationship("UserRole", back_populates="role")
    permissions = relationship("RolePermission", back_populates="role")
    tenant_roles = relationship("TenantRole", back_populates="role")

    def __repr__(self) -> str:
        return (
            f"<Role(id={self.id}, "
            f"role_code='{self.role_code}', "
            f"role_name='{self.role_name}')>"
        )


__all__ = ["Role"]
