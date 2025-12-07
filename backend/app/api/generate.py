"""
图像生成 API
"""
from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form, Query
from pydantic import BaseModel
from typing import Optional, List
import uuid
import os
import tempfile
from datetime import datetime
from pathlib import Path
import json
from sqlalchemy.orm import Session
from app.services.ai_service import ai_service
from app.services.image_service import image_service
from app.database import get_db
from app.models.user import User, Transaction
from app.models.task import GenerationTask
from app.api.account import GENERATE_IMAGE_COST
from app.api.prompts import get_prompt_from_json
from app.services.task_service import task_manager
import logging

router = APIRouter()
logger = logging.getLogger(__name__)


class GenerateRequest(BaseModel):
    """生成请求模型"""
    prompt: str
    style_id: Optional[str] = None
    user_id: Optional[str] = None
    width: int = 512
    height: int = 512
    model: str = "dall-e-3"
    notify_on_complete: bool = False


class GenerateResponse(BaseModel):
    """生成响应模型"""
    image_url: Optional[str] = None
    task_id: str
    status: str
    prompt: str


class GenerateImageResponse(BaseModel):
    """图片上传生成响应模型"""
    success: bool
    images: List[dict]  # [{"url": str, "id": str}, ...]
    task_id: str
    prompt: str
    status: str
    usage: Optional[dict] = None
    error: Optional[str] = None


class TaskStatusResponse(BaseModel):
    """任务状态查询响应"""
    task_id: str
    status: str
    prompt: str
    image_urls: List[str] = []
    error: Optional[str] = None


class TaskListResponse(BaseModel):
    """任务列表响应"""
    tasks: List[TaskStatusResponse]
    total: int


def _to_task_status(task: GenerationTask) -> TaskStatusResponse:
    """内部转换工具"""
    image_urls: List[str] = []
    if task.image_urls:
        try:
            image_urls = json.loads(task.image_urls)
        except Exception:
            image_urls = []
    return TaskStatusResponse(
        task_id=task.id,
        status=task.status,
        prompt=task.prompt,
        image_urls=image_urls,
        error=task.error,
    )


@router.get("/generate/tasks/{task_id}", response_model=TaskStatusResponse)
async def get_task_status(task_id: str, db: Session = Depends(get_db)):
    """查询单个任务状态"""
    task = db.query(GenerationTask).filter(GenerationTask.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="任务不存在")
    return _to_task_status(task)


