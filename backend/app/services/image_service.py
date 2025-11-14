"""
图像处理服务
"""
import os
import httpx
import aiofiles
from PIL import Image
from typing import Optional, Tuple
from pathlib import Path
import hashlib
import logging
from app.config import settings

logger = logging.getLogger(__name__)


class ImageService:
    """图像处理服务"""
    
    def __init__(self):
        self.upload_dir = Path(settings.UPLOAD_DIR)
        self.style_images_dir = Path(settings.STYLE_IMAGES_DIR)
        self.max_size = settings.MAX_UPLOAD_SIZE
        
        # 创建必要的目录
        self.upload_dir.mkdir(parents=True, exist_ok=True)
        self.style_images_dir.mkdir(parents=True, exist_ok=True)
    
    async def download_and_save_image(
        self,
        image_url: str,
        filename: Optional[str] = None,
        subfolder: str = "generated"
    ) -> str:
        """
        下载并保存图像
        
        Args:
            image_url: 图像URL
            filename: 文件名（可选，如果不提供则自动生成）
            subfolder: 子文件夹名称
        
        Returns:
            保存后的文件路径（相对路径）
        """
        try:
            # 下载图像
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.get(image_url)
                response.raise_for_status()
                image_data = response.content
            
            # 生成文件名
            if not filename:
                # 使用URL的hash作为文件名
                url_hash = hashlib.md5(image_url.encode()).hexdigest()
                filename = f"{url_hash}.png"
            
            # 保存路径
            save_dir = self.upload_dir / subfolder
            save_dir.mkdir(parents=True, exist_ok=True)
            file_path = save_dir / filename
            
            # 保存文件
            async with aiofiles.open(file_path, 'wb') as f:
                await f.write(image_data)
            
            logger.info(f"图像已保存: {file_path}")
            return str(file_path.relative_to(self.upload_dir))
        
        except Exception as e:
            logger.error(f"下载图像失败: {str(e)}")
            raise
    
    async def optimize_image(
        self,
        image_path: str,
        max_width: int = 1024,
        max_height: int = 1024,
        quality: int = 85
    ) -> str:
        """
        优化图像（调整大小、压缩）
        
        Args:
            image_path: 图像文件路径
            max_width: 最大宽度
            max_height: 最大高度
            quality: JPEG质量（1-100）
        
        Returns:
            优化后的图像路径
        """
        try:
            full_path = self.upload_dir / image_path
            
            # 打开图像
            with Image.open(full_path) as img:
                # 转换为RGB（如果不是）
                if img.mode != 'RGB':
                    img = img.convert('RGB')
                
                # 调整大小（如果需要）
                if img.width > max_width or img.height > max_height:
                    img.thumbnail((max_width, max_height), Image.Resampling.LANCZOS)
                
                # 生成优化后的文件名
                path_obj = Path(image_path)
                optimized_path = path_obj.parent / f"{path_obj.stem}_optimized{path_obj.suffix}"
                optimized_full_path = self.upload_dir / optimized_path
                
                # 保存优化后的图像
                img.save(optimized_full_path, 'JPEG', quality=quality, optimize=True)
            
            logger.info(f"图像已优化: {optimized_path}")
            return str(optimized_path)
        
        except Exception as e:
            logger.error(f"优化图像失败: {str(e)}")
            raise
    
    async def create_thumbnail(
        self,
        image_path: str,
        size: Tuple[int, int] = (200, 200)
    ) -> str:
        """
        创建缩略图（带缓存机制）
        
        Args:
            image_path: 原始图像路径（相对路径）
            size: 缩略图尺寸 (width, height)
        
        Returns:
            缩略图路径（相对路径）
        """
        try:
            full_path = self.upload_dir / image_path
            
            # 检查原始文件是否存在
            if not full_path.exists():
                raise FileNotFoundError(f"图片文件不存在: {full_path}")
            
            # 生成缩略图文件名（包含尺寸信息，用于缓存）
            path_obj = Path(image_path)
            thumbnail_filename = f"{path_obj.stem}_thumb_{size[0]}x{size[1]}.jpg"
            thumbnail_path = path_obj.parent / thumbnail_filename
            thumbnail_full_path = self.upload_dir / thumbnail_path
            
            # 检查缩略图是否已存在（缓存检查）
            if thumbnail_full_path.exists():
                # 检查原始文件的修改时间
                original_mtime = full_path.stat().st_mtime
                thumbnail_mtime = thumbnail_full_path.stat().st_mtime
                
                # 如果缩略图比原图新，则使用缓存
                if thumbnail_mtime >= original_mtime:
                    logger.info(f"使用缓存的缩略图: {thumbnail_path}")
                    return str(thumbnail_path)
            
            # 打开图像
            with Image.open(full_path) as img:
                # 转换为 RGB 模式（如果需要）
                if img.mode != 'RGB':
                    img = img.convert('RGB')
                
                # 创建缩略图（保持宽高比）
                img.thumbnail(size, Image.Resampling.LANCZOS)
                
                # 确保缩略图目录存在
                thumbnail_full_path.parent.mkdir(parents=True, exist_ok=True)
                
                # 保存缩略图（统一使用 JPEG 格式）
                img.save(thumbnail_full_path, 'JPEG', quality=80, optimize=True)
            
            logger.info(f"缩略图已创建: {thumbnail_path}")
            return str(thumbnail_path)
        
        except Exception as e:
            logger.error(f"创建缩略图失败: {str(e)}")
            raise
    
    def get_image_url(self, image_path: str) -> str:
        """
        获取图像的访问URL
        
        Args:
            image_path: 图像相对路径
        
        Returns:
            图像的完整URL
        """
        # 返回包含 /api/v1 前缀的URL，匹配静态文件路由
        return f"/api/v1/uploads/{image_path}"
    
    async def save_style_example_image(
        self,
        image_url: str,
        style_id: str
    ) -> str:
        """
        保存风格示例图片
        
        Args:
            image_url: 图像URL
            style_id: 风格ID
        
        Returns:
            保存后的文件路径
        """
        filename = f"{style_id}_example.jpg"
        return await self.download_and_save_image(
            image_url,
            filename=filename,
            subfolder="style_examples"
        )
    
    async def resize_image(
        self,
        image_path: Path,
        max_width: Optional[int] = None,
        max_height: Optional[int] = None,
        quality: int = 85
    ) -> Path:
        """
        调整图片尺寸（带缓存机制）
        
        Args:
            image_path: 原始图片路径（绝对路径）
            max_width: 最大宽度（可选）
            max_height: 最大高度（可选）
            quality: JPEG质量（1-100）
        
        Returns:
            调整后的图片路径（绝对路径）
        """
        if not image_path.exists():
            raise FileNotFoundError(f"图片文件不存在: {image_path}")
        
        # 如果没有指定尺寸，直接返回原图
        if max_width is None and max_height is None:
            return image_path
        
        # 生成缓存文件名（包含尺寸信息）
        path_obj = Path(image_path)
        size_suffix = ""
        if max_width and max_height:
            size_suffix = f"_resized_{max_width}x{max_height}"
        elif max_width:
            size_suffix = f"_resized_w{max_width}"
        elif max_height:
            size_suffix = f"_resized_h{max_height}"
        
        resized_filename = f"{path_obj.stem}{size_suffix}.jpg"
        resized_path = path_obj.parent / resized_filename
        
        # 检查缓存是否存在且有效
        if resized_path.exists():
            original_mtime = image_path.stat().st_mtime
            resized_mtime = resized_path.stat().st_mtime
            
            # 如果调整后的图片比原图新，使用缓存
            if resized_mtime >= original_mtime:
                logger.info(f"使用缓存的调整后图片: {resized_path}")
                return resized_path
        
        # 打开并调整图片
        with Image.open(image_path) as img:
            # 转换为 RGB 模式（如果需要）
            if img.mode != 'RGB':
                img = img.convert('RGB')
            
            # 计算新尺寸（保持宽高比）
            original_width, original_height = img.size
            new_width, new_height = original_width, original_height
            
            if max_width and max_height:
                # 同时限制宽度和高度
                ratio = min(max_width / original_width, max_height / original_height)
                if ratio < 1.0:
                    new_width = int(original_width * ratio)
                    new_height = int(original_height * ratio)
            elif max_width and original_width > max_width:
                # 只限制宽度
                ratio = max_width / original_width
                new_width = max_width
                new_height = int(original_height * ratio)
            elif max_height and original_height > max_height:
                # 只限制高度
                ratio = max_height / original_height
                new_width = int(original_width * ratio)
                new_height = max_height
            
            # 如果尺寸有变化，调整图片
            if new_width != original_width or new_height != original_height:
                img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
            
            # 保存调整后的图片
            img.save(resized_path, 'JPEG', quality=quality, optimize=True)
            logger.info(f"图片已调整尺寸: {resized_path} ({new_width}x{new_height})")
        
        return resized_path


# 全局图像服务实例
image_service = ImageService()

