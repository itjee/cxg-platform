# API 키 관리 모델
# 사용자/서비스 계정별 API 키, 접근 범위, 사용 이력 등 관리
from sqlalchemy import (
    ARRAY,
    BigInteger,
    Column,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import INET, TIMESTAMP, UUID
from sqlalchemy.orm import relationship

from src.models.base import BaseModel


class ApiKey(BaseModel):
    """
    idam.api_keys: API 키 관리
    - 사용자/서비스 계정별 API 키, 접근 범위, 사용 이력 등 관리
    """

    __tablename__ = "api_keys"
    __table_args__ = {"schema": "idam"}

    key_id = Column(
        String(100), unique=True, nullable=False, comment="API 키 고유 식별자"
    )
    key_hash = Column(String(255), nullable=False, comment="API 키 해시값")
    key_name = Column(String(100), nullable=False, comment="API 키 이름")
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("idam.users.id"),
        nullable=False,
        comment="API 키 소유 사용자 ID",
    )
    tenant_context = Column(
        UUID(as_uuid=True), nullable=True, comment="테넌트 컨텍스트"
    )
    service_account = Column(
        String(100), nullable=True, comment="서비스 계정명"
    )
    scopes = Column(
        ARRAY(Text), nullable=True, comment="API 접근 권한 범위 목록"
    )
    allowed_ips = Column(
        ARRAY(INET), nullable=True, comment="허용된 접근 IP 목록"
    )
    rate_limit_per_minute = Column(
        Integer, default=1000, nullable=True, comment="분당 호출 제한"
    )
    rate_limit_per_hour = Column(
        Integer, default=10000, nullable=True, comment="시간당 호출 제한"
    )
    rate_limit_per_day = Column(
        Integer, default=100000, nullable=True, comment="일일 호출 제한"
    )
    status = Column(
        String(20),
        default="ACTIVE",
        nullable=False,
        comment="API 키 상태(ACTIVE/INACTIVE/REVOKED)",
    )
    expires_at = Column(
        TIMESTAMP(timezone=True), nullable=True, comment="API 키 만료 시각"
    )
    last_used_at = Column(
        TIMESTAMP(timezone=True), nullable=True, comment="마지막 사용 시각"
    )
    last_used_ip = Column(INET, nullable=True, comment="마지막 사용 IP")
    usage_count = Column(
        BigInteger, default=0, nullable=False, comment="API 키 사용 횟수"
    )

    # 관계
    user = relationship("User", back_populates="api_keys")

    def __repr__(self):
        return (
            f"<ApiKey name={self.key_name} "
            f"user_id={self.user_id} status={self.status}>"
        )


__all__ = ["ApiKey"]
