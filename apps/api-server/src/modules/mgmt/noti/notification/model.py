from sqlalchemy import (
    ARRAY,
    Column,
    ForeignKey,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID

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
