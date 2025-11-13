"""
风格管理 API
"""
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import List, Optional

router = APIRouter()


class Style(BaseModel):
    """风格模型"""
    id: str
    name: str
    description: str
    category: str
    example_image_url: str
    prompt_template: str
    tags: List[str] = []


class StyleListResponse(BaseModel):
    """风格列表响应"""
    styles: List[Style]
    total: int


@router.get("/styles/list", response_model=StyleListResponse)
async def list_styles(
    category: Optional[str] = Query(None, description="按类别筛选"),
    limit: int = Query(20, ge=1, le=100, description="返回数量限制"),
    offset: int = Query(0, ge=0, description="偏移量")
):
    """
    获取风格列表
    
    - **category**: 风格类别（可选）
    - **limit**: 返回数量限制（1-100）
    - **offset**: 偏移量
    """
    # TODO: 从数据库或配置文件加载风格数据
    # 示例数据
    styles = [
        Style(
            id="style_001",
            name="日系卡通",
            description="日系风格的卡通头像",
            category="anime",
            example_image_url="/style_images/anime_example.jpg",
            prompt_template="anime style, kawaii, {user_prompt}, high quality",
            tags=["anime", "kawaii", "cute"]
        ),
        Style(
            id="style_002",
            name="美式卡通",
            description="美式风格的卡通头像",
            category="cartoon",
            example_image_url="/style_images/cartoon_example.jpg",
            prompt_template="American cartoon style, {user_prompt}, vibrant colors",
            tags=["cartoon", "american", "colorful"]
        ),
        Style(
            id="style_003",
            name="3D 渲染",
            description="3D 渲染风格的卡通头像",
            category="3d",
            example_image_url="/style_images/3d_example.jpg",
            prompt_template="3D rendered, Pixar style, {user_prompt}, detailed",
            tags=["3d", "pixar", "rendered"]
        ),
    ]
    
    # 按类别筛选
    if category:
        styles = [s for s in styles if s.category == category]
    
    # 分页
    total = len(styles)
    styles = styles[offset:offset + limit]
    
    return StyleListResponse(styles=styles, total=total)


@router.get("/styles/search", response_model=StyleListResponse)
async def search_styles(
    q: str = Query(..., description="搜索关键词"),
    limit: int = Query(20, ge=1, le=100)
):
    """
    搜索风格
    
    - **q**: 搜索关键词（名称、描述、标签）
    - **limit**: 返回数量限制
    """
    # TODO: 实现搜索逻辑
    # 示例：简单的关键词匹配
    all_styles = [
        Style(
            id="style_001",
            name="日系卡通",
            description="日系风格的卡通头像",
            category="anime",
            example_image_url="/style_images/anime_example.jpg",
            prompt_template="anime style, kawaii, {user_prompt}, high quality",
            tags=["anime", "kawaii", "cute"]
        ),
    ]
    
    # 简单的搜索匹配
    query_lower = q.lower()
    matched_styles = [
        s for s in all_styles
        if query_lower in s.name.lower()
        or query_lower in s.description.lower()
        or any(query_lower in tag.lower() for tag in s.tags)
    ]
    
    return StyleListResponse(
        styles=matched_styles[:limit],
        total=len(matched_styles)
    )


@router.get("/styles/{style_id}", response_model=Style)
async def get_style(style_id: str):
    """
    获取单个风格的详细信息
    
    - **style_id**: 风格ID
    """
    # TODO: 从数据库加载风格数据
    # 示例数据
    if style_id == "style_001":
        return Style(
            id="style_001",
            name="日系卡通",
            description="日系风格的卡通头像",
            category="anime",
            example_image_url="/style_images/anime_example.jpg",
            prompt_template="anime style, kawaii, {user_prompt}, high quality",
            tags=["anime", "kawaii", "cute"]
        )
    
    raise HTTPException(status_code=404, detail="风格不存在")

