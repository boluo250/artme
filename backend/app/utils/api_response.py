"""
统一 API 返回结构（MVP）：

成功：
{
  "success": true,
  "request_id": "...",
  "data": {...},
  "error": null
}

失败：
{
  "success": false,
  "request_id": "...",
  "data": null,
  "error": { "code": "...", "message": "...", "details": {...}? }
}
"""

from __future__ import annotations

from typing import Any, Optional

from fastapi.responses import JSONResponse
from fastapi.encoders import jsonable_encoder

from app.utils.request_context import get_request_id
from app.utils.error_codes import default_message


def api_ok(*, data: Any, status_code: int = 200, headers: Optional[dict[str, str]] = None) -> JSONResponse:
    payload = {
        "success": True,
        "request_id": get_request_id(),
        "data": data,
        "error": None,
    }
    # Ensure datetime and other complex types are converted to JSON-serializable forms
    return JSONResponse(status_code=status_code, content=jsonable_encoder(payload), headers=headers)


def api_error(
    *,
    status_code: int,
    code: str,
    message: Optional[str] = None,
    details: Optional[dict[str, Any]] = None,
    headers: Optional[dict[str, str]] = None,
) -> JSONResponse:
    err = {
        "code": code,
        "message": message or default_message(code),
    }
    if details is not None:
        err["details"] = details
    payload = {
        "success": False,
        "request_id": get_request_id(),
        "data": None,
        "error": err,
    }
    return JSONResponse(status_code=status_code, content=jsonable_encoder(payload), headers=headers)

