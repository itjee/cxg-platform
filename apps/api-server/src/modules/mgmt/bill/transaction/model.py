from sqlalchemy import Column, DateTime, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Transaction(BaseModel):
    """
    bill.transactions: 결제 거래 내역
    - 청구서별 결제, 환불, 실패 내역 등 관리
    """

    __tablename__ = "transactions"
    __table_args__ = {"schema": "bill"}

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="거래 대상 테넌트 ID",
    )
    invoice_id = Column(
        UUID(as_uuid=True),
        ForeignKey("bill.invoices.id", ondelete="SET NULL"),
        nullable=True,
        comment="연결된 청구서 ID",
    )
    transaction_no = Column(String(100), nullable=False, comment="거래 번호")
    transaction_type = Column(
        String(20),
        nullable=False,
        default="PAYMENT",
        comment="거래 유형(PAYMENT/REFUND 등)",
    )
    payment_gateway = Column(
        String(50), nullable=True, comment="결제 PG사 이름"
    )
    payment_gateway_id = Column(
        String(255), nullable=True, comment="PG사 거래 ID"
    )
    amount = Column(Numeric(18, 4), nullable=False, comment="거래 금액")
    currency = Column(
        String(3), nullable=False, default="KRW", comment="통화 코드"
    )
    exchange_rate = Column(Numeric(18, 6), nullable=True, comment="환율")
    payment_method = Column(String(50), nullable=False, comment="결제 수단")
    card_digits = Column(String(4), nullable=True, comment="카드 끝 4자리")
    processed_at = Column(
        DateTime(timezone=True), nullable=True, comment="처리 일시"
    )
    status = Column(
        String(20),
        nullable=False,
        default="PENDING",
        comment="거래 상태 (PENDING/COMPLETED/FAILED/CANCELLED/REFUNDED)",
    )
    failure_reason = Column(Text, nullable=True, comment="실패 사유")
    pg_transaction_id = Column(
        String(255), nullable=True, comment="PG사 거래 ID"
    )
    metadata = Column(JSONB, nullable=True, comment="추가 메타데이터")

    # Relationships
    tenant = relationship("Tenant", back_populates="transactions")
    invoice = relationship("Invoice", back_populates="transactions")
