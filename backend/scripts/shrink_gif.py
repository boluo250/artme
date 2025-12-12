"""
批量压缩 / 缩小 GIF 动图的小工具。

使用场景：
- backend/data 里有一些用于展示效果的 GIF（例如 *_abbreviated.gif），
  体积往往在几 MB，既影响首页加载速度，也增加 CPU/GPU 压力。
- 该脚本可以批量为 GIF 生成「瘦身版」副本，减少分辨率、帧率和颜色数，
  在肉眼观感尽量保持的前提下，大幅降低文件大小。

注意：
- 默认不会覆盖原始 GIF，而是在同目录生成一个 *_small.gif 文件。
- 建议先在少量文件/小目录上测试效果，再在整体 data 目录跑一遍。

运行示例（在项目根目录）：
    python artme/backend/scripts/shrink_gif.py

自定义参数示例：
    python artme/backend/scripts/shrink_gif.py \
        --root ./artme/backend/data \
        --max-width 400 \
        --max-height 400 \
        --target-fps 12 \
        --colors 128
"""

import argparse
import logging
from pathlib import Path
from typing import Iterable, List

from PIL import Image, ImageSequence


logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")


def iter_gifs(root: Path) -> Iterable[Path]:
    """递归遍历 root 下的所有 GIF 文件。"""
    for path in root.rglob("*.gif"):
        if path.is_file():
            yield path


def build_small_gif_path(gif_path: Path) -> Path:
    """为原始 GIF 构造一个 *_small.gif 输出路径。"""
    return gif_path.with_name(f"{gif_path.stem}_small.gif")


def downsample_frames(
    frame_count: int,
    original_duration: int,
    target_fps: int,
) -> tuple[List[int], List[int]]:
    """
    根据目标 FPS 下采样帧索引，并返回 (indices, durations)：
    - indices: 需要保留的帧索引
    - durations: 对应每帧的持续时间（毫秒）

    简化策略：
    - 假定原始每帧 duration 大致一致，按 target_fps 计算需要的帧数；
    - 通过步长选择子集帧，保证动作大致连续；
    - 每帧 duration 设置为 1000 / target_fps ms。
    """
    if frame_count <= 0 or target_fps <= 0:
        return [], []

    target_frame_count = max(1, int(original_duration / 1000 * target_fps))
    target_frame_count = min(target_frame_count, frame_count)

    if target_frame_count <= 1:
        return [0], [int(1000 / max(target_fps, 1))]

    # 计算步长，在 [0, frame_count-1] 之间等间隔取样
    step = frame_count / target_frame_count
    indices = [min(frame_count - 1, int(i * step)) for i in range(target_frame_count)]

    # 每帧持续时间（毫秒）
    per_frame_duration = int(1000 / target_fps)
    durations = [per_frame_duration] * len(indices)
    return indices, durations


