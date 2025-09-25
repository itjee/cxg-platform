from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from src.core.database import get_db
from src.schemas.common.response import EnvelopeResponse

from .schemas import (
    TenantCreateRequest,
    TenantResponse,
    TenantUpdateRequest,
)
from .service import TenantService

router = APIRouter(prefix="/tenants", tags=["TNNT - 테넌트 관리"])


@router.get("/", response_model=EnvelopeResponse[list[TenantResponse]])
async def get_tenants(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
):
    """
    테넌트 목록 조회

    시스템에 등록된 모든 테넌트 목록을 조회합니다. 페이지네이션을 지원하여 대량의 데이터를 효율적으로 처리합니다.

    **매개변수:**
    - **skip**: 건너뛸 레코드 수 (기본값: 0)
    - **limit**: 조회할 최대 레코드 수 (기본값: 100)

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 테넌트 정보 배열
      - 각 테넌트의 상세 정보 포함
      - 비즈니스 정보, 주소, 상태 등
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 500: 서버 내부 오류
    """
    try:
        tenants = TenantService.get_tenants(db, skip=skip, limit=limit)
        return EnvelopeResponse(success=True, data=tenants, error=None)
    except Exception as e:
        return EnvelopeResponse(
            success=False, data=None, error={"message": str(e)}
        )


@router.get("/{tenant_id}", response_model=EnvelopeResponse[TenantResponse])
async def get_tenant(
    tenant_id: str,
    db: Session = Depends(get_db),
):
    """
    특정 테넌트 조회

    테넌트 ID를 통해 특정 테넌트의 상세 정보를 조회합니다.

    **매개변수:**
    - **tenant_id**: 조회할 테넌트의 고유 식별자 (UUID)

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 테넌트 상세 정보
      - 기본 정보: 테넌트 코드, 이름, 유형
      - 비즈니스 정보: 사업자등록번호, 업종, 대표자명
      - 주소 정보: 우편번호, 주소1, 주소2
      - 설정 정보: 시간대, 로케일, 통화
      - 상태 정보: 활성화 여부, 생성/수정 일시
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 404: 테넌트를 찾을 수 없음
    - 500: 서버 내부 오류
    """
    tenant = TenantService.get_tenant(db, tenant_id)
    if not tenant:
        return EnvelopeResponse(
            success=False,
            data=None,
            error={"message": "테넌트를 찾을 수 없습니다"},
        )
    return EnvelopeResponse(success=True, data=tenant, error=None)


@router.post(
    "/",
    response_model=EnvelopeResponse[TenantResponse],
    status_code=status.HTTP_201_CREATED,
)
async def create_tenant(
    tenant_data: TenantCreateRequest,
    db: Session = Depends(get_db),
):
    """
    새 테넌트 생성

    새로운 테넌트를 시스템에 등록합니다. 멀티 테넌트 환경에서 새로운 고객사를 추가할 때 사용합니다.

    **매개변수:**
    - **tenant_data**: 테넌트 생성 정보
      - tenant_code: 테넌트 코드 (필수, 고유값)
      - tenant_name: 테넌트 명 (필수)
      - tenant_type: 테넌트 유형 (기본값: STANDARD)
      - business_no: 사업자등록번호 (선택)
      - business_name: 사업체명 (선택)
      - business_type: 사업체 유형 (기본값: CORPORATE)
      - ceo_name: 대표자명 (선택)
      - employee_count: 직원 수 (기본값: 0)
      - start_date: 서비스 시작일 (필수)
      - timezone: 시간대 (기본값: Asia/Seoul)
      - locale: 로케일 (기본값: ko-KR)
      - currency: 통화 (기본값: KRW)

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 생성된 테넌트 정보
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 400: 잘못된 요청 데이터
    - 409: 테넌트 코드 또는 사업자등록번호 중복
    - 500: 서버 내부 오류
    """
    try:
        tenant = TenantService.create_tenant_with_request(db, tenant_data)
        return EnvelopeResponse(success=True, data=tenant, error=None)
    except Exception as e:
        return EnvelopeResponse(
            success=False, data=None, error={"message": str(e)}
        )


