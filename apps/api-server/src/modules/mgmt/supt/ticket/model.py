from sqlalchemy import Column, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID

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
