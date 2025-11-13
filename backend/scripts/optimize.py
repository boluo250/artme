"""
性能优化脚本
"""
import asyncio
import time
from app.services.image_service import image_service
from app.services.ai_service import ai_service


async def test_image_optimization():
    """测试图像优化性能"""
    # 这里可以添加性能测试代码
    print("图像优化性能测试...")


async def test_api_performance():
    """测试 API 性能"""
    # 这里可以添加 API 性能测试代码
    print("API 性能测试...")


if __name__ == "__main__":
    asyncio.run(test_image_optimization())
    asyncio.run(test_api_performance())

