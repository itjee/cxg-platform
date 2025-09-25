"""
IDAM 기본 데이터 생성 스크립트
권한과 역할에 대한 기본 데이터를 생성합니다.
"""

import uuid
from datetime import datetime

from sqlalchemy.orm import Session

from src.core.database import get_db

from .permission.model import Permission
from .role.model import Role
from .role_permission.model import RolePermission


def create_basic_permissions(db: Session):
    """기본 권한 데이터 생성"""

    basic_permissions = [
        # 사용자 관리 권한
        {
            "permission_code": "USER_CREATE",
            "permission_name": "사용자 생성",
            "description": "새로운 사용자 계정을 생성할 수 있는 권한",
            "category": "USER",
            "resource_type": "USER",
            "action": "CREATE",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "USER_READ",
            "permission_name": "사용자 조회",
            "description": "사용자 정보를 조회할 수 있는 권한",
            "category": "USER",
            "resource_type": "USER",
            "action": "READ",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "USER_UPDATE",
            "permission_name": "사용자 수정",
            "description": "사용자 정보를 수정할 수 있는 권한",
            "category": "USER",
            "resource_type": "USER",
            "action": "UPDATE",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "USER_DELETE",
            "permission_name": "사용자 삭제",
            "description": "사용자 계정을 삭제할 수 있는 권한",
            "category": "USER",
            "resource_type": "USER",
            "action": "DELETE",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "USER_LIST",
            "permission_name": "사용자 목록 조회",
            "description": "사용자 목록을 조회할 수 있는 권한",
            "category": "USER",
            "resource_type": "USER",
            "action": "LIST",
            "is_system": False,
            "status": "ACTIVE",
        },
        # 역할 관리 권한
        {
            "permission_code": "ROLE_CREATE",
            "permission_name": "역할 생성",
            "description": "새로운 역할을 생성할 수 있는 권한",
            "category": "ADMIN",
            "resource_type": "ROLE",
            "action": "CREATE",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "ROLE_READ",
            "permission_name": "역할 조회",
            "description": "역할 정보를 조회할 수 있는 권한",
            "category": "ADMIN",
            "resource_type": "ROLE",
            "action": "READ",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "ROLE_UPDATE",
            "permission_name": "역할 수정",
            "description": "역할 정보를 수정할 수 있는 권한",
            "category": "ADMIN",
            "resource_type": "ROLE",
            "action": "UPDATE",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "ROLE_DELETE",
            "permission_name": "역할 삭제",
            "description": "역할을 삭제할 수 있는 권한",
            "category": "ADMIN",
            "resource_type": "ROLE",
            "action": "DELETE",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "ROLE_LIST",
            "permission_name": "역할 목록 조회",
            "description": "역할 목록을 조회할 수 있는 권한",
            "category": "ADMIN",
            "resource_type": "ROLE",
            "action": "LIST",
            "is_system": False,
            "status": "ACTIVE",
        },
        # 권한 관리 권한
        {
            "permission_code": "PERMISSION_CREATE",
            "permission_name": "권한 생성",
            "description": "새로운 권한을 생성할 수 있는 권한",
            "category": "ADMIN",
            "resource_type": "PERMISSION",
            "action": "CREATE",
            "is_system": True,
            "status": "ACTIVE",
        },
        {
            "permission_code": "PERMISSION_READ",
            "permission_name": "권한 조회",
            "description": "권한 정보를 조회할 수 있는 권한",
            "category": "ADMIN",
            "resource_type": "PERMISSION",
            "action": "READ",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "PERMISSION_UPDATE",
            "permission_name": "권한 수정",
            "description": "권한 정보를 수정할 수 있는 권한",
            "category": "ADMIN",
            "resource_type": "PERMISSION",
            "action": "UPDATE",
            "is_system": True,
            "status": "ACTIVE",
        },
        {
            "permission_code": "PERMISSION_DELETE",
            "permission_name": "권한 삭제",
            "description": "권한을 삭제할 수 있는 권한",
            "category": "ADMIN",
            "resource_type": "PERMISSION",
            "action": "DELETE",
            "is_system": True,
            "status": "ACTIVE",
        },
        {
            "permission_code": "PERMISSION_LIST",
            "permission_name": "권한 목록 조회",
            "description": "권한 목록을 조회할 수 있는 권한",
            "category": "ADMIN",
            "resource_type": "PERMISSION",
            "action": "LIST",
            "is_system": False,
            "status": "ACTIVE",
        },
        # 테넌트 관리 권한
        {
            "permission_code": "TENANT_CREATE",
            "permission_name": "테넌트 생성",
            "description": "새로운 테넌트를 생성할 수 있는 권한",
            "category": "TENANT",
            "resource_type": "TENANT",
            "action": "CREATE",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "TENANT_READ",
            "permission_name": "테넌트 조회",
            "description": "테넌트 정보를 조회할 수 있는 권한",
            "category": "TENANT",
            "resource_type": "TENANT",
            "action": "READ",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "TENANT_UPDATE",
            "permission_name": "테넌트 수정",
            "description": "테넌트 정보를 수정할 수 있는 권한",
            "category": "TENANT",
            "resource_type": "TENANT",
            "action": "UPDATE",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "TENANT_DELETE",
            "permission_name": "테넌트 삭제",
            "description": "테넌트를 삭제할 수 있는 권한",
            "category": "TENANT",
            "resource_type": "TENANT",
            "action": "DELETE",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "TENANT_LIST",
            "permission_name": "테넌트 목록 조회",
            "description": "테넌트 목록을 조회할 수 있는 권한",
            "category": "TENANT",
            "resource_type": "TENANT",
            "action": "LIST",
            "is_system": False,
            "status": "ACTIVE",
        },
        # API 키 관리 권한
        {
            "permission_code": "API_KEY_CREATE",
            "permission_name": "API 키 생성",
            "description": "새로운 API 키를 생성할 수 있는 권한",
            "category": "API",
            "resource_type": "API_KEY",
            "action": "CREATE",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "API_KEY_READ",
            "permission_name": "API 키 조회",
            "description": "API 키 정보를 조회할 수 있는 권한",
            "category": "API",
            "resource_type": "API_KEY",
            "action": "READ",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "API_KEY_UPDATE",
            "permission_name": "API 키 수정",
            "description": "API 키 정보를 수정할 수 있는 권한",
            "category": "API",
            "resource_type": "API_KEY",
            "action": "UPDATE",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "API_KEY_DELETE",
            "permission_name": "API 키 삭제",
            "description": "API 키를 삭제할 수 있는 권한",
            "category": "API",
            "resource_type": "API_KEY",
            "action": "DELETE",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "API_KEY_LIST",
            "permission_name": "API 키 목록 조회",
            "description": "API 키 목록을 조회할 수 있는 권한",
            "category": "API",
            "resource_type": "API_KEY",
            "action": "LIST",
            "is_system": False,
            "status": "ACTIVE",
        },
        # 시스템 관리 권한
        {
            "permission_code": "SYSTEM_ADMIN",
            "permission_name": "시스템 관리자",
            "description": "모든 시스템 리소스에 대한 관리 권한",
            "category": "SYSTEM",
            "resource_type": "SYSTEM",
            "action": "MANAGE",
            "is_system": True,
            "status": "ACTIVE",
        },
        {
            "permission_code": "AUDIT_VIEW",
            "permission_name": "감사 로그 조회",
            "description": "시스템 감사 로그를 조회할 수 있는 권한",
            "category": "SYSTEM",
            "resource_type": "AUDIT",
            "action": "VIEW",
            "is_system": False,
            "status": "ACTIVE",
        },
        {
            "permission_code": "DASHBOARD_VIEW",
            "permission_name": "대시보드 조회",
            "description": "관리자 대시보드를 조회할 수 있는 권한",
            "category": "SYSTEM",
            "resource_type": "SYSTEM",
            "action": "VIEW",
            "is_system": False,
            "status": "ACTIVE",
        },
    ]

    created_permissions = []
    for perm_data in basic_permissions:
        # 중복 확인
        existing = (
            db.query(Permission)
            .filter(Permission.permission_code == perm_data["permission_code"])
            .first()
        )

        if not existing:
            permission = Permission(
                id=str(uuid.uuid4()),
                **perm_data,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            db.add(permission)
            created_permissions.append(permission)

    db.commit()
    return created_permissions


def create_basic_roles(db: Session):
    """기본 역할 데이터 생성"""

    basic_roles = [
        {
            "role_code": "SUPER_ADMIN",
            "role_name": "슈퍼 관리자",
            "description": "모든 시스템 권한을 가진 최고 관리자",
            "role_type": "SYSTEM",
            "is_default": False,
            "priority": 1,
            "status": "ACTIVE",
        },
        {
            "role_code": "ADMIN",
            "role_name": "관리자",
            "description": "시스템 관리 권한을 가진 관리자",
            "role_type": "ADMIN",
            "is_default": False,
            "priority": 10,
            "status": "ACTIVE",
        },
        {
            "role_code": "TENANT_ADMIN",
            "role_name": "테넌트 관리자",
            "description": "테넌트 관리 권한을 가진 관리자",
            "role_type": "CUSTOM",
            "is_default": False,
            "priority": 20,
            "status": "ACTIVE",
        },
        {
            "role_code": "USER_MANAGER",
            "role_name": "사용자 매니저",
            "description": "사용자 관리 권한을 가진 매니저",
            "role_type": "CUSTOM",
            "is_default": False,
            "priority": 30,
            "status": "ACTIVE",
        },
        {
            "role_code": "VIEWER",
            "role_name": "뷰어",
            "description": "읽기 전용 권한을 가진 사용자",
            "role_type": "CUSTOM",
            "is_default": True,
            "priority": 100,
            "status": "ACTIVE",
        },
    ]

    created_roles = []
    for role_data in basic_roles:
        # 중복 확인
        existing = (
            db.query(Role)
            .filter(Role.role_code == role_data["role_code"])
            .first()
        )

        if not existing:
            role = Role(
                id=str(uuid.uuid4()),
                **role_data,
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            db.add(role)
            created_roles.append(role)

    db.commit()
    return created_roles


def assign_permissions_to_roles(db: Session):
    """역할에 권한 할당"""

    # 모든 권한과 역할 조회
    permissions = {p.permission_code: p for p in db.query(Permission).all()}
    roles = {r.role_code: r for r in db.query(Role).all()}

    # 역할별 권한 할당 정의
    role_permissions = {
        "SUPER_ADMIN": [
            # 모든 권한
            perm_code
            for perm_code in permissions.keys()
        ],
        "ADMIN": [
            "USER_CREATE",
            "USER_READ",
            "USER_UPDATE",
            "USER_DELETE",
            "USER_LIST",
            "ROLE_CREATE",
            "ROLE_READ",
            "ROLE_UPDATE",
            "ROLE_DELETE",
            "ROLE_LIST",
            "PERMISSION_READ",
            "PERMISSION_LIST",
            "TENANT_CREATE",
            "TENANT_READ",
            "TENANT_UPDATE",
            "TENANT_DELETE",
            "TENANT_LIST",
            "API_KEY_CREATE",
            "API_KEY_READ",
            "API_KEY_UPDATE",
            "API_KEY_DELETE",
            "API_KEY_LIST",
            "AUDIT_VIEW",
            "DASHBOARD_VIEW",
        ],
        "TENANT_ADMIN": [
            "TENANT_READ",
            "TENANT_UPDATE",
            "TENANT_LIST",
            "USER_READ",
            "USER_LIST",
            "API_KEY_CREATE",
            "API_KEY_READ",
            "API_KEY_UPDATE",
            "API_KEY_DELETE",
            "API_KEY_LIST",
            "DASHBOARD_VIEW",
        ],
        "USER_MANAGER": [
            "USER_CREATE",
            "USER_READ",
            "USER_UPDATE",
            "USER_LIST",
            "ROLE_READ",
            "ROLE_LIST",
            "DASHBOARD_VIEW",
        ],
        "VIEWER": [
            "USER_READ",
            "USER_LIST",
            "ROLE_READ",
            "ROLE_LIST",
            "PERMISSION_READ",
            "PERMISSION_LIST",
            "TENANT_READ",
            "TENANT_LIST",
            "API_KEY_READ",
            "API_KEY_LIST",
            "DASHBOARD_VIEW",
        ],
    }

    created_assignments = []
    for role_code, perm_codes in role_permissions.items():
        if role_code not in roles:
            continue

        role = roles[role_code]

        for perm_code in perm_codes:
            if perm_code not in permissions:
                continue

            permission = permissions[perm_code]

            # 중복 확인
            existing = (
                db.query(RolePermission)
                .filter(
                    RolePermission.role_id == role.id,
                    RolePermission.permission_id == permission.id,
                )
                .first()
            )

            if not existing:
                role_permission = RolePermission(
                    id=str(uuid.uuid4()),
                    role_id=role.id,
                    permission_id=permission.id,
                    granted_by="system",
                    created_at=datetime.utcnow(),
                    updated_at=datetime.utcnow(),
                )
                db.add(role_permission)
                created_assignments.append(role_permission)

    db.commit()
    return created_assignments


def seed_idam_data():
    """IDAM 기본 데이터 전체 생성"""
    db = next(get_db())

    try:
        print("권한 기본 데이터 생성 중...")
        permissions = create_basic_permissions(db)
        print(f"권한 {len(permissions)}개 생성 완료")

        print("역할 기본 데이터 생성 중...")
        roles = create_basic_roles(db)
        print(f"역할 {len(roles)}개 생성 완료")

        print("역할-권한 할당 중...")
        assignments = assign_permissions_to_roles(db)
        print(f"역할-권한 할당 {len(assignments)}개 완료")

        print("IDAM 기본 데이터 생성이 완료되었습니다!")

    except Exception as e:
        print(f"데이터 생성 중 오류 발생: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed_idam_data()
