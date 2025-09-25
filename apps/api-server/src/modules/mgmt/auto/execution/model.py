from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Execution(BaseModel):
    """
    auto.executions: 워크플로우 실행 이력
    각 워크플로우 실행의 상세 기록 및 결과
    """

    __tablename__ = "executions"
    __table_args__ = {"schema": "auto"}

    workflow_id = Column(
        UUID,
        ForeignKey("auto.workflows.id", ondelete="CASCADE"),
        nullable=False,
        comment="실행된 워크플로우 ID",
    )
    tenant_id = Column(
        UUID,
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        comment="테넌트별 실행 대상 ID",
    )
    execution_id = Column(
        String(100),
        unique=True,
        nullable=False,
        comment="워크플로우 실행 고유 식별자",
    )
    trigger_source = Column(String(100), comment="트리거 소스")
    triggered_by = Column(String(100), comment="트리거 실행자")
    input_data = Column(
        JSONB, default=dict, comment="워크플로우 입력 데이터 (JSON)"
    )
    output_data = Column(JSONB, comment="워크플로우 출력 데이터 (JSON)")
    status = Column(
        String(20),
        nullable=False,
        default="PENDING",
        comment="실행 상태 (PENDING/RUNNING/COMPLETED/FAILED/CANCELLED)",
    )
    started_at = Column(DateTime(timezone=True), comment="실행 시작 시간")
    completed_at = Column(DateTime(timezone=True), comment="실행 완료 시간")
    error_message = Column(Text, comment="오류 발생 시 상세 메시지")

    # Relationships
    workflow = relationship("Workflow", back_populates="executions")
