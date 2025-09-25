# 테넌트 구독/요금제 관리 모델
# 요금제, 기간, 한도, 금액, 자동갱신 등 관리
from sqlalchemy import (
    CHAR,
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
    user_amount = Column(
        Numeric(18, 4), nullable=True, default=0, comment="사용자당 추가 요금"
    )
    currency = Column(
        CHAR(3), nullable=False, default="KRW", comment="통화 단위"
    )
    auto_renewal = Column(
        Boolean, nullable=True, default=True, comment="자동 갱신 여부"
    )
    noti_renewal = Column(
        Boolean, nullable=True, default=False, comment="갱신 알림 발송 여부"
    )
    status = Column(
        String(20), nullable=False, default="ACTIVE", comment="구독 상태"
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    tenant = relationship("Tenant", back_populates="subscriptions")

    def __repr__(self):
        return (
            f"<Subscription tenant_id={self.tenant_id} "
            f"plan_id={self.plan_id} status={self.status}>"
        )
