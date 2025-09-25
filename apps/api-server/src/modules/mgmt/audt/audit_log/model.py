# 보안 감사 로그 모델
# 모든 보안 관련 이벤트와 중요한 비즈니스 액션의 상세 기록
from sqlalchemy import Column, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class AuditLog(BaseModel):
    """
    audt.audit_logs: 보안 감사 로그
    모든 보안 관련 이벤트와 중요한 비즈니스 액션의 상세 기록
    """

    __tablename__ = "audit_logs"
    __table_args__ = {"schema": "audt"}

    tenant_id = Column(
        UUID,
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        comment="테넌트별 이벤트인 경우 테넌트 ID",
    )
    user_id = Column(
        UUID,
        ForeignKey("tnnt.users.id", ondelete="SET NULL"),
        nullable=True,
        comment="사용자별 이벤트인 경우 사용자 ID",
    )
    event_type = Column(
        String(50),
        nullable=False,
        comment="이벤트 유형 (LOGIN/LOGOUT/API_CALL/DATA_ACCESS/ADMIN_ACTION)",
    )
    event_category = Column(
        String(50),
        nullable=False,
        comment=(
            "이벤트 분류 "
            "(AUTHENTICATION/AUTHORIZATION/DATA_MODIFICATION/SYSTEM_CHANGE)"
        ),
    )
    description = Column(Text, nullable=False, comment="이벤트 상세 설명")
    source_ip = Column(String(45), comment="클라이언트 IP 주소")
    user_agent = Column(Text, comment="브라우저/클라이언트 정보")
    session_id = Column(String(255), comment="세션 ID")
    resource_type = Column(String(50), comment="리소스 유형")
    resource_id = Column(String(255), comment="접근한 리소스 식별자")
    action_performed = Column(String(50), comment="수행된 작업")
    result = Column(
        String(20), nullable=False, comment="작업 결과 (SUCCESS/FAILURE/ERROR)"
    )
    metadata_json = Column(JSONB, comment="추가 메타데이터 (JSON 형식)")

    # Relationships
    tenant = relationship("Tenant", back_populates="audit_logs")
    user = relationship("User", back_populates="audit_logs")
