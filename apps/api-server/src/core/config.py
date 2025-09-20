from typing import List

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    SECRET_KEY: str = "your-secret-key-here-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    DATABASE_URL_MANAGES: str = "postgresql://admin:cxg2025!!@localhost:5432/manages"
    DATABASE_URL_TENANTS: str = "postgresql://admin:cxg2025!!@localhost:5432/tenants"

    # Redis 설정
    REDIS_URL: str = "redis://localhost:6379/0"

    # OpenAI API 설정
    OPENAI_API_KEY: str = ""

    # Pinecone 설정
    PINECONE_API_KEY: str = ""
    PINECONE_ENVIRONMENT: str = ""

    # 파일 업로드 설정
    UPLOAD_MAX_SIZE: int = 10485760  # 10MB
    UPLOAD_DIR: str = "./uploads"

    # 로그 설정
    LOG_LEVEL: str = "info"

    # CORS 설정
    CORS_ORIGINS: List[str] = [
        "http://localhost:3100",  # web-mgmt
        "http://localhost:3200",  # web-tnnt
        "http://localhost:3000",  # 개발용 대체 포트
    ]

    class Config:
        env_file = ".env"


settings = Settings()
