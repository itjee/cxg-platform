# 지원 티켓 관리 모델
# 문의/요청, SLA, 담당자, 처리상태, 고객평가 등 기록
from sqlalchemy import (
    Boolean,
    Column,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import TIMESTAMP, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Ticket(BaseModel):
    """
    supt.tickets: 지원 티켓 관리
    - 문의/요청, SLA, 담당자, 처리상태, 고객평가 등 기록
    """

    __tablename__ = "tickets"
    __table_args__ = {"schema": "supt"}

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="테넌트 UUID",
    )
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenant_users.id", ondelete="SET NULL"),
        nullable=True,
        comment="티켓 등록자 UUID",
    )
    ticket_no = Column(
        String(50), nullable=False, unique=True, comment="티켓 고유번호"
    )
    title = Column(String(200), nullable=False, comment="티켓 제목")
    description = Column(Text, nullable=False, comment="티켓 상세 내용")
    category = Column(
        String(50), nullable=False, comment="카테고리(문의/요청/불만 등)"
    )
    priority = Column(
        String(20),
        nullable=False,
        default="MEDIUM",
        comment="우선순위(LOW/MEDIUM/HIGH)",
    )
    contact_email = Column(
        String(255), nullable=False, comment="고객 연락 이메일"
    )
    contact_phone = Column(String(20), comment="고객 연락 전화번호")
    assigned_to = Column(String(100), comment="담당자")
    assigned_at = Column(TIMESTAMP(timezone=True), comment="담당자 배정 시각")
    sla_level = Column(
        String(20),
        nullable=False,
        default="STANDARD",
        comment="SLA 등급(STANDARD/URGENT 등)",
    )
    first_response_due = Column(
        TIMESTAMP(timezone=True), comment="최초 응답 예정 시각"
    )
    resolution_due = Column(TIMESTAMP(timezone=True), comment="해결 예정 시각")
    first_response_at = Column(
        TIMESTAMP(timezone=True), comment="최초 응답 실제 시각"
    )
    resolved_at = Column(TIMESTAMP(timezone=True), comment="해결 완료 시각")
    resolution_summary = Column(Text, comment="해결 요약")
    customer_rating = Column(Integer, comment="고객 평가 점수(1-5)")
    customer_feedback = Column(Text, comment="고객 피드백")
    status = Column(
        String(20),
        nullable=False,
        default="OPEN",
        comment="상태(OPEN/IN_PROGRESS/RESOLVED 등)",
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    tenant = relationship("Tenant", back_populates="tickets")
    user = relationship("TenantUser", back_populates="tickets")
    comments = relationship("TicketComment", back_populates="ticket")

    def __repr__(self):
        return f"<Ticket {self.ticket_no} status={self.status}>"
