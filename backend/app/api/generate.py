"""
图像生成 API
"""
from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form
from pydantic import BaseModel
from typing import Optional, List
import uuid
import os
import tempfile
from datetime import datetime
from pathlib import Path
from sqlalchemy.orm import Session
from app.services.ai_service import ai_service
from app.services.image_service import image_service
from app.database import get_db
from app.models.user import User, Transaction
from app.api.account import GENERATE_IMAGE_COST
from app.api.prompts import get_prompt_from_csv
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


class GenerateResponse(BaseModel):
    """生成响应模型"""
    image_url: str
    task_id: str
    status: str
    prompt: str


class GenerateImageResponse(BaseModel):
    """图片上传生成响应模型"""
    success: bool
    images: List[dict]  # [{"url": str, "id": str}, ...]
    task_id: str
    prompt: str
    usage: Optional[dict] = None
    error: Optional[str] = None


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
        
        # 调用 AI 服务生成图像
        result = await ai_service.generate_image(
            prompt=request.prompt,
            style_id=request.style_id,
            width=request.width,
            height=request.height,
            model=request.model
        )
        
        # 下载并保存图像到本地
        saved_path = await image_service.download_and_save_image(
            result["image_url"],
            subfolder="generated"
        )
        
        # 生成缩略图
        thumbnail_path = await image_service.create_thumbnail(saved_path)
        
        # 生成任务ID
        task_id = str(uuid.uuid4())
        
        # 获取本地图像URL
        local_image_url = image_service.get_image_url(saved_path)
        
        return GenerateResponse(
            image_url=local_image_url,
            task_id=task_id,
            status=result["status"],
            prompt=result["prompt"]
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
        
        # 保存上传的图片到临时文件
        temp_file_path = os.path.join(
            tempfile.gettempdir(),
            f"upload_{task_id}_{image.filename}"
        )
        
        # 读取上传的文件内容
        contents = await image.read()
        with open(temp_file_path, "wb") as f:
            f.write(contents)
        
        logger.info(f"上传的图片已保存到临时文件: {temp_file_path}")
        
        # 从 CSV 中获取 prompt
        final_prompt = get_prompt_from_csv(category, subcategory)
        if not final_prompt:
            raise HTTPException(
                status_code=404,
                detail=f"未找到对应的 prompt: {category}/{subcategory}"
            )
        logger.info(f"从 CSV 中获取 prompt: {final_prompt[:50]}...")
        
        # 调用 OpenRouter API 生成图片
        result = await ai_service.generate_image_with_doubao(
            image_path_or_url=temp_file_path,
            prompt=final_prompt,
            output_dir=None,  # 使用默认输出目录
            size=size,
            watermark=watermark,
            max_images=max_images
        )
        
        # 清理临时文件
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.remove(temp_file_path)
                logger.info(f"临时文件已删除: {temp_file_path}")
            except Exception as e:
                logger.warning(f"删除临时文件失败: {e}")
        
        if not result.get("success"):
            error_msg = result.get("error", "生成图片失败")
            logger.error(f"OpenRouter API 调用失败: {error_msg}")
            raise HTTPException(
                status_code=500,
                detail=f"图片生成失败: {error_msg}"
            )
        
        # 构建响应数据
        image_list = []
        for idx, image_url in enumerate(result.get("images", [])):
            image_list.append({
                "url": image_url,
                "id": f"{task_id}_{idx}"
            })
        
        return GenerateImageResponse(
            success=True,
            images=image_list,
            task_id=task_id,
            prompt=final_prompt,
            usage=result.get("usage"),
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

