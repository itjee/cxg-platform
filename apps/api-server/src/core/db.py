from src.core.config import settings
from fastapi import Request
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# 두 개의 DB 엔진 생성
mgmt_engine = create_engine(settings.DATABASE_URL_MANAGES, pool_pre_ping=True)
tnnt_engine = create_engine(settings.DATABASE_URL_TENANTS, pool_pre_ping=True)

mgmt_SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=mgmt_engine)
tnnt_SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=tnnt_engine)


def get_db(request: Request):
    # 예시: 경로에 따라 DB 선택 (실제 로직은 인증정보 등으로 변경 가능)
    if request.url.path.startswith("/api/v1/tenants"):
        db = tnnt_SessionLocal()
    else:
        db = mgmt_SessionLocal()
    try:
        yield db
    finally:
        db.close()
