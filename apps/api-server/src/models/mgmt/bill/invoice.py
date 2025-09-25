# 청구서 관리 모델
# 테넌트별 요금 청구 내역, 결제 상태, 사용량 등 관리
from sqlalchemy import Boolean, Column, ForeignKey, Integer, Numeric, String
from sqlalchemy.dialects.postgresql import TIMESTAMP, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Invoice(BaseModel):
    """
    bill.invoices: 청구서 관리
    - 테넌트별 요금 청구 내역, 결제 상태, 사용량 등 관리
    """

    __tablename__ = "invoices"
    __table_args__ = {"schema": "bill"}

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="청구 대상 테넌트 ID",
    )
    subscription_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.subscriptions.id", ondelete="SET NULL"),
        nullable=True,
        comment="구독/요금제 ID",
    )
    invoice_no = Column(String(50), nullable=False, comment="청구서 번호")
    invoice_date = Column(
        TIMESTAMP(timezone=False), nullable=False, comment="청구서 발행일"
    )
    due_date = Column(
        TIMESTAMP(timezone=False), nullable=False, comment="납기일"
    )
    start_date = Column(
        TIMESTAMP(timezone=False), nullable=False, comment="청구 기간 시작일"
    )
    close_date = Column(
        TIMESTAMP(timezone=False), nullable=False, comment="청구 기간 종료일"
    )
    base_amount = Column(Numeric(18, 4), nullable=False, comment="기본 요금")
    usage_amount = Column(
        Numeric(18, 4),
        nullable=True,
        default=0,
        comment="사용량 기반 추가 요금",
    )
    discount_amount = Column(
        Numeric(18, 4), nullable=True, default=0, comment="할인 금액"
    )
    tax_amount = Column(
        Numeric(18, 4), nullable=True, default=0, comment="세금 금액"
    )
    total_amount = Column(
        Numeric(18, 4), nullable=False, comment="총 청구 금액"
    )
    currency = Column(
        String(3), nullable=False, default="KRW", comment="통화 코드"
    )
    user_count = Column(Integer, nullable=False, comment="청구 기준 사용자 수")
    used_storage = Column(
        Numeric(18, 4), nullable=True, default=0, comment="사용한 스토리지(GB)"
    )
    api_calls = Column(
        Integer, nullable=True, default=0, comment="API 호출 횟수"
    )
    paid_at = Column(
        TIMESTAMP(timezone=True), nullable=True, comment="결제 완료 시각"
    )
    payment_method = Column(String(50), nullable=True, comment="결제 수단")
    status = Column(
        String(20),
        nullable=False,
        default="PENDING",
        comment="청구서 상태(PENDING/PAID/FAILED)",
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    tenant = relationship("Tenant", back_populates="invoices")
    subscription = relationship("Subscription", back_populates="invoices")
    transactions = relationship("Transaction", back_populates="invoice")

    def __repr__(self):
        return (
            f"<Invoice no={self.invoice_no} "
            f"tenant_id={self.tenant_id} status={self.status}>"
        )
