"""
请求上下文（MVP 版）：
- 通过 contextvars 存放 request_id，避免在每个 API handler 里显式传 Request
- 中间件负责设置 / 清理
"""

from __future__ import annotations

from contextvars import ContextVar
from typing import Optional

_request_id_var: ContextVar[Optional[str]] = ContextVar("request_id", default=None)


def set_request_id(request_id: str):
    """设置本次请求的 request_id，返回 token 用于 reset。"""
    return _request_id_var.set(request_id)


def reset_request_id(token) -> None:
    """清理本次请求的 request_id。"""
    _request_id_var.reset(token)


def get_request_id() -> str:
    """获取 request_id（如果不存在则返回空字符串，避免 None 传播到 JSON）。"""
    return _request_id_var.get() or ""


