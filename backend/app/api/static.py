"""
静态文件服务（用于提供上传的图像和数据目录的图片）
"""
from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
from pathlib import Path
from app.config import settings
import os

router = APIRouter()

# 配置静态文件服务
upload_dir = Path(settings.UPLOAD_DIR)
upload_dir.mkdir(parents=True, exist_ok=True)

# 数据目录路径
data_dir = Path(__file__).parent.parent.parent / "data"

# 允许的图片扩展名
ALLOWED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG", ".gif", ".GIF"}


def is_safe_path(base_path: Path, target_path: Path) -> bool:
    """
    检查目标路径是否在基础路径内（防止路径遍历攻击）
    
    Args:
        base_path: 基础路径
        target_path: 目标路径
        
    Returns:
        如果路径安全则返回 True，否则返回 False
    """
    try:
        # 解析真实路径
        base_real = base_path.resolve()
        target_real = target_path.resolve()
        
        # 检查目标路径是否在基础路径内
        # 使用 try-except 处理 Python 3.8 及以下版本
        try:
            # Python 3.9+ 使用 is_relative_to
            return target_real.is_relative_to(base_real)
        except AttributeError:
            # Python 3.8 及以下版本使用其他方法
            try:
                target_real.relative_to(base_real)
                return True
            except ValueError:
                return False
    except (ValueError, OSError):
        return False


@router.get("/uploads/{file_path:path}")
async def serve_uploaded_file(file_path: str):
    """
    提供上传的文件访问
    
    - **file_path**: 文件相对路径
    """
    full_path = upload_dir / file_path
    
    # 安全检查：防止路径遍历
    if not is_safe_path(upload_dir, full_path):
        raise HTTPException(status_code=403, detail="访问被拒绝：路径不安全")
    
    if not full_path.exists() or not full_path.is_file():
        raise HTTPException(status_code=404, detail="文件不存在")
    
    return FileResponse(full_path)


@router.get("/data/{category}/{file_name}")
async def serve_data_file(category: str, file_name: str):
    """
    提供数据目录下的图片文件访问
    
    - **category**: 类别名称（目录名）
    - **file_name**: 文件名（包含扩展名）
    
    支持常见图片格式：jpg, jpeg, png
    """
    # 安全检查：验证文件名和类别名
    if not category or not file_name:
        raise HTTPException(status_code=400, detail="类别名或文件名不能为空")
    
    # 检查文件名中是否包含路径分隔符（防止路径遍历）
    if "/" in file_name or "\\" in file_name or ".." in file_name:
        raise HTTPException(status_code=403, detail="访问被拒绝：文件名包含非法字符")
    
    if "/" in category or "\\" in category or ".." in category:
        raise HTTPException(status_code=403, detail="访问被拒绝：类别名包含非法字符")
    
    # 检查文件扩展名
    file_ext = Path(file_name).suffix
    if file_ext not in ALLOWED_IMAGE_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"不支持的文件格式。支持的格式：{', '.join(ALLOWED_IMAGE_EXTENSIONS)}"
        )
    
    # 构建完整路径
    category_dir = data_dir / category
    full_path = category_dir / file_name
    
    # 安全检查：防止路径遍历
    if not is_safe_path(data_dir, full_path):
        raise HTTPException(status_code=403, detail="访问被拒绝：路径不安全")
    
    # 检查文件是否存在
    if not full_path.exists():
        raise HTTPException(
            status_code=404,
            detail=f"文件不存在: {category}/{file_name}"
        )
    
    if not full_path.is_file():
        raise HTTPException(
            status_code=404,
            detail=f"路径不是文件: {category}/{file_name}"
        )
    
    # 返回文件响应，设置正确的媒体类型
    media_type = None
    if file_ext.lower() in [".jpg", ".jpeg"]:
        media_type = "image/jpeg"
    elif file_ext.lower() == ".png":
        media_type = "image/png"
    
    return FileResponse(full_path, media_type=media_type)

