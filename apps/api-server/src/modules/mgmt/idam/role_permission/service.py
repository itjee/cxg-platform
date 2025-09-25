import logging

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from ..permission.model import Permission as PermissionModel
from ..role.model import Role as RoleModel
from .model import RolePermission as RolePermissionModel
from .schemas import RolePermissionCreate

# 로거 초기화
logger = logging.getLogger(__name__)


class RolePermissionService:
    """역할-권한 매핑 관련 비즈니스 로직을 처리하는 서비스"""

    @staticmethod
    def get_role_permissions(
        db: Session, role_id: str, skip: int = 0, limit: int = 100
    ) -> list[RolePermissionModel]:
        """
        특정 역할의 권한 매핑 목록을 조회합니다.
        """
        try:
            role_permissions = (
                db.query(RolePermissionModel)
                .filter(RolePermissionModel.role_id == role_id)
                .offset(skip)
                .limit(limit)
                .all()
            )
            return role_permissions
        except SQLAlchemyError as e:
            logger.error(f"역할 권한 매핑 목록 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def assign_permission_to_role(
        db: Session, role_permission_data: RolePermissionCreate
    ) -> RolePermissionModel:
        """
        역할에 권한을 할당합니다.
        """
        try:
            # 역할 및 권한 존재 여부 확인
            role = (
                db.query(RoleModel)
                .filter(RoleModel.id == role_permission_data.role_id)
                .first()
            )
            permission = (
                db.query(PermissionModel)
                .filter(
                    PermissionModel.id == role_permission_data.permission_id
                )
                .first()
            )

            if not role:
                raise ValueError(
                    f"Role with ID {role_permission_data.role_id} not found."
                )
            if not permission:
                raise ValueError(
                    f"Permission with ID "
                    f"{role_permission_data.permission_id} not found."
                )

            # 이미 할당된 권한인지 확인
            existing_role_permission = (
                db.query(RolePermissionModel)
                .filter(
                    RolePermissionModel.role_id
                    == role_permission_data.role_id,
                    RolePermissionModel.permission_id
                    == role_permission_data.permission_id,
                )
                .first()
            )
            if existing_role_permission:
                raise ValueError(
                    "Permission is already assigned to this role."
                )

            db_role_permission = RolePermissionModel(
                role_id=role_permission_data.role_id,
                permission_id=role_permission_data.permission_id,
            )
            db.add(db_role_permission)
            db.commit()
            db.refresh(db_role_permission)
            return db_role_permission
        except SQLAlchemyError as e:
            logger.error(f"역할 권한 할당 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def unassign_permission_from_role(
        db: Session, role_id: str, permission_id: str
    ) -> bool:
        """
        역할로부터 권한을 해제합니다.
        """
        try:
            db_role_permission = (
                db.query(RolePermissionModel)
                .filter(
                    RolePermissionModel.role_id == role_id,
                    RolePermissionModel.permission_id == permission_id,
                )
                .first()
            )
            if not db_role_permission:
                return False

            db.delete(db_role_permission)
            db.commit()
            return True
        except SQLAlchemyError as e:
            logger.error(f"역할 권한 해제 중 데이터베이스 에러: {e}")
            db.rollback()
            raise


__all__ = ["RolePermissionService"]
