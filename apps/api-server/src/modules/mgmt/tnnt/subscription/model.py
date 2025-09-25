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


class Subscription(BaseModel):
    """
    tnnt.subscriptions: 테넌트 구독/요금제 관리
    - 요금제, 기간, 한도, 금액, 자동갱신 등 관리
    """

    __tablename__ = "subscriptions"
    __table_args__ = {"schema": "tnnt"}
    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="테넌트 UUID",
    )
    plan_id = Column(
        UUID(as_uuid=True),
        ForeignKey("bill.plans.id"),
        nullable=False,
        comment="요금제(플랜) UUID",
    )
    start_date = Column(Date, nullable=False, comment="구독 시작일")
    close_date = Column(Date, nullable=True, comment="구독 종료일")
    billing_cycle = Column(
        String(20),
        nullable=False,
        default="MONTHLY",
        comment="청구 주기(MONTHLY/QUARTERLY/YEARLY)",
    )
    max_users = Column(
        Integer, nullable=True, default=50, comment="최대 허용 사용자 수"
    )
    max_storage = Column(
        Integer, nullable=True, default=100, comment="최대 스토리지 용량(GB)"
    )
    max_api_calls = Column(
        Integer,
        nullable=True,
        default=10000,
        comment="월간 최대 API 호출 횟수",
    )
    base_amount = Column(Numeric(18, 4), nullable=False, comment="기본 요금")
