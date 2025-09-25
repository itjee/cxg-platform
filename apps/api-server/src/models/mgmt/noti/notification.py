# 알림/메시지 관리 모델
# 사용자/테넌트별 알림, 발송채널, 상태, 액션 등 기록
from sqlalchemy import (
    ARRAY,
    Boolean,
    Column,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, TIMESTAMP, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Notification(BaseModel):
    """
    noti.notifications: 알림/메시지 관리
    - 사용자/테넌트별 알림, 발송채널, 상태, 액션 등 기록
    """

    __tablename__ = "notifications"
    __table_args__ = {"schema": "noti"}

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=True,
        comment="테넌트 UUID",
    )
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.users.id", ondelete="CASCADE"),
        nullable=True,
        comment="사용자 UUID",
    )
    target_type = Column(
        String(20),
        nullable=False,
        default="USER",
        comment="타겟 유형(USER/TENANT 등)",
    )
    notify_type = Column(
        String(50), nullable=False, comment="알림 유형(이벤트/공지/경고 등)"
    )
    title = Column(String(200), nullable=False, comment="알림 제목")
    message = Column(Text, nullable=False, comment="알림 메시지 본문")
    priority = Column(
        String(20),
        nullable=False,
        default="MEDIUM",
        comment="우선순위(LOW/MEDIUM/HIGH)",
    )
    channels = Column(
        ARRAY(Text),
        nullable=False,
        default=["IN_APP"],
        comment="발송 채널(IN_APP/EMAIL/SMS 등)",
    )
    scheduled_at = Column(
        TIMESTAMP(timezone=True), nullable=False, comment="예약 발송 시각"
    )
    sent_at = Column(TIMESTAMP(timezone=True), comment="실제 발송 시각")
    delivery_attempts = Column(
        Integer, nullable=False, default=0, comment="발송 시도 횟수"
    )
    read_at = Column(TIMESTAMP(timezone=True), comment="읽은 시각")
    acknowledged_at = Column(
        TIMESTAMP(timezone=True), comment="확인(ack) 시각"
    )
    action_required = Column(
        Boolean, nullable=False, default=False, comment="액션 필요 여부"
    )
    action_url = Column(String(500), comment="액션 URL(예: 승인/처리 링크)")
    action_deadline = Column(
        TIMESTAMP(timezone=True), comment="액션 마감 시각"
    )
    expires_at = Column(TIMESTAMP(timezone=True), comment="알림 만료 시각")
    status = Column(
        String(20),
        nullable=False,
        default="PENDING",
        comment="상태(PENDING/SENT/READ 등)",
    )
    delivery_status = Column(
        JSONB, nullable=False, default={}, comment="채널별 발송 상태(JSON)"
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    tenant = relationship("Tenant", back_populates="notifications")
    user = relationship("TenantUser", back_populates="notifications")

    def __repr__(self):
        return (
            f"<Notification {self.title} "
            f"type={self.notify_type} "
            f"status={self.status}>"
        )
