"""
공통 응답 스키마 모듈

모든 API 응답에서 사용할 수 있는 공통 스키마들을 정의합니다.
"""

from typing import Generic, TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class EnvelopeResponse(BaseModel, Generic[T]):
    """
    API 응답을 감싸는 공통 엔벨로프 구조

    모든 API 응답은 이 구조를 따라 일관된 형태로 반환됩니다.

    Attributes:
        success (bool): 요청 성공 여부
        data (Optional[T]): 실제 응답 데이터 (성공 시)
        error (Optional[dict]): 에러 정보 (실패 시)
    """

    success: bool
    data: T | None = None
    error: dict | None = None
