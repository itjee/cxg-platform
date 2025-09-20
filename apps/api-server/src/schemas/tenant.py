from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from src.models.tenant import TenantStatus, TenantPlan

class TenantBase(BaseModel):
    name: str
    domain: str
    status: TenantStatus = TenantStatus.ACTIVE
    plan: TenantPlan = TenantPlan.BASIC

class TenantCreate(TenantBase):
    pass

class TenantUpdate(BaseModel):
    name: Optional[str] = None
    domain: Optional[str] = None
    status: Optional[TenantStatus] = None
    plan: Optional[TenantPlan] = None

class TenantInDB(TenantBase):
    id: str
    users_count: int
    last_activity: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class Tenant(TenantBase):
    id: str
    users_count: int
    last_activity: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True