# 복구 계획 모델
from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class RecoveryPlan(BaseModel):
    """
    bkup.recovery_plans: 재해 복구 계획
    """

    __tablename__ = "recovery_plans"
    __table_args__ = {"schema": "bkup"}

    tenant_id = Column(
        UUID,
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="테넌트 ID",
    )
    name = Column(String(255), nullable=False, comment="복구 계획 이름")
    description = Column(Text, comment="복구 계획 설명")
    priority = Column(
        String(10),
        nullable=False,
        default="MEDIUM",
        comment="우선순위 (LOW/MEDIUM/HIGH/CRITICAL)",
    )
    rto_minutes = Column(Integer, comment="복구 목표 시간 (분)")
    rpo_minutes = Column(Integer, comment="데이터 손실 허용 시간 (분)")
    recovery_steps = Column(JSONB, comment="복구 단계 (JSON)")
    is_active = Column(
        Boolean, nullable=False, default=True, comment="계획 활성화 여부"
    )
    last_tested_at = Column(
        DateTime(timezone=True), comment="마지막 테스트 일시"
    )

    # Relationships
    tenant = relationship("Tenant", back_populates="recovery_plans")
