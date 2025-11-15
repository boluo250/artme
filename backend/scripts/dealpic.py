from PIL import Image, ImageDraw, ImageOps
import os
import argparse

def add_round_corners(image, radius):
    """给图片加圆角"""
    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, image.size[0], image.size[1]], radius, fill=255)
    image.putalpha(mask)
    return image

def add_white_border_with_round_corners(image, border_size, corner_radius):
    """添加带圆角的白色描边"""
    # 先给图片本身加圆角
    rounded_image = add_round_corners(image, corner_radius)
    
    # 计算带白边的总尺寸
    total_width = image.width + border_size * 2
    total_height = image.height + border_size * 2
    
    # 创建白色背景层（带圆角）
    white_bg = Image.new("RGBA", (total_width, total_height), (255, 255, 255, 255))
    white_bg = add_round_corners(white_bg, corner_radius + border_size)
    
    # 将圆角图片放在白色背景中央
    paste_x = border_size
    paste_y = border_size
    white_bg.paste(rounded_image, (paste_x, paste_y), rounded_image)
    
    return white_bg

if __name__ == "__main__":
    # ------------------------------
    # 参数解析
    # ------------------------------
    parser = argparse.ArgumentParser(description="图片合成脚本：将前景图合成到背景图上")
    parser.add_argument("--foreground", "-f", required=True, help="前景图片路径")
    parser.add_argument("--background", "-b", required=True, help="背景图片路径")
    parser.add_argument("--output", "-o", required=True, help="输出图片路径")
    parser.add_argument("--abbreviated", "-a", required=True, help="调整后的背景图保存路径（450x450像素）")
    
    args = parser.parse_args()
    
    foreground_path = args.foreground
    background_path = args.background
    output_path = args.output
    abbreviated_path = args.abbreviated
    
    # 前景图缩放后的尺寸
    fg_width = 200
    fg_height = 200
    
    # 前景图圆角半径 & 白边粗细
    corner_radius = 10
    border_size = 10
    
    # 左下角距离
    offset_x = 40   # 距左
    offset_y = 40   # 距下
    
    # ------------------------------
    # 开始处理
    # ------------------------------
    
    # 读取背景图（原功能使用原始背景图）
    bg = Image.open(background_path).convert("RGBA")
    
    # 新功能：复制背景图并调整为 450x450 像素后保存
    bg_copy = bg.copy()
    bg_resized = bg_copy.resize((450, 450), Image.LANCZOS)
    
    # 保存调整后的背景图
    bg_resized_rgb = bg_resized.convert("RGB")  # 转换为RGB以保存为JPG
    bg_resized_rgb.save(abbreviated_path)
    print("背景图已调整为 450x450 并保存为:", abbreviated_path)
    
    # 读取前景图并统一处理
    fg = Image.open(foreground_path).convert("RGBA")
    
    # 缩放前景图
    fg = fg.resize((fg_width, fg_height), Image.LANCZOS)
    
    # 添加带圆角的白色描边（图片本身和白边都有圆角）
    fg = add_white_border_with_round_corners(fg, border_size, corner_radius)
    
    # 计算前景图贴图的位置（左下角）
    pos_x = offset_x
    pos_y = bg.height - fg.height - offset_y
    
    # 合成
    result = bg.copy()
    result.paste(fg, (pos_x, pos_y), fg)
    
    # 保存为JPG格式（需要转换为RGB，因为JPG不支持alpha通道）
    result_rgb = result.convert("RGB")
    result_rgb.save(output_path, "JPEG")
    
    print("合成完成:", output_path)
