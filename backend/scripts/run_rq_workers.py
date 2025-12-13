"""
启动多个 RQ worker（并发）

用法：
  python scripts/run_rq_workers.py

说明：
- RQ 的并发通常通过“多进程 worker”实现
- 该脚本会根据 Settings.RQ_WORKER_CONCURRENCY 拉起多个 rq worker 进程
"""

from __future__ import annotations

import os
import subprocess
import sys
from typing import List

from app.config import settings


def main() -> int:
    concurrency = int(getattr(settings, "RQ_WORKER_CONCURRENCY", 1) or 1)
    queue_name = settings.RQ_QUEUE_NAME

    procs: List[subprocess.Popen] = []
    try:
        for idx in range(concurrency):
            # rq worker <queue_name>
            cmd = [sys.executable, "-m", "rq", "worker", queue_name]
            env = os.environ.copy()
            # 保证 worker 进程能读取到相同环境变量
            env["REDIS_URL"] = settings.REDIS_URL

            p = subprocess.Popen(cmd, env=env)  # noqa: S603
            procs.append(p)
            print(f"[rq-worker] started {idx + 1}/{concurrency}, pid={p.pid}, queue={queue_name}")

        # 等待任意一个退出（或 Ctrl+C）
        exit_codes = [p.wait() for p in procs]
        return max(exit_codes) if exit_codes else 0
    except KeyboardInterrupt:
        print("\n[rq-worker] received KeyboardInterrupt, terminating...")
        for p in procs:
            try:
                p.terminate()
            except Exception:
                pass
        return 130


if __name__ == "__main__":
    raise SystemExit(main())


