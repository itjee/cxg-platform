from sqlalchemy import Boolean, Column, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB

from src.models.base import BaseModel


class HealthCheck(BaseModel):
    """
    mntr.health_checks: 시스템 헬스체크 관리
    - 서비스/API 엔드포인트별 상태, 응답시간, 오류, 체크데이터 등 모니터링
    """

    __tablename__ = "health_checks"
    __table_args__ = {"schema": "mntr"}
    service_name = Column(
        String(100), nullable=False, comment="대상 서비스/엔드포인트 이름"
    )
    api_endpoint = Column(String(500), comment="API 엔드포인트 URL")
    check_type = Column(
        String(50), nullable=False, comment="체크 유형(PING/HTTP/DB 등)"
    )
    response_time = Column(Integer, comment="응답 시간(ms)")
    error_message = Column(Text, comment="오류 메시지")
    timeout_duration = Column(Integer, default=5000, comment="타임아웃(ms)")
    expected_status_code = Column(Integer, comment="예상 응답 상태코드")
    check_data = Column(JSONB, default={}, comment="추가 체크 데이터(JSON)")
    status = Column(
        String(20), nullable=False, comment="헬스체크 상태(OK/FAIL/WARNING 등)"
    )
    deleted = Column(
        Boolean, nullable=False, default=False, comment="논리적 삭제 플래그"
    )

    def __repr__(self):
        return f"<HealthCheck {self.service_name} type={self.check_type} status={self.status}>"
