# 테넌트-사용자 연결 관리 모델
# 테넌트별 사용자 역할, 부서, 직급, 가입/탈퇴일 등 관리
from sqlalchemy import Boolean, Column, Date, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class TenantUser(BaseModel):
    """
    tnnt.tenant_users: 테넌트-사용자 연결 관리
    - 테넌트별 사용자 역할, 부서, 직급, 가입/탈퇴일 등 관리
    """

    __tablename__ = "tenant_users"
    __table_args__ = {"schema": "tnnt"}

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="테넌트 ID",
    )
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("idam.users.id", ondelete="CASCADE"),
        nullable=False,
        comment="사용자 ID",
    )
    role = Column(String(50), nullable=True, comment="테넌트 내 역할/직책")
    department = Column(String(100), nullable=True, comment="테넌트 내 부서")
    position = Column(String(100), nullable=True, comment="테넌트 내 직급")
    employee_id = Column(String(50), nullable=True, comment="테넌트 내 사번")
    start_date = Column(Date, nullable=False, comment="테넌트 가입일")
    close_date = Column(Date, nullable=True, comment="테넌트 탈퇴일")
    status = Column(
        String(20), nullable=False, default="ACTIVE", comment="테넌트 내 상태"
    )
    is_primary = Column(
        Boolean, nullable=False, default=False, comment="주 테넌트 여부"
    )
    is_admin = Column(
        Boolean, nullable=False, default=False, comment="테넌트 관리자 여부"
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    tenant = relationship("Tenant", back_populates="users")
    # Temporarily removed to fix relationship issues
    # tickets = relationship("Ticket", back_populates="user")
    # ticket_comments = relationship("TicketComment", back_populates="user")
    # feedbacks = relationship("Feedback", back_populates="user")

    def __repr__(self):
        return (
            f"<TenantUser tenant_id={self.tenant_id} "
            f"user_id={self.user_id} status={self.status}>"
        )
