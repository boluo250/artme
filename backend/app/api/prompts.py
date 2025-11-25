"""
Prompt 图片管理 API
"""
import json
import os
import logging
import hashlib
from pathlib import Path
from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
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
    category_id: int
    subcategory: str
    subcategory_id: int
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
    获取数据版本号（基于JSON配置文件内容的哈希值）
    使用文件内容的MD5哈希值，确保任何内容变化都会被检测到
    
    Returns:
        版本号字符串（MD5哈希值的前16个字符）
    """
    if PROMPTS_FILE_PATH.exists():
        try:
            with open(PROMPTS_FILE_PATH, 'rb') as f:
                file_content = f.read()
                # 使用MD5哈希确保任何内容变化都会被检测到
                hash_obj = hashlib.md5(file_content)
                hash_hex = hash_obj.hexdigest()
                # 使用前16个字符作为版本号（足够唯一，且不会太长）
                version = hash_hex[:16]
                logger.debug(f"数据版本号: {version} (文件: {PROMPTS_FILE_PATH})")
                return version
        except Exception as e:
            logger.error(f"计算版本号失败: {str(e)}")
            # 如果计算哈希失败，回退到使用修改时间
            stat = PROMPTS_FILE_PATH.stat()
            mtime = stat.st_mtime
            return str(int(mtime))
    return "0"


def find_thumbnail_file(category: str, subcategory: str, explicit_thumbnail: Optional[str] = None) -> Optional[str]:
    """
    查找缩略图文件
    如果 JSON 中明确指定了 thumbnail，则直接使用；
    否则使用默认规则查找（查找 _abbreviated 后缀的文件）
    
    Args:
        category: 类别名称
        subcategory: 子类别名称
        explicit_thumbnail: JSON 中明确指定的缩略图文件名
        
    Returns:
        缩略图文件的相对路径，如果未找到则返回 None
    """
    category_dir = DATA_DIR / category
    if not category_dir.exists():
        logger.warning("类别目录不存在: %s", category_dir)
        return None

    # 1. 优先使用 JSON 中明确指定的缩略图
    if explicit_thumbnail:
        image_path = category_dir / explicit_thumbnail
        if image_path.exists():
            return f"/api/v1/data/{category}/{explicit_thumbnail}"
        else:
            logger.warning("JSON 指定的缩略图不存在: %s", image_path)
    
    # 2. 默认查找规则：查找 subcategory_abbreviated.*
    # 尝试不同的类别名称映射（处理拼写错误）
    category_mappings = {
        "cartoon": ["cartoon", "katoon", "katoon"],
    }
    
    # 尝试映射后的类别
    possible_categories = category_mappings.get(category.lower(), [category])
    possible_categories.append(category)  # 也尝试原始类别
    
    # 支持的图片扩展名（优先返回 GIF 动画）
    extensions = [ 
        ".gif", ".GIF",      
        ".png", ".PNG",      
        ".jpg", ".jpeg", ".JPG", ".JPEG",  
    ]
    
    # 尝试不同的组合
    for cat in set(possible_categories):  # 使用 set 去重
        cat_dir = DATA_DIR / cat
        if not cat_dir.exists():
            continue
            
        # 生成候选名称（只包含带 _abbreviated 后缀的）
        candidate_names: list[str] = []

        def add_variants(base: str):
            bases = set([base])
            # 分隔符互换
            bases.update({
                base.replace(" ", "_"),
                base.replace(" ", "-"),
                base.replace("_", " "),
                base.replace("-", " "),
                base.replace("_", "-"),
                base.replace("-", "_")
            })
            for b in list(bases):
                # 只添加带 _abbreviated 后缀的
                candidate_names.append(b + "_abbreviated")
                if b:
                    candidate_names.append(b[0].upper() + b[1:] + "_abbreviated")
                candidate_names.append(b.lower() + "_abbreviated")
                candidate_names.append(b.title() + "_abbreviated")

        add_variants(subcategory)
        
        # 去重并保持顺序
        seen = set()
        unique_candidates = []
        for name in candidate_names:
            if name not in seen:
                unique_candidates.append(name)
                seen.add(name)
        
        # 优化搜索策略：
        # 1. 先遍历所有候选名称，专门找 .gif
        # 2. 如果没找到 gif，再遍历一遍找其他格式 (.jpg, .png)
        
        # 第一轮：只找 GIF
        for name in unique_candidates:
            for ext in [".gif", ".GIF"]:
                image_path = cat_dir / f"{name}{ext}"
                if image_path.exists():
                    return f"/api/v1/data/{cat}/{name}{ext}"
        
        # 第二轮：找其他格式
        other_extensions = [e for e in extensions if e.lower() != ".gif"]
        for name in unique_candidates:
            for ext in other_extensions:
                image_path = cat_dir / f"{name}{ext}"
                if image_path.exists():
                    return f"/api/v1/data/{cat}/{name}{ext}"
    
    # 记录诊断信息，便于排查 404
    logger.warning(
        "未找到缩略图文件: category=%s, subcategory=%s_abbreviated, 搜索目录=%s",
        category, subcategory, str(DATA_DIR / category)
    )
    return None


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
    
    # 支持的图片扩展名（常见优先）
    # 用于详情页原图，通常是 JPG 格式
    extensions = [
        ".jpg", ".jpeg", ".JPG", ".JPEG",  # 优先 JPG（原图常用格式）
        ".png", ".PNG",      # 其次是 PNG
        ".gif", ".GIF",      # 最后才是 GIF
    ]
    
    # 尝试不同的组合
    for cat in set(possible_categories):  # 使用 set 去重
        category_dir = DATA_DIR / cat
        if not category_dir.exists():
            continue
            
        # 生成候选名称集合：
        # - 原始、首字母大写、全小写、Title Case
        # - 分隔符互换：空格 <-> '_' <-> '-'
        # - 去空格
        # - 常见后缀（如 _abbreviated）
        candidate_names: list[str] = []

        def add_variants(base: str):
            bases = set([base])
            # 分隔符互换
            bases.update({
                base.replace(" ", "_"),
                base.replace(" ", "-"),
                base.replace("_", " "),
                base.replace("-", " "),
                base.replace("_", "-"),
                base.replace("-", "_")
            })
            for b in list(bases):
                candidate_names.append(b)
                if b:
                    candidate_names.append(b[0].upper() + b[1:])
                candidate_names.append(b.lower())
                candidate_names.append(b.title())
                # 去空格变体
                no_space = b.replace(" ", "")
                if no_space and no_space != b:
                    candidate_names.append(no_space)

        add_variants(subcategory)
        
        # 详情页优先使用原始文件（不带 _abbreviated 后缀）
        # 如果找不到原始文件，作为后备才尝试 _abbreviated 版本
        base_candidates = list(candidate_names)
        abbreviated_candidates = [name + "_abbreviated" for name in base_candidates]
        
        # 先查找原始文件，找不到再查找 _abbreviated 版本
        candidate_names = base_candidates + abbreviated_candidates
        
        # 去重并保持顺序
        seen = set()
        unique_candidates = []
        for name in candidate_names:
            if name not in seen:
                unique_candidates.append(name)
                seen.add(name)
        
        # 依次尝试候选名称与扩展名
        for name in unique_candidates:
            for ext in extensions:
                image_path = category_dir / f"{name}{ext}"
                if image_path.exists():
                    return f"/api/v1/data/{cat}/{name}{ext}"
    
    # 记录诊断信息，便于排查 404
    logger.warning(
        "未找到图片文件: category=%s, subcategory=%s, 搜索目录=%s",
        category, subcategory, str(DATA_DIR / category)
    )
    return None


def get_prompt_from_json(category: str, subcategory: str) -> Optional[dict]:
    """
    从 JSON 配置文件中获取指定 category 和 subcategory 的详细信息
    
    Args:
        category: 类别名称
        subcategory: 子类别名称
        
    Returns:
        subcategory 对象字典，如果未找到则返回 None
    """
    if not PROMPTS_FILE_PATH.exists():
        return None
    
    try:
        with open(PROMPTS_FILE_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
            categories = data.get("categories", [])
            
            for cat in categories:
                if cat.get("name", "").lower() == category.lower():
                    subcategories = cat.get("subcategories", [])
                    for subcat in subcategories:
                        if subcat.get("name", "").lower() == subcategory.lower():
                            return subcat
    except Exception as e:
        logger.error(f"读取 JSON 配置文件失败: {str(e)}")
        return None
    
    return None


def load_prompts_from_json() -> List[PromptStyle]:
    """
    从 JSON 配置文件加载 prompt 列表
    
    Returns:
        Prompt 风格列表（按 category_id 和 subcategory_id 排序）
    """
    prompts = []
    
    if not PROMPTS_FILE_PATH.exists():
        raise HTTPException(
            status_code=500,
            detail=f"JSON 配置文件不存在: {PROMPTS_FILE_PATH}"
        )
    
    try:
        with open(PROMPTS_FILE_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
            categories = data.get("categories", [])
            
            # 按 category_id 排序
            categories.sort(key=lambda x: x.get("id", 0))
            
            for cat in categories:
                category_id = cat.get("id", 0)
                category_name = cat.get("name", "").strip()
                subcategories = cat.get("subcategories", [])
                
                if not category_name:
                    continue
                
                # 按 subcategory_id 排序
                subcategories.sort(key=lambda x: x.get("id", 0))
                
                for subcat in subcategories:
                    subcategory_id = subcat.get("id", 0)
                    subcategory_name = subcat.get("name", "").strip()
                    prompt = subcat.get("prompt", "").strip()
                    thumbnail_name = subcat.get("thumbnail", "").strip()
                    
                    if not subcategory_name or not prompt:
                        continue
                    
                    # 生成唯一 ID
                    prompt_id = f"{category_name}_{subcategory_name}".lower().replace(" ", "_")
                    
                    # 缩略图路由：专门查找 _abbreviated 后缀的文件
                    thumbnail_route = f"/api/v1/prompts/{category_name}/{subcategory_name}/thumbnail"
                    # 原图路由：查找原始大图
                    original_route = f"/api/v1/prompts/{category_name}/{subcategory_name}/image"

                    prompts.append(PromptStyle(
                        id=prompt_id,
                        category=category_name,
                        category_id=category_id,
                        subcategory=subcategory_name,
                        subcategory_id=subcategory_id,
                        prompt=prompt,
                        thumbnail_url=thumbnail_route,
                        original_url=original_route
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


@router.get("/prompts/{category}/{subcategory}/thumbnail")
async def get_prompt_thumbnail(category: str, subcategory: str):
    """
    获取缩略图
    
    - **category**: 类别名称
    - **subcategory**: 子类别名称
    """
    # 先尝试从 JSON 获取明确指定的缩略图配置
    explicit_thumbnail = None
    subcat_data = get_prompt_from_json(category, subcategory)
    if subcat_data:
        explicit_thumbnail = subcat_data.get("thumbnail")
        
    image_url = find_thumbnail_file(category, subcategory, explicit_thumbnail)
    
    if not image_url:
        raise HTTPException(
            status_code=404,
            detail=f"缩略图文件不存在: {category}/{subcategory}"
        )
    
    # 从 URL 路径构建实际文件路径
    url_path = image_url.replace("/api/v1/data/", "")
    image_path = DATA_DIR / url_path
    
    if not image_path.exists():
        raise HTTPException(
            status_code=404,
            detail=f"缩略图文件不存在: {image_path}"
        )
    
    return FileResponse(image_path)


@router.get("/prompts/{category}/{subcategory}/image")
async def get_prompt_image(category: str, subcategory: str):
    """
    获取原始大图
    
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
    
    return FileResponse(image_path)
