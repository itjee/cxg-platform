# 리소스 사용량 메트릭 집계 모델
# 테넌트별 인프라 리소스별 사용량, 단위, 측정시각, 집계주기 등 관리
from sqlalchemy import Column, ForeignKey, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class ResourceUsage(BaseModel):
    """
    ifra.resource_usages: 리소스 사용량 메트릭 집계
    - 테넌트별 인프라 리소스별 사용량, 단위, 측정시각, 집계주기 등 관리
    """

    __tablename__ = "resource_usages"
    __table_args__ = {"schema": "ifra"}

    resource_id = Column(
        UUID(as_uuid=True),
        ForeignKey("ifra.resources.id", ondelete="CASCADE"),
        nullable=False,
        comment="대상 리소스 고유 ID",
    )
    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=True,
        comment="테넌트 ID",
    )
    metric_name = Column(
        String(50),
        nullable=False,
        comment="측정 메트릭명(예: CPU_USAGE, STORAGE_USED)",
    )
    metric_value = Column(Numeric(18, 4), nullable=False, comment="측정값")
    metric_unit = Column(
        String(20), nullable=False, comment="측정 단위(GB, %, 개수 등)"
    )
    measure_time = Column(
        String,
        nullable=False,
        comment="측정 시각(ISO8601 문자열, 필요시 DateTime으로 변경)",
    )
    summary_period = Column(
        String(20),
        nullable=False,
        default="HOURLY",
        comment="집계 주기(HOURLY/DAILY 등)",
    )

    # 관계
    resource = relationship("Resource", back_populates="usages")
    tenant = relationship("Tenant", back_populates="resource_usages")

    def __repr__(self):
        return (
            f"<ResourceUsage resource={self.resource_id} "
            f"metric={self.metric_name} value={self.metric_value}>"
        )
