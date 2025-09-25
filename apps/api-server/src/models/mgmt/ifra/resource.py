# 인프라 리소스 마스터 모델
# 테넌트별 클라우드/온프레미스 리소스 정보, 비용, 상태 등 관리
from sqlalchemy import (
    Boolean,
    Column,
    ForeignKey,
    Integer,
    Numeric,
    String,
)
from sqlalchemy.dialects.postgresql import CHAR, JSONB, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Resource(BaseModel):
    """
    ifra.resources: 인프라 리소스 마스터
    - 테넌트별 클라우드/온프레미스 리소스 정보, 비용, 상태 등 관리
    """

    __tablename__ = "resources"
    __table_args__ = {"schema": "ifra"}

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="SET NULL"),
        nullable=True,
        comment="소유 테넌트 ID",
    )
    resource_type = Column(
        String(50), nullable=False, comment="리소스 유형(예: VM, DB, STORAGE)"
    )
    resource_name = Column(String(100), nullable=False, comment="리소스 이름")
    resource_arn = Column(String(500), comment="클라우드 ARN 또는 고유 식별자")
    resource_id = Column(String(100), nullable=False, comment="리소스 고유 ID")
    region = Column(
        String(50),
        nullable=False,
        default="ap-northeast-2",
        comment="리소스 지역(Region)",
    )
    availability_zone = Column(
        String(50), comment="가용 영역(Availability Zone)"
    )
    instance_type = Column(String(50), comment="인스턴스 타입(예: t3.medium)")
    cpu_cores = Column(Integer, comment="CPU 코어 수")
    memory_size = Column(Integer, comment="메모리 크기(MB 또는 GB)")
    storage_size = Column(Integer, comment="스토리지 크기(GB)")
    hourly_cost = Column(Numeric(18, 4), comment="시간당 비용")
    monthly_cost = Column(Numeric(18, 4), comment="월간 비용")
    currency = Column(
        CHAR(3),
        nullable=False,
        default="USD",
        comment="통화 코드(USD, KRW 등)",
    )
    tags = Column(JSONB, default={}, comment="리소스 태그(JSON)")
    configuration = Column(JSONB, default={}, comment="리소스 상세 설정(JSON)")
    status = Column(
        String(20),
        nullable=False,
        default="PROVISIONING",
        comment="리소스 상태(PROVISIONING/ACTIVE/DELETED 등)",
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    tenant = relationship("Tenant", back_populates="resources")
    usages = relationship("ResourceUsage", back_populates="resource")

    def __repr__(self):
        return (
            f"<Resource {self.resource_name} "
            f"type={self.resource_type} "
            f"status={self.status}>"
        )
