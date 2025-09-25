# 보안 정책 관리 모델
# 시스템 전반의 보안 정책 정의, 버전 관리, 승인 프로세스
from sqlalchemy import (
    ARRAY,
    TIMESTAMP,
    Boolean,
    Column,
    Date,
    ForeignKey,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Policy(BaseModel):
    """
    audt.policies: 보안 정책 관리
    시스템 전반의 보안 정책 정의, 버전 관리, 승인 프로세스
    """

    __tablename__ = "policies"
    __table_args__ = {"schema": "audt"}

    policy_name = Column(String(200), nullable=False, comment="정책 이름")
    policy_type = Column(String(50), nullable=False, comment="정책 유형")
    policy_category = Column(String(50), nullable=False, comment="정책 분류")
    description = Column(Text, comment="정책 설명")
    rules = Column(JSONB, nullable=False, comment="정책 규칙 (JSON)")
    apply_to_all_tenants = Column(
        Boolean, default=True, comment="전체 테넌트 적용 여부"
    )
    tenant_ids = Column(
        ARRAY(UUID), comment="특정 테넌트만 적용하는 경우 테넌트 ID 배열"
    )
    effective_date = Column(Date, nullable=False, comment="정책 시행 시작일")
    expiry_date = Column(Date, comment="정책 만료일")
    enforcement_level = Column(
        String(20), nullable=False, default="MANDATORY", comment="시행 수준"
    )
    version = Column(String(20), nullable=False, comment="정책 버전")
    previous_version_id = Column(
        UUID,
        ForeignKey("audt.policies.id", ondelete="SET NULL"),
        comment="이전 버전 참조",
    )
    approved_at = Column(TIMESTAMP(timezone=True), comment="정책 승인 일시")
    approved_by = Column(String(100), comment="승인자")
    status = Column(
        String(20), nullable=False, default="DRAFT", comment="정책 상태"
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    previous_version = relationship("Policy", remote_side=[BaseModel.id])

    def __repr__(self):
        return (
            f"<Policy name={self.policy_name} "
            f"version={self.version} status={self.status}>"
        )
