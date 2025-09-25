# 서비스 할당량 관리
# 테넌트별 서비스 사용 한도, 경고/임계치, 초과 요금 등 관리
from sqlalchemy import (
    Boolean,
    Column,
    Date,
    ForeignKey,
    Integer,
    Numeric,
    String,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class ServiceQuota(BaseModel):
    """
    cnfg.service_quotas: 서비스 할당량 관리
    - 테넌트별 서비스 사용 한도, 경고/임계치, 초과 요금 등 관리
    """

    __tablename__ = "service_quotas"
    __table_args__ = {"schema": "cnfg"}

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="대상 테넌트 ID",
    )
    quota_type = Column(
        String(50), nullable=False, comment="할당량 유형(API/STORAGE/USER 등)"
    )
    quota_limit = Column(Integer, nullable=False, comment="할당량 한도 값")
    quota_used = Column(Integer, default=0, comment="현재 사용량")
    quota_period = Column(
        String(20),
        nullable=False,
        default="MONTHLY",
        comment="할당량 기간(MONTHLY/DAILY 등)",
    )
    start_date = Column(Date, nullable=False, comment="할당량 적용 시작일")
    close_date = Column(Date, nullable=False, comment="할당량 적용 종료일")
    warning_threshold_rate = Column(
        Integer, default=80, comment="경고 임계치 비율(%)"
    )
    critical_threshold_rate = Column(
        Integer, default=95, comment="임계 임계치 비율(%)"
    )
    warning_alert_sent = Column(
        Boolean, default=False, comment="경고 알림 발송 여부"
    )
    critical_alert_sent = Column(
        Boolean, default=False, comment="임계 알림 발송 여부"
    )
    allow_overage = Column(
        Boolean, default=False, comment="초과 사용 허용 여부"
    )
    overage_unit_charge = Column(
        Numeric(18, 4), default=0, comment="초과 단위당 요금"
    )
    max_overage_rate = Column(
        Integer, default=0, comment="최대 초과 허용 비율(%)"
    )
    status = Column(
        String(20),
        nullable=False,
        default="ACTIVE",
        comment="할당량 상태(ACTIVE/INACTIVE)",
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    tenant = relationship("Tenant", back_populates="service_quotas")

    def __repr__(self):
        return (
            f"<ServiceQuota tenant={self.tenant_id} "
            f"type={self.quota_type} "
            f"limit={self.quota_limit}>"
        )
