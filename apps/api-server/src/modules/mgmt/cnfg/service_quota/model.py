# 서비스 할당량 모델
from sqlalchemy import (
    Boolean,
    Column,
    ForeignKey,
    Numeric,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class ServiceQuota(BaseModel):
    """
    cnfg.service_quotas: 테넌트별 서비스 사용 할당량
    """

    __tablename__ = "service_quotas"
    __table_args__ = {"schema": "cnfg"}

    tenant_id = Column(
        UUID,
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="테넌트 ID",
    )
    resource_type = Column(
        String(100),
        nullable=False,
        comment="리소스 유형 (API_CALLS/STORAGE/USERS/PROJECTS)",
    )
    limit_value = Column(
        Numeric(18, 2), nullable=False, comment="할당량 한계값"
    )
    used_value = Column(Numeric(18, 2), default=0, comment="현재 사용량")
    unit = Column(String(20), comment="단위 (COUNT/MB/GB/TB)")
    period_type = Column(
        String(20),
        nullable=False,
        default="MONTHLY",
        comment="기간 유형 (DAILY/WEEKLY/MONTHLY/YEARLY)",
    )
    is_soft_limit = Column(
        Boolean, default=False, comment="소프트 리미트 여부 (경고만 발생)"
    )
    notification_threshold = Column(
        Numeric(5, 2), default=80, comment="알림 발생 임계치 (%)"
    )
    description = Column(Text, comment="할당량 설명")

    # Relationships
    tenant = relationship("Tenant", back_populates="service_quotas")
