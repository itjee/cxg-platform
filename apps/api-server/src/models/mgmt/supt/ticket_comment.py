# 지원 티켓 댓글/대화 관리 모델
# 사용자/운영자 댓글, 내부/자동화 구분, 파일 첨부 등 기록
from sqlalchemy import Boolean, Column, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class TicketComment(BaseModel):
    """
    supt.ticket_comments: 지원 티켓 댓글/대화 관리
    - 사용자/운영자 댓글, 내부/자동화 구분, 파일 첨부 등 기록
    """

    __tablename__ = "ticket_comments"
    __table_args__ = {"schema": "supt"}

    ticket_id = Column(
        UUID(as_uuid=True),
        ForeignKey("supt.tickets.id", ondelete="CASCADE"),
        nullable=False,
        comment="티켓 UUID",
    )
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenant_users.id", ondelete="SET NULL"),
        nullable=True,
        comment="댓글 작성자 UUID",
    )
    comment_text = Column(Text, nullable=False, comment="댓글/대화 내용")
    comment_type = Column(
        String(20),
        nullable=False,
        default="COMMENT",
        comment="댓글 유형(COMMENT/NOTE/REPLY 등)",
    )
    is_internal = Column(Boolean, default=False, comment="내부 댓글 여부")
    files = Column(JSONB, default=list, comment="첨부 파일 목록(JSON)")
    automated = Column(Boolean, default=False, comment="자동화 생성 여부")
    automation_source = Column(
        String(50), comment="자동화 소스(예: RPA, 시스템)"
    )
    status = Column(
        String(20),
        nullable=False,
        default="ACTIVE",
        comment="상태(ACTIVE/INACTIVE 등)",
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    ticket = relationship("Ticket", back_populates="comments")
    user = relationship("TenantUser", back_populates="ticket_comments")

    def __repr__(self):
        return (
            f"<TicketComment ticket_id={self.ticket_id} "
            f"user_id={self.user_id}>"
        )
