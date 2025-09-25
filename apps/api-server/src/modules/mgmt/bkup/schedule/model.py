# 백업 스케줄 모델
from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class BackupSchedule(BaseModel):
    """
    bkup.backup_schedules: 백업 스케줄
    """

    __tablename__ = "backup_schedules"
    __table_args__ = {"schema": "bkup"}

    tenant_id = Column(
        UUID,
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="테넌트 ID",
    )
    name = Column(String(255), nullable=False, comment="백업 스케줄 이름")
    description = Column(Text, comment="백업 스케줄 설명")
    backup_type = Column(
        String(20),
        nullable=False,
        comment="백업 유형 (FULL/INCREMENTAL/DIFFERENTIAL)",
    )
    cron_expression = Column(
        String(100), nullable=False, comment="스케줄 Cron 표현식"
    )
    retention_days = Column(
        Integer, nullable=False, default=30, comment="백업 보존 기간 (일)"
    )
    is_active = Column(
        Boolean, nullable=False, default=True, comment="스케줄 활성화 여부"
    )
    storage_location = Column(String(500), comment="백업 저장 위치")
    compression_enabled = Column(
        Boolean, default=True, comment="압축 사용 여부"
    )
    encryption_enabled = Column(
        Boolean, default=False, comment="암호화 사용 여부"
    )
    notification_settings = Column(JSONB, comment="알림 설정 (JSON)")
    next_run_at = Column(
        DateTime(timezone=True), comment="다음 실행 예정 시간"
    )
    last_run_at = Column(DateTime(timezone=True), comment="마지막 실행 시간")

    # Relationships
    tenant = relationship("Tenant", back_populates="backup_schedules")
    executions = relationship("BackupExecution", back_populates="schedule")
