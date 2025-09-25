# 시스템 성능 메트릭 관리 모델
# 서비스/인스턴스별 CPU, 메모리, 트래픽 등 주요 지표 기록
from sqlalchemy import (
    Boolean,
    Column,
    ForeignKey,
    Numeric,
    String,
)
from sqlalchemy.dialects.postgresql import TIMESTAMP, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class SystemMetric(BaseModel):
    """
    mntr.system_metrics: 시스템 성능 메트릭 관리
    - 서비스/인스턴스별 CPU, 메모리, 트래픽 등 주요 지표 기록 및 임계치 관리
    """

    __tablename__ = "system_metrics"
    __table_args__ = {"schema": "mntr"}

    metric_category = Column(
        String(50),
        nullable=False,
        comment="메트릭 카테고리(CPU/MEMORY/TRAFFIC 등)",
    )
    metric_name = Column(
        String(100),
        nullable=False,
        comment="메트릭 이름(예: cpu_usage, memory_free)",
    )
    metric_value = Column(Numeric(18, 4), nullable=False, comment="측정값")
    metric_unit = Column(
        String(20), nullable=False, comment="단위(%, MB, req/s 등)"
    )
    service_name = Column(String(100), comment="대상 서비스 이름")
    instance_id = Column(String(100), comment="인스턴스/서버 ID")
    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="SET NULL"),
        nullable=True,
        comment="테넌트 UUID(멀티테넌트용)",
    )
    measure_time = Column(
        TIMESTAMP(timezone=True), nullable=False, comment="측정 시각"
    )
    summary_period = Column(
        String(20), default="MINUTE", comment="집계 주기(MINUTE/HOUR/DAY 등)"
    )
    warning_threshold = Column(Numeric(18, 4), comment="경고 임계치")
    critical_threshold = Column(Numeric(18, 4), comment="치명 임계치")
    alert_triggered = Column(
        Boolean, default=False, comment="알림 트리거 여부"
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
    tenant = relationship("Tenant", back_populates="system_metrics")

    def __repr__(self):
        return f"<SystemMetric {self.metric_name} value={self.metric_value}>"
