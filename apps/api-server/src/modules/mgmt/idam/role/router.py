from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from src.core.database import get_db
from src.schemas.common.response import EnvelopeResponse

from .schemas import RoleCreateRequest, RoleResponse, RoleUpdateRequest
from .service import RoleService

router = APIRouter(prefix="/roles", tags=["IDAM - 역할 관리"])


@router.get("/", response_model=EnvelopeResponse[list[RoleResponse]])
async def get_roles(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    """
    역할 목록 조회
    """
    try:
        roles = RoleService.get_roles(db, skip, limit)
        return EnvelopeResponse(success=True, data=roles, error=None)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.get("/{role_id}", response_model=EnvelopeResponse[RoleResponse])
async def get_role(
    role_id: str,
    db: Session = Depends(get_db),
):
    """
    특정 역할 조회
    """
    try:
        role = RoleService.get_role_by_id(db, role_id)
        if not role:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Role not found"
            )
        return EnvelopeResponse(success=True, data=role, error=None)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.post(
    "/",
    response_model=EnvelopeResponse[RoleResponse],
    status_code=status.HTTP_201_CREATED,
)
async def create_role(
    role_data: RoleCreateRequest,
    db: Session = Depends(get_db),
):
    """
    새로운 역할 생성
    """
    try:
        role = RoleService.create_role(db, role_data)
        return EnvelopeResponse(success=True, data=role, error=None)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.put("/{role_id}", response_model=EnvelopeResponse[RoleResponse])
async def update_role(
    role_id: str,
    role_data: RoleUpdateRequest,
    db: Session = Depends(get_db),
):
    """
    역할 정보 수정
    """
    try:
        role = RoleService.update_role(db, role_id, role_data)
        if not role:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Role not found"
            )
        return EnvelopeResponse(success=True, data=role, error=None)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.delete("/{role_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_role(
    role_id: str,
    db: Session = Depends(get_db),
):
    """
    역할 삭제
    """
    try:
        success = RoleService.delete_role(db, role_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Role not found"
            )
        return EnvelopeResponse(success=True, data=None, error=None)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )
