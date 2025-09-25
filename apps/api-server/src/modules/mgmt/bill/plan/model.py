from sqlalchemy import Boolean, Column, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Plan(BaseModel):
    """
    bill.plans: 요금제 마스터
    - 서비스별 요금제, 가격, 기능 제한 등 관리
    """

    __tablename__ = "plans"
    __table_args__ = {"schema": "bill"}

    plan_code = Column(String(50), nullable=False, comment="요금제 코드")
    plan_name = Column(String(100), nullable=False, comment="요금제 이름")
    plan_type = Column(
        String(20),
        nullable=False,
        default="STANDARD",
        comment="요금제 유형(STANDARD/ENTERPRISE 등)",
    )
    description = Column(Text, nullable=True, comment="요금제 설명")
    base_price = Column(Numeric(18, 4), nullable=False, comment="기본 가격")
    user_price = Column(
        Numeric(18, 4), nullable=True, default=0, comment="사용자 추가 가격"
    )
    currency = Column(
        String(3), nullable=False, default="KRW", comment="통화 코드"
    )
    billing_cycle = Column(
        String(20),
        nullable=False,
        default="MONTHLY",
        comment="청구 주기(MONTHLY/ANNUAL)",
    )
    max_users = Column(
        Integer, nullable=True, default=50, comment="최대 사용자 수"
    )
    max_storage = Column(
        Integer, nullable=True, default=100, comment="최대 스토리지(GB)"
    )
    max_api_calls = Column(
        Integer, nullable=True, default=10000, comment="최대 API 호출 횟수"
    )
    features = Column(
        JSONB, nullable=True, default={}, comment="요금제별 제공 기능(JSON)"
    )
    is_active = Column(
        Boolean, nullable=False, default=True, comment="요금제 활성화 여부"
    )
    sort_order = Column(Integer, nullable=True, default=0, comment="정렬 순서")

    # Relationships
    subscriptions = relationship("TenantSubscription", back_populates="plan")
    invoices = relationship("Invoice", back_populates="plan")
