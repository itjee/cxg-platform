# 스케줄된 작업 모델
# 정기적으로 실행되는 시스템 작업 및 유지보수 스케줄
from sqlalchemy import ARRAY, TIMESTAMP, Boolean, Column, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB

from src.models.base import BaseModel


class Task(BaseModel):
    """
    auto.tasks: 스케줄된 작업
    정기적으로 실행되는 시스템 작업 및 유지보수 스케줄
    """

    __tablename__ = "tasks"
    __table_args__ = {"schema": "auto"}

    task_name = Column(
        String(200), nullable=False, comment="스케줄된 작업 이름"
    )
    task_type = Column(String(50), nullable=False, comment="작업 유형")
    description = Column(Text, comment="작업 설명")
    schedule_expression = Column(
        String(100), nullable=False, comment="CRON 표현식"
    )
    timezone = Column(String(50), default="Asia/Seoul", comment="실행 시간대")
    command = Column(String(1000), comment="실행할 명령어")
    parameters = Column(
        JSONB, default=dict, comment="작업 실행 매개변수 (JSON)"
    )
    working_directory = Column(String(500), comment="작업 실행 디렉터리 경로")
    environment_variables = Column(
        JSONB, default=dict, comment="환경 변수 설정 (JSON)"
    )
    max_execution_time = Column(
        Integer, default=60, comment="최대 실행 시간 (분)"
    )
    max_instances = Column(
        Integer, default=1, comment="최대 동시 실행 인스턴스 수"
    )
    notify_success = Column(
        Boolean, default=False, comment="성공 시 알림 여부"
    )
    notify_failure = Column(Boolean, default=True, comment="실패 시 알림 여부")
    notify_emails = Column(ARRAY(Text), comment="알림 이메일 주소 목록")
    next_run_at = Column(
        TIMESTAMP(timezone=True), comment="다음 실행 예정 시각"
    )
    last_run_at = Column(TIMESTAMP(timezone=True), comment="마지막 실행 시각")
    last_run_status = Column(String(20), comment="마지막 실행 상태")
    last_run_duration = Column(Integer, comment="마지막 실행 시간 (초)")
    total_runs = Column(Integer, default=0, comment="총 실행 횟수")
    successful_runs = Column(Integer, default=0, comment="성공 실행 횟수")
    failed_runs = Column(Integer, default=0, comment="실패 실행 횟수")
    enabled = Column(Boolean, default=True, comment="작업 활성화 여부")
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 여부"
    )

    def __repr__(self):
        return (
            f"<Task name={self.task_name} "
            f"type={self.task_type} enabled={self.enabled}>"
        )
