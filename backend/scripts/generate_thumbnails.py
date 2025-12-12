"""
批量生成缩略图的小工具。

使用场景：
- 给 backend/data 里的示例图片/风格图批量生成“小一号”的缩略图文件，
  用于首页 / 列表等场景，减小前端加载压力。

特点：
- 递归遍历指定目录（默认：项目根下的 artme/backend/data）
- 只处理静态图片：.jpg/.jpeg/.png
- **仅处理文件名以 "_abbreviated" 结尾的图片**，
  例如：`Natural_Retouching_abbreviated.png`
- 为每张满足条件的图片生成一份缩略图（默认长边 320px，JPEG 质量 80）
- 缩略图文件命名规则：
  - 将 `_abbreviated` 替换为 `_thumb_{w}x{h}`，并统一保存为 `.jpg`
  - 例如：`Natural_Retouching_abbreviated.png`
    -> `Natural_Retouching_thumb_320x320.jpg`
- 已存在同名缩略图且比原图新时，会跳过（简单缓存机制）

运行示例（在项目根目录）：
    python artme/backend/scripts/generate_thumbnails.py

自定义参数：
    python artme/backend/scripts/generate_thumbnails.py \
        --root ./artme/backend/data \
        --max-width 320 \
        --max-height 320 \
        --quality 80
"""

import argparse
import logging
from pathlib import Path
from typing import Iterable

from PIL import Image


logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")


SUPPORTED_EXTS = {".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG"}
ABBREVIATED_SUFFIX = "_abbreviated"


def iter_images(root: Path) -> Iterable[Path]:
    """
    递归遍历 root 下的所有静态图片文件，
    仅返回文件名以 "_abbreviated" 结尾的图片。
    """
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix in SUPPORTED_EXTS and path.stem.endswith(ABBREVIATED_SUFFIX):
            yield path


def build_thumb_path(image_path: Path, max_width: int, max_height: int) -> Path:
    """
    根据原图路径和尺寸生成缩略图路径。
    
    规则：
    - 原始文件名需以 "_abbreviated" 结尾
    - 将 "_abbreviated" 去掉，替换为 "_thumb_{w}x{h}.jpg"
    例如：
        Natural_Retouching_abbreviated.png
        -> Natural_Retouching_thumb_320x320.jpg
    """
    stem = image_path.stem
    if stem.endswith(ABBREVIATED_SUFFIX):
        base = stem[: -len(ABBREVIATED_SUFFIX)]
    else:
        # 理论上 iter_images 已经过滤，这里只是兜底
        base = stem
    parent = image_path.parent
    thumb_name = f"{base}_thumb_{max_width}x{max_height}.jpg"
    return parent / thumb_name


def create_thumbnail(
    image_path: Path,
    max_width: int,
    max_height: int,
    quality: int,
) -> None:
    """为单张图片创建缩略图。"""
    thumb_path = build_thumb_path(image_path, max_width, max_height)

    # 如果缩略图已存在且比原图新，则直接跳过
    if thumb_path.exists():
        try:
            if thumb_path.stat().st_mtime >= image_path.stat().st_mtime:
                logger.info("跳过（已存在且为最新）：%s", thumb_path)
                return
        except OSError:
            # 读取 stat 失败时，继续重新生成
            pass

    try:
        with Image.open(image_path) as img:
            # 统一转换为 RGB，便于保存为 JPEG
            if img.mode not in ("RGB", "L"):
                img = img.convert("RGB")

            # 使用 thumbnail 保持宽高比，长边不超过给定尺寸
            img.thumbnail((max_width, max_height), Image.Resampling.LANCZOS)

            thumb_path.parent.mkdir(parents=True, exist_ok=True)
            img.save(thumb_path, "JPEG", quality=quality, optimize=True)

        logger.info("生成缩略图：%s -> %s", image_path.name, thumb_path.name)
    except Exception as exc:  # noqa: BLE001
        logger.error("生成缩略图失败：%s，错误：%s", image_path, exc)


def main() -> None:
    parser = argparse.ArgumentParser(description="批量为图片生成缩略图")
    parser.add_argument(
        "--root",
        type=str,
        default=None,
        help="要遍历的根目录，默认使用项目中的 artme/backend/data",
    )
    parser.add_argument(
        "--max-width",
        type=int,
        default=320,
        help="缩略图最大宽度（像素），默认 320",
    )
    parser.add_argument(
        "--max-height",
        type=int,
        default=320,
        help="缩略图最大高度（像素），默认 320",
    )
    parser.add_argument(
        "--quality",
        type=int,
        default=100,
        help="JPEG 质量（1-100），默认 80",
    )

    args = parser.parse_args()

    if args.root:
        root = Path(args.root).expanduser().resolve()
    else:
        # 默认：当前脚本所在目录的上上级下的 data 目录
        # 即：artme/backend/scripts/generate_thumbnails.py
        # -> artme/backend/data
        root = Path(__file__).parent.parent / "data"

    if not root.exists():
        raise SystemExit(f"根目录不存在：{root}")

    logger.info("开始生成缩略图，根目录：%s", root)
    logger.info("目标尺寸：%dx%d, JPEG 质量：%d", args.max_width, args.max_height, args.quality)

    count = 0
    for img_path in iter_images(root):
        create_thumbnail(
            image_path=img_path,
            max_width=args.max_width,
            max_height=args.max_height,
            quality=args.quality,
        )
        count += 1

    logger.info("处理完成，共扫描图片文件：%d", count)


if __name__ == "__main__":
    main()


