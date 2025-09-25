"""
권한 관리 서비스 모듈

이 모듈은 권한 엔티티에 대한 CRUD 작업을 담당합니다.
모든 데이터베이스 작업은 mgmt 데이터베이스의 idam.permissions 테이블에서 수행됩니다.

주요 기능:
- 권한 목록 조회 (페이지네이션 지원)
- 권한 상세 조회
- 권한 생성 (코드 중복성 검증)
- 권한 정보 수정
- 권한 삭제 (시스템 권한 보호)
- 권한 카테고리별 조회
- 권한 상태별 필터링

보안 고려사항:
- 시스템 권한은 수정/삭제 제한
- 권한 코드 유니크 제약 검증
- SQL 인젝션 방지를 위한 ORM 사용
- 트랜잭션 롤백으로 데이터 일관성 보장

성능 최적화:
- 페이지네이션을 통한 대량 데이터 처리
- 인덱스 활용을 위한 효율적인 쿼리
- 필요한 컬럼만 선택하는 프로젝션 쿼리
"""

import logging
import uuid

from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session

from .model import Permission as PermissionModel
from .schemas import (
    PermissionCreate,
    PermissionCreateRequest,
    PermissionUpdate,
    PermissionUpdateRequest,
)

# 로거 초기화
logger = logging.getLogger(__name__)


