# 기능 플래그 모델
from sqlalchemy import Boolean, Column, DateTime, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSONB

from src.models.base import BaseModel


class FeatureFlag(BaseModel):
    """
    cnfg.feature_flags: 기능 플래그 관리
    """

    __tablename__ = "feature_flags"
    __table_args__ = {"schema": "cnfg"}

    name = Column(
        String(255), nullable=False, unique=True, comment="기능 플래그 이름"
    )
    description = Column(Text, comment="기능 설명")
    is_enabled = Column(
        Boolean, nullable=False, default=False, comment="기능 활성화 여부"
    )
    rollout_percentage = Column(
        Numeric(5, 2), default=0, comment="점진적 배포 비율 (0-100%)"
    )
    target_groups = Column(JSONB, comment="대상 그룹 설정 (JSON)")
    conditions = Column(JSONB, comment="조건부 활성화 규칙 (JSON)")
    start_date = Column(DateTime(timezone=True), comment="기능 시작 일시")
    end_date = Column(DateTime(timezone=True), comment="기능 종료 일시")
    environment = Column(
        String(20), default="ALL", comment="적용 환경 (DEV/STAGING/PROD/ALL)"
    )
