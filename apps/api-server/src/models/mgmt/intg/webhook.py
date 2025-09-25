# 웹훅 엔드포인트 모델
# 외부 시스템으로 이벤트 알림을 전송하는 웹훅 관리
from sqlalchemy import (
    ARRAY,
    TIMESTAMP,
    Boolean,
    Column,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

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
        String(50), default="application/json", comment="HTTP 컨텐츠 타입"
    )
    custom_headers = Column(
        JSONB, default=dict, comment="커스텀 HTTP 헤더 (JSON)"
    )
    timeout = Column(Integer, default=30, comment="HTTP 요청 타임아웃 (초)")
    max_retry_attempts = Column(Integer, default=3, comment="최대 재시도 횟수")
    retry_backoff = Column(Integer, default=60, comment="재시도 간격 (초)")
    total_deliveries = Column(Integer, default=0, comment="총 웹훅 전송 횟수")
    successful_deliveries = Column(
        Integer, default=0, comment="성공한 웹훅 전송 횟수"
    )
    failed_deliveries = Column(
        Integer, default=0, comment="실패한 웹훅 전송 횟수"
    )
    last_delivery_at = Column(
        TIMESTAMP(timezone=True), comment="마지막 웹훅 전송 시각"
    )
    last_success_at = Column(
        TIMESTAMP(timezone=True), comment="마지막 성공 전송 시각"
    )
    last_failure_at = Column(
        TIMESTAMP(timezone=True), comment="마지막 실패 전송 시각"
    )
    last_failure_reason = Column(Text, comment="마지막 실패 사유")
    enabled = Column(Boolean, default=True, comment="웹훅 활성화 여부")
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 여부"
    )

    # 관계
    tenant = relationship("Tenant", back_populates="webhooks")
    integration = relationship("Api", back_populates="webhooks")

    def __repr__(self):
        return (
            f"<Webhook {self.webhook_name} "
            f"url={self.webhook_url} enabled={self.enabled}>"
        )
