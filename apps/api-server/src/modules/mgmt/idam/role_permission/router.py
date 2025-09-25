from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from src.core.database import get_db
from src.schemas.common.response import EnvelopeResponse

from .schemas import RolePermissionCreateRequest, RolePermissionResponse
from .service import RolePermissionService

router = APIRouter(prefix="/role-permissions", tags=["IDAM - 역할 권한 관리"])


@router.get(
    "/roles/{role_id}",
    response_model=EnvelopeResponse[list[RolePermissionResponse]],
)
async def get_role_permissions(
    role_id: str,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    """
    특정 역할의 권한 매핑 목록 조회
    """
    try:
        role_permissions = RolePermissionService.get_role_permissions(
            db, role_id, skip, limit
        )
        return EnvelopeResponse(
            success=True, data=role_permissions, error=None
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.post(
    "/assign",
    response_model=EnvelopeResponse[RolePermissionResponse],
    status_code=status.HTTP_201_CREATED,
)
async def assign_permission_to_role(
    role_permission_data: RolePermissionCreateRequest,
    db: Session = Depends(get_db),
):
    """
    역할에 권한 할당
    """
    try:
        # Convert Request model to service model
        from .schemas import RolePermissionCreate

        service_data = RolePermissionCreate(
            role_id=role_permission_data.role_id,
            permission_id=role_permission_data.permission_id,
        )
        role_permission = RolePermissionService.assign_permission_to_role(
            db, service_data
        )
        return EnvelopeResponse(success=True, data=role_permission, error=None)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.delete("/unassign", status_code=status.HTTP_204_NO_CONTENT)
async def unassign_permission_from_role(
    role_id: str,
    permission_id: str,
    db: Session = Depends(get_db),
):
    """
    역할로부터 권한 해제
    """
    try:
        success = RolePermissionService.unassign_permission_from_role(
            db, role_id, permission_id
        )
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Role-Permission mapping not found",
            )
        return EnvelopeResponse(success=True, data=None, error=None)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


__all__ = ["router"]
