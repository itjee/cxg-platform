import enum
from datetime import datetime
from typing import Optional
from sqlmodel import SQLModel, Field
import uuid


class TenantStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
    SUSPENDED = "SUSPENDED"


class TenantPlan(str, enum.Enum):
    BASIC = "Basic"
    PRO = "Pro"
    ENTERPRISE = "Enterprise"


class Tenant(SQLModel, table=True):
    __tablename__ = "tenants"
    __table_args__ = {"schema": "tnnt"}

    id: uuid.UUID = Field(default_factory=uuid.uuid4, primary_key=True)
    name: str = Field(max_length=255)
    domain: str = Field(max_length=255, unique=True, index=True)
    status: TenantStatus = Field(default=TenantStatus.ACTIVE)
    plan: TenantPlan = Field(default=TenantPlan.BASIC)
    users_count: int = Field(default=0)
    last_activity: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: Optional[datetime] = None