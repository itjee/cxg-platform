from datetime import datetime
from typing import Optional
import uuid

from pydantic import BaseModel, EmailStr
from src.models.user import UserStatus


class UserBase(BaseModel):
    username: str
    email: EmailStr
    full_name: str
    phone: Optional[str] = None
    department: Optional[str] = None
    position: Optional[str] = None


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    username: Optional[str] = None
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    department: Optional[str] = None
    position: Optional[str] = None
    status: Optional[UserStatus] = None


class UserInDB(UserBase):
    id: uuid.UUID
    password: Optional[str]
    salt_key: Optional[str]
    status: UserStatus
    created_at: datetime
    updated_at: Optional[datetime]
    last_login_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class User(UserBase):
    id: uuid.UUID
    status: UserStatus
    created_at: datetime
    last_login_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    email: Optional[str] = None
