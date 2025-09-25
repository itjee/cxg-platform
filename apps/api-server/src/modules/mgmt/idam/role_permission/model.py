"""
역할-권한 매핑 관리 모델
- 역할별 권한 부여, 승인자, 승인일시 등 관리
"""

from sqlalchemy import Column, ForeignKey
from sqlalchemy.dialects.postgresql import TIMESTAMP, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class RolePermission(BaseModel):
    """
    idam.role_permissions: 역할-권한 매핑 관리
    - 역할별 권한 부여, 승인자, 승인일시 등 관리
    """

    __tablename__ = "role_permissions"
    __table_args__ = {"schema": "idam"}

    role_id = Column(
        UUID(as_uuid=True),
        ForeignKey("idam.roles.id", ondelete="CASCADE"),
        nullable=False,
        comment="권한을 부여받는 역할 ID",
    )
    permission_id = Column(
        UUID(as_uuid=True),
        ForeignKey("idam.permissions.id", ondelete="CASCADE"),
        nullable=False,
        comment="부여된 권한 ID",
    )
    granted_by = Column(
        UUID(as_uuid=True), nullable=True, comment="권한 부여자 ID"
    )
    granted_at = Column(
        TIMESTAMP(timezone=True), nullable=True, comment="권한 부여 일시"
    )

    role = relationship("Role", back_populates="permissions")
    permission = relationship("Permission", back_populates="roles")

    def __repr__(self) -> str:
        return (
            f"<RolePermission role_id={self.role_id} "
            f"permission_id={self.permission_id}>"
        )


__all__ = ["RolePermission"]
