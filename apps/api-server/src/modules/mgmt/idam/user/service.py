"""
사용자 관리 서비스 모듈

이 모듈은 사용자 엔티티에 대한 CRUD 작업을 담당합니다.
모든 데이터베이스 작업은 mgmt 데이터베이스의 idam.users 테이블에서 수행됩니다.
"""

import logging
import uuid

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from .model import User as UserModel
from .schemas import UserCreate, UserUpdate

logger = logging.getLogger(__name__)


class UserService:
    """사용자 관련 비즈니스 로직을 처리하는 서비스"""

    @staticmethod
    def get_users(db: Session, skip: int = 0, limit: int = 100) -> list[dict]:
        """
        전체 사용자 목록을 조회합니다.

        Args:
            db (Session): 데이터베이스 세션
            skip (int): 건너뛸 레코드 수 (기본값: 0)
            limit (int): 조회할 최대 레코드 수 (기본값: 100)

        Returns:
            List[dict]: 사용자 정보 딕셔너리 리스트
                (username, email, full_name, user_type 포함)

        Raises:
            SQLAlchemyError: 데이터베이스 작업 중 에러 발생 시
        """
        try:
            logger.info(f"사용자 목록 조회 시작: skip={skip}, limit={limit}")
            users = (
                db.query(
                    UserModel.id,
                    UserModel.username,
                    UserModel.email,
                    UserModel.full_name,
                    UserModel.user_type,
                    UserModel.created_at,
                    UserModel.last_login_at,
                )
                .offset(skip)
                .limit(limit)
                .all()
            )
            users_data = [
                {
                    "id": str(user.id),
                    "username": user.username,
                    "email": user.email,
                    "full_name": user.full_name,
                    "user_type": user.user_type,
                    "created_at": (
                        user.created_at.isoformat()
                        if user.created_at
                        else None
                    ),
                    "last_login_at": (
                        user.last_login_at.isoformat()
                        if user.last_login_at
                        else None
                    ),
                }
                for user in users
            ]
            logger.info(f"사용자 목록 조회 완료: {len(users_data)}명")
            return users_data
        except SQLAlchemyError as e:
            logger.error(f"사용자 목록 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def get_user_count(db: Session) -> int:
        """
        전체 사용자 수를 조회합니다.

        Args:
            db (Session): 데이터베이스 세션

        Returns:
            int: 전체 사용자 수

        Raises:
            SQLAlchemyError: 데이터베이스 작업 중 에러 발생 시
        """
        try:
            logger.info("전체 사용자 수 조회 시작")
            count = db.query(UserModel).count()
            logger.info(f"전체 사용자 수 조회 완료: {count}명")
            return count
        except SQLAlchemyError as e:
            logger.error(f"사용자 수 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def get_user(db: Session, user_id: str) -> UserModel | None:
        """
        ID로 특정 사용자를 조회합니다.

        Args:
            db (Session): 데이터베이스 세션
            user_id (str): 사용자 ID (UUID 문자열)

        Returns:
            Optional[UserModel]: 사용자 모델 (없으면 None)

        Raises:
            SQLAlchemyError: 데이터베이스 작업 중 에러 발생 시
            ValueError: 잘못된 UUID 형식일 때
        """
        try:
            logger.info(f"사용자 조회 시작: user_id={user_id}")
            uuid_obj = uuid.UUID(user_id)
            user = db.query(UserModel).filter(UserModel.id == uuid_obj).first()

            if user:
                logger.info(f"사용자 조회 완료: {user.username}")
            else:
                logger.warning(f"사용자를 찾을 수 없음: user_id={user_id}")

            return user
        except ValueError as e:
            logger.error(f"잘못된 UUID 형식: {user_id} - {e}")
            raise
        except SQLAlchemyError as e:
            logger.error(f"사용자 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def create_user(db: Session, user: UserCreate) -> UserModel:
        """
        새로운 사용자를 생성합니다.

        Args:
            db (Session): 데이터베이스 세션
            user (UserCreate): 사용자 생성 데이터

        Returns:
            UserModel: 생성된 사용자 모델

        Raises:
            SQLAlchemyError: 데이터베이스 작업 중 에러 발생 시
            ValueError: 중복된 이메일 또는 사용자명일 때
        """
        try:
            logger.info(f"사용자 생성 시작: username={user.username}")

            existing_user = (
                db.query(UserModel)
                .filter(
                    (UserModel.email == user.email)
                    | (UserModel.username == user.username)
                )
                .first()
            )

            if existing_user:
                if existing_user.email == user.email:
                    raise ValueError("이미 사용 중인 이메일입니다.")
                else:
                    raise ValueError("이미 사용 중인 사용자명입니다.")

            db_user = UserModel(
                email=user.email,
                username=user.username,
                password=user.password,
                full_name=user.full_name,
            )

            db.add(db_user)
            db.commit()
            db.refresh(db_user)

            logger.info(f"사용자 생성 완료: {db_user.username}")
            return db_user
        except ValueError as e:
            logger.warning(f"사용자 생성 실패 (유효성 검사): {e}")
            raise
        except SQLAlchemyError as e:
            logger.error(f"사용자 생성 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def update_user(  # noqa: C901
        db: Session, user_id: str, user: UserUpdate
    ) -> UserModel | None:
        """
        사용자 정보를 수정합니다.

        Args:
            db (Session): 데이터베이스 세션
            user_id (str): 사용자 ID (UUID 문자열)
            user (UserUpdate): 사용자 수정 데이터

        Returns:
            Optional[UserModel]: 수정된 사용자 모델 (없으면 None)

        Raises:
            SQLAlchemyError: 데이터베이스 작업 중 에러 발생 시
            ValueError: 잘못된 UUID 형식이거나 중복된 데이터일 때
        """
        try:
            logger.info(f"사용자 수정 시작: user_id={user_id}")
            uuid_obj = uuid.UUID(user_id)
            db_user = (
                db.query(UserModel).filter(UserModel.id == uuid_obj).first()
            )

            if not db_user:
                logger.warning(
                    f"수정할 사용자를 찾을 수 없음: user_id={user_id}"
                )
                return None

            update_data = user.model_dump(exclude_unset=True)
            if not update_data:
                logger.info("수정할 데이터가 없음")
                return db_user

            if "email" in update_data or "username" in update_data:
                conditions = []
                if "email" in update_data:
                    conditions.append(UserModel.email == update_data["email"])
                if "username" in update_data:
                    conditions.append(
                        UserModel.username == update_data["username"]
                    )

                existing = (
                    db.query(UserModel)
                    .filter(UserModel.id != uuid_obj)
                    .filter(db.query(*conditions).exists())
                    .first()
                )

                if existing:
                    raise ValueError(
                        "이미 사용 중인 이메일 또는 사용자명입니다."
                    )

            for field, value in update_data.items():
                if hasattr(db_user, field):
                    setattr(db_user, field, value)

            db.commit()
            db.refresh(db_user)

            logger.info(f"사용자 수정 완료: {db_user.username}")
            return db_user
        except ValueError as e:
            logger.warning(f"사용자 수정 실패 (유효성 검사): {e}")
            raise
        except SQLAlchemyError as e:
            logger.error(f"사용자 수정 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def delete_user(db: Session, user_id: str) -> bool:
        """
        사용자를 삭제합니다.

        Args:
            db (Session): 데이터베이스 세션
            user_id (str): 사용자 ID (UUID 문자열)

        Returns:
            bool: 삭제 성공 여부

        Raises:
            SQLAlchemyError: 데이터베이스 작업 중 에러 발생 시
            ValueError: 잘못된 UUID 형식일 때
        """
        try:
            logger.info(f"사용자 삭제 시작: user_id={user_id}")
            uuid_obj = uuid.UUID(user_id)
            db_user = (
                db.query(UserModel).filter(UserModel.id == uuid_obj).first()
            )

            if not db_user:
                logger.warning(
                    f"삭제할 사용자를 찾을 수 없음: user_id={user_id}"
                )
                return False

            username = db_user.username
            db.delete(db_user)
            db.commit()

            logger.info(f"사용자 삭제 완료: {username}")
            return True
        except ValueError as e:
            logger.error(f"잘못된 UUID 형식: {user_id} - {e}")
            raise
        except SQLAlchemyError as e:
            logger.error(f"사용자 삭제 중 데이터베이스 에러: {e}")
            db.rollback()
            raise