def shrink_gif(
    gif_path: Path,
    max_width: int,
    max_height: int,
    target_fps: int,
    colors: int,
    overwrite: bool = False,
) -> None:
    """
    对单个 GIF 进行压缩 / 缩小处理。

    为避免出现你看到的「信号异常」/ 花屏问题，这里采用更保守策略：
    - 保留原始的调色板/模式，不强行为每帧重新量化不同调色板；
    - 只做：帧下采样 + 分辨率缩放；
    - 关闭 GIF 的 optimize（某些多调色板动图配合 optimize 容易出错）。
    """
    out_path = gif_path if overwrite else build_small_gif_path(gif_path)

    try:
        with Image.open(gif_path) as img:
            # 获取原始总时长（简单估计：帧数 * 单帧 duration）
            try:
                frame_count = getattr(img, "n_frames", 1)
            except Exception:  # noqa: BLE001
                frame_count = 1

            try:
                original_duration = img.info.get("duration", 100) * frame_count
            except Exception:  # noqa: BLE001
                original_duration = 100 * frame_count

            # 下采样帧索引 & 新的 duration 列表
            indices, durations = downsample_frames(
                frame_count=frame_count,
                original_duration=original_duration,
                target_fps=target_fps,
            )
            if not indices:
                logger.warning("GIF 帧数为 0，跳过：%s", gif_path)
                return

            frames = []
            for idx in indices:
                # 使用 copy() 保持原始帧的模式/调色板信息，避免花屏
                img.seek(idx)
                frame = img.copy()

                # 按比例缩放（保持宽高比）
                w, h = frame.size
                scale = min(max_width / w, max_height / h, 1.0)
                if scale < 1.0:
                    new_size = (int(w * scale), int(h * scale))
                    # resize 时使用高质量插值，但保持原有模式（P / RGBA 等）
                    frame = frame.resize(new_size, Image.Resampling.LANCZOS)

                frames.append(frame)

            if not frames:
                logger.warning("未生成任何帧，跳过：%s", gif_path)
                return

            # 保存新的 GIF（使用第 1 帧 + 其余追加）
            # 关闭 optimize，以避免某些复杂调色板 GIF 被错误合并导致花屏
            frames[0].save(
                out_path,
                save_all=True,
                append_images=frames[1:],
                loop=0,
                duration=durations,
                optimize=False,
                disposal=2,
            )

        old_size = gif_path.stat().st_size
        new_size = out_path.stat().st_size
        ratio = new_size / old_size if old_size > 0 else 0
        logger.info(
            "压缩 GIF：%s -> %s (%.1f KB -> %.1f KB, %.0f%%)",
            gif_path.name,
            out_path.name,
            old_size / 1024,
            new_size / 1024,
            ratio * 100 if ratio else 0,
        )
    except Exception as exc:  # noqa: BLE001
        logger.error("压缩 GIF 失败：%s，错误：%s", gif_path, exc)


def main() -> None:
    parser = argparse.ArgumentParser(description="批量压缩 / 缩小 GIF 动图")
    parser.add_argument(
        "--root",
        type=str,
        default=None,
        help="要遍历的根目录，默认使用项目中的 artme/backend/data",
    )
    parser.add_argument(
        "--max-width",
        type=int,
        default=400,
        help="压缩后 GIF 的最大宽度（像素），默认 400",
    )
    parser.add_argument(
        "--max-height",
        type=int,
        default=400,
        help="压缩后 GIF 的最大高度（像素），默认 400",
    )
    parser.add_argument(
        "--target-fps",
        type=int,
        default=12,
        help="目标帧率（FPS），默认 12",
    )
    parser.add_argument(
        "--colors",
        type=int,
        default=128,
        help="目标颜色数（1-256），默认 128",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="是否直接覆盖原始 GIF（默认否，生成 *_small.gif）",
    )

    args = parser.parse_args()

    if args.root:
        root = Path(args.root).expanduser().resolve()
    else:
        # 默认：当前脚本所在目录的上上级下的 data 目录
        # 即：artme/backend/scripts/shrink_gif.py
        # -> artme/backend/data
        root = Path(__file__).parent.parent / "data/hot"

    if not root.exists():
        raise SystemExit(f"根目录不存在：{root}")

    logger.info("开始压缩 GIF，根目录：%s", root)
    logger.info(
        "目标尺寸：%dx%d, 目标 FPS：%d, 颜色数：%d, 覆盖原图：%s",
        args.max_width,
        args.max_height,
        args.target_fps,
        args.colors,
        args.overwrite,
    )

    count = 0
    for gif_path in iter_gifs(root):
        shrink_gif(
            gif_path=gif_path,
            max_width=args.max_width,
            max_height=args.max_height,
            target_fps=args.target_fps,
            colors=args.colors,
            overwrite=args.overwrite,
        )
        count += 1

    logger.info("处理完成，共扫描 GIF 文件：%d", count)


if __name__ == "__main__":
    main()


