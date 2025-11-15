from PIL import Image, ImageDraw, ImageOps

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

# ------------------------------
# 参数
# ------------------------------
foreground_path= "/Users/keximing/mycode/iosapp/test/input/meinv1.jpeg"
background_path= "/Users/keximing/mycode/iosapp/test/output/3D_figurine.jpg"

output_path = "output.png"

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

# 读取背景图
bg = Image.open(background_path).convert("RGBA")

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

# 保存
result.save(output_path)

print("合成完成:", output_path)
