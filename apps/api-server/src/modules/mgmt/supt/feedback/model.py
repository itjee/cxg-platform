from sqlalchemy import Column, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID

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
