# 권한 마스터 모델
# 시스템/리소스별 권한 코드, 설명, 유형 등 관리
from sqlalchemy import Boolean, Column, String, Text
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Permission(BaseModel):
    """
    idam.permissions: 권한 마스터
    - 시스템/리소스별 권한 코드, 설명, 유형 등 관리
    """

    __tablename__ = "permissions"
    __table_args__ = {"schema": "idam"}

    permission_code = Column(
        String(100), unique=True, nullable=False, comment="권한 코드(고유키)"
    )
    permission_name = Column(String(100), nullable=False, comment="권한 이름")
    description = Column(Text, nullable=True, comment="권한 설명")
    category = Column(String(50), nullable=False, comment="권한 카테고리")
    resource_type = Column(String(50), nullable=False, comment="리소스 유형")
    action = Column(String(50), nullable=False, comment="허용 액션")

    scope = Column(
        String(20),
        nullable=False,
        default="GLOBAL",
        comment="권한 적용 범위(GLOBAL/TENANT)",
    )
    applies_to = Column(
        String(20),
        nullable=False,
        default="ALL",
        comment="적용 대상(ALL/MASTER/TENANT/SYSTEM)",
    )

    is_system = Column(
        Boolean, default=False, nullable=False, comment="시스템 권한 여부"
    )
    status = Column(
        String(20),
        default="ACTIVE",
        nullable=False,
        comment="권한 상태(ACTIVE/INACTIVE)",
    )

    roles = relationship("RolePermission", back_populates="permission")

    def __repr__(self) -> str:
        return (
            f"<Permission(id={self.id}, permission_code='{self.permission_code}', "
            f"permission_name='{self.permission_name}')>"
        )


__all__ = ["Permission"]
