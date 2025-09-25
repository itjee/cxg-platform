# 워크플로우 실행 이력 모델
# 각 워크플로우 실행의 상세 기록 및 결과
from sqlalchemy import (
    ARRAY,
    TIMESTAMP,
    Boolean,
    Column,
    ForeignKey,
    Integer,
    Numeric,
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
    output_data = Column(
        JSONB, default=dict, comment="워크플로우 출력 데이터 (JSON)"
    )
    status = Column(
        String(20),
        nullable=False,
        default="PENDING",
        comment="워크플로우 실행 상태",
    )
    current_step = Column(
        String(100), comment="현재 실행 중인 워크플로우 단계"
    )
    completed_steps = Column(
        ARRAY(Text), comment="완료된 워크플로우 단계 목록"
    )
    failed_step = Column(String(100), comment="실패한 워크플로우 단계명")
    started_at = Column(
        TIMESTAMP(timezone=True), comment="워크플로우 실행 시작 시각"
    )
    completed_at = Column(
        TIMESTAMP(timezone=True), comment="워크플로우 실행 완료 시각"
    )
    duration = Column(Integer, comment="총 실행 시간 (초)")
    error_message = Column(Text, comment="실행 오류 메시지")
    error_details = Column(
        JSONB, default=dict, comment="상세 오류 정보 (JSON)"
    )
    retry_count = Column(Integer, default=0, comment="재시도 횟수")
    execution_logs = Column(
        JSONB, default=list, comment="워크플로우 실행 로그 (JSON 배열)"
    )
    cpu_usage = Column(Numeric(18, 4), comment="CPU 사용 시간 (초)")
    memory_usage = Column(Numeric(18, 4), comment="메모리 사용량 (MB)")
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 여부"
    )

    # 관계
    workflow = relationship("Workflow", back_populates="executions")
    tenant = relationship("Tenant", back_populates="executions")

    def __repr__(self):
        return (
            f"<Execution id={self.execution_id} "
            f"workflow_id={self.workflow_id} status={self.status}>"
        )
