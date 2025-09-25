# 테넌트별 기능 플래그 오버라이드 모델
# 테넌트별 기능 활성화/비활성화, 승인 이력 등 관리
import datetime

from sqlalchemy import (
    Boolean,
    Column,
    ForeignKey,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import TIMESTAMP, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class TenantFeature(BaseModel):
    """
    cnfg.tenant_features: 테넌트별 기능 플래그 오버라이드
    - 테넌트별 기능 활성화/비활성화, 승인 이력 등 관리
    """

    __tablename__ = "tenant_features"
    __table_args__ = (
        UniqueConstraint(
            "tenant_id",
            "feature_flag_id",
            name="uk_tenant_features__tenant_feature",
        ),
        {"schema": "cnfg"},
    )

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="대상 테넌트 ID",
    )
    feature_flag_id = Column(
        UUID(as_uuid=True),
        ForeignKey("cnfg.feature_flags.id", ondelete="CASCADE"),
        nullable=False,
        comment="적용 기능 플래그 ID",
    )
    enabled = Column(Boolean, nullable=False, comment="기능 활성화 여부")
    reason = Column(String(500), comment="오버라이드 사유")
    start_time = Column(
        TIMESTAMP(timezone=True),
        nullable=False,
        default=datetime.datetime.utcnow,
        comment="적용 시작 시각",
    )
    close_time = Column(TIMESTAMP(timezone=True), comment="적용 종료 시각")
    approved_by = Column(UUID(as_uuid=True), comment="승인자 ID")
    approved_at = Column(TIMESTAMP(timezone=True), comment="승인 시각")
    approval_reason = Column(Text, comment="승인 사유")
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    tenant = relationship("Tenant", back_populates="tenant_features")
    feature_flag = relationship(
        "FeatureFlag", back_populates="tenant_features"
    )

    def __repr__(self):
        return (
            f"<TenantFeature tenant={self.tenant_id} "
            f"flag={self.feature_flag_id} "
            f"enabled={self.enabled}>"
        )
