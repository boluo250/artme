"""
Prompt 模板管理
"""
from typing import Dict, Optional
import json
import os


class PromptManager:
    """Prompt 模板管理器"""
    
    def __init__(self):
        self.style_templates: Dict[str, str] = {}
        self._load_default_templates()
    
    def _load_default_templates(self):
        """加载默认的 prompt 模板"""
        self.style_templates = {
            "style_001": "anime style, kawaii, {user_prompt}, high quality, detailed, colorful",
            "style_002": "American cartoon style, {user_prompt}, vibrant colors, clean lines",
            "style_003": "3D rendered, Pixar style, {user_prompt}, detailed, professional lighting",
            "style_004": "hand-drawn illustration, {user_prompt}, artistic, sketch style",
            "style_005": "pixel art style, {user_prompt}, 8-bit, retro gaming aesthetic",
            "style_006": "watercolor painting, {user_prompt}, soft colors, artistic",
            "style_007": "chibi style, {user_prompt}, super cute, big head, small body",
            "style_008": "realistic portrait, {user_prompt}, professional photography style",
        }
    
    def get_prompt(self, style_id: Optional[str], user_prompt: str) -> str:
        """
        根据风格ID和用户输入生成完整的 prompt
        
        Args:
            style_id: 风格ID，如果为None则使用默认风格
            user_prompt: 用户输入的描述文本
        
        Returns:
            完整的 prompt 字符串
        """
        if style_id and style_id in self.style_templates:
            template = self.style_templates[style_id]
            return template.format(user_prompt=user_prompt)
        else:
            # 默认风格：卡通头像
            return f"cartoon avatar, {user_prompt}, cute, colorful, high quality"
    
    def add_template(self, style_id: str, template: str):
        """添加新的 prompt 模板"""
        self.style_templates[style_id] = template
    
    def get_all_templates(self) -> Dict[str, str]:
        """获取所有模板"""
        return self.style_templates.copy()


# 全局 Prompt 管理器实例
prompt_manager = PromptManager()

