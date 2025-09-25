from sqlalchemy import (
    Column,
    Date,
    ForeignKey,
    Integer,
    Numeric,
    String,
)
from sqlalchemy.dialects.postgresql import UUID

from src.models.base import BaseModel


class TenantStat(BaseModel):
    """
    stat.tenant_stats: 테넌트별 통계/분석 데이터
    - 사용자, API, AI, 스토리지, 만족도 등 주요 지표 집계
    """

    __tablename__ = "tenant_stats"
    __table_args__ = {"schema": "stat"}
    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="테넌트 UUID",
    )
    analysis_date = Column(Date, nullable=False, comment="분석 기준 일자")
    analysis_period = Column(
        String(20),
        nullable=False,
        default="DAILY",
        comment="분석 주기(DAILY/WEEKLY/MONTHLY 등)",
    )
    active_users_count = Column(Integer, default=0, comment="활성 사용자 수")
    new_users_count = Column(Integer, default=0, comment="신규 가입자 수")
    login_count = Column(Integer, default=0, comment="로그인 횟수")
    avg_session_duration = Column(
        Numeric(18, 4), default=0, comment="평균 세션 지속시간(초)"
    )
    api_calls_count = Column(Integer, default=0, comment="API 호출 횟수")
    uploads_count = Column(Integer, default=0, comment="파일 업로드 건수")
    executions_count = Column(
        Integer, default=0, comment="백업/자동화 등 실행 건수"
    )
    ai_requests_count = Column(Integer, default=0, comment="AI 요청 건수")
    used_storage = Column(
        Numeric(18, 4), default=0, comment="사용 스토리지(MB)"
    )
    grow_storage = Column(
        Numeric(18, 4), default=0, comment="스토리지 증가량(MB)"
    )
    avg_response_time = Column(
        Numeric(18, 4), default=0, comment="평균 응답시간(ms)"
    )
    error_rate = Column(Numeric(5, 2), default=0, comment="에러율(%)")
