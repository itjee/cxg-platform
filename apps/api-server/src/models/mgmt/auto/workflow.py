# 자동화 워크플로우 모델
# 시스템 운영, 테넌트 관리 등의 자동화 프로세스 정의
from sqlalchemy import (
    ARRAY,
    TIMESTAMP,
    Boolean,
    Column,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
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
        Integer, default=1, comment="최대 동시 실행 수"
    )
    execution_timeout = Column(
        Integer, default=60, comment="실행 타임아웃 (분)"
    )
    retry_policy = Column(JSONB, default=dict, comment="재시도 정책 (JSON)")
    required_permissions = Column(
        ARRAY(Text), comment="필요한 권한 목록 (배열)"
    )
    execution_context = Column(
        String(50), default="SYSTEM", comment="실행 컨텍스트"
    )
    notify_success = Column(
        Boolean, default=False, comment="성공 시 알림 여부"
    )
    notify_failure = Column(Boolean, default=True, comment="실패 시 알림 여부")
    notification_channels = Column(
        ARRAY(Text), comment="알림 채널 목록 (배열)"
    )
    total_executions = Column(Integer, default=0, comment="총 실행 횟수")
    successful_executions = Column(
        Integer, default=0, comment="성공 실행 횟수"
    )
    failed_executions = Column(Integer, default=0, comment="실패 실행 횟수")
    last_execution_at = Column(
        TIMESTAMP(timezone=True), comment="마지막 실행 시각"
    )
    version = Column(String(20), default="1.0", comment="워크플로우 버전")
    previous_version_id = Column(
        UUID,
        ForeignKey("auto.workflows.id", ondelete="SET NULL"),
        comment="이전 버전 워크플로우 ID",
    )
    enabled = Column(Boolean, default=True, comment="워크플로우 활성화 여부")
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 여부"
    )

    # 관계
    previous_version = relationship("Workflow", remote_side=[BaseModel.id])
    executions = relationship("Execution", back_populates="workflow")

    def __repr__(self):
        return (
            f"<Workflow name={self.workflow_name} "
            f"version={self.version} enabled={self.enabled}>"
        )
