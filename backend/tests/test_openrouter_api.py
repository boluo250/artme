#!/usr/bin/env python3
"""
测试 OpenRouter API 的脚本
模拟前端请求，直接调用 ai_service 接口
"""
import asyncio
import os
import sys
from pathlib import Path
from typing import Optional

# 添加项目路径到 sys.path
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

from app.services.ai_service import ai_service
from app.api.prompts import get_prompt_from_csv
import logging

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def test_ai_service_direct(
    image_path: str,
    category: str,
    subcategory: str,
    size: str = "2K",
    watermark: bool = True,
    max_images: int = 5
):
    """
    直接调用 ai_service 的方法，模拟前端请求流程
    
    Args:
        image_path: 输入图片路径
        category: 类别（用于查找 prompt）
        subcategory: 子类别（用于查找 prompt）
        size: 图片尺寸
        watermark: 是否添加水印
        max_images: 最大生成图片数
    """
    print("=" * 80)
    print("测试 OpenRouter API - 直接调用 ai_service")
    print("=" * 80)
    print(f"输入图片: {image_path}")
    print(f"类别: {category}")
    print(f"子类别: {subcategory}")
    print(f"尺寸: {size}")
    print(f"水印: {watermark}")
    print(f"最大图片数: {max_images}")
    print("=" * 80)
    print()
    
    try:
        # 步骤1: 检查输入图片
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"图片文件不存在: {image_path}")
        print(f"✓ 输入图片检查通过: {image_path}")
        print()
        
        # 步骤2: 从 CSV 获取 prompt（模拟前端请求中的 prompt 获取）
        print("正在从 CSV 获取 prompt...")
        final_prompt = get_prompt_from_csv(category, subcategory)
        if not final_prompt:
            raise ValueError(f"未找到对应的 prompt: {category}/{subcategory}")
        print(f"✓ 获取到 prompt:")
        print(f"  {final_prompt[:100]}..." if len(final_prompt) > 100 else f"  {final_prompt}")
        print()
        
        # 步骤3: 调用 ai_service.generate_image_with_doubao（模拟后端处理）
        print("正在调用 ai_service.generate_image_with_doubao...")
        print()
        
        result = await ai_service.generate_image_with_doubao(
            image_path_or_url=image_path,
            prompt=final_prompt,
            output_dir=None,  # 使用默认输出目录
            size=size,
            watermark=watermark,
            max_images=max_images
        )
        
        print()
        print("=" * 80)
        print("生成结果")
        print("=" * 80)
        
        if result.get("success"):
            print("✓ 生成成功！")
            print()
            
            images = result.get("images", [])
            saved_files = result.get("saved_files", [])
            usage = result.get("usage")
            output_dir = result.get("output_dir")
            
            print(f"生成图片数量: {len(images)}")
            print(f"输出目录: {output_dir}")
            print()
            
            if images:
                print("生成的图片 URL:")
                for idx, image_url in enumerate(images, 1):
                    print(f"  {idx}. {image_url}")
                print()
            
            if saved_files:
                print("保存的文件路径:")
                for idx, file_path in enumerate(saved_files, 1):
                    file_size = os.path.getsize(file_path) if os.path.exists(file_path) else 0
                    print(f"  {idx}. {file_path} ({file_size} 字节)")
                print()
            
            if usage:
                print("API 使用情况:")
                for key, value in usage.items():
                    print(f"  {key}: {value}")
                print()
            
            return {
                "success": True,
                "images": images,
                "saved_files": saved_files,
                "usage": usage,
                "output_dir": output_dir
            }
        else:
            error = result.get("error", "未知错误")
            print(f"✗ 生成失败: {error}")
            return {
                "success": False,
                "error": error
            }
    
    except Exception as e:
        print()
        print("=" * 80)
        print("错误")
        print("=" * 80)
        print(f"✗ 发生错误: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": str(e)
        }


async def test_with_custom_prompt(
    image_path: str,
    prompt: str,
    size: str = "2K",
    watermark: bool = True,
    max_images: int = 5
):
    """
    使用自定义 prompt 测试（不通过 CSV）
    
    Args:
        image_path: 输入图片路径
        prompt: 自定义提示词
        size: 图片尺寸
        watermark: 是否添加水印
        max_images: 最大生成图片数
    """
    print("=" * 80)
    print("测试 OpenRouter API - 使用自定义 prompt")
    print("=" * 80)
    print(f"输入图片: {image_path}")
    print(f"提示词: {prompt}")
    print("=" * 80)
    print()
    
    try:
        # 检查输入图片
        if not os.path.exists(image_path):
            raise FileNotFoundError(f"图片文件不存在: {image_path}")
        print(f"✓ 输入图片检查通过: {image_path}")
        print()
        
        # 直接调用 ai_service
        print("正在调用 ai_service.generate_image_with_doubao...")
        print()
        
        result = await ai_service.generate_image_with_doubao(
            image_path_or_url=image_path,
            prompt=prompt,
            output_dir=None,
            size=size,
            watermark=watermark,
            max_images=max_images
        )
        
        print()
        print("=" * 80)
        print("生成结果")
        print("=" * 80)
        
        if result.get("success"):
            print("✓ 生成成功！")
            images = result.get("images", [])
            saved_files = result.get("saved_files", [])
            
            if images:
                print("\n生成的图片 URL:")
                for idx, image_url in enumerate(images, 1):
                    print(f"  {idx}. {image_url}")
            
            if saved_files:
                print("\n保存的文件路径:")
                for idx, file_path in enumerate(saved_files, 1):
                    print(f"  {idx}. {file_path}")
            
            return result
        else:
            error = result.get("error", "未知错误")
            print(f"✗ 生成失败: {error}")
            return result
    
    except Exception as e:
        print(f"✗ 发生错误: {type(e).__name__}: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "error": str(e)
        }


async def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="测试 OpenRouter API")
    parser.add_argument("image", help="输入图片路径")
    parser.add_argument("--category", help="类别（用于从 CSV 获取 prompt）")
    parser.add_argument("--subcategory", help="子类别（用于从 CSV 获取 prompt）")
    parser.add_argument("--prompt", help="自定义提示词（如果提供，将忽略 category/subcategory）")
    parser.add_argument("--size", default="2K", help="图片尺寸（默认: 2K）")
    parser.add_argument("--watermark", type=bool, default=True, help="是否添加水印（默认: True）")
    parser.add_argument("--max-images", type=int, default=5, help="最大生成图片数（默认: 5）")
    
    args = parser.parse_args()
    
    # 检查参数
    if args.prompt:
        # 使用自定义 prompt
        result = await test_with_custom_prompt(
            image_path=args.image,
            prompt=args.prompt,
            size=args.size,
            watermark=args.watermark,
            max_images=args.max_images
        )
    elif args.category and args.subcategory:
        # 使用 CSV 中的 prompt
        result = await test_ai_service_direct(
            image_path=args.image,
            category=args.category,
            subcategory=args.subcategory,
            size=args.size,
            watermark=args.watermark,
            max_images=args.max_images
        )
    else:
        print("错误: 必须提供 --category 和 --subcategory，或者 --prompt")
        print()
        print("示例:")
        print(f"  python {sys.argv[0]} image.jpg --category Cartoon_Anime --subcategory '2D Anime'")
        print(f"  python {sys.argv[0]} image.jpg --prompt '转换为卡通风格'")
        sys.exit(1)
    
    # 返回退出码
    sys.exit(0 if result.get("success") else 1)


if __name__ == "__main__":
    asyncio.run(main())
