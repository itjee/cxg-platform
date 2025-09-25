# ✅ 올바른 API 엔드포인트 예시

이 문서는 CXG 플랫폼 백엔드 API 엔드포인트 구현의 모범 사례를 보여주는 예시입니다. FastAPI를 사용하여 고객 생성 엔드포인트를 정의하는 방법을 보여줍니다.

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional

router = APIRouter(prefix="/api/v1/customers", tags=["customers"])

<!-- Import failed: router.post("/", - ENOENT: no such file or directory, access '/home/itjee/.gemini/router.post("/",' --> response_model=CustomerResponse)
async def create_customer_endpoint(
    customer_data: CustomerCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
) -> CustomerResponse:
    """
    신규 고객 등록
    - 권한 체크: customer:create 필요
    - 중복 검사: 이메일, 사업자번호
    - 이벤트 발행: customer.created
    """
    try:
        # 권한 체크
        await check_permission(current_user, "customer:create")

        # 중복 검사
        existing = await customer_service.get_by_email(customer_data.email)
        if existing:
            raise HTTPException(409, "Email already exists")

        # 비즈니스 로직
        customer = await customer_service.create(customer_data)

        # 이벤트 발행
        await event_bus.publish("customer.created", {
            "customer_id": customer.id,
            "tenant_id": current_user.tenant_id
        })

        # 로깅
        logger.info(f"Customer created: {customer.id}")

        return customer

    except ValidationError as e:
        raise HTTPException(400, f"Validation error: {e}")
    except Exception as e:
        logger.error(f"Failed to create customer: {e}")
        raise HTTPException(500, "Internal server error")
```
