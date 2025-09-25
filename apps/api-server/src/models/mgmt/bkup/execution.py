# 백업 작업 관리 모델
# 시스템 및 테넌트 데이터 백업 작업 실행 이력 및 상태 관리
from sqlalchemy import (
    TIMESTAMP,
    BigInteger,
    Boolean,
    Column,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Execution(BaseModel):
    """
    bkup.executions: 백업 작업 관리
    시스템 및 테넌트 데이터 백업 작업 실행 이력 및 상태 관리
    """

    __tablename__ = "executions"
    __table_args__ = {"schema": "bkup"}

    backup_type = Column(String(50), nullable=False, comment="백업 유형")
    tenant_id = Column(
        UUID,
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        comment="특정 테넌트 백업 대상 ID",
    )
    backup_database = Column(String(100), comment="대상 데이터베이스명")
    backup_schema = Column(String(100), comment="대상 스키마명")
    backup_name = Column(String(200), nullable=False, comment="백업 작업명")
    backup_method = Column(
        String(50), nullable=False, default="AUTOMATED", comment="백업 방식"
    )
    backup_format = Column(
        String(20), nullable=False, default="COMPRESSED", comment="백업 형식"
    )
    schedule_id = Column(
        UUID, ForeignKey("bkup.schedules.id"), comment="백업 스케줄 참조 ID"
    )
    scheduled_at = Column(TIMESTAMP(timezone=True), comment="예약 실행 시각")
    started_at = Column(TIMESTAMP(timezone=True), comment="백업 시작 일시")
    completed_at = Column(TIMESTAMP(timezone=True), comment="백업 완료 일시")
    duration = Column(Integer, comment="백업 소요 시간 (초)")
    backup_size = Column(BigInteger, comment="백업 파일 크기 (바이트)")
    backup_file = Column(String(500), comment="백업 파일 저장 경로")
    backup_checksum = Column(String(255), comment="백업 파일 무결성 체크섬")
    original_size = Column(BigInteger, comment="원본 데이터 크기 (바이트)")
    compression_rate = Column(Numeric(5, 2), comment="압축률 (백분율)")
    status = Column(
        String(20), nullable=False, default="PENDING", comment="백업 작업 상태"
    )
    error_message = Column(Text, comment="실패 시 오류 메시지")
    retry_count = Column(
        Integer, nullable=False, default=0, comment="재시도 횟수"
    )
    retention_days = Column(
        Integer, nullable=False, default=30, comment="백업 보관 기간 (일)"
    )
    expires_at = Column(TIMESTAMP(timezone=True), comment="백업 만료 일시")
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    tenant = relationship("Tenant", back_populates="backup_executions")
    schedule = relationship("Schedule", back_populates="executions")

    def __repr__(self):
        return (
            f"<Execution name={self.backup_name} "
            f"type={self.backup_type} status={self.status}>"
        )