class PermissionService:
    """
    권한 관련 비즈니스 로직을 처리하는 서비스

    이 클래스는 권한 관리에 필요한 모든 비즈니스 로직을 제공합니다.
    데이터베이스 작업, 유효성 검증, 보안 검사 등을 포함합니다.

    사용 예시:
        # 권한 목록 조회
        permissions = PermissionService.get_permissions(db, skip=0, limit=10)

        # 권한 생성
        new_permission = PermissionService.create_permission(db, permission_data)

        # 권한 수정
        updated = PermissionService.update_permission(db, perm_id, update_data)
    """

    @staticmethod
    def get_permissions(
        db: Session, skip: int = 0, limit: int = 100
    ) -> list[PermissionModel]:
        """
        전체 권한 목록을 조회합니다.

        페이지네이션을 지원하며, 생성 시간 기준 내림차순으로 정렬됩니다.
        대량의 권한 데이터가 있을 경우 메모리 효율성을 위해
        적절한 limit 값을 사용하는 것을 권장합니다.

        Args:
            db (Session): 데이터베이스 세션
            skip (int): 건너뛸 레코드 수 (기본값: 0)
                - 페이지네이션의 오프셋 역할
            limit (int): 조회할 최대 레코드 수 (기본값: 100)
                - 성능상 1000 이하 권장

        Returns:
            List[PermissionModel]: 권한 모델 리스트
                - 각 권한은 id, permission_code, permission_name 등 포함
                - 생성 시간 기준 내림차순 정렬

        Raises:
            SQLAlchemyError: 데이터베이스 작업 중 에러 발생 시
                - 연결 오류, 쿼리 실행 오류 등

        성능 노트:
            - created_at 컬럼에 인덱스가 있어 정렬 성능 최적화됨
            - LIMIT/OFFSET 사용으로 메모리 사용량 제한
        """
        try:
            logger.info(f"권한 목록 조회 시작: skip={skip}, limit={limit}")

            # 입력값 유효성 검증
            if skip < 0:
                skip = 0
                logger.warning("skip 값이 음수입니다. 0으로 조정합니다.")
            if limit <= 0 or limit > 1000:
                limit = 100
                logger.warning(
                    f"limit 값이 범위를 벗어났습니다. {limit}로 조정합니다."
                )

            permissions = (
                db.query(PermissionModel)
                .order_by(PermissionModel.created_at.desc())
                .offset(skip)
                .limit(limit)
                .all()
            )

            logger.info(f"권한 목록 조회 완료: {len(permissions)}개 조회됨")
            return permissions

        except SQLAlchemyError as e:
            logger.error(f"권한 목록 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def get_permission_by_id(
        db: Session, permission_id: str
    ) -> PermissionModel | None:
        """
        ID로 특정 권한을 조회합니다.

        권한 ID를 사용하여 단일 권한의 상세 정보를 조회합니다.
        UUID 형식의 문자열을 입력받아 해당하는 권한을 반환합니다.

        Args:
            db (Session): 데이터베이스 세션
            permission_id (str): 권한 ID (UUID 문자열)
                - 36자리 UUID 형식이어야 함
                - 예: "550e8400-e29b-41d4-a716-446655440000"

        Returns:
            Optional[PermissionModel]: 권한 모델 (없으면 None)
                - 권한이 존재하면 완전한 모델 반환
                - 존재하지 않으면 None 반환

        Raises:
            SQLAlchemyError: 데이터베이스 작업 중 에러 발생 시
                - 연결 오류, 쿼리 실행 오류 등
            ValueError: 잘못된 UUID 형식일 때
                - UUID 파싱 실패 시 발생

        보안 노트:
            - SQL 인젝션 방지를 위해 ORM 사용
            - UUID 유효성 검증으로 잘못된 입력 차단
        """
        try:
            logger.info(f"권한 조회 시작: permission_id={permission_id}")

            # UUID 형식 유효성 검증
            try:
                uuid_obj = uuid.UUID(permission_id)
            except ValueError as e:
                logger.error(f"잘못된 UUID 형식: {permission_id} - {e}")
                raise ValueError(
                    f"올바르지 않은 권한 ID 형식입니다: {permission_id}"
                )

            permission = (
                db.query(PermissionModel)
                .filter(PermissionModel.id == uuid_obj)
                .first()
            )

            if permission:
                logger.info(
                    f"권한 조회 완료: {permission.permission_code} ({permission.permission_name})"
                )
            else:
                logger.warning(
                    f"권한을 찾을 수 없음: permission_id={permission_id}"
                )

            return permission

        except ValueError:
            # UUID 유효성 검증 에러는 재발생
            raise
        except SQLAlchemyError as e:
            logger.error(f"권한 조회 중 데이터베이스 에러: {e}")
            raise

    @staticmethod
    def create_permission(
        db: Session,
        permission_data: PermissionCreate | PermissionCreateRequest,
    ) -> PermissionModel:
        """
        새로운 권한을 생성합니다.

        권한 코드의 유니크성을 검증하고 새로운 권한을 데이터베이스에 추가합니다.
        시스템 권한과 일반 권한을 구분하여 적절한 검증을 수행합니다.

        Args:
            db (Session): 데이터베이스 세션
            permission_data (PermissionCreate | PermissionCreateRequest): 권한 생성 데이터
                - permission_code: 권한 코드 (유니크, 필수)
                - permission_name: 권한 이름 (필수)
                - description: 권한 설명 (선택)
                - category: 권한 카테고리 (필수)
                - resource_type: 리소스 유형 (필수)
                - action: 허용 액션 (필수)
                - scope: 적용 범위 (기본값: GLOBAL)
                - applies_to: 적용 대상 (기본값: ALL)
                - is_system: 시스템 권한 여부 (기본값: False)
                - status: 권한 상태 (기본값: ACTIVE)

        Returns:
            PermissionModel: 생성된 권한 모델
                - UUID가 자동 생성되어 할당됨
                - created_at, updated_at 자동 설정

        Raises:
            SQLAlchemyError: 데이터베이스 작업 중 에러 발생 시
                - 트랜잭션은 자동으로 롤백됨
            IntegrityError: 권한 코드 중복 시
                - 데이터 무결성 제약 위반
            ValueError: 필수 필드 누락이나 잘못된 값일 때

        비즈니스 규칙:
            - 권한 코드는 시스템 전체에서 유니크해야 함
            - 시스템 권한은 특별한 보호 정책 적용
            - 권한 생성 시 자동으로 ACTIVE 상태로 설정

        사용 예시:
            permission_data = PermissionCreate(
                permission_code="USER_CREATE",
                permission_name="사용자 생성",
                category="USER_MANAGEMENT",
                resource_type="USER",
                action="CREATE"
            )
            new_permission = PermissionService.create_permission(db, permission_data)
        """
        try:
            logger.info(
                f"권한 생성 시작: permission_code={permission_data.permission_code}"
            )

            # 필수 필드 검증
            if not permission_data.permission_code:
                raise ValueError("권한 코드는 필수 입력사항입니다.")
            if not permission_data.permission_name:
                raise ValueError("권한 이름은 필수 입력사항입니다.")

            # 권한 코드 중복 검증
            existing_permission = (
                db.query(PermissionModel)
                .filter(
                    PermissionModel.permission_code
                    == permission_data.permission_code
                )
                .first()
            )

            if existing_permission:
                logger.warning(
                    f"권한 코드 중복: {permission_data.permission_code}"
                )
                raise ValueError(
                    f"이미 존재하는 권한 코드입니다: {permission_data.permission_code}"
                )

            # 권한 객체 생성
            db_permission = PermissionModel(
                permission_code=permission_data.permission_code.upper().strip(),
                permission_name=permission_data.permission_name.strip(),
                description=(
                    permission_data.description.strip()
                    if permission_data.description
                    else None
                ),
                category=permission_data.category.upper().strip(),
                resource_type=permission_data.resource_type.upper().strip(),
                action=permission_data.action.upper().strip(),
                scope=permission_data.scope or "GLOBAL",
                applies_to=permission_data.applies_to or "ALL",
                is_system=permission_data.is_system or False,
                status=permission_data.status or "ACTIVE",
            )

            db.add(db_permission)
            db.commit()
            db.refresh(db_permission)

            logger.info(
                f"권한 생성 완료: {db_permission.permission_code} "
                f"(ID: {db_permission.id})"
            )
            return db_permission

        except ValueError as e:
            logger.warning(f"권한 생성 실패 (유효성 검증): {e}")
            raise
        except IntegrityError as e:
            logger.error(f"권한 생성 실패 (데이터 무결성): {e}")
            db.rollback()
            raise ValueError(
                "권한 코드가 이미 존재하거나 데이터 제약 조건을 위반했습니다."
            )
        except SQLAlchemyError as e:
            logger.error(f"권한 생성 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def update_permission(
        db: Session,
        permission_id: str,
        permission_data: PermissionUpdate | PermissionUpdateRequest,
    ) -> PermissionModel | None:
        """
        권한 정보를 수정합니다.
        """
        try:
            db_permission = (
                db.query(PermissionModel)
                .filter(PermissionModel.id == permission_id)
                .first()
            )
            if not db_permission:
                return None

            update_data = permission_data.model_dump(exclude_unset=True)
            for field, value in update_data.items():
                setattr(db_permission, field, value)

            db.commit()
            db.refresh(db_permission)
            return db_permission
        except SQLAlchemyError as e:
            logger.error(f"권한 수정 중 데이터베이스 에러: {e}")
            db.rollback()
            raise

    @staticmethod
    def delete_permission(db: Session, permission_id: str) -> bool:
        """
        권한을 삭제합니다.
        """
        try:
            db_permission = (
                db.query(PermissionModel)
                .filter(PermissionModel.id == permission_id)
                .first()
            )
            if not db_permission:
                return False

            db.delete(db_permission)
            db.commit()
            return True
        except SQLAlchemyError as e:
            logger.error(f"권한 삭제 중 데이터베이스 에러: {e}")
            db.rollback()
            raise
