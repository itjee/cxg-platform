from sqlalchemy import (
    TIMESTAMP,
    Column,
    Date,
    ForeignKey,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Compliance(BaseModel):
    """
    audt.compliances: 컴플라이언스 보고서
    GDPR, SOX, HIPAA 등 각종 규정 준수 보고서의 생성, 승인, 관리
    """

    __tablename__ = "compliances"
    __table_args__ = {"schema": "audt"}

    report_type = Column(
        String(50),
        nullable=False,
        comment="보고서 유형 (GDPR/SOX/HIPAA/ISO27001/CUSTOM)",
    )
    report_name = Column(String(200), nullable=False, comment="보고서 이름")
    start_date = Column(
        Date, nullable=False, comment="보고서 대상 기간 시작일"
    )
    close_date = Column(
        Date, nullable=False, comment="보고서 대상 기간 종료일"
    )
    generated_at = Column(
        TIMESTAMP(timezone=True),
        nullable=False,
        comment="보고서 실제 생성 일시",
    )
    generated_by_id = Column(
        UUID,
        ForeignKey("tnnt.users.id", ondelete="SET NULL"),
        nullable=True,
        comment="보고서 생성 담당자 UUID",
    )
    scope = Column(
        String(100),
        nullable=False,
        comment="규정 준수 범위 (COMPANY_WIDE/DEPARTMENT/PROJECT)",
    )
    findings = Column(Text, comment="규정 준수 검토 결과")
    recommendations = Column(Text, comment="개선 권장사항")
    status = Column(
        String(20),
        nullable=False,
        default="DRAFT",
        comment="보고서 상태 (DRAFT/REVIEW/APPROVED/REJECTED)",
    )

    # Relationships
    tenant = relationship("Tenant", back_populates="compliance_reports")
    generated_by = relationship(
        "User", back_populates="generated_compliance_reports"
    )
