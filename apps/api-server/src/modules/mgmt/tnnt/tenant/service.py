"""
테넌트 서비스 모듈

테넌트 관련 비즈니스 로직을 처리하는 서비스 계층
"""

import uuid
from datetime import datetime

from sqlalchemy import and_
from sqlalchemy.orm import Session

from .model import Tenant
from .schemas import (
    TenantCreate,
    TenantCreateRequest,
    TenantUpdate,
    TenantUpdateRequest,
)


class TenantService:
    """테넌트 관련 비즈니스 로직을 처리하는 서비스"""

    @staticmethod
    def get_tenants(
        db: Session, skip: int = 0, limit: int = 100
    ) -> list[Tenant]:
        """활성화된 테넌트 목록 조회"""
        return (
            db.query(Tenant)
            .filter(~Tenant.deleted)
            .offset(skip)
            .limit(limit)
            .all()
        )

    @staticmethod
    def get_tenant_by_id(db: Session, tenant_id: uuid.UUID) -> Tenant | None:
        """ID로 테넌트 조회"""
        return (
            db.query(Tenant)
            .filter(and_(Tenant.id == tenant_id, ~Tenant.deleted))
            .first()
        )

    @staticmethod
    def get_tenant(db: Session, tenant_id: str) -> Tenant | None:
        """문자열 ID로 테넌트 조회"""
        try:
            tenant_uuid = uuid.UUID(tenant_id)
            return TenantService.get_tenant_by_id(db, tenant_uuid)
        except ValueError:
            return None

    @staticmethod
    def get_tenant_by_code(db: Session, tenant_code: str) -> Tenant | None:
        """테넌트 코드로 테넌트 조회"""
        return (
            db.query(Tenant)
            .filter(and_(Tenant.tenant_code == tenant_code, ~Tenant.deleted))
            .first()
        )

    @staticmethod
    def get_tenant_by_business_no(
        db: Session, business_no: str
    ) -> Tenant | None:
        """사업자등록번호로 테넌트 조회"""
        return (
            db.query(Tenant)
            .filter(and_(Tenant.business_no == business_no, ~Tenant.deleted))
            .first()
        )

    @staticmethod
    def create_tenant_with_request(
        db: Session,
        tenant_data: TenantCreateRequest,
        created_by: uuid.UUID | None = None,
    ) -> Tenant:
        """새 테넌트 생성 (Request 스키마 사용)"""

        # 테넌트 코드 중복 체크
        existing_tenant = TenantService.get_tenant_by_code(
            db, tenant_data.tenant_code
        )
        if existing_tenant:
            raise ValueError("이미 사용 중인 테넌트 코드입니다")

        # 사업자등록번호 중복 체크 (제공된 경우)
        if tenant_data.business_no:
            existing_business = TenantService.get_tenant_by_business_no(
                db, tenant_data.business_no
            )
            if existing_business:
                raise ValueError("이미 등록된 사업자등록번호입니다")

        # 새 테넌트 생성
        db_tenant = Tenant(
            **tenant_data.model_dump(),
            created_by=created_by,
            created_at=datetime.now(),
        )

        db.add(db_tenant)
        db.commit()
        db.refresh(db_tenant)

        return db_tenant

    @staticmethod
    def create_tenant(
        db: Session,
        tenant_data: TenantCreate,
        created_by: uuid.UUID | None = None,
    ) -> Tenant:
        """새 테넌트 생성 (새로운 PascalCase 스키마 사용)"""

        # 테넌트 코드 중복 체크
        existing_tenant = TenantService.get_tenant_by_code(
            db, tenant_data.tenant_code
        )
        if existing_tenant:
            raise ValueError("이미 사용 중인 테넌트 코드입니다")

        # 사업자등록번호 중복 체크 (제공된 경우)
        if tenant_data.business_no:
            existing_business = TenantService.get_tenant_by_business_no(
                db, tenant_data.business_no
            )
            if existing_business:
                raise ValueError("이미 등록된 사업자등록번호입니다")

        # 새 테넌트 생성
        db_tenant = Tenant(
            **tenant_data.model_dump(),
            created_by=created_by,
            created_at=datetime.now(),
        )

        db.add(db_tenant)
        db.commit()
        db.refresh(db_tenant)

        return db_tenant

    @staticmethod
    def update_tenant_with_request(
        db: Session,
        tenant_id: str,
        tenant_data: TenantUpdateRequest,
        updated_by: uuid.UUID | None = None,
    ) -> Tenant | None:
        """테넌트 정보 수정 (Request 스키마 사용)"""

        db_tenant = TenantService.get_tenant(db, tenant_id)
        if not db_tenant:
            return None

        # 테넌트 코드 변경 시 중복 체크
        if (
            tenant_data.tenant_code
            and tenant_data.tenant_code != db_tenant.tenant_code
        ):
            existing_tenant = TenantService.get_tenant_by_code(
                db, tenant_data.tenant_code
            )
            if existing_tenant:
                raise ValueError("이미 사용 중인 테넌트 코드입니다")

        # 사업자등록번호 변경 시 중복 체크
        if (
            tenant_data.business_no
            and tenant_data.business_no != db_tenant.business_no
        ):
            existing_business = TenantService.get_tenant_by_business_no(
                db, tenant_data.business_no
            )
            if existing_business:
                raise ValueError("이미 등록된 사업자등록번호입니다")

        # 수정 데이터 적용
        update_data = tenant_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            if value is not None:
                setattr(db_tenant, field, value)

        db_tenant.updated_at = datetime.now()
        db_tenant.updated_by = updated_by

        db.commit()
        db.refresh(db_tenant)

        return db_tenant

    @staticmethod
    def update_tenant(
        db: Session,
        tenant_id: str,
        tenant_data: TenantUpdate,
        updated_by: uuid.UUID | None = None,
    ) -> Tenant | None:
        """테넌트 정보 수정 (새로운 PascalCase 스키마 사용)"""

        db_tenant = TenantService.get_tenant(db, tenant_id)
        if not db_tenant:
            return None

        # 테넌트 코드 변경 시 중복 체크
        if (
            tenant_data.tenant_code
            and tenant_data.tenant_code != db_tenant.tenant_code
        ):
            existing_tenant = TenantService.get_tenant_by_code(
                db, tenant_data.tenant_code
            )
            if existing_tenant:
                raise ValueError("이미 사용 중인 테넌트 코드입니다")

        # 사업자등록번호 변경 시 중복 체크
        if (
            tenant_data.business_no
            and tenant_data.business_no != db_tenant.business_no
        ):
            existing_business = TenantService.get_tenant_by_business_no(
                db, tenant_data.business_no
            )
            if existing_business:
                raise ValueError("이미 등록된 사업자등록번호입니다")

        # 수정 데이터 적용
        update_data = tenant_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            if value is not None:
                setattr(db_tenant, field, value)

        db_tenant.updated_at = datetime.now()
        db_tenant.updated_by = updated_by

        db.commit()
        db.refresh(db_tenant)

        return db_tenant

    @staticmethod
    def delete_tenant(db: Session, tenant_id: str) -> bool:
        """테넌트 논리적 삭제"""

        db_tenant = TenantService.get_tenant(db, tenant_id)
        if not db_tenant:
            return False

        db_tenant.deleted = True
        db_tenant.updated_at = datetime.now()

        db.commit()

        return True

    @staticmethod
    def suspend_tenant(
        db: Session,
        tenant_id: str,
        updated_by: uuid.UUID | None = None,
    ) -> Tenant | None:
        """테넌트 정지"""

        db_tenant = TenantService.get_tenant(db, tenant_id)
        if not db_tenant:
            return None

        from .model import TenantStatus

        db_tenant.status = TenantStatus.SUSPENDED
        db_tenant.updated_at = datetime.now()
        db_tenant.updated_by = updated_by

        db.commit()
        db.refresh(db_tenant)

        return db_tenant

    @staticmethod
    def activate_tenant(
        db: Session,
        tenant_id: str,
        updated_by: uuid.UUID | None = None,
    ) -> Tenant | None:
        """테넌트 활성화"""

        db_tenant = TenantService.get_tenant(db, tenant_id)
        if not db_tenant:
            return None

        from .model import TenantStatus

        db_tenant.status = TenantStatus.ACTIVE
        db_tenant.updated_at = datetime.now()
        db_tenant.updated_by = updated_by

        db.commit()
        db.refresh(db_tenant)

        return db_tenant


__all__ = ["TenantService"]
