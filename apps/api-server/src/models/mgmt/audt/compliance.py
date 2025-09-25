# 컴플라이언스 보고서 모델
# GDPR, SOX, HIPAA 등 각종 규정 준수 보고서의 생성, 승인, 관리
from sqlalchemy import (
    ARRAY,
    TIMESTAMP,
    Boolean,
    Column,
    Date,
    ForeignKey,
    Integer,
    String,
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
        String(50),
        nullable=False,
        default="ALL_TENANTS",
        comment="보고서 적용 범위",
    )
    tenant_ids = Column(
        ARRAY(UUID), comment="특정 테넌트 대상인 경우 테넌트 ID 배열"
    )
    compliance_status = Column(
        String(20), nullable=False, comment="컴플라이언스 상태"
    )
    findings_count = Column(Integer, default=0, comment="발견된 총 이슈 수")
    critical_count = Column(Integer, default=0, comment="심각한 이슈 수")
    file_path = Column(String(500), comment="보고서 파일 저장 경로")
    file_size = Column(Integer, comment="파일 크기 (bytes)")
    file_type = Column(String(20), default="PDF", comment="파일 형식")
    approved_at = Column(TIMESTAMP(timezone=True), comment="보고서 승인 일시")
    approved_by = Column(String(100), comment="승인자")
    status = Column(
        String(20), nullable=False, default="DRAFT", comment="보고서 상태"
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    generated_by = relationship("TenantUser", back_populates="compliances")

    def __repr__(self):
        return (
            f"<Compliance name={self.report_name} "
            f"type={self.report_type} status={self.status}>"
        )