@router.put("/{tenant_id}", response_model=EnvelopeResponse[TenantResponse])
async def update_tenant(
    tenant_id: str,
    tenant_data: TenantUpdateRequest,
    db: Session = Depends(get_db),
):
    """
    테넌트 정보 수정

    기존 테넌트의 정보를 부분적으로 또는 전체적으로 수정합니다.

    **매개변수:**
    - **tenant_id**: 수정할 테넌트의 고유 식별자 (UUID)
    - **tenant_data**: 수정할 테넌트 정보 (모든 필드 선택적)
      - 기본 정보: 테넌트 코드, 이름, 유형
      - 비즈니스 정보: 사업자등록번호, 업종, 대표자명
      - 연락처 정보: 전화번호, 주소
      - 설정 정보: 시간대, 로케일, 통화
      - 운영 정보: 직원 수, 서비스 기간

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 수정된 테넌트 정보
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 400: 잘못된 요청 데이터
    - 404: 테넌트를 찾을 수 없음
    - 409: 테넌트 코드 또는 사업자등록번호 중복
    - 500: 서버 내부 오류
    """
    tenant = TenantService.update_tenant_with_request(
        db, tenant_id, tenant_data
    )
    if not tenant:
        return EnvelopeResponse(
            success=False,
            data=None,
            error={"message": "테넌트를 찾을 수 없습니다"},
        )
    return EnvelopeResponse(success=True, data=tenant, error=None)


@router.delete("/{tenant_id}")
async def delete_tenant(
    tenant_id: str,
    db: Session = Depends(get_db),
):
    """
    테넌트 삭제

    특정 테넌트를 시스템에서 논리적으로 삭제합니다. 실제 데이터는 유지되지만 deleted 플래그가 설정됩니다.

    **매개변수:**
    - **tenant_id**: 삭제할 테넌트의 고유 식별자 (UUID)

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 삭제 결과 메시지
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 404: 테넌트를 찾을 수 없음
    - 500: 서버 내부 오류

    **주의사항:**
    - 논리적 삭제로 데이터는 보존됩니다
    - 삭제된 테넌트는 일반 목록에서 노출되지 않습니다
    - 관련된 사용자 데이터도 영향을 받을 수 있습니다
    """
    success = TenantService.delete_tenant(db, tenant_id)
    if not success:
        return EnvelopeResponse(
            success=False,
            data=None,
            error={"message": "테넌트를 찾을 수 없습니다"},
        )
    return EnvelopeResponse(
        success=True,
        data={"message": "테넌트가 성공적으로 삭제되었습니다"},
        error=None,
    )


@router.patch("/{tenant_id}/suspend")
async def suspend_tenant(
    tenant_id: str,
    db: Session = Depends(get_db),
):
    """
    테넌트 일시정지

    특정 테넌트의 서비스를 일시적으로 중단합니다. 계약 만료, 결제 지연, 정책 위반 등의 사유로 서비스를 잠시 중단할 때 사용합니다.

    **매개변수:**
    - **tenant_id**: 일시정지할 테넌트의 고유 식별자 (UUID)

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 업데이트된 테넌트 정보
      - 상태가 SUSPENDED로 변경됨
      - 일시정지 시점 기록
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 404: 테넌트를 찾을 수 없음
    - 409: 이미 일시정지된 테넌트
    - 500: 서버 내부 오류

    **주의사항:**
    - 일시정지된 테넌트는 로그인 및 서비스 이용이 제한됩니다
    - 테넌트 사용자들의 세션이 무효화될 수 있습니다
    - 일시정지 해제는 activate 엔드포인트를 사용하여 가능합니다
    """
    tenant = TenantService.suspend_tenant(db, tenant_id)
    if not tenant:
        return EnvelopeResponse(
            success=False,
            data=None,
            error={"message": "테넌트를 찾을 수 없습니다"},
        )
    return EnvelopeResponse(success=True, data=tenant, error=None)


@router.patch("/{tenant_id}/activate")
async def activate_tenant(
    tenant_id: str,
    db: Session = Depends(get_db),
):
    """
    테넌트 활성화

    일시정지된 테넌트의 서비스를 다시 활성화합니다. 결제 완료, 계약 갱신, 정책 준수 등의 조건 충족 후 서비스를 재개할 때 사용합니다.

    **매개변수:**
    - **tenant_id**: 활성화할 테넌트의 고유 식별자 (UUID)

    **반환값:**
    - **success**: 요청 성공 여부
    - **data**: 업데이트된 테넌트 정보
      - 상태가 ACTIVE로 변경됨
      - 활성화 시점 기록
    - **error**: 오류 정보 (실패 시)

    **예외:**
    - 404: 테넌트를 찾을 수 없음
    - 409: 이미 활성화된 테넌트
    - 500: 서버 내부 오류

    **주의사항:**
    - 활성화된 테넌트는 즉시 모든 서비스 이용이 가능합니다
    - 기존 사용자 계정들이 복원되어 로그인할 수 있습니다
    - 일시정지 기간 중의 데이터는 그대로 보존됩니다
    """
    tenant = TenantService.activate_tenant(db, tenant_id)
    if not tenant:
        return EnvelopeResponse(
            success=False,
            data=None,
            error={"message": "테넌트를 찾을 수 없습니다"},
        )
    return EnvelopeResponse(success=True, data=tenant, error=None)


__all__ = ["router"]
