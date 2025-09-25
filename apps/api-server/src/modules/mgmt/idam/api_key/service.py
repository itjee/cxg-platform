import logging
import secrets

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from .model import ApiKey as ApiKeyModel
from .schemas import (
    ApiKeyCreate,
    ApiKeyCreateRequest,
    ApiKeyUpdate,
    ApiKeyUpdateRequest,
)

# 로거 초기화
logger = logging.getLogger(__name__)


class ApiKeyService:
    """API 키 관련 비즈니스 로직을 처리하는 서비스"""

    @staticmethod
    def generate_api_key() -> str:
        """안전한 API 키를 생성합니다."""
        return secrets.token_urlsafe(32)

    @staticmethod
    def get_api_keys_for_user(
        db: Session, user_id: str, skip: int = 0, limit: int = 100
    ) -> list[ApiKeyModel]:
        """
        특정 사용자의 API 키 목록을 조회합니다.
        """
        try:
            api_keys = (
                db.query(ApiKeyModel)
                .filter(ApiKeyModel.user_id == user_id)
                .offset(skip)
                .limit(limit)
                .all()
            )
            return api_keys
        except SQLAlchemyError as e:
            logger.error(f"API 키 목록 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def get_api_key_by_id(db: Session, api_key_id: str) -> ApiKeyModel | None:
        """
        ID로 특정 API 키를 조회합니다.
        """
        try:
            api_key = (
                db.query(ApiKeyModel)
                .filter(ApiKeyModel.id == api_key_id)
                .first()
            )
            return api_key
        except SQLAlchemyError as e:
            logger.error(f"API 키 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def create_api_key(
        db: Session,
        user_id: str,
        api_key_data: ApiKeyCreate | ApiKeyCreateRequest,
    ) -> ApiKeyModel:
        """
        새로운 API 키를 생성합니다.
        """
        try:
            # 실제 API 키 생성 (저장되지 않음, 사용자에게 한 번만 보여줌)
            raw_api_key = ApiKeyService.generate_api_key()
            # TODO: raw_api_key를 해싱하여 key_hash에 저장해야 합니다.
            # 현재는 임시로 raw_api_key를 그대로 저장합니다. 실제 서비스에서는 보안 강화 필요.
            key_hash = (
                raw_api_key  # For now, store raw key. Implement hashing later.
            )

            db_api_key = ApiKeyModel(
                name=api_key_data.name,
                user_id=user_id,
                key_hash=key_hash,
                expires_at=api_key_data.expires_at,
            )
            db.add(db_api_key)
            db.commit()
            db.refresh(db_api_key)
            return db_api_key
        except SQLAlchemyError as e:
            logger.error(f"API 키 생성 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def update_api_key(
        db: Session,
        api_key_id: str,
        api_key_data: ApiKeyUpdate | ApiKeyUpdateRequest,
    ) -> ApiKeyModel | None:
        """
        API 키 정보를 수정합니다.
        """
        try:
            db_api_key = (
                db.query(ApiKeyModel)
                .filter(ApiKeyModel.id == api_key_id)
                .first()
            )
            if not db_api_key:
                return None

            update_data = api_key_data.model_dump(exclude_unset=True)
            for field, value in update_data.items():
                setattr(db_api_key, field, value)

            db.commit()
            db.refresh(db_api_key)
            return db_api_key
        except SQLAlchemyError as e:
            logger.error(f"API 키 수정 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def delete_api_key(db: Session, api_key_id: str) -> bool:
        """
        API 키를 삭제합니다.
        """
        try:
            db_api_key = (
                db.query(ApiKeyModel)
                .filter(ApiKeyModel.id == api_key_id)
                .first()
            )
            if not db_api_key:
                return False

            db.delete(db_api_key)
            db.commit()
            return True
        except SQLAlchemyError as e:
            logger.error(f"API 키 삭제 중 데이터베이스 에러: {e}")
            db.rollback()
            raise
