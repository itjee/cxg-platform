from sqlalchemy import (
    TIMESTAMP,
    Column,
    ForeignKey,
    String,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID

from src.models.base import BaseModel


class Api(BaseModel):
    """
    intg.apis: 외부 시스템 연동 API 마스터
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
