from sqlalchemy import (
    ARRAY,
    Column,
    ForeignKey,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID

from src.models.base import BaseModel


class Webhook(BaseModel):
    """
    intg.webhooks: 외부 시스템 웹훅 엔드포인트
    외부 시스템으로 이벤트 알림을 전송하는 웹훅 관리
    """

    __tablename__ = "webhooks"
    __table_args__ = {"schema": "intg"}
    tenant_id = Column(
        UUID,
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="테넌트 ID",
    )
    integration_id = Column(
        UUID,
        ForeignKey("intg.apis.id", ondelete="CASCADE"),
        comment="연동 서비스 ID",
    )
    webhook_name = Column(
        String(200), nullable=False, comment="웹훅 엔드포인트 이름"
    )
    webhook_url = Column(
        String(500), nullable=False, comment="웹훅을 받을 대상 URL"
    )
    description = Column(Text, comment="웹훅 엔드포인트 설명")
    event_types = Column(
        ARRAY(Text), nullable=False, comment="구독할 이벤트 유형 목록"
    )
    event_filters = Column(
        JSONB, default=dict, comment="이벤트 필터링 조건 (JSON)"
    )
    secret_key_hash = Column(
        String(255), comment="서명 검증용 시크릿 키 해시값"
    )
    signature_algorithm = Column(
        String(20), default="HMAC_SHA256", comment="웹훅 서명 알고리즘"
    )
    http_method = Column(
        String(10), default="POST", comment="HTTP 요청 메소드"
    )
    content_type = Column(
        String(50), default="application/json", comment="Content-Type"
    )
