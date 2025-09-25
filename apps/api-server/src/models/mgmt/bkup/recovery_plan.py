# 재해복구 계획 모델
# 시스템 장애 및 재해 상황에서의 복구 절차와 목표 정의
from sqlalchemy import ARRAY, TIMESTAMP, Boolean, Column, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID

from src.models.base import BaseModel


class RecoveryPlan(BaseModel):
    """
    bkup.recovery_plans: 재해복구 계획
    시스템 장애 및 재해 상황에서의 복구 절차와 목표 정의
    """

    __tablename__ = "recovery_plans"
    __table_args__ = {"schema": "bkup"}

    plan_name = Column(String(200), nullable=False, comment="복구 계획명")
    plan_type = Column(String(50), nullable=False, comment="계획 유형")
    description = Column(Text, comment="계획 상세 설명")
    recovery_scope = Column(String(50), nullable=False, comment="복구 범위")
    target_services = Column(ARRAY(Text), comment="복구 대상 서비스 목록")
    target_tenants = Column(ARRAY(UUID), comment="복구 대상 테넌트 ID 목록")
    recovery_time = Column(
        Integer, nullable=False, comment="복구 목표 시간 (분)"
    )
    recovery_point = Column(
        Integer, nullable=False, comment="복구 목표 시점 (분)"
    )
    recovery_steps = Column(
        JSONB, nullable=False, comment="전체 복구 단계별 절차"
    )
    automated_steps = Column(
        JSONB, nullable=False, default=list, comment="자동화된 복구 단계"
    )
    manual_steps = Column(
        JSONB, nullable=False, default=list, comment="수동 복구 단계"
    )
    required_backup_types = Column(
        ARRAY(Text), comment="필요한 백업 유형 목록"
    )
    minimum_backup_age = Column(
        Integer,
        nullable=False,
        default=24,
        comment="최소 백업 보관 시간 (시간)",
    )
    last_tested_at = Column(
        TIMESTAMP(timezone=True), comment="마지막 테스트 실행 일시"
    )
    test_frequency_days = Column(
        Integer, nullable=False, default=90, comment="테스트 주기 (일)"
    )
    test_results = Column(
        JSONB, nullable=False, default=dict, comment="마지막 테스트 결과"
    )
    primary_contact = Column(String(100), comment="1차 담당자 연락처")
    secondary_contact = Column(String(100), comment="2차 담당자 연락처")
    escalation_contacts = Column(
        ARRAY(Text), comment="에스컬레이션 담당자 목록"
    )
    approved_by = Column(String(100), comment="계획 승인자")
    approved_at = Column(TIMESTAMP(timezone=True), comment="계획 승인 일시")
    status = Column(
        String(20), nullable=False, default="DRAFT", comment="계획 상태"
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    def __repr__(self):
        return (
            f"<RecoveryPlan name={self.plan_name} "
            f"type={self.plan_type} status={self.status}>"
        )
