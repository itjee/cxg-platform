from sqlalchemy import ARRAY, Boolean, Column, String, Text
from sqlalchemy.dialects.postgresql import TIMESTAMP, UUID

from src.models.base import BaseModel


class Campaign(BaseModel):
    """
    noti.campaigns: 알림/이메일 캠페인 관리
    - 타겟, 발송, 통계, AB테스트 등 캠페인 전체 라이프사이클 관리
    """

    __tablename__ = "campaigns"
    __table_args__ = {"schema": "noti"}
    campaign_name = Column(String(200), nullable=False, comment="캠페인 이름")
    campaign_type = Column(
        String(50), nullable=False, comment="캠페인 유형(이메일/푸시/SMS 등)"
    )
    description = Column(Text, comment="캠페인 설명")
    target_type = Column(
        String(20),
        nullable=False,
        default="users",
        comment="타겟 유형(users/tenants 등)",
    )
    target_tenant_types = Column(ARRAY(Text), comment="타겟 테넌트 유형 목록")
    target_user_roles = Column(ARRAY(Text), comment="타겟 사용자 역할 목록")
    custom_recipients = Column(
        ARRAY(UUID(as_uuid=True)), comment="커스텀 수신자 UUID 목록"
    )
    subject = Column(String(500), nullable=False, comment="이메일/알림 제목")
    html_content = Column(Text, comment="HTML 본문 내용")
    text_content = Column(Text, comment="텍스트 본문 내용")
    sender_name = Column(
        String(100),
        nullable=False,
        default="CXG 플랫폼 관리자",
        comment="발신자 이름",
    )
    sender_email = Column(
        String(255),
        nullable=False,
        default="noreply@cxg.co.kr",
        comment="발신자 이메일",
    )
    reply_to_email = Column(String(255), comment="회신 이메일")
    send_immediately = Column(
        Boolean, nullable=False, default=False, comment="즉시 발송 여부"
    )
    scheduled_send_at = Column(
        TIMESTAMP(timezone=True), comment="예약 발송 시각"
    )
