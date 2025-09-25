from sqlalchemy import Boolean, Column, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID

from src.models.base import BaseModel


class Template(BaseModel):
    """
    noti.templates: 알림/메시지 템플릿 관리
    - 이메일, SMS, 푸시, 인앱 등 다채널 템플릿 및 변수 관리
    """

    __tablename__ = "templates"
    __table_args__ = {"schema": "noti"}
    template_code = Column(
        String(100), unique=True, nullable=False, comment="템플릿 코드(고유)"
    )
    template_name = Column(String(200), nullable=False, comment="템플릿 이름")
    description = Column(Text, comment="템플릿 설명")
    category = Column(
        String(50), nullable=False, comment="카테고리(이메일/SMS/푸시/인앱 등)"
    )
    notify_type = Column(
        String(50), nullable=False, comment="알림 유형(이벤트/공지/경고 등)"
    )
    email_subject = Column(String(500), comment="이메일 제목")
    email_body = Column(Text, comment="이메일 본문")
    sms_message = Column(String(1000), comment="SMS 메시지 내용")
    push_title = Column(String(200), comment="푸시 제목")
    push_body = Column(String(500), comment="푸시 본문")
    in_app_title = Column(String(200), comment="인앱 알림 제목")
    in_app_message = Column(Text, comment="인앱 알림 본문")
    template_variables = Column(
        JSONB, nullable=False, default={}, comment="템플릿 변수(JSON)"
    )
    locale = Column(
        String(10), nullable=False, default="ko-KR", comment="언어/로케일 코드"
    )
    version = Column(
        String(20), nullable=False, default="1.0", comment="템플릿 버전"
    )
    previous_version_id = Column(
        UUID(as_uuid=True), comment="이전 버전 템플릿 UUID"
    )
    test_data = Column(
        JSONB, nullable=False, default={}, comment="테스트용 데이터(JSON)"
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
