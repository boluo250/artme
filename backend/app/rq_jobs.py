"""
RQ Job：后台生图任务（并发执行 + 幂等扣费）

说明：
- RQ Worker 执行的是同步函数；本项目的 ai_service/image_service 多为 async，
  因此这里用 asyncio.run 包一层。
- 扣费语义：
  - API 层创建 Transaction(status="pending", amount=-cost, related_task_id=task_id)
  - Job 成功：将 tx 置为 completed，并扣减 user.balance（balance += tx.amount）
  - Job 失败：将 tx 置为 canceled（不扣费）
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
from datetime import datetime
from typing import Optional

from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.task import GenerationTask
from app.models.user import Transaction
from app.services.ai_service import ai_service
from app.services.billing_service import billing_service
from app.services.image_service import image_service

logger = logging.getLogger(__name__)

def _should_retry_current_job() -> bool:
    """
    判断当前 RQ job 是否还会自动重试。
    - rq==1.16.x 提供 get_current_job()，并有 retries_left 属性
    - 若取不到 job 或属性，则保守返回 False（按最终失败处理）
    """
    try:
        from rq import get_current_job  # type: ignore
    except Exception:
        return False
    try:
        job = get_current_job()
        retries_left = getattr(job, "retries_left", None)
        if retries_left is None:
            return False
        return int(retries_left) > 0
    except Exception:
        return False


def _run(coro):
    """在 RQ 同步上下文中运行 async 协程"""
    return asyncio.run(coro)


def _load_task(db: Session, task_id: str) -> Optional[GenerationTask]:
    return db.query(GenerationTask).filter(GenerationTask.id == task_id).first()


def _load_tx(db: Session, transaction_id: Optional[str]) -> Optional[Transaction]:
    if not transaction_id:
        return None
    return db.query(Transaction).filter(Transaction.id == transaction_id).first()


def _mark_processing(db: Session, task: GenerationTask) -> None:
    task.status = "processing"
    task.updated_at = datetime.utcnow()
    db.commit()


def _mark_failed(db: Session, task: GenerationTask, error: str) -> None:
    task.status = "failed"
    task.error = error
    task.updated_at = datetime.utcnow()
    db.commit()


def _mark_completed(db: Session, task: GenerationTask) -> None:
    task.status = "completed"
    task.error = None
    task.updated_at = datetime.utcnow()
    db.commit()


def generate_text_job(
    task_id: str,
    user_id: Optional[str] = None,
    transaction_id: Optional[str] = None,
    prompt: Optional[str] = None,
    style_id: Optional[str] = None,
    width: int = 512,
    height: int = 512,
    model: str = "dall-e-3",
):
    """
    文本生图 Job
    - 幂等：若 tx 已非 pending，则直接返回（避免重复扣费）
    """
    db = SessionLocal()
    try:
        task = _load_task(db, task_id)
        if not task:
            logger.warning("RQ job: task not found: %s", task_id)
            return

        tx = _load_tx(db, transaction_id)
        if tx is not None and tx.status != "pending":
            logger.info("RQ job: tx already processed, skip. tx=%s status=%s", tx.id, tx.status)
            return

        # 若任务已完成，也无需重复生成；若 tx 还 pending，则补做结算/取消（保护性逻辑）
        if task.status == "completed":
            if tx is not None and tx.status == "pending":
                billing_service.settle_pending_consume_transaction(db=db, tx=tx)
                db.commit()
            return
        if task.status == "failed":
            if tx is not None and tx.status == "pending":
                billing_service.cancel_pending_transaction(db=db, tx=tx, reason=task.error)
                db.commit()
            return

        _mark_processing(db, task)

        # 执行生图
        result = _run(
            ai_service.generate_image(
                prompt=prompt or task.prompt,
                style_id=style_id or task.style_id,
                width=width,
                height=height,
                model=model,
            )
        )

        saved_path = _run(
            image_service.download_and_save_image(
                result["image_url"],
                subfolder="generated",
            )
        )
        _run(image_service.create_thumbnail(saved_path))

        local_image_url = image_service.get_image_url(saved_path)
        task.image_urls = json.dumps([local_image_url])
        task.prompt = result.get("prompt", task.prompt)

        # 成功路径：任务完成 + 扣费结算（单事务提交）
        if tx is not None and tx.status == "pending":
            billing_service.settle_pending_consume_transaction(db=db, tx=tx)
        task.status = "completed"
        task.error = None
        task.updated_at = datetime.utcnow()
        db.commit()

    except Exception as exc:  # noqa: BLE001
        db.rollback()
        task = _load_task(db, task_id)
        if task:
            error_str = str(exc)
            will_retry = _should_retry_current_job()
            if will_retry:
                # 还会自动重试：不取消预扣，不将任务置为最终失败
                # 这里将任务回退为 pending，表示“等待下一次重试”
                task.status = "pending"
                task.error = error_str
                task.updated_at = datetime.utcnow()
                db.commit()
            else:
                # 最终失败：任务 failed + 取消预扣（不扣费）
                task.status = "failed"
                task.error = error_str
                task.updated_at = datetime.utcnow()
                tx = _load_tx(db, transaction_id)
                if tx is not None and tx.status == "pending":
                    billing_service.cancel_pending_transaction(db=db, tx=tx, reason=error_str)
                db.commit()
        logger.exception("RQ text job failed: task=%s err=%s", task_id, exc)
        # 让 RQ 标记为失败（便于观察）；幂等逻辑可避免重复扣费
        raise
    finally:
        db.close()


def generate_upload_job(
    task_id: str,
    user_id: Optional[str] = None,
    transaction_id: Optional[str] = None,
    prompt: Optional[str] = None,
    image_path: Optional[str] = None,
    size: str = "2K",
    watermark: bool = True,
    max_images: int = 5,
):
    """
    上传图生图 Job（豆包）
    """
    db = SessionLocal()
    try:
        task = _load_task(db, task_id)
        if not task:
            logger.warning("RQ job: task not found: %s", task_id)
            return

        tx = _load_tx(db, transaction_id)
        if tx is not None and tx.status != "pending":
            logger.info("RQ job: tx already processed, skip. tx=%s status=%s", tx.id, tx.status)
            return

        if task.status == "completed":
            if tx is not None and tx.status == "pending":
                billing_service.settle_pending_consume_transaction(db=db, tx=tx)
                db.commit()
            return
        if task.status == "failed":
            if tx is not None and tx.status == "pending":
                billing_service.cancel_pending_transaction(db=db, tx=tx, reason=task.error)
                db.commit()
            return

        _mark_processing(db, task)

        # 执行豆包生图（并清理临时文件）
        img_path = image_path or ""
        try:
            result = _run(
                ai_service.generate_image_with_doubao(
                    image_path_or_url=img_path,
                    prompt=prompt or task.prompt,
                    output_dir=None,
                    size=size,
                    watermark=watermark,
                    max_images=max_images,
                )
            )
        finally:
            try:
                if img_path and os.path.exists(img_path):
                    os.remove(img_path)
                    logger.info("RQ job: deleted temp file: %s", img_path)
            except Exception as exc:  # noqa: BLE001
                logger.warning("RQ job: delete temp file failed: %s", exc)

        if not result.get("success"):
            raise RuntimeError(result.get("error") or "图片生成失败")

        image_urls = result.get("images", [])
        if not image_urls:
            raise RuntimeError("生成结果为空")

        task.image_urls = json.dumps(image_urls)

        # 成功路径：任务完成 + 扣费结算（单事务提交）
        if tx is not None and tx.status == "pending":
            billing_service.settle_pending_consume_transaction(db=db, tx=tx)
        task.status = "completed"
        task.error = None
        task.updated_at = datetime.utcnow()
        db.commit()

    except Exception as exc:  # noqa: BLE001
        db.rollback()
        task = _load_task(db, task_id)
        if task:
            error_str = str(exc)
            will_retry = _should_retry_current_job()
            if will_retry:
                task.status = "pending"
                task.error = error_str
                task.updated_at = datetime.utcnow()
                db.commit()
            else:
                task.status = "failed"
                task.error = error_str
                task.updated_at = datetime.utcnow()
                tx = _load_tx(db, transaction_id)
                if tx is not None and tx.status == "pending":
                    billing_service.cancel_pending_transaction(db=db, tx=tx, reason=error_str)
                db.commit()
        logger.exception("RQ upload job failed: task=%s err=%s", task_id, exc)
        raise
    finally:
        db.close()