@router.get("/generate/tasks", response_model=TaskListResponse)
async def list_tasks(
    user_id: Optional[str] = Query(None, description="按用户筛选"),
    status: Optional[str] = Query(None, description="按状态筛选"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """列出任务（可按用户/状态过滤）"""
    query = db.query(GenerationTask)
    if user_id:
        query = query.filter(GenerationTask.user_id == user_id)
    if status:
        query = query.filter(GenerationTask.status == status)
    total = query.count()
    tasks = (
        query.order_by(GenerationTask.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return TaskListResponse(
        tasks=[_to_task_status(task) for task in tasks],
        total=total,
    )


@router.post("/generate", response_model=GenerateResponse)
async def generate_image(request: GenerateRequest, db: Session = Depends(get_db)):
    """
    生成卡通头像
    
    - **prompt**: 用户输入的描述文本
    - **style_id**: 选择的风格ID（可选）
    - **width**: 图像宽度（默认512）
    - **height**: 图像高度（默认512）
    - **model**: 使用的大模型（默认dall-e-3）
    """
    try:
        # 如果有用户ID，检查余额并扣费
        if request.user_id:
            user = db.query(User).filter(User.id == request.user_id).first()
            if user:
                # 检查是否有有效订阅
                has_subscription = (
                    user.subscription_type != "none" and
                    user.subscription_expires_at and
                    user.subscription_expires_at > datetime.now()
                )
                
                if not has_subscription:
                    # 检查余额
                    if user.balance < GENERATE_IMAGE_COST:
                        raise HTTPException(
                            status_code=400,
                            detail=f"余额不足，需要 {GENERATE_IMAGE_COST} 元"
                        )
                    
                    # 扣除费用
                    user.balance -= GENERATE_IMAGE_COST
                    from app.models.user import Transaction
                    transaction = Transaction(
                        id=str(uuid.uuid4()),
                        user_id=request.user_id,
                        transaction_type="consume",
                        amount=-GENERATE_IMAGE_COST,
                        description="生成图像",
                        status="completed"
                    )
                    db.add(transaction)
                    db.commit()
        
        # 创建任务记录
        task_id = str(uuid.uuid4())
        task = GenerationTask(
            id=task_id,
            user_id=request.user_id,
            request_type="text",
            prompt=request.prompt,
            style_id=request.style_id,
            status="pending",
            notify_on_complete=request.notify_on_complete,
        )
        db.add(task)
        db.commit()
        
        # 入队后台处理
        await task_manager.enqueue_text_task(
            task_id=task_id,
            prompt=request.prompt,
            style_id=request.style_id,
            width=request.width,
            height=request.height,
            model=request.model,
        )
        
        return GenerateResponse(
            image_url=None,
            task_id=task_id,
            status="pending",
            prompt=request.prompt
        )
    
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"图像生成失败: {str(e)}")


@router.post("/generate/with-image", response_model=GenerateImageResponse)
async def generate_image_with_upload(
    image: UploadFile = File(..., description="上传的图片文件"),
    category: str = Form(..., description="Category（用于查找对应的 prompt）"),
    subcategory: str = Form(..., description="Subcategory（用于查找对应的 prompt）"),
    user_id: Optional[str] = Form(None, description="用户ID（可选）"),
    size: str = Form("2K", description="图片尺寸（可选，默认 2K）"),
    watermark: bool = Form(True, description="是否添加水印（可选，默认 true）"),
    max_images: int = Form(5, description="最大生成图片数（可选，默认 5）"),
    notify_on_complete: bool = Form(False, description="完成后通知"),
    db: Session = Depends(get_db)
):
    """
    使用上传的图片和 prompt 生成图片
    
    - **image**: 上传的图片文件
    - **category**: Category（用于查找对应的 prompt）
    - **subcategory**: Subcategory（用于查找对应的 prompt）
    - **user_id**: 用户ID（可选）
    - **size**: 图片尺寸（可选，默认 "2K"）
    - **watermark**: 是否添加水印（可选，默认 true）
    - **max_images**: 最大生成图片数（可选，默认 5）
    """
    task_id = str(uuid.uuid4())
    temp_file_path = None
    
    try:
        # 验证文件类型
        if not image.content_type or not image.content_type.startswith("image/"):
            raise HTTPException(
                status_code=400,
                detail="文件必须是图片格式"
            )
        
        # 如果有用户ID，检查余额并扣费
        if user_id:
            user = db.query(User).filter(User.id == user_id).first()
            if user:
                # 检查是否有有效订阅
                has_subscription = (
                    user.subscription_type != "none" and
                    user.subscription_expires_at and
                    user.subscription_expires_at > datetime.now()
                )
                
                if not has_subscription:
                    # 检查余额
                    if user.balance < GENERATE_IMAGE_COST:
                        raise HTTPException(
                            status_code=400,
                            detail=f"余额不足，需要 {GENERATE_IMAGE_COST} 元"
                        )
                    
                    # 扣除费用
                    user.balance -= GENERATE_IMAGE_COST
                    transaction = Transaction(
                        id=str(uuid.uuid4()),
                        user_id=user_id,
                        transaction_type="consume",
                        amount=-GENERATE_IMAGE_COST,
                        description="生成图像（图片上传）",
                        status="completed"
                    )
                    db.add(transaction)
                    db.commit()
        
        # 保存上传的图片到持久临时文件，供后台任务使用
        temp_dir = Path(image_service.upload_dir) / "tmp"
        temp_dir.mkdir(parents=True, exist_ok=True)
        temp_file_path = temp_dir / f"upload_{task_id}_{image.filename}"
        
        contents = await image.read()
        with open(temp_file_path, "wb") as f:
            f.write(contents)
        
        logger.info(f"上传的图片已保存到临时文件: {temp_file_path}")
        
        # 从 JSON 配置文件中获取 prompt
        prompt_data = get_prompt_from_json(category, subcategory)
        if not prompt_data:
            raise HTTPException(
                status_code=404,
                detail=f"未找到对应的 prompt: {category}/{subcategory}"
            )
        
        final_prompt = prompt_data.get("prompt", "")
        if not final_prompt:
             raise HTTPException(
                status_code=404,
                detail=f"Category {category}/{subcategory} 中未配置 prompt"
            )
            
        logger.info(f"从 JSON 配置文件中获取 prompt: {final_prompt[:50]}...")
        
        # 创建任务记录
        task = GenerationTask(
            id=task_id,
            user_id=user_id,
            request_type="upload",
            prompt=final_prompt,
            category=category,
            subcategory=subcategory,
            status="pending",
            notify_on_complete=notify_on_complete,
        )
        db.add(task)
        db.commit()

        # 入队后台处理
        await task_manager.enqueue_upload_task(
            task_id=task_id,
            prompt=final_prompt,
            image_path=str(temp_file_path),
            size=size,
            watermark=watermark,
            max_images=max_images,
        )
        
        # 立即返回排队结果，并附带「上传图片预览」URL，供前端在 pending 阶段展示缩略图
        try:
            # 将临时文件路径转换为相对于 upload_dir 的相对路径
            rel_path = temp_file_path.relative_to(image_service.upload_dir)
            preview_url = image_service.get_image_url(str(rel_path))
            preview_images = [{"url": preview_url, "id": str(task_id)}]
        except Exception:
            # 回退：如果路径转换失败，则不返回预览图，保持兼容
            preview_images = []
        
        return GenerateImageResponse(
            success=True,
            images=preview_images,
            task_id=task_id,
            prompt=final_prompt,
            status="pending",
            usage=None,
            error=None
        )
    
    except HTTPException:
        # 清理临时文件
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
            except Exception:
                pass
        raise
    
    except Exception as e:
        # 清理临时文件
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
            except Exception:
                pass
        
        logger.error(f"生成图片失败: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"图片生成失败: {str(e)}"
        )


@router.get("/models")
async def list_models():
    """获取可用的大模型列表"""
    models = await ai_service.list_models()
    return {"models": models}


