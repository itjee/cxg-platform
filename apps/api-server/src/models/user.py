import enum
from datetime import datetime
from typing import Optional, List
from sqlmodel import SQLModel, Field
import uuid


class UserStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
    LOCKED = "LOCKED"
    SUSPENDED = "SUSPENDED"


class User(SQLModel, table=True):
    __tablename__ = "users"
    __table_args__ = {"schema": "idam"}

    # Primary key
    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)

    # Audit fields
    created_at: datetime = Field(default_factory=datetime.now)
    created_by: Optional[uuid.UUID] = None
    updated_at: Optional[datetime] = None
    updated_by: Optional[uuid.UUID] = None

    # Authentication info
    username: str = Field(max_length=100, unique=True, index=True)
    password: Optional[str] = Field(max_length=255)  # encrypted password
    salt_key: Optional[str] = Field(max_length=100)

    # Basic info
    email: str = Field(max_length=255, unique=True, index=True)
    full_name: str = Field(max_length=100)

    # SSO info
    sso_provider: Optional[str] = Field(max_length=50)
    sso_subject: Optional[str] = Field(max_length=255)

    # MFA settings
    mfa_enabled: bool = Field(default=False)
    mfa_secret: Optional[str] = Field(max_length=255)
    backup_codes: Optional[str] = None  # JSON string instead of List

    # Account status
    status: UserStatus = Field(default=UserStatus.ACTIVE)
    is_system: bool = Field(default=False)

    # Security info
    last_login_at: Optional[datetime] = None
    last_login_ip: Optional[str] = None
    failed_login_attempts: int = Field(default=0)
    locked_until: Optional[datetime] = None
    password_changed_at: Optional[datetime] = None
    force_password_change: bool = Field(default=False)

    # Additional metadata
    timezone: str = Field(default="UTC", max_length=50)
    locale: str = Field(default="ko-KR", max_length=10)
    phone: Optional[str] = Field(max_length=20)
    department: Optional[str] = Field(max_length=100)
    position: Optional[str] = Field(max_length=100)
