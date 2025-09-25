from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from src.core.database import get_db
from src.schemas.common.response import EnvelopeResponse

from .schemas import UserRoleCreateRequest, UserRoleResponse
from .service import UserRoleService

router = APIRouter(prefix="/user-roles", tags=["IDAM - 사용자 역할 관리"])


@router.get(
    "/users/{user_id}", response_model=EnvelopeResponse[list[UserRoleResponse]]
)
async def get_user_roles(
    user_id: str,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    """
    특정 사용자의 역할 매핑 목록 조회
    """
    try:
        user_roles = UserRoleService.get_user_roles(db, user_id, skip, limit)
        return EnvelopeResponse(success=True, data=user_roles, error=None)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.post(
    "/assign",
    response_model=EnvelopeResponse[UserRoleResponse],
    status_code=status.HTTP_201_CREATED,
)
async def assign_role_to_user(
    user_role_data: UserRoleCreateRequest,
    db: Session = Depends(get_db),
):
    """
    사용자에게 역할 할당
    """
    try:
        user_role = UserRoleService.assign_role_to_user(db, user_role_data)
        return EnvelopeResponse(success=True, data=user_role, error=None)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.delete("/unassign", status_code=status.HTTP_204_NO_CONTENT)
async def unassign_role_from_user(
    user_id: str,
    role_id: str,
    db: Session = Depends(get_db),
):
    """
    사용자로부터 역할 해제
    """
    try:
        success = UserRoleService.unassign_role_from_user(db, user_id, role_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User-Role mapping not found",
            )
        return EnvelopeResponse(success=True, data=None, error=None)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


__all__ = ["router"]
