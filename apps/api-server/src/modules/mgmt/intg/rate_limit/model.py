from sqlalchemy import TIMESTAMP, Column, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID

from src.models.base import BaseModel


class RateLimit(BaseModel):
    """
    intg.rate_limits: API 호출 제한
    테넌트, 사용자, IP별 API 사용량 제한 및 모니터링
    """

    __tablename__ = "rate_limits"
    __table_args__ = {"schema": "intg"}
    tenant_id = Column(
        UUID,
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        comment="테넌트별 제한 대상 ID",
    )
    user_id = Column(
        UUID,
        ForeignKey("tnnt.users.id", ondelete="CASCADE"),
        comment="사용자별 제한 대상 ID",
    )
    api_key_id = Column(
        UUID,
        ForeignKey("tnnt.api_keys.id", ondelete="CASCADE"),
        comment="API 키별 제한 대상 ID",
    )
    client_ip = Column(String(45), comment="IP별 제한 대상 주소")
    limit_type = Column(
        String(50),
        nullable=False,
        comment="제한 유형 (분당/시간당/일당 요청 수)",
    )
    limit_value = Column(Integer, nullable=False, comment="제한 임계값")
    window_size = Column(
        Integer, nullable=False, comment="시간 윈도우 크기 (초)"
    )
    current_usage = Column(Integer, default=0, comment="현재 윈도우 내 사용량")
    window_start = Column(
        TIMESTAMP(timezone=True), default=None, comment="현재 윈도우 시작 시각"
    )
    action_on_exceed = Column(
        String(20),
        nullable=False,
        default="BLOCK",
        comment="제한 초과 시 조치 방법",
    )
    burst_allowance = Column(
        Integer, default=0, comment="버스트 트래픽 허용량"
    )
    last_access_at = Column(
        TIMESTAMP(timezone=True), comment="마지막 API 접근 시각"
    )
    total_requests = Column(Integer, default=0, comment="총 요청 수")
    blocked_requests = Column(Integer, default=0, comment="차단된 요청 수")
