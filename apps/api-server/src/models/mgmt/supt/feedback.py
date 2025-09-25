# 고객 피드백 관리 모델
# 기능/제품별 평가, 긴급도, 검토/조치 상태 등 기록
from sqlalchemy import (
    Boolean,
    Column,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, TIMESTAMP, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class Feedback(BaseModel):
    """
    supt.feedbacks: 고객 피드백 관리
    - 기능/제품별 평가, 긴급도, 검토/조치 상태 등 기록
    """

    __tablename__ = "feedbacks"
    __table_args__ = {"schema": "supt"}

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenants.id", ondelete="CASCADE"),
        nullable=False,
        comment="테넌트 UUID",
    )
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tnnt.tenant_users.id", ondelete="SET NULL"),
        nullable=True,
        comment="사용자 UUID",
    )
    feedback_type = Column(
        String(50),
        nullable=False,
        comment="피드백 유형(기능/버그/개선/문의 등)",
    )
    title = Column(String(200), nullable=False, comment="피드백 제목")
    description = Column(Text, nullable=False, comment="피드백 상세 내용")
    overall_rating = Column(Integer, comment="전체 만족도 점수(1~5)")
    feature_ratings = Column(JSONB, default={}, comment="기능별 만족도(JSON)")
    product_area = Column(String(50), comment="관련 제품/영역")
    urgency = Column(
        String(20), default="MEDIUM", comment="긴급도(LOW/MEDIUM/HIGH)"
    )
    reviewed_by = Column(String(100), comment="검토 담당자")
    reviewed_at = Column(TIMESTAMP(timezone=True), comment="검토 완료 시각")
    implement_priority = Column(Integer, comment="조치 우선순위")
    implement_status = Column(
        String(20),
        default="SUBMITTED",
        comment="조치 상태(SUBMITTED/IN_PROGRESS/COMPLETED 등)",
    )
    response_message = Column(Text, comment="응답 메시지")
    response_sent_at = Column(
        TIMESTAMP(timezone=True), comment="응답 발송 시각"
    )
    status = Column(
        String(20),
        nullable=False,
        default="ACTIVE",
        comment="상태(ACTIVE/INACTIVE 등)",
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    # 관계
    tenant = relationship("Tenant", back_populates="feedbacks")
    user = relationship("TenantUser", back_populates="feedbacks")

    def __repr__(self):
        return (
            f"<Feedback tenant={self.tenant_id} "
            f"type={self.feedback_type} "
            f"status={self.status}>"
        )
