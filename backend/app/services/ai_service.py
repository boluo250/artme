"""
大模型 API 服务封装
"""
import httpx
import asyncio
import base64
import os
import datetime
from pathlib import Path
from typing import Optional, Dict, Any, List
from app.config import settings
from app.utils.prompts import prompt_manager
from app.services.image_service import image_service
import logging

logger = logging.getLogger(__name__)


class AIService:
    """大模型 API 服务"""
    
    def __init__(self):
        self.api_key = settings.OPENAI_API_KEY
        self.base_url = "https://api.openai.com/v1"
        self.max_retries = 3
        self.retry_delay = 1.0
        
        # OpenRouter API 配置（用于图像生成）
        self.openrouter_api_key = settings.OPENROUTER_API_KEY
        self.openrouter_endpoint = settings.OPENROUTER_ENDPOINT
        self.openrouter_model = settings.OPENROUTER_MODEL
    
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
            {"id": "google/gemini-2.5-flash-image-preview", "name": "Google Gemini 2.5 Flash Image", "status": "available"},
        ]
    
    async def encode_image_to_base64(self, image_path: str) -> str:
        """
        将图片文件编码为 base64 格式（异步版本）
        
        Args:
            image_path: 图片文件路径
            
        Returns:
            base64 编码的图片数据（data URI 格式）
        """
        try:
            # 读取图片文件
            async with httpx.AsyncClient() as client:
                # 如果是本地文件
                if os.path.exists(image_path):
                    with open(image_path, "rb") as f:
                        data = f.read()
                # 如果是 URL，下载图片
                elif image_path.startswith("http://") or image_path.startswith("https://"):
                    response = await client.get(image_path)
                    response.raise_for_status()
                    data = response.content
                else:
                    raise ValueError(f"无效的图片路径: {image_path}")
            
            # 编码为 base64
            encoded = base64.b64encode(data).decode("utf-8")
            
            # 根据文件扩展名确定 MIME 类型
            ext = Path(image_path).suffix.lower()
            if ext in [".jpg", ".jpeg"]:
                mime_type = "image/jpeg"
            elif ext == ".png":
                mime_type = "image/png"
            else:
                mime_type = "image/jpeg"  # 默认使用 jpeg
            
            return f"data:{mime_type};base64,{encoded}"
        except Exception as e:
            logger.error(f"编码图片失败: {str(e)}")
            raise
    
    async def generate_image_with_doubao(
        self,
        image_path_or_url: Optional[str] = None,
        prompt: str = "请把这张图片转换为吉卜力工作室风格,一组图",
        output_dir: Optional[str] = None,
        size: str = "2K",
        watermark: bool = True,
        max_images: int = 5
    ) -> Dict[str, Any]:
        """
        使用 OpenRouter API (Google Gemini) 生成图片（异步版本）
        注意：方法名保持 generate_image_with_doubao 以保持接口兼容性
        
        Args:
            image_path_or_url: 图片路径（本地文件）或图片URL，必须提供
            prompt: 提示词
            output_dir: 输出目录，如果为None则使用 uploads/generated 目录
            size: 图片尺寸（OpenRouter API 不支持此参数，保留以兼容接口）
            watermark: 是否添加水印（OpenRouter API 不支持此参数，保留以兼容接口）
            max_images: 最大生成图片数量（OpenRouter API 目前只返回一张，保留以兼容接口）
            
        Returns:
            包含生成结果的字典:
            {
                "success": bool,
                "images": List[str],  # 生成的图片URL列表
                "usage": Dict,  # API使用情况
                "output_dir": str  # 输出目录
            }
        """
        try:
            # 检查 API Key 是否配置
            if not self.openrouter_api_key or self.openrouter_api_key.strip() == "":
                error_msg = "OpenRouter API Key 未配置，请在环境变量或配置文件中设置 OPENROUTER_API_KEY"
                logger.error(error_msg)
                return {
                    "success": False,
                    "error": error_msg,
                    "images": [],
                    "output_dir": output_dir if output_dir else None
                }
            
            # 检查输入图片
            if not image_path_or_url:
                raise ValueError("必须提供输入图片路径或URL")
            
            # 确定输出目录
            if output_dir is None:
                output_dir = str(image_service.upload_dir / "generated")
            else:
                output_dir = str(output_dir)
            
            # 创建输出目录
            os.makedirs(output_dir, exist_ok=True)
            
            # 编码图片为 base64
            if image_path_or_url.startswith("http://") or image_path_or_url.startswith("https://"):
                # 如果是URL，下载并编码
                image_b64 = await self.encode_image_to_base64(image_path_or_url)
            else:
                # 如果是本地文件，直接编码
                if not os.path.exists(image_path_or_url):
                    raise ValueError(f"图片文件不存在: {image_path_or_url}")
                image_b64 = await self.encode_image_to_base64(image_path_or_url)
            
            # 构建请求头
            headers = {
                "Authorization": f"Bearer {self.openrouter_api_key}",
                "Content-Type": "application/json",
            }
            
            # 构造 messages
            messages = [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {"type": "image_url", "image_url": {"url": image_b64}}
                    ]
                }
            ]
            
            # 构建请求体
            payload = {
                "model": self.openrouter_model,
                "messages": messages,
                "modalities": ["image", "text"],
                "image_config": {
                    "aspect_ratio": "1:1"
                }
            }
            
            # 记录请求信息（不记录敏感信息）
            logger.info(f"调用 OpenRouter API: 模型={self.openrouter_model}, prompt长度={len(prompt)}")
            
            # 调用 OpenRouter API
            async with httpx.AsyncClient(timeout=120.0) as client:
                response = await client.post(
                    self.openrouter_endpoint,
                    headers=headers,
                    json=payload
                )
                
                # 记录响应状态和内容（用于调试）
                logger.info(f"OpenRouter API 响应状态: {response.status_code}")
                
                # 检查响应状态
                try:
                    response.raise_for_status()
                except httpx.HTTPStatusError as e:
                    error_text = response.text[:500] if hasattr(response, 'text') else str(e)
                    logger.error(f"OpenRouter API 返回错误: {response.status_code}, 响应: {error_text}")
                    
                    # 针对 401 错误提供更详细的错误信息
                    if e.response.status_code == 401:
                        error_detail = "OpenRouter API 认证失败。请检查：\n"
                        error_detail += "1. API Key 是否正确（在环境变量 OPENROUTER_API_KEY 或配置文件中设置）\n"
                        error_detail += "2. API Key 是否已过期或被撤销\n"
                        error_detail += "3. API Key 是否有访问该模型的权限\n"
                        error_detail += f"原始错误: {error_text}"
                        logger.error(error_detail)
                        raise ValueError(error_detail) from e
                    
                    raise
                
                result = response.json()
                logger.debug(f"OpenRouter API 响应: {result}")
            
            # 从响应中提取图片数据
            choices = result.get("choices", [])
            if not choices:
                raise RuntimeError(f"No choices returned: {result}")
            
            message = choices[0].get("message", {})
            images = message.get("images", [])
            if not images:
                raise RuntimeError(f"No images returned: {result}")
            
            # 获取第一张图片（OpenRouter API 目前只返回一张）
            image_data = images[0]["image_url"]["url"]
            
            # 保存图片
            saved_files = []
            image_urls = []
            
            # 生成文件名
            timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S_%f")
            filename = f"generated_image_{timestamp}.png"
            filepath = os.path.join(output_dir, filename)
            
            # 解码 base64 数据并保存
            if image_data.startswith("data:image"):
                image_data = image_data.split(",", 1)[1]
            
            image_bytes = base64.b64decode(image_data)
            with open(filepath, "wb") as f:
                f.write(image_bytes)
            
            logger.info(f"图片已成功保存为: {filepath}")
            saved_files.append(filepath)
            
            # 生成图片URL（相对于 uploads 目录）
            rel_path = os.path.relpath(filepath, image_service.upload_dir)
            image_url = image_service.get_image_url(rel_path)
            image_urls.append(image_url)
            
            # 提取使用情况（如果存在）
            usage = result.get("usage")
            
            return {
                "success": True,
                "images": image_urls,
                "saved_files": saved_files,
                "usage": usage,
                "output_dir": output_dir
            }
            
        except ValueError as e:
            # 处理 API Key 验证错误或认证错误
            error_msg = str(e)
            logger.error(f"OpenRouter API 调用失败: {error_msg}", exc_info=True)
            return {
                "success": False,
                "error": error_msg,
                "images": [],
                "output_dir": output_dir if 'output_dir' in locals() else None
            }
        except httpx.HTTPStatusError as e:
            error_msg = f"HTTP 错误 {e.response.status_code}: {e.response.text[:200] if e.response else str(e)}"
            logger.error(f"OpenRouter API 调用失败: {error_msg}", exc_info=True)
            
            # 针对 401 错误提供更友好的错误信息
            if e.response.status_code == 401:
                error_msg = "OpenRouter API 认证失败。请检查 API Key 是否正确配置且有效。"
            
            return {
                "success": False,
                "error": error_msg,
                "images": [],
                "output_dir": output_dir if 'output_dir' in locals() else None
            }
        except httpx.RequestError as e:
            error_msg = f"请求错误: {str(e)}"
            logger.error(f"OpenRouter API 调用失败: {error_msg}", exc_info=True)
            return {
                "success": False,
                "error": error_msg,
                "images": [],
                "output_dir": output_dir if 'output_dir' in locals() else None
            }
        except Exception as e:
            error_msg = f"{type(e).__name__}: {str(e)}"
            logger.error(f"OpenRouter API 调用失败: {error_msg}", exc_info=True)
            return {
                "success": False,
                "error": error_msg,
                "images": [],
                "output_dir": output_dir if 'output_dir' in locals() else None
            }


# 全局 AI 服务实例
ai_service = AIService()

