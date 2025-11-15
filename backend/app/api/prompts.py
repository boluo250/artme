"""
Prompt 图片管理 API
"""
import json
import os
import logging
from pathlib import Path
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional

router = APIRouter()
logger = logging.getLogger(__name__)

# JSON 配置文件路径
PROMPTS_FILE_PATH = Path(__file__).parent.parent.parent / "data" / "AI_Draw_Prompts_EN.json"
DATA_DIR = Path(__file__).parent.parent.parent / "data"


class PromptStyle(BaseModel):
    """Prompt 风格模型"""
    id: str
    category: str
    subcategory: str
    prompt: str
    thumbnail_url: str
    original_url: str


class PromptStyleListResponse(BaseModel):
    """Prompt 列表响应"""
    prompts: List[PromptStyle]
    total: int
    version: Optional[str] = None  # 数据版本号（JSON配置文件最后修改时间）


def get_data_version() -> str:
    """
    获取数据版本号（基于JSON配置文件的最后修改时间）
    
    Returns:
        版本号字符串（时间戳）
    """
    if PROMPTS_FILE_PATH.exists():
        mtime = PROMPTS_FILE_PATH.stat().st_mtime
        return str(int(mtime))
    return "0"


def find_image_file(category: str, subcategory: str) -> Optional[str]:
    """
    查找图片文件，支持多种扩展名和大小写变体
    
    Args:
        category: 类别名称
        subcategory: 子类别名称
        
    Returns:
        图片文件的相对路径，如果未找到则返回 None
    """
    # 尝试不同的类别名称映射（处理拼写错误）
    category_mappings = {
        "cartoon": ["cartoon", "katoon", "katoon"],
    }
    
    # 尝试映射后的类别
    possible_categories = category_mappings.get(category.lower(), [category])
    possible_categories.append(category)  # 也尝试原始类别
    
    # 支持的图片扩展名
    extensions = [".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG"]
    
    # 尝试不同的组合
    for cat in set(possible_categories):  # 使用 set 去重
        category_dir = DATA_DIR / cat
        if not category_dir.exists():
            continue
            
        # 尝试原始 subcategory 名称
        for ext in extensions:
            image_path = category_dir / f"{subcategory}{ext}"
            if image_path.exists():
                return f"/api/v1/data/{cat}/{subcategory}{ext}"
        
        # 尝试首字母大写的 subcategory
        for ext in extensions:
            capitalized_sub = subcategory[0].upper() + subcategory[1:] if subcategory else subcategory
            image_path = category_dir / f"{capitalized_sub}{ext}"
            if image_path.exists():
                return f"/api/v1/data/{cat}/{capitalized_sub}{ext}"
        
        # 尝试全小写的 subcategory
        for ext in extensions:
            lower_sub = subcategory.lower()
            image_path = category_dir / f"{lower_sub}{ext}"
            if image_path.exists():
                return f"/api/v1/data/{cat}/{lower_sub}{ext}"
        
        # 尝试全大写的 subcategory（首字母大写）
        for ext in extensions:
            title_sub = subcategory.title()
            image_path = category_dir / f"{title_sub}{ext}"
            if image_path.exists():
                return f"/api/v1/data/{cat}/{title_sub}{ext}"
    
    return None


def get_prompt_from_json(category: str, subcategory: str) -> Optional[str]:
    """
    从 JSON 配置文件中获取指定 category 和 subcategory 的 prompt
    
    Args:
        category: 类别名称
        subcategory: 子类别名称
        
    Returns:
        prompt 字符串，如果未找到则返回 None
    """
    if not PROMPTS_FILE_PATH.exists():
        return None
    
    try:
        with open(PROMPTS_FILE_PATH, 'r', encoding='utf-8') as f:
            prompts_data = json.load(f)
            for item in prompts_data:
                # 比较 category 和 subcategory（不区分大小写）
                if (item.get("category", "").lower() == category.lower() and 
                    item.get("subcategory", "").lower() == subcategory.lower()):
                    return item.get("prompt", "")
    except Exception as e:
        logger.error(f"读取 JSON 配置文件失败: {str(e)}")
        return None
    
    return None


def load_prompts_from_json() -> List[PromptStyle]:
    """
    从 JSON 配置文件加载 prompt 列表
    
    Returns:
        Prompt 风格列表
    """
    prompts = []
    
    if not PROMPTS_FILE_PATH.exists():
        raise HTTPException(
            status_code=500,
            detail=f"JSON 配置文件不存在: {PROMPTS_FILE_PATH}"
        )
    
    try:
        with open(PROMPTS_FILE_PATH, 'r', encoding='utf-8') as f:
            prompts_data = json.load(f)
            
            for item in prompts_data:
                category = item.get("category", "").strip()
                subcategory = item.get("subcategory", "").strip()
                prompt = item.get("prompt", "").strip()
                
                if not category or not subcategory or not prompt:
                    continue
                
                # 生成唯一 ID
                prompt_id = f"{category}_{subcategory}".lower().replace(" ", "_")
                
                # 查找图片文件
                image_url = find_image_file(category, subcategory)
                
                # 如果没有找到图片，使用默认路径（可能文件不存在）
                if not image_url:
                    # 尝试最常见的扩展名
                    image_url = f"/api/v1/data/{category}/{subcategory}.jpg"
                
                prompts.append(PromptStyle(
                    id=prompt_id,
                    category=category,
                    subcategory=subcategory,
                    prompt=prompt,
                    thumbnail_url=image_url,
                    original_url=image_url
                ))
    except json.JSONDecodeError as e:
        raise HTTPException(
            status_code=500,
            detail=f"JSON 配置文件格式错误: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"读取 JSON 配置文件失败: {str(e)}"
        )
    
    return prompts


@router.get("/prompts/list", response_model=PromptStyleListResponse)
async def list_prompts():
    """
    获取图片列表
    
    从 JSON 配置文件中读取 Category、Subcategory、AI Drawing Prompt 信息
    并返回对应的图片 URL
    """
    prompts = load_prompts_from_json()
    version = get_data_version()
    
    return PromptStyleListResponse(
        prompts=prompts,
        total=len(prompts),
        version=version
    )


@router.get("/prompts/version")
async def get_prompts_version():
    """
    获取数据版本号（用于检查是否有更新）
    
    返回JSON配置文件的最后修改时间作为版本号
    """
    return {
        "version": get_data_version()
    }


@router.get("/prompts/{category}/{subcategory}/image")
async def get_prompt_image(category: str, subcategory: str):
    """
    获取原始图片
    
    - **category**: 类别名称
    - **subcategory**: 子类别名称
    """
    image_url = find_image_file(category, subcategory)
    
    if not image_url:
        raise HTTPException(
            status_code=404,
            detail=f"图片文件不存在: {category}/{subcategory}"
        )
    
    # 从 URL 路径构建实际文件路径
    url_path = image_url.replace("/api/v1/data/", "")
    image_path = DATA_DIR / url_path
    
    if not image_path.exists():
        raise HTTPException(
            status_code=404,
            detail=f"图片文件不存在: {image_path}"
        )
    
    from fastapi.responses import FileResponse
    return FileResponse(image_path)

