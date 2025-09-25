# 시스템 설정 모델
from sqlalchemy import Boolean, Column, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Configuration(BaseModel):
    """
    cnfg.configurations: 시스템 전체 설정
    """

    __tablename__ = "configurations"
    __table_args__ = {"schema": "cnfg"}

    key = Column(String(255), nullable=False, unique=True, comment="설정 키")
    value = Column(Text, comment="설정 값")
    value_type = Column(
        String(20),
        nullable=False,
        default="STRING",
        comment="값 타입 (STRING/INTEGER/BOOLEAN/JSON)",
    )
    description = Column(Text, comment="설정 설명")
    category = Column(String(100), comment="설정 카테고리")
    is_public = Column(
        Boolean, nullable=False, default=False, comment="공개 설정 여부"
    )
    is_system = Column(
        Boolean, nullable=False, default=False, comment="시스템 필수 설정 여부"
    )
    validation_rules = Column(JSONB, comment="유효성 검증 규칙 (JSON)")
    updated_by_id = Column(
        UUID,
        ForeignKey("idam.users.id", ondelete="SET NULL"),
        nullable=True,
        comment="설정 변경자 ID",
    )

    # Relationships
    updated_by = relationship("User", back_populates="updated_configurations")
