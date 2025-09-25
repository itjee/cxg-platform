import logging
from uuid import UUID

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from ..role.model import Role as RoleModel
from ..user.model import User as UserModel
from .model import UserRole as UserRoleModel
from .schemas import (
    UserRoleCreate,
    UserRoleCreateRequest,
    UserRoleRead,
    UserRoleUpdate,
)

# 로거 초기화
logger = logging.getLogger(__name__)


class UserRoleService:
    """사용자-역할 매핑 관련 비즈니스 로직을 처리하는 서비스"""

    @staticmethod
    def get_user_roles(
        db: Session, user_id: str, skip: int = 0, limit: int = 100
    ) -> list[UserRoleModel]:
        """
        특정 사용자의 역할 매핑 목록을 조회합니다.
        """
        try:
            user_roles = (
                db.query(UserRoleModel)
                .filter(UserRoleModel.user_id == user_id)
                .offset(skip)
                .limit(limit)
                .all()
            )
            return user_roles
        except SQLAlchemyError as e:
            logger.error(
                f"사용자 역할 매핑 목록 조회 중 데이터베이스 에러: {e}"
            )
            raise

    @staticmethod
    def assign_role_to_user(
        db: Session, user_role_data: UserRoleCreateRequest
    ) -> UserRoleModel:
        """
        사용자에게 역할을 할당합니다.
        """
        try:
            # 사용자 및 역할 존재 여부 확인
            user = (
                db.query(UserModel)
                .filter(UserModel.id == user_role_data.user_id)
                .first()
            )
            role = (
                db.query(RoleModel)
                .filter(RoleModel.id == user_role_data.role_id)
                .first()
            )

            if not user:
                raise ValueError(
                    f"User with ID {user_role_data.user_id} not found."
                )
            if not role:
                raise ValueError(
                    f"Role with ID {user_role_data.role_id} not found."
                )

            # 이미 할당된 역할인지 확인
            existing_user_role = (
                db.query(UserRoleModel)
                .filter(
                    UserRoleModel.user_id == user_role_data.user_id,
                    UserRoleModel.role_id == user_role_data.role_id,
                )
                .first()
            )
            if existing_user_role:
                raise ValueError("Role is already assigned to this user.")

            db_user_role = UserRoleModel(
                user_id=user_role_data.user_id, role_id=user_role_data.role_id
            )
            db.add(db_user_role)
            db.commit()
            db.refresh(db_user_role)
            return db_user_role
        except SQLAlchemyError as e:
            logger.error(f"사용자 역할 할당 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def unassign_role_from_user(
        db: Session, user_id: str, role_id: str
    ) -> bool:
        """
        사용자로부터 역할을 해제합니다.
        """
        try:
            db_user_role = (
                db.query(UserRoleModel)
                .filter(
                    UserRoleModel.user_id == user_id,
                    UserRoleModel.role_id == role_id,
                )
                .first()
            )
            if not db_user_role:
                return False

            db.delete(db_user_role)
            db.commit()
            return True
        except SQLAlchemyError as e:
            logger.error(f"사용자 역할 해제 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    # New methods using the new schema classes
    @staticmethod
    def create_user_role(
        db: Session, user_role_data: UserRoleCreate
    ) -> UserRoleRead:
        """
        새로운 사용자-역할 매핑을 생성합니다. (새로운 스키마 사용)
        """
        try:
            # 사용자 및 역할 존재 여부 확인
            user = (
                db.query(UserModel)
                .filter(UserModel.id == user_role_data.user_id)
                .first()
            )
            role = (
                db.query(RoleModel)
                .filter(RoleModel.id == user_role_data.role_id)
                .first()
            )

            if not user:
                raise ValueError(
                    f"User with ID {user_role_data.user_id} not found."
                )
            if not role:
                raise ValueError(
                    f"Role with ID {user_role_data.role_id} not found."
                )

            # 이미 할당된 역할인지 확인
            existing_user_role = (
                db.query(UserRoleModel)
                .filter(
                    UserRoleModel.user_id == user_role_data.user_id,
                    UserRoleModel.role_id == user_role_data.role_id,
                )
                .first()
            )
            if existing_user_role:
                raise ValueError("Role is already assigned to this user.")

            db_user_role = UserRoleModel(**user_role_data.model_dump())
            db.add(db_user_role)
            db.commit()
            db.refresh(db_user_role)

            return UserRoleRead.model_validate(db_user_role)
        except SQLAlchemyError as e:
            logger.error(f"사용자 역할 생성 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def get_user_role_by_id(
        db: Session, user_role_id: UUID
    ) -> UserRoleRead | None:
        """
        ID로 사용자-역할 매핑을 조회합니다.
        """
        try:
            user_role = (
                db.query(UserRoleModel)
                .filter(UserRoleModel.id == user_role_id)
                .first()
            )
            if user_role:
                return UserRoleRead.model_validate(user_role)
            return None
        except SQLAlchemyError as e:
            logger.error(f"사용자 역할 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def update_user_role(
        db: Session, user_role_id: UUID, user_role_data: UserRoleUpdate
    ) -> UserRoleRead | None:
        """
        사용자-역할 매핑을 업데이트합니다.
        """
        try:
            db_user_role = (
                db.query(UserRoleModel)
                .filter(UserRoleModel.id == user_role_id)
                .first()
            )
            if not db_user_role:
                return None

            update_data = user_role_data.model_dump(exclude_unset=True)
            for field, value in update_data.items():
                setattr(db_user_role, field, value)

            db.commit()
            db.refresh(db_user_role)

            return UserRoleRead.model_validate(db_user_role)
        except SQLAlchemyError as e:
            logger.error(f"사용자 역할 업데이트 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def delete_user_role(db: Session, user_role_id: UUID) -> bool:
        """
        사용자-역할 매핑을 삭제합니다.
        """
        try:
            db_user_role = (
                db.query(UserRoleModel)
                .filter(UserRoleModel.id == user_role_id)
                .first()
            )
            if not db_user_role:
                return False

            db.delete(db_user_role)
            db.commit()
            return True
        except SQLAlchemyError as e:
            logger.error(f"사용자 역할 삭제 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def list_user_roles(
        db: Session, skip: int = 0, limit: int = 100
    ) -> list[UserRoleRead]:
        """
        사용자-역할 매핑 목록을 조회합니다.
        """
        try:
            user_roles = (
                db.query(UserRoleModel).offset(skip).limit(limit).all()
            )
            return [
                UserRoleRead.model_validate(user_role)
                for user_role in user_roles
            ]
        except SQLAlchemyError as e:
            logger.error(f"사용자 역할 목록 조회 중 데이터베이스 에러: {e}")
            raise


__all__ = ["UserRoleService"]
