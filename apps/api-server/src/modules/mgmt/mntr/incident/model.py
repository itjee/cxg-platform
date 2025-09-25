from sqlalchemy import ARRAY, Column, Integer, String, Text
from sqlalchemy.dialects.postgresql import TIMESTAMP, UUID

from src.models.base import BaseModel


class Incident(BaseModel):
    """
    mntr.incidents: 장애 및 인시던트 관리
    - 시스템 장애 발생, 영향 서비스/테넌트, 원인, 조치, 상태 등 기록
    """

    __tablename__ = "incidents"
    __table_args__ = {"schema": "mntr"}
    incident_no = Column(
        String(50), nullable=False, unique=True, comment="인시던트 고유번호"
    )
    title = Column(String(200), nullable=False, comment="장애/인시던트 제목")
    description = Column(Text, comment="상세 설명")
    severity = Column(
        String(20),
        nullable=False,
        default="MEDIUM",
        comment="심각도(LOW/MEDIUM/HIGH/CRITICAL)",
    )
    affected_services = Column(ARRAY(Text), comment="영향받은 서비스 목록")
    affected_tenants = Column(
        ARRAY(UUID(as_uuid=True)), comment="영향받은 테넌트 UUID 목록"
    )
    impact_scope = Column(
        String(20),
        nullable=False,
        default="PARTIAL",
        comment="영향 범위(PARTIAL/TOTAL)",
    )
    incident_start_time = Column(
        TIMESTAMP(timezone=True), nullable=False, comment="장애 시작 시각"
    )
    incident_end_time = Column(
        TIMESTAMP(timezone=True), comment="장애 종료 시각"
    )
    detection_time = Column(TIMESTAMP(timezone=True), comment="탐지 시각")
    resolution_time = Column(
        TIMESTAMP(timezone=True), comment="조치 완료 시각"
    )
    assigned_to = Column(String(100), comment="담당자")
    escalation_level = Column(Integer, default=1, comment="에스컬레이션 단계")
    resolution_summary = Column(Text, comment="조치 요약")
    root_cause = Column(Text, comment="장애 원인")
    preventive_actions = Column(Text, comment="재발 방지 조치")
    lessons_learned = Column(Text, comment="교훈 및 개선점")
    status = Column(
        String(20), nullable=False, default="OPEN", comment="인시던트 상태"
    )
