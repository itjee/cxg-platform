from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from typing import List
from src.schemas.tenant import Tenant, TenantCreate, TenantUpdate
import uuid

router = APIRouter(tags=["테넌트 관리"], prefix="/tenants")

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/login")

# 임시 테넌트 데이터 (실제로는 데이터베이스에서 가져와야 함)
fake_tenants_db = {
    "1": {
        "id": "1",
        "name": "스마트솔루션",
        "domain": "smartsol.com",
        "status": "ACTIVE",
        "plan": "Pro",
        "users_count": 25,
        "last_activity": "2시간 전",
        "created_at": "2024-01-15T00:00:00",
        "updated_at": "2024-01-15T00:00:00"
    },
    "2": {
        "id": "2",
        "name": "테크스타트업",
        "domain": "techstartup.co.kr",
        "status": "ACTIVE",
        "plan": "Basic",
        "users_count": 8,
        "last_activity": "1일 전",
        "created_at": "2024-02-20T00:00:00",
        "updated_at": "2024-02-20T00:00:00"
    },
    "3": {
        "id": "3",
        "name": "글로벌트레이딩",
        "domain": "globaltrading.com",
        "status": "SUSPENDED",
        "plan": "Enterprise",
        "users_count": 0,
        "last_activity": "1주 전",
        "created_at": "2024-01-05T00:00:00",
        "updated_at": "2024-01-05T00:00:00"
    }
}

async def get_current_user(token: str = Depends(oauth2_scheme)):
    # 토큰 검증 로직 (간단화)
    return {"email": "admin@example.com", "role": "admin"}

@router.get("/", response_model=List[Tenant])
async def get_tenants(current_user: dict = Depends(get_current_user)):
    return [Tenant(**tenant) for tenant in fake_tenants_db.values()]

@router.get("/{tenant_id}", response_model=Tenant)
async def get_tenant(tenant_id: str, current_user: dict = Depends(get_current_user)):
    if tenant_id not in fake_tenants_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="테넌트를 찾을 수 없습니다"
        )
    return Tenant(**fake_tenants_db[tenant_id])

@router.post("/", response_model=Tenant)
async def create_tenant(tenant_data: TenantCreate, current_user: dict = Depends(get_current_user)):
    # 도메인 중복 체크
    for tenant in fake_tenants_db.values():
        if tenant["domain"] == tenant_data.domain:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="이미 등록된 도메인입니다"
            )

    # 새 테넌트 생성
    tenant_id = str(uuid.uuid4())
    new_tenant = {
        "id": tenant_id,
        "name": tenant_data.name,
        "domain": tenant_data.domain,
        "status": tenant_data.status,
        "plan": tenant_data.plan,
        "users_count": 0,
        "last_activity": "방금 전",
        "created_at": "2024-01-01T00:00:00",
        "updated_at": "2024-01-01T00:00:00"
    }

    fake_tenants_db[tenant_id] = new_tenant
    return Tenant(**new_tenant)

@router.put("/{tenant_id}", response_model=Tenant)
async def update_tenant(
    tenant_id: str,
    tenant_data: TenantUpdate,
    current_user: dict = Depends(get_current_user)
):
    if tenant_id not in fake_tenants_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="테넌트를 찾을 수 없습니다"
        )

    tenant = fake_tenants_db[tenant_id]
    update_data = tenant_data.model_dump(exclude_unset=True)

    # 도메인 중복 체크 (변경하는 경우)
    if "domain" in update_data:
        for tid, t in fake_tenants_db.items():
            if tid != tenant_id and t["domain"] == update_data["domain"]:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="이미 등록된 도메인입니다"
                )

    for field, value in update_data.items():
        if value is not None:
            tenant[field] = value

    tenant["updated_at"] = "2024-01-01T00:00:00"  # 실제로는 현재 시간

    return Tenant(**tenant)

@router.delete("/{tenant_id}")
async def delete_tenant(tenant_id: str, current_user: dict = Depends(get_current_user)):
    if tenant_id not in fake_tenants_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="테넌트를 찾을 수 없습니다"
        )

    del fake_tenants_db[tenant_id]
    return {"message": "테넌트가 삭제되었습니다"}

@router.post("/{tenant_id}/suspend")
async def suspend_tenant(tenant_id: str, current_user: dict = Depends(get_current_user)):
    if tenant_id not in fake_tenants_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="테넌트를 찾을 수 없습니다"
        )

    tenant = fake_tenants_db[tenant_id]
    tenant["status"] = "SUSPENDED"
    tenant["updated_at"] = "2024-01-01T00:00:00"

    return {"message": "테넌트가 정지되었습니다"}

@router.post("/{tenant_id}/activate")
async def activate_tenant(tenant_id: str, current_user: dict = Depends(get_current_user)):
    if tenant_id not in fake_tenants_db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="테넌트를 찾을 수 없습니다"
        )

    tenant = fake_tenants_db[tenant_id]
    tenant["status"] = "ACTIVE"
    tenant["updated_at"] = "2024-01-01T00:00:00"

    return {"message": "테넌트가 활성화되었습니다"}