"""
中间件：请求验证和错误处理
"""
from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
import time
import logging
import uuid

from app.utils.api_response import api_error
from app.utils.error_codes import AvatarErrorCode, default_message, map_http_status_to_code
from app.utils.request_context import set_request_id, reset_request_id

logger = logging.getLogger(__name__)


async def logging_middleware(request: Request, call_next):
    """请求日志中间件"""
    start_time = time.time()

    # 每个请求生成 request_id，贯穿日志/错误返回；同时回写响应头便于抓包排查
    request_id = request.headers.get("X-Request-ID") or f"req_{uuid.uuid4().hex[:16]}"
    token = set_request_id(request_id)
    request.state.request_id = request_id
    
    # 记录请求信息
    logger.info("Request: %s %s rid=%s", request.method, request.url.path, request_id)
    
    try:
        response = await call_next(request)
        process_time = time.time() - start_time
        response.headers["X-Process-Time"] = str(process_time)
        response.headers["X-Request-ID"] = request_id
        logger.info("Response: %s - %.3fs rid=%s", response.status_code, process_time, request_id)
        return response
    except Exception as e:
        process_time = time.time() - start_time
        logger.error("Error: %s - %.3fs rid=%s", str(e), process_time, request_id)
        raise
    finally:
        # 防止 context 泄露到其他请求
        reset_request_id(token)


async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """请求验证错误处理"""
    # MVP：统一按 400 返回，并给稳定的业务错误码
    return api_error(
        status_code=status.HTTP_400_BAD_REQUEST,
        code=AvatarErrorCode.INVALID_ARGUMENT,
        message=default_message(AvatarErrorCode.INVALID_ARGUMENT, "请求参数验证失败"),
        details={"validation": exc.errors()},
    )


async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    """HTTP 异常处理"""
    # 兼容两种 detail：
    # 1) 旧逻辑：detail 是字符串
    # 2) 新逻辑：detail 是 dict，形如 {"code": "...", "message": "...", "details": {...}?}
    detail = exc.detail
    if isinstance(detail, dict):
        code = str(detail.get("code") or map_http_status_to_code(exc.status_code))
        message = str(detail.get("message") or default_message(code))
        details = detail.get("details")
        return api_error(
            status_code=int(exc.status_code),
            code=code,
            message=message,
            details=details if isinstance(details, dict) else None,
        )

    code = map_http_status_to_code(exc.status_code)
    message = str(detail) if detail else default_message(code)
    return api_error(status_code=int(exc.status_code), code=code, message=message)


async def general_exception_handler(request: Request, exc: Exception):
    """通用异常处理"""
    logger.exception("Unhandled exception")
    return api_error(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        code=AvatarErrorCode.INTERNAL_ERROR,
        message=default_message(AvatarErrorCode.INTERNAL_ERROR, "服务器内部错误，请稍后重试"),
    )

