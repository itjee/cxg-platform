# 테넌트별 사용량 요약 통계 모델
# 사용자, API, AI, 스토리지, 매출, 이탈 등 주요 KPI 집계
from sqlalchemy import (
    Boolean,
    Column,
    Date,
    ForeignKey,
    Integer,
    Numeric,
    String,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class UsageStat(BaseModel):
    """
    stat.usage_stats: 테넌트별 사용량 요약 통계
    - 사용자, API, AI, 스토리지, 매출, 이탈 등 주요 KPI 집계
    """

    __tablename__ = "usage_stats"
    __table_args__ = {"schema": "stat"}

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        comment="테넌트 UUID",
    )
    summary_date = Column(Date, nullable=False, comment="요약 기준 일자")
    summary_type = Column(
        String(20),
        nullable=False,
        comment="요약 유형(DAILY/WEEKLY/MONTHLY 등)",
    )
    total_users = Column(Integer, default=0, comment="전체 사용자 수")
    active_users = Column(Integer, default=0, comment="활성 사용자 수")
    new_users = Column(Integer, default=0, comment="신규 가입자 수")
    churned_users = Column(Integer, default=0, comment="이탈 사용자 수")
    total_logins = Column(Integer, default=0, comment="전체 로그인 횟수")
    total_api_calls = Column(Integer, default=0, comment="전체 API 호출 횟수")
    total_ai_requests = Column(Integer, default=0, comment="전체 AI 요청 건수")
    total_storage_used = Column(
        Numeric(18, 4), default=0, comment="총 사용 스토리지(MB)"
    )
    revenue = Column(Numeric(18, 4), default=0, comment="매출액")
    churn_rate = Column(Numeric(5, 2), default=0, comment="이탈률(%)")
    acquisition_cost = Column(
        Numeric(18, 4), default=0, comment="고객 획득 비용"
    )
    lifetime_value = Column(
        Numeric(18, 4), default=0, comment="고객 생애가치(LTV)"
    )
    avg_response_time = Column(
        Numeric(18, 4), default=0, comment="평균 응답시간(ms)"
    )
    error_count = Column(Integer, default=0, comment="에러 발생 건수")
    uptime_minutes = Column(Integer, default=0, comment="가동 시간(분)")
    downtime_minutes = Column(Integer, default=0, comment="다운타임(분)")
    status = Column(
        String(20),
        nullable=False,
        default="ACTIVE",
        comment="상태(ACTIVE/INACTIVE 등)",
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    tenant = relationship("Tenant", back_populates="usage_stats")

    def __repr__(self):
        return (
            f"<UsageStat tenant={self.tenant_id} "
            f"date={self.summary_date} "
            f"status={self.status}>"
        )
