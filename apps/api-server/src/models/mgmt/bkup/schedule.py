# 백업 스케줄 정의 모델
# 자동 백업 작업의 주기적 실행 설정 및 관리
from sqlalchemy import (
    ARRAY,
    TIMESTAMP,
    Boolean,
    Column,
    Integer,
    String,
    Text,
    Time,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Schedule(BaseModel):
    """
    bkup.schedules: 백업 스케줄 정의
    자동 백업 작업의 주기적 실행 설정 및 관리
    """

    __tablename__ = "schedules"
    __table_args__ = {"schema": "bkup"}

    schedule_name = Column(String(200), nullable=False, comment="스케줄 이름")
    backup_type = Column(String(50), nullable=False, comment="백업 유형")
    target_scope = Column(
        String(50),
        nullable=False,
        default="ALL_TENANTS",
        comment="백업 대상 범위",
    )
    target_tenants = Column(ARRAY(UUID), comment="특정 테넌트 대상 ID 배열")
    target_databases = Column(ARRAY(Text), comment="대상 데이터베이스 목록")
    frequency = Column(String(20), nullable=False, comment="실행 주기")
    schedule_time = Column(Time, nullable=False, comment="실행 시각")
    schedule_days = Column(ARRAY(Integer), comment="실행 요일 또는 날짜 배열")
    timezone = Column(
        String(50), nullable=False, default="Asia/Seoul", comment="시간대 설정"
    )
    backup_format = Column(
        String(20), nullable=False, default="COMPRESSED", comment="백업 형식"
    )
    retention_days = Column(
        Integer, nullable=False, default=30, comment="백업 보관 기간 (일)"
    )
    max_parallel_jobs = Column(
        Integer,
        nullable=False,
        default=1,
        comment="동시 실행 가능한 백업 작업 수",
    )
    notify_success = Column(
        Boolean, nullable=False, default=False, comment="성공 시 알림 여부"
    )
    notify_failure = Column(
        Boolean, nullable=False, default=True, comment="실패 시 알림 여부"
    )
    notify_emails = Column(ARRAY(Text), comment="알림 받을 이메일 목록")
    next_run_at = Column(
        TIMESTAMP(timezone=True), comment="다음 실행 예정 시각"
    )
    last_run_at = Column(TIMESTAMP(timezone=True), comment="마지막 실행 시각")
    enabled = Column(
        Boolean, nullable=False, default=True, comment="스케줄 활성화 여부"
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    executions = relationship("Execution", back_populates="schedule")

    def __repr__(self):
        return (
            f"<Schedule name={self.schedule_name} "
            f"type={self.backup_type} enabled={self.enabled}>"
        )
