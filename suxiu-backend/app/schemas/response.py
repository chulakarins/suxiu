"""
统一 API 响应格式
"""
from typing import Optional, Any, TypeVar, Generic
from pydantic import BaseModel

T = TypeVar('T')


class APIResponse(BaseModel, Generic[T]):
    """统一 API 响应格式"""
    code: int = 0
    message: str = "success"
    data: Optional[T] = None
    request_id: Optional[str] = None


def success_response(data: Any = None, message: str = "success") -> dict:
    """成功响应"""
    return {
        "code": 0,
        "message": message,
        "data": data
    }


def error_response(code: int, message: str) -> dict:
    """错误响应"""
    return {
        "code": code,
        "message": message
    }


# 错误码定义
class ErrorCode:
    # 通用错误 (1000-1999)
    SUCCESS = 0
    PARAM_ERROR = 1001
    AUTH_ERROR = 1002
    PERMISSION_DENIED = 1003
    NOT_FOUND = 1004
    INTERNAL_ERROR = 1005

    # AI 服务错误 (2000-2999)
    AI_SERVICE_ERROR = 2001
    AI_GENERATION_TIMEOUT = 2002
    AI_INVALID_PROMPT = 2003

    # 数据库错误 (3000-3999)
    DATABASE_ERROR = 3001
    RECORD_NOT_FOUND = 3002
    DUPLICATE_RECORD = 3003

    # 订单错误 (4000-4999)
    ORDER_ERROR = 4001
    ORDER_NOT_FOUND = 4002
    ORDER_STATUS_INVALID = 4003

    # 工厂错误 (5000-5999)
    FACTORY_NOT_FOUND = 5001
    FACTORY_MATCH_FAILED = 5002
