# 외부 시스템 연동 API 모델
# 결제, CRM, ERP 등 외부 서비스와의 API 연동 설정 및 상태 관리
from sqlalchemy import (
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


class Api(BaseModel):
    """
    intg.apis: 외부 시스템 연동 설정
    결제, CRM, ERP 등 외부 서비스와의 API 연동 설정 및 상태 관리
    """

    __tablename__ = "apis"
    __table_args__ = {"schema": "intg"}

    tenant_id = Column(
        UUID,
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        comment="테넌트별 연동인 경우 테넌트 ID",
    )
    api_type = Column(
        String(50),
        nullable=False,
        comment="연동 유형 (PAYMENT_GATEWAY/CRM/ERP/EMAIL_SERVICE 등)",
    )
    api_name = Column(String(200), nullable=False, comment="연동 이름")
    provider = Column(String(100), nullable=False, comment="서비스 제공업체명")
    api_endpoint = Column(String(500), comment="API 엔드포인트 URL")
    api_version = Column(String(20), comment="API 버전")
    authentication_type = Column(
        String(50), nullable=False, default="API_KEY", comment="인증 방식"
    )
    api_key = Column(String(255), comment="암호화된 API 키")
    client_id = Column(String(255), comment="OAuth 클라이언트 ID")
    client_secret = Column(String(255), comment="암호화된 클라이언트 시크릿")
    access_token = Column(String(255), comment="암호화된 액세스 토큰")
    refresh_token = Column(String(255), comment="암호화된 리프레시 토큰")
    token_expires_at = Column(
        TIMESTAMP(timezone=True), comment="토큰 만료 시각"
    )
    configuration = Column(
        JSONB, nullable=False, default=dict, comment="연동별 상세 설정"
    )
    mapping_rules = Column(
        JSONB, nullable=False, default=dict, comment="데이터 매핑 규칙"
    )
    sync_frequency = Column(
        String(20), nullable=False, default="HOURLY", comment="동기화 주기"
    )
    last_sync_at = Column(
        TIMESTAMP(timezone=True), comment="마지막 동기화 시각"
    )
    last_success_at = Column(
        TIMESTAMP(timezone=True), comment="마지막 성공 시각"
    )
    last_error_at = Column(
        TIMESTAMP(timezone=True), comment="마지막 오류 발생 시각"
    )
    last_error_message = Column(Text, comment="마지막 오류 메시지")
    consecutive_failures = Column(
        Integer, nullable=False, default=0, comment="연속 실패 횟수"
    )
    total_requests = Column(
        Integer, nullable=False, default=0, comment="총 요청 수"
    )
    successful_requests = Column(
        Integer, nullable=False, default=0, comment="성공 요청 수"
    )
    failed_requests = Column(
        Integer, nullable=False, default=0, comment="실패 요청 수"
    )
    rate_limit = Column(
        Integer, nullable=False, default=100, comment="분당 요청 제한"
    )
    daily_limit = Column(
        Integer, nullable=False, default=10000, comment="일일 요청 제한"
    )
    status = Column(
        String(20), nullable=False, default="ACTIVE", comment="연동 상태"
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    tenant = relationship("Tenant", back_populates="apis")
    webhooks = relationship("Webhook", back_populates="integration")

    def __repr__(self):
        return (
            f"<Api {self.api_name} type={self.api_type} status={self.status}>"
        )
