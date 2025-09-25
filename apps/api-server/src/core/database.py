from fastapi import Request
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker

from src.core.config import settings

# 두 개의 DB 엔진 생성 (시간대 설정 포함)
mgmt_engine = create_engine(
    settings.DATABASE_URL_MANAGES,
    pool_pre_ping=True,
    connect_args={"options": "-c timezone=Asia/Seoul"},
)
tnnt_engine = create_engine(
    settings.DATABASE_URL_TENANTS,
    pool_pre_ping=True,
    connect_args={"options": "-c timezone=Asia/Seoul"},
)


# 세션 생성 시마다 시간대 설정
@event.listens_for(mgmt_engine, "connect")
def set_timezone_mgmt(dbapi_connection, connection_record):
    with dbapi_connection.cursor() as cursor:
        cursor.execute("SET timezone='Asia/Seoul'")


@event.listens_for(tnnt_engine, "connect")
def set_timezone_tnnt(dbapi_connection, connection_record):
    with dbapi_connection.cursor() as cursor:
        cursor.execute("SET timezone='Asia/Seoul'")


mgmt_session_local = sessionmaker(
    autocommit=False, autoflush=False, bind=mgmt_engine
)
tnnt_session_local = sessionmaker(
    autocommit=False, autoflush=False, bind=tnnt_engine
)


def get_db(request: Request):
    # 관리자 시스템이므로 모든 요청에서 mgmt 데이터베이스 사용
    db = mgmt_session_local()
    try:
        yield db
    finally:
        db.close()


def get_mgmt_db():
    """Management 데이터베이스 세션"""
    db = mgmt_session_local()
    try:
        yield db
    finally:
        db.close()


def get_tnnt_db():
    """Tenant 데이터베이스 세션"""
    db = tnnt_session_local()
    try:
        yield db
    finally:
        db.close()
