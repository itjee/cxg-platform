from sqlalchemy import Column, Date, DateTime, ForeignKey, Numeric, String
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
        Numeric(18, 4), nullable=True, default=0, comment="세금"
    )
    total_amount = Column(Numeric(18, 4), nullable=False, comment="총 금액")
    status = Column(
        String(20),
        nullable=False,
        default="DRAFT",
        comment="청구서 상태 (DRAFT/SENT/PAID/OVERDUE/CANCELLED)",
    )
    due_date = Column(Date, nullable=False, comment="결제 기한")
    paid_at = Column(DateTime(timezone=True), comment="결제 일시")

    # Relationships
    tenant = relationship("Tenant", back_populates="invoices")
    plan = relationship("BillingPlan", back_populates="invoices")
