#!/usr/bin/env python3
"""
串联 modelapi.py 和 dealpic.py 的脚本
参数说明：
1. input_path: modelapi.py 的输入图片路径，同时也是 dealpic.py 的前景图路径
2. output_dir: modelapi.py 的输出目录，生成的图片将作为 dealpic.py 的背景图
3. prompt: modelapi.py 的生成提示词
4. output: dealpic.py 的最终输出图片路径
5. abbreviated: dealpic.py 的调整后背景图保存路径（450x450像素）
"""
import os
import sys
import argparse

# 导入两个脚本的功能
from modelapi import generate_with_multiple_models, MODELS
from dealpic import add_round_corners, add_white_border_with_round_corners
from PIL import Image

def process_pipeline(input_path, output_dir, prompt, final_output, abbreviated_path):
    """
    执行完整的处理流程：
    1. 使用 modelapi.py 生成图片
    2. 使用 dealpic.py 合成图片
    """
    print("=" * 60)
    print("图片处理流水线")
    print("=" * 60)
    print(f"输入图片: {input_path}")
    print(f"输出目录: {output_dir}")
    print(f"提示词: {prompt}")
    print(f"最终输出: {final_output}")
    print(f"缩略图输出: {abbreviated_path}")
    print("=" * 60)
    print()
    
    # 步骤1: 使用 modelapi.py 生成图片
    print("步骤1: 使用 AI 模型生成图片...")
    print("-" * 60)
    results = generate_with_multiple_models(
        image_path=input_path,
        models=MODELS,
        prompt=prompt,
        output_dir=output_dir
    )
    
    # 检查生成结果
    success_results = [r for r in results if r["success"]]
    if not success_results:
        print("错误: 所有模型都生成失败，无法继续处理")
        sys.exit(1)
    
    # 使用第一个成功生成的图片作为背景图
    background_path = success_results[0]["output_path"]
    print(f"\n使用生成的图片作为背景: {background_path}")
    # input_path 作为前景图
    foreground_path = input_path
    print(f"使用原图作为前景: {foreground_path}")
    print()
    
    # 步骤2: 使用 dealpic.py 合成图片
    print("步骤2: 合成前景图和背景图...")
    print("-" * 60)
    
    # 读取背景图（生成的图片）
    bg = Image.open(background_path).convert("RGBA")
    
    # 复制背景图并调整为 450x450 像素后保存
    bg_copy = bg.copy()
    bg_resized = bg_copy.resize((450, 450), Image.LANCZOS)
    bg_resized_rgb = bg_resized.convert("RGB")
    bg_resized_rgb.save(abbreviated_path)
    print(f"背景图已调整为 450x450 并保存为: {abbreviated_path}")
    
    # 读取前景图（原图）
    fg = Image.open(foreground_path).convert("RGBA")
    
    # 前景图缩放后的尺寸
    fg_width = 200
    fg_height = 200
    
    # 前景图圆角半径 & 白边粗细
    corner_radius = 10
    border_size = 10
    
    # 左下角距离
    offset_x = 40   # 距左
    offset_y = 40   # 距下
    
    # 缩放前景图
    fg = fg.resize((fg_width, fg_height), Image.LANCZOS)
    
    # 添加带圆角的白色描边
    fg = add_white_border_with_round_corners(fg, border_size, corner_radius)
    
    # 计算前景图贴图的位置（左下角）
    pos_x = offset_x
    pos_y = bg.height - fg.height - offset_y
    
    # 合成
    result = bg.copy()
    result.paste(fg, (pos_x, pos_y), fg)
    
    # 保存最终结果（如果是JPG格式，需要转换为RGB）
    if final_output.lower().endswith(('.jpg', '.jpeg')):
        result_rgb = result.convert("RGB")
        result_rgb.save(final_output, "JPEG")
    else:
        result.save(final_output)
    print(f"合成完成: {final_output}")
    
    print()
    print("=" * 60)
    print("处理完成！")
    print("=" * 60)
    print(f"最终输出: {final_output}")
    print(f"缩略图: {abbreviated_path}")
    print("=" * 60)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="图片处理流水线：先使用 AI 生成背景图，再将原图合成到背景图上",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
参数说明：
  参数1: 输入图片路径（modelapi.py 的输入，dealpic.py 的前景）
  参数2: 输出目录（modelapi.py 的输出目录，生成的图片作为 dealpic.py 的背景）
  参数3: 生成提示词（modelapi.py 的提示词）
  参数4: 最终输出路径（dealpic.py 的输出）
  参数5: 缩略图输出路径（dealpic.py 的 abbreviated 输出，450x450像素）

示例：
  python pipeline.py input.jpg ./output "吉卜力风格" result.png thumbnail.jpg
        """
    )
    
    parser.add_argument("input_path", help="输入图片路径（modelapi.py 的输入，dealpic.py 的前景）")
    parser.add_argument("output_dir", help="输出目录（modelapi.py 的输出目录，生成的图片作为 dealpic.py 的背景）")
    parser.add_argument("prompt", help="生成提示词（modelapi.py 的提示词）")
    parser.add_argument("output", help="最终输出路径（dealpic.py 的输出）")
    parser.add_argument("abbreviated", help="缩略图输出路径（dealpic.py 的 abbreviated 输出，450x450像素）")
    
    args = parser.parse_args()
    
    # 验证输入文件是否存在
    if not os.path.exists(args.input_path):
        print(f"错误: 输入文件不存在: {args.input_path}")
        sys.exit(1)
    
    # 确保输出目录存在
    os.makedirs(args.output_dir, exist_ok=True)
    
    # 确保最终输出目录存在
    final_output_dir = os.path.dirname(args.output)
    if final_output_dir:
        os.makedirs(final_output_dir, exist_ok=True)
    
    # 确保缩略图输出目录存在
    abbreviated_dir = os.path.dirname(args.abbreviated)
    if abbreviated_dir:
        os.makedirs(abbreviated_dir, exist_ok=True)
    
    # 执行流水线
    process_pipeline(
        input_path=args.input_path,
        output_dir=args.output_dir,
        prompt=args.prompt,
        final_output=args.output,
        abbreviated_path=args.abbreviated
    )

