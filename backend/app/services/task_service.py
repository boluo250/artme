"""
图像生成任务队列与处理服务
"""
import asyncio
import json
import logging
import os
from datetime import datetime
from typing import Optional, Dict, Any

from app.database import SessionLocal
from app.models.task import GenerationTask
from app.services.ai_service import ai_service
from app.services.image_service import image_service

logger = logging.getLogger(__name__)


class TaskManager:
    """简单的异步任务管理器"""

    def __init__(self):
        self.queue: asyncio.Queue[Dict[str, Any]] = asyncio.Queue()
        self._worker_task: Optional[asyncio.Task] = None
        self._started = False

    async def start(self):
        """启动后台工作协程"""
        if self._started:
            return
        self._started = True
        self._worker_task = asyncio.create_task(self._worker_loop())
        logger.info("Generation task worker started")

    async def stop(self):
        """停止后台工作协程"""
        if self._worker_task:
            self._worker_task.cancel()
            try:
                await self._worker_task
            except asyncio.CancelledError:
                pass
        self._started = False
        logger.info("Generation task worker stopped")

    async def enqueue_text_task(
        self,
        task_id: str,
        prompt: str,
        style_id: Optional[str],
        width: int,
        height: int,
        model: str,
    ):
        """入队文本生成任务"""
        await self.queue.put(
            {
                "task_id": task_id,
                "type": "text",
                "prompt": prompt,
                "style_id": style_id,
                "width": width,
                "height": height,
                "model": model,
            }
        )

    async def enqueue_upload_task(
        self,
        task_id: str,
        prompt: str,
        image_path: str,
        size: str,
        watermark: bool,
        max_images: int,
    ):
        """入队图片上传生成任务"""
        await self.queue.put(
            {
                "task_id": task_id,
                "type": "upload",
                "prompt": prompt,
                "image_path": image_path,
                "size": size,
                "watermark": watermark,
                "max_images": max_images,
            }
        )

    async def _worker_loop(self):
        """工作协程：顺序处理队列中的任务"""
        while True:
            payload = await self.queue.get()
            task_id = payload.get("task_id")
            try:
                await self._process_task(payload)
            except Exception as exc:  # noqa: BLE001
                logger.exception("处理任务 %s 失败: %s", task_id, exc)
            finally:
                self.queue.task_done()

    async def _process_task(self, payload: Dict[str, Any]):
        """执行具体任务逻辑"""
        task_id = payload["task_id"]
        db = SessionLocal()
        try:
            task: Optional[GenerationTask] = (
                db.query(GenerationTask).filter(GenerationTask.id == task_id).first()
            )
            if not task:
                logger.warning("未找到任务 %s", task_id)
                return

            # 标记为处理中
            task.status = "processing"
            task.updated_at = datetime.utcnow()
            db.commit()

            if payload["type"] == "text":
                await self._handle_text_task(task, payload, db)
            elif payload["type"] == "upload":
                await self._handle_upload_task(task, payload, db)
            else:
                raise ValueError(f"未知的任务类型: {payload['type']}")

            task.status = "completed"
            task.updated_at = datetime.utcnow()
            task.error = None
            db.commit()

        except Exception as exc:  # noqa: BLE001
            # 失败处理
            logger.error("任务 %s 失败: %s", task_id, exc, exc_info=True)
            db.rollback()
            task = (
                db.query(GenerationTask).filter(GenerationTask.id == task_id).first()
            )
            if task:
                task.status = "failed"
                task.error = str(exc)
                task.updated_at = datetime.utcnow()
                db.commit()
        finally:
            db.close()

    async def _handle_text_task(
        self,
        task: GenerationTask,
        payload: Dict[str, Any],
        db: SessionLocal,
    ):
        """处理文本生成任务"""
        result = await ai_service.generate_image(
            prompt=payload["prompt"],
            style_id=payload.get("style_id"),
            width=payload.get("width", 512),
            height=payload.get("height", 512),
            model=payload.get("model", "dall-e-3"),
        )

        saved_path = await image_service.download_and_save_image(
            result["image_url"],
            subfolder="generated",
        )
        await image_service.create_thumbnail(saved_path)

        local_image_url = image_service.get_image_url(saved_path)
        task.image_urls = json.dumps([local_image_url])
        task.prompt = result.get("prompt", task.prompt)
        task.updated_at = datetime.utcnow()
        db.commit()

    async def _handle_upload_task(
        self,
        task: GenerationTask,
        payload: Dict[str, Any],
        db: SessionLocal,
    ):
        """处理图片上传生成任务"""
        image_path = payload["image_path"]
        try:
            result = await ai_service.generate_image_with_doubao(
                image_path_or_url=image_path,
                prompt=payload["prompt"],
                output_dir=None,
                size=payload.get("size", "2K"),
                watermark=payload.get("watermark", True),
                max_images=payload.get("max_images", 5),
            )
        finally:
            # 清理上传的临时文件
            try:
                if os.path.exists(image_path):
                    os.remove(image_path)
                    logger.info("已删除临时文件: %s", image_path)
            except Exception as exc:  # noqa: BLE001
                logger.warning("删除临时文件失败: %s", exc)

        if not result.get("success"):
            raise RuntimeError(result.get("error") or "图片生成失败")

        image_urls = result.get("images", [])
        if not image_urls:
            raise RuntimeError("生成结果为空")

        task.image_urls = json.dumps(image_urls)
        task.updated_at = datetime.utcnow()
        db.commit()


# 全局任务管理器实例
task_manager = TaskManager()


