import logging

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from .model import Role as RoleModel
from .schemas import RoleCreate, RoleUpdate

logger = logging.getLogger(__name__)


class RoleService:
    """역할 관련 비즈니스 로직을 처리하는 서비스"""

    @staticmethod
    def get_roles(
        db: Session, skip: int = 0, limit: int = 100
    ) -> list[RoleModel]:
        """
        역할 목록을 조회합니다.
        """
        try:
            roles = db.query(RoleModel).offset(skip).limit(limit).all()
            return roles
        except SQLAlchemyError as e:
            logger.error(f"역할 목록 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def get_role_by_id(db: Session, role_id: str) -> RoleModel | None:
        """
        ID로 특정 역할을 조회합니다.
        """
        try:
            role = db.query(RoleModel).filter(RoleModel.id == role_id).first()
            return role
        except SQLAlchemyError as e:
            logger.error(f"역할 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def create_role(db: Session, role_data: RoleCreate) -> RoleModel:
        """
        새로운 역할을 생성합니다.
        """
        try:
            db_role = RoleModel(
                role_code=role_data.role_code,
                role_name=role_data.role_name,
                description=role_data.description,
                role_type=role_data.role_type,
                scope=role_data.scope,
                is_default=role_data.is_default,
                priority=role_data.priority,
                status=role_data.status,
            )
            db.add(db_role)
            db.commit()
            db.refresh(db_role)
            return db_role
        except SQLAlchemyError as e:
            logger.error(f"역할 생성 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def update_role(
        db: Session, role_id: str, role_data: RoleUpdate
    ) -> RoleModel | None:
        """
        역할 정보를 수정합니다.
        """
        try:
            db_role = (
                db.query(RoleModel).filter(RoleModel.id == role_id).first()
            )
            if not db_role:
                return None

            update_data = role_data.model_dump(exclude_unset=True)
            for field, value in update_data.items():
                setattr(db_role, field, value)

            db.commit()
            db.refresh(db_role)
            return db_role
        except SQLAlchemyError as e:
            logger.error(f"역할 수정 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def delete_role(db: Session, role_id: str) -> bool:
        """
        역할을 삭제합니다.
        """
        try:
            db_role = (
                db.query(RoleModel).filter(RoleModel.id == role_id).first()
            )
            if not db_role:
                return False

            db.delete(db_role)
            db.commit()
            return True
        except SQLAlchemyError as e:
            logger.error(f"역할 삭제 중 데이터베이스 에러: {e}")
            db.rollback()
            raise
