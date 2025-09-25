import uuid
from datetime import datetime

from sqlalchemy import Column
from sqlalchemy.dialects.postgresql import TIMESTAMP, UUID
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()


class BaseModel(Base):
    __abstract__ = True
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    created_at = Column(
        TIMESTAMP(timezone=True),
        default=datetime.utcnow,
        nullable=False,
    )
    created_by = Column(UUID(as_uuid=True), nullable=True)
    updated_at = Column(
        TIMESTAMP(timezone=True),
        onupdate=datetime.utcnow,
        nullable=True,
    )
    updated_by = Column(UUID(as_uuid=True), nullable=True)
