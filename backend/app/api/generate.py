"""
图像生成 API
"""
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
import uuid
from datetime import datetime
from sqlalchemy.orm import Session
from app.services.ai_service import ai_service
from app.services.image_service import image_service
from app.database import get_db
from app.models.user import User, Transaction
from app.api.account import GENERATE_IMAGE_COST

router = APIRouter()


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


@router.get("/models")
async def list_models():
    """获取可用的大模型列表"""
    models = await ai_service.list_models()
    return {"models": models}

