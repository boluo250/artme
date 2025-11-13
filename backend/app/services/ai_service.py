"""
大模型 API 服务封装
"""
import httpx
import asyncio
from typing import Optional, Dict, Any
from app.config import settings
from app.utils.prompts import prompt_manager
import logging

logger = logging.getLogger(__name__)


class AIService:
    """大模型 API 服务"""
    
    def __init__(self):
        self.api_key = settings.OPENAI_API_KEY
        self.base_url = "https://api.openai.com/v1"
        self.max_retries = 3
        self.retry_delay = 1.0
    
    async def generate_image(
        self,
        prompt: str,
        style_id: Optional[str] = None,
        width: int = 512,
        height: int = 512,
        model: str = "dall-e-3"
    ) -> Dict[str, Any]:
        """
        生成图像
        
        Args:
            prompt: 用户输入的描述
            style_id: 风格ID（可选）
            width: 图像宽度
            height: 图像高度
            model: 使用的模型
        
        Returns:
            包含图像URL和任务信息的字典
        """
        # 根据风格ID生成完整的 prompt
        full_prompt = prompt_manager.get_prompt(style_id, prompt)
        
        # 调用大模型 API
        if model.startswith("dall-e"):
            return await self._call_openai_dalle(full_prompt, width, height, model)
        else:
            raise ValueError(f"不支持的模型: {model}")
    
    async def _call_openai_dalle(
        self,
        prompt: str,
        width: int,
        height: int,
        model: str
    ) -> Dict[str, Any]:
        """调用 OpenAI DALL-E API"""
        if not self.api_key:
            raise ValueError("OpenAI API Key 未配置")
        
        url = f"{self.base_url}/images/generations"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        # DALL-E 3 只支持特定尺寸
        if model == "dall-e-3":
            size = "1024x1024"  # DALL-E 3 只支持 1024x1024
        else:
            # DALL-E 2 支持多种尺寸
            if width == 512 and height == 512:
                size = "512x512"
            elif width == 1024 and height == 1024:
                size = "1024x1024"
            else:
                size = "512x512"
        
        payload = {
            "model": model,
            "prompt": prompt,
            "n": 1,
            "size": size,
            "quality": "standard"
        }
        
        # 重试机制
        for attempt in range(self.max_retries):
            try:
                async with httpx.AsyncClient(timeout=60.0) as client:
                    response = await client.post(url, headers=headers, json=payload)
                    response.raise_for_status()
                    data = response.json()
                    
                    if "data" in data and len(data["data"]) > 0:
                        image_url = data["data"][0]["url"]
                        return {
                            "image_url": image_url,
                            "prompt": prompt,
                            "model": model,
                            "status": "completed"
                        }
                    else:
                        raise ValueError("API 响应格式错误")
            
            except httpx.HTTPStatusError as e:
                if e.response.status_code == 429:  # 速率限制
                    wait_time = self.retry_delay * (2 ** attempt)
                    logger.warning(f"速率限制，等待 {wait_time} 秒后重试...")
                    await asyncio.sleep(wait_time)
                    continue
                elif e.response.status_code >= 500:  # 服务器错误
                    if attempt < self.max_retries - 1:
                        wait_time = self.retry_delay * (2 ** attempt)
                        logger.warning(f"服务器错误，等待 {wait_time} 秒后重试...")
                        await asyncio.sleep(wait_time)
                        continue
                raise
            
            except Exception as e:
                if attempt < self.max_retries - 1:
                    wait_time = self.retry_delay * (2 ** attempt)
                    logger.warning(f"请求失败，等待 {wait_time} 秒后重试: {str(e)}")
                    await asyncio.sleep(wait_time)
                    continue
                raise
        
        raise Exception("达到最大重试次数，请求失败")
    
    async def list_models(self) -> list:
        """获取可用的模型列表"""
        # TODO: 实现模型列表获取
        return [
            {"id": "dall-e-3", "name": "DALL-E 3", "status": "available"},
            {"id": "dall-e-2", "name": "DALL-E 2", "status": "available"},
        ]


# 全局 AI 服务实例
ai_service = AIService()

