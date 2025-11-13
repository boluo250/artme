"""
静态文件服务（用于提供上传的图像）
"""
from fastapi import APIRouter
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from app.config import settings

router = APIRouter()

# 配置静态文件服务
upload_dir = Path(settings.UPLOAD_DIR)
upload_dir.mkdir(parents=True, exist_ok=True)


@router.get("/uploads/{file_path:path}")
async def serve_uploaded_file(file_path: str):
    """
    提供上传的文件访问
    
    - **file_path**: 文件相对路径
    """
    full_path = upload_dir / file_path
    
    if not full_path.exists() or not full_path.is_file():
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="文件不存在")
    
    return FileResponse(full_path)

