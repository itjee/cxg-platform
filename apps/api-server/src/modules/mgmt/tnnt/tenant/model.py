"""
테넌트 모델 모듈
"""

# 테넌트 마스터 정보 관리 모델
# 사업자, 주소, 요금제, 상태, 추가데이터 등 관리
from sqlalchemy import CHAR, Boolean, Column, Date, Integer, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Tenant(BaseModel):
    """
    tnnt.tenants: 테넌트 마스터 정보 관리
    - 사업자, 주소, 요금제, 상태, 추가데이터 등 관리
    """

    __tablename__ = "tenants"
    __table_args__ = {"schema": "tnnt"}

    tenant_code = Column(
        String(20), nullable=False, comment="테넌트 식별 코드"
    )
    tenant_name = Column(String(100), nullable=False, comment="테넌트(회사)명")
    tenant_type = Column(
        String(20),
        nullable=False,
        default="STANDARD",
        comment="테넌트 유형 (TRIAL/STANDARD/PREMIUM/ENTERPRISE)",
    )
    business_no = Column(String(20), nullable=True, comment="사업자등록번호")
    business_name = Column(String(200), nullable=True, comment="상호(법인명)")
    business_type = Column(
        CHAR(1),
        nullable=True,
        default="C",
        comment="사업자구분 (C:법인, S:개인)",
    )
    ceo_name = Column(String(50), nullable=True, comment="대표자명")
    business_kind = Column(String(100), nullable=True, comment="업태")
    business_item = Column(String(100), nullable=True, comment="종목")
    postcode = Column(String(10), nullable=True, comment="우편번호")
    address1 = Column(String(100), nullable=True, comment="주소1")
    address2 = Column(String(100), nullable=True, comment="주소2")
    phone_no = Column(String(20), nullable=True, comment="대표 전화번호")
    employee_count = Column(
        Integer, nullable=False, default=0, comment="직원 수"
    )
    start_date = Column(Date, nullable=False, comment="계약 시작일")
    close_date = Column(Date, nullable=True, comment="계약 종료일")
    timezone = Column(
        String(50), nullable=True, default="Asia/Seoul", comment="시간대"
    )
    locale = Column(
        String(10), nullable=True, default="ko-KR", comment="로케일"
    )
    currency = Column(
        String(3), nullable=True, default="KRW", comment="기본 통화"
    )
    extra_data = Column(
        JSONB, nullable=True, default=dict, comment="추가 메타정보 (JSON)"
    )
    status = Column(
        String(20), nullable=False, default="ACTIVE", comment="테넌트 상태"
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    subscriptions = relationship("Subscription", back_populates="tenant")
    onboardings = relationship("Onboarding", back_populates="tenant")
    users = relationship("TenantUser", back_populates="tenant")
    tenant_roles = relationship("TenantRole", back_populates="tenant")
    # Temporarily removed to fix relationship issues
    # tickets = relationship("Ticket", back_populates="tenant")
    # feedbacks = relationship("Feedback", back_populates="tenant")
    # tenant_stats = relationship("TenantStat", back_populates="tenant")
    # usage_stats = relationship("UsageStat", back_populates="tenant")
    # system_metrics = relationship("SystemMetric", back_populates="tenant")

    def __repr__(self):
        return (
            f"<Tenant {self.tenant_code} "
            f"name={self.tenant_name} status={self.status}>"
        )


__all__ = ["Tenant"]
