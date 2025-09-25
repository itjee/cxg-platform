# 백업 실행 모델
from sqlalchemy import Column, DateTime, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class BackupExecution(BaseModel):
    """
    bkup.backup_executions: 백업 실행 기록
    """

    __tablename__ = "backup_executions"
    __table_args__ = {"schema": "bkup"}

    schedule_id = Column(
        UUID,
        ForeignKey("bkup.backup_schedules.id", ondelete="CASCADE"),
        nullable=False,
        comment="백업 스케줄 ID",
    )
    status = Column(
        String(20),
        nullable=False,
        default="PENDING",
        comment="실행 상태 (PENDING/RUNNING/COMPLETED/FAILED)",
    )
    started_at = Column(DateTime(timezone=True), comment="실행 시작 시간")
    completed_at = Column(DateTime(timezone=True), comment="실행 완료 시간")
    backup_size = Column(Numeric(18, 2), comment="백업 파일 크기 (MB)")
    backup_location = Column(String(500), comment="백업 파일 저장 위치")
    error_message = Column(Text, comment="오류 발생 시 메시지")
    metadata = Column(JSONB, comment="추가 메타데이터")

    # Relationships
    schedule = relationship("BackupSchedule", back_populates="executions")
