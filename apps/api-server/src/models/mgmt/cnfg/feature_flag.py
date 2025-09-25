# 기능 플래그 관리 모델
# 시스템/테넌트별 기능 활성화, 롤아웃, 조건부 적용 등 관리
from sqlalchemy import (
    ARRAY,
    Boolean,
    Column,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB, TIMESTAMP, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class FeatureFlag(BaseModel):
    """
    cnfg.feature_flags: 기능 플래그 관리
    - 시스템/테넌트별 기능 활성화, 롤아웃, 조건부 적용 등 관리
    """

    __tablename__ = "feature_flags"
    __table_args__ = (
        UniqueConstraint("flag_code", name="uk_feature_flags__flag_code"),
        {"schema": "cnfg"},
    )

    flag_code = Column(
        String(100), nullable=False, comment="기능 플래그 코드(고유키)"
    )
    flag_name = Column(String(200), nullable=False, comment="기능 플래그 이름")
    description = Column(Text, comment="기능 설명")
    enabled = Column(
        Boolean, nullable=False, default=False, comment="기능 활성화 여부"
    )
    rollout_rate = Column(Integer, default=0, comment="롤아웃 비율(%)")
    target_environment = Column(
        String(20),
        default="PRODUCTION",
        comment="적용 환경(PRODUCTION/STAGING/DEV)",
    )
    target_user_groups = Column(ARRAY(Text), comment="적용 대상 사용자 그룹")
    target_tenant_types = Column(ARRAY(Text), comment="적용 대상 테넌트 유형")
    excluded_tenants = Column(
        ARRAY(UUID(as_uuid=True)), comment="적용 제외 테넌트 목록"
    )
    activation_conditions = Column(
        JSONB, default={}, comment="활성화 조건(JSON)"
    )
    deactivation_conditions = Column(
        JSONB, default={}, comment="비활성화 조건(JSON)"
    )
    scheduled_enable_at = Column(
        TIMESTAMP(timezone=True), comment="예약 활성화 시각"
    )
    scheduled_disable_at = Column(
        TIMESTAMP(timezone=True), comment="예약 비활성화 시각"
    )
    usage_count = Column(Integer, default=0, comment="기능 사용 횟수")
    error_count = Column(Integer, default=0, comment="오류 발생 횟수")
    last_used_at = Column(TIMESTAMP(timezone=True), comment="마지막 사용 시각")
    owner_team = Column(String(100), comment="담당 팀")
    contact_email = Column(String(255), comment="담당자 이메일")
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    tenant_features = relationship(
        "TenantFeature", back_populates="feature_flag"
    )

    def __repr__(self):
        return f"<FeatureFlag {self.flag_code} enabled={self.enabled}>"
