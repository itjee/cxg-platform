from sqlalchemy import (
    Boolean,
    Column,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Workflow(BaseModel):
    """
    auto.workflows: 자동화 워크플로우
    시스템 운영, 테넌트 관리 등의 자동화 프로세스 정의
    """

    __tablename__ = "workflows"
    __table_args__ = {"schema": "auto"}

    workflow_name = Column(
        String(200), nullable=False, comment="워크플로우 이름"
    )
    workflow_type = Column(
        String(50), nullable=False, comment="워크플로우 유형"
    )
    description = Column(Text, comment="워크플로우 설명")
    category = Column(
        String(50), nullable=False, comment="워크플로우 카테고리"
    )
    trigger_type = Column(String(50), nullable=False, comment="트리거 유형")
    trigger_config = Column(
        JSONB, nullable=False, comment="트리거 상세 설정 (JSON)"
    )
    workflow_definition = Column(
        JSONB, nullable=False, comment="워크플로우 단계별 작업 정의 (JSON)"
    )
    input_schema = Column(
        JSONB, default=dict, comment="입력 데이터 스키마 (JSON)"
    )
    output_schema = Column(
        JSONB, default=dict, comment="출력 데이터 스키마 (JSON)"
    )
    max_concurrent_executions = Column(
        Integer, nullable=True, default=1, comment="최대 동시 실행 수"
    )
    is_active = Column(
        Boolean, nullable=False, default=True, comment="워크플로우 활성화 여부"
    )

    # Relationships
    tenant = relationship("Tenant", back_populates="workflows")
    executions = relationship("WorkflowExecution", back_populates="workflow")
