import cv2
import numpy as np
from moviepy.video.io.ffmpeg_tools import ffmpeg_extract_subclip
from moviepy.video.io.ImageSequenceClip import ImageSequenceClip
from PIL import Image

# 读取图片
image1 = cv2.imread('/Users/keximing/mycode/iosapp/artme/backend/data/hot/Decomposition_Clothes_abbreviated.png')  # 第一张图片
image2 = cv2.imread('/Users/keximing/mycode/iosapp/test/input/亚洲女生17.png')  # 第二张图片

# 调整图片尺寸为 300x400
target_width = 300
target_height = 400
image1 = cv2.resize(image1, (target_width, target_height))
image2 = cv2.resize(image2, (target_width, target_height))

height, width, _ = image1.shape

# 创建遮罩（矩形）
def create_mask(position, width, height):
    mask = np.zeros((height, width), dtype=np.uint8)
    mask[:, :position] = 255  # 让遮罩在指定位置逐渐扩展
    return mask

# 生成拉链动画
def create_zip_animation(image1, image2, output_video_path, output_gif_path):
    frames = []
    fps = 30
    duration = 1.5  # 动画时长（秒）
    total_frames = int(fps * duration)
    
    # 生成每一帧图像
    for i in range(total_frames):
        # 计算当前遮罩的位置 - 确保能覆盖 0 到 width
        if total_frames > 1:
            position = int((i / (total_frames - 1)) * width)
        else:
            position = width

        # 创建遮罩
        mask = create_mask(position, width, height)
        
        # 平滑处理：对遮罩进行高斯模糊，产生羽化效果
        blur_radius = int(width * 0.05) # 模糊半径设为宽度的 5%
        if blur_radius % 2 == 0: blur_radius += 1 # 必须是奇数
        if blur_radius < 1: blur_radius = 1
        mask_blurred = cv2.GaussianBlur(mask, (blur_radius, blur_radius), 0)
        
        # 使用 Alpha 混合 (Alpha Blending) 代替硬切割
        alpha = mask_blurred.astype(float) / 255.0
        alpha = np.expand_dims(alpha, axis=2) # (H, W, 1)
        
        # 混合公式: image1 * alpha + image2 * (1 - alpha)
        combined = image1.astype(float) * alpha + image2.astype(float) * (1.0 - alpha)
        combined_frame = combined.astype(np.uint8)

        # 添加白色线条
        line_width = int(width * 0.015) # 线条宽度变细
        if line_width < 1: line_width = 1
        
        # 直接在 combined_frame 上绘制白色实线
        # 注意：如果 position = width，线会画在外面，这正是我们想要的（拉链拉出画面）
        cv2.line(combined_frame, (position, 0), (position, height), (255, 255, 255), line_width)

        # 修复颜色问题：OpenCV使用BGR，而MoviePy需要RGB
        combined_frame = cv2.cvtColor(combined_frame, cv2.COLOR_BGR2RGB)

        # 将每一帧添加到视频帧列表
        frames.append(combined_frame)
    
    # 准备纯净的静止帧 (无白线)
    # 注意：OpenCV 读取的是 BGR，需要转 RGB
    img1_rgb = cv2.cvtColor(image1, cv2.COLOR_BGR2RGB)
    img2_rgb = cv2.cvtColor(image2, cv2.COLOR_BGR2RGB)
    
    # 1. 向右移动 (已在 frames 中)
    
    # 1.5 向右打开后停顿 1s (使用纯净的 image1)
    pause_duration_right = 1
    pause_frames_right = [img1_rgb] * (fps * pause_duration_right)

    # 2. 向左移动回来 (反转 frames 列表)
    # 使用切片 [::-1] 反转列表，产生从右向左的动画
    frames_backward = frames[::-1]
    
    # 3. 到头后停顿 1s (使用纯净的 image2)
    pause_duration_left = 1
    pause_frames_left = [img2_rgb] * (fps * pause_duration_left)
    
    # 合并所有帧：向右 -> 右停顿 -> 向左 -> 左停顿
    final_frames = frames + pause_frames_right + frames_backward + pause_frames_left

    # 使用moviepy将图像序列转换为视频
    clip = ImageSequenceClip(final_frames, fps=fps)  # 生成视频剪辑
    clip.write_videofile(output_video_path, fps=fps)  # 输出视频
    
    # 将视频转换为GIF
    clip.write_gif(output_gif_path, fps=fps)

# 执行函数
output_video_path = "zip_animation.mp4"
output_gif_path = "zip_animation.gif"
create_zip_animation(image1, image2, output_video_path, output_gif_path)
