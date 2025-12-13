"""
RQ / Redis 队列封装
"""

from __future__ import annotations

from typing import Any

from app.config import settings


def get_redis_connection() -> Any:
    # decode_responses=False: 保持 bytes，兼容 rq 默认行为
    from redis import Redis  # lazy import

    return Redis.from_url(settings.REDIS_URL, decode_responses=False)


def get_rq_queue() -> Any:
    from rq import Queue  # lazy import

    return Queue(
        name=settings.RQ_QUEUE_NAME,
        connection=get_redis_connection(),
        default_timeout=settings.RQ_JOB_TIMEOUT,
    )


