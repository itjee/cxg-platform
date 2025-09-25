from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from src.core.database import get_db
from src.schemas.common.response import EnvelopeResponse

from .schemas import (
    ApiKeyCreateRequest,
    ApiKeyResponse,
    ApiKeyUpdateRequest,
)
from .service import ApiKeyService

router = APIRouter(prefix="/api-keys", tags=["IDAM - API 키 관리"])


@router.get(
    "/users/{user_id}", response_model=EnvelopeResponse[list[ApiKeyResponse]]
)
async def get_api_keys_for_user(
    user_id: str,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    """
    특정 사용자의 API 키 목록 조회
    """
    try:
        api_keys = ApiKeyService.get_api_keys_for_user(
            db, user_id, skip, limit
        )
        return EnvelopeResponse(success=True, data=api_keys, error=None)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.post(
    "/users/{user_id}",
    response_model=EnvelopeResponse[ApiKeyResponse],
    status_code=status.HTTP_201_CREATED,
)
async def create_api_key(
    user_id: str,
    api_key_data: ApiKeyCreateRequest,
    db: Session = Depends(get_db),
):
    """
    새로운 API 키 생성
    """
    try:
        api_key = ApiKeyService.create_api_key(db, user_id, api_key_data)
        return EnvelopeResponse(success=True, data=api_key, error=None)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.put("/{api_key_id}", response_model=EnvelopeResponse[ApiKeyResponse])
async def update_api_key(
    api_key_id: str,
    api_key_data: ApiKeyUpdateRequest,
    db: Session = Depends(get_db),
):
    """
    API 키 정보 수정
    """
    try:
        api_key = ApiKeyService.update_api_key(db, api_key_id, api_key_data)
        if not api_key:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="API Key not found",
            )
        return EnvelopeResponse(success=True, data=api_key, error=None)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )


@router.delete("/{api_key_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_api_key(
    api_key_id: str,
    db: Session = Depends(get_db),
):
    """
    API 키 삭제
    """
    try:
        success = ApiKeyService.delete_api_key(db, api_key_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="API Key not found",
            )
        return EnvelopeResponse(success=True, data=None, error=None)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=str(e)
        )
