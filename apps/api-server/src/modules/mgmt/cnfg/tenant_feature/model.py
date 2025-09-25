# 테넌트 기능 모델
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class TenantFeature(BaseModel):
    """
    cnfg.tenant_features: 테넌트별 기능 활성화 설정
    """

    __tablename__ = "tenant_features"
    __table_args__ = {"schema": "cnfg"}

    tenant_id = Column(
        UUID,
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="테넌트 ID",
    )
    feature_name = Column(String(255), nullable=False, comment="기능 이름")
    is_enabled = Column(
        Boolean, nullable=False, default=True, comment="기능 활성화 여부"
    )
    configuration = Column(JSONB, comment="기능별 설정 (JSON)")
    enabled_at = Column(DateTime(timezone=True), comment="기능 활성화 일시")
    disabled_at = Column(DateTime(timezone=True), comment="기능 비활성화 일시")
    expires_at = Column(DateTime(timezone=True), comment="기능 만료 일시")
    notes = Column(Text, comment="기능 설정 메모")

    # Relationships
    tenant = relationship("Tenant", back_populates="tenant_features")
