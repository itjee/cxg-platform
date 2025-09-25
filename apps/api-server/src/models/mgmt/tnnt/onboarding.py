# 테넌트 온보딩 프로세스 관리 모델
# 단계별 진행상태, 오류, 재시도, 데이터 등 관리
from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB, TIMESTAMP, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Onboarding(BaseModel):
    """
    tnnt.onboardings: 테넌트 온보딩 프로세스 관리
    - 단계별 진행상태, 오류, 재시도, 데이터 등 관리
    """

    __tablename__ = "onboardings"
    __table_args__ = {"schema": "tnnt"}

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="테넌트 UUID",
    )
    step_name = Column(String(50), nullable=False, comment="온보딩 단계명")
    step_order = Column(Integer, nullable=False, comment="단계 실행 순서")
    step_status = Column(
        String(20),
        nullable=False,
        default="PENDING",
        comment="단계 상태 (PENDING/IN_PROGRESS/COMPLETED/FAILED/...)",
    )
    started_at = Column(
        TIMESTAMP(timezone=True), nullable=True, comment="단계 시작 일시"
    )
    completed_at = Column(
        TIMESTAMP(timezone=True), nullable=True, comment="단계 완료 일시"
    )
    error_message = Column(Text, nullable=True, comment="실패 시 오류 메시지")
    retry_count = Column(
        Integer, nullable=True, default=0, comment="재시도 횟수"
    )
    step_data = Column(
        JSONB,
        nullable=True,
        default=dict,
        comment="각 단계별 추가 데이터 (JSON)",
    )
    status = Column(
        String(20),
        nullable=False,
        default="ACTIVE",
        comment="온보딩 레코드 상태",
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계: 테넌트와 연결
    tenant = relationship("Tenant", back_populates="onboardings")

    def __repr__(self):
        return (
            f"<Onboarding tenant_id={self.tenant_id} "
            f"step={self.step_name} status={self.step_status}>"
        )
