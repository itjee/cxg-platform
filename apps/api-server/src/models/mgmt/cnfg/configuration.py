# 시스템 환경설정 관리 모델
# 카테고리/코드별 환경설정 값, 유효성, 적용 범위 등 관리
import datetime

from sqlalchemy import (
    Boolean,
    Column,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB, TIMESTAMP

from src.models.base import BaseModel


class Configuration(BaseModel):
    """
    cnfg.configurations: 시스템 환경설정 관리
    - 카테고리/코드별 환경설정 값, 유효성, 적용 범위 등 관리
    """

    __tablename__ = "configurations"
    __table_args__ = (
        UniqueConstraint(
            "config_category",
            "config_code",
            "environment",
            name="uk_configurations__category_key_env",
        ),
        {"schema": "cnfg"},
    )

    config_category = Column(
        String(50),
        nullable=False,
        comment="설정 카테고리(예: SYSTEM, BILLING, SECURITY)",
    )
    config_code = Column(
        String(200), nullable=False, comment="설정 코드(고유키)"
    )
    config_value = Column(Text, comment="설정 값(문자열, JSON 등)")
    config_type = Column(
        String(20),
        nullable=False,
        default="STRING",
        comment="설정 값 타입(STRING/INT/BOOL/JSON)",
    )
    description = Column(Text, comment="설정 설명")
    default_value = Column(Text, comment="기본값")
    required = Column(Boolean, default=False, comment="필수 여부")
    validation_rules = Column(
        JSONB, default={}, comment="유효성 검사 규칙(JSON)"
    )
    environment = Column(
        String(20),
        nullable=False,
        default="PRODUCTION",
        comment="적용 환경(PRODUCTION/STAGING/DEV)",
    )
    applies_to_all = Column(
        Boolean, default=True, comment="전체 테넌트 적용 여부"
    )
    previous_value = Column(Text, comment="이전 설정 값")
    changed_by = Column(String(100), comment="변경자")
    change_reason = Column(Text, comment="변경 사유")
    start_time = Column(
        TIMESTAMP(timezone=True),
        default=datetime.datetime.utcnow,
        comment="설정 적용 시작일",
    )
    close_time = Column(TIMESTAMP(timezone=True), comment="설정 적용 종료일")
    status = Column(
        String(20),
        nullable=False,
        default="ACTIVE",
        comment="설정 상태(ACTIVE/INACTIVE)",
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    def __repr__(self):
        return (
            f"<Configuration {self.config_code} "
            f"env={self.environment} status={self.status}>"
        )
