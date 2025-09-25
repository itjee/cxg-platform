from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from src.core.database import get_db
from src.schemas.common.response import EnvelopeResponse

from .schemas import (
    PermissionCreateRequest,
    PermissionResponse,
    PermissionUpdateRequest,
)
from .service import PermissionService

router = APIRouter(prefix="/permissions", tags=["IDAM - 권한 관리"])


@router.get("/", response_model=EnvelopeResponse[list[PermissionResponse]])
async def get_permissions(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    """
    권한 목록 조회
    """
    try:
        permissions = PermissionService.get_permissions(db, skip, limit)
        return EnvelopeResponse(success=True, data=permissions, error=None)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.get(
    "/{permission_id}", response_model=EnvelopeResponse[PermissionResponse]
)
async def get_permission(
    permission_id: str,
    db: Session = Depends(get_db),
):
    """
    특정 권한 조회
    """
    try:
        permission = PermissionService.get_permission_by_id(db, permission_id)
        if not permission:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Permission not found",
            )
        return EnvelopeResponse(success=True, data=permission, error=None)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.post(
    "/",
    response_model=EnvelopeResponse[PermissionResponse],
    status_code=status.HTTP_201_CREATED,
)
async def create_permission(
    permission_data: PermissionCreateRequest,
    db: Session = Depends(get_db),
):
    """
    새로운 권한 생성
    """
    try:
        permission = PermissionService.create_permission(db, permission_data)
        return EnvelopeResponse(success=True, data=permission, error=None)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.put(
    "/{permission_id}", response_model=EnvelopeResponse[PermissionResponse]
)
async def update_permission(
    permission_id: str,
    permission_data: PermissionUpdateRequest,
    db: Session = Depends(get_db),
):
    """
    권한 정보 수정
    """
    try:
        permission = PermissionService.update_permission(
            db, permission_id, permission_data
        )
        if not permission:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Permission not found",
            )
        return EnvelopeResponse(success=True, data=permission, error=None)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.delete("/{permission_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_permission(
    permission_id: str,
    db: Session = Depends(get_db),
):
    """
    권한 삭제
    """
    try:
        success = PermissionService.delete_permission(db, permission_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Permission not found",
            )
        return EnvelopeResponse(success=True, data=None, error=None)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )
