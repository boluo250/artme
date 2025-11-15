import os
import requests
import base64
import argparse
from datetime import datetime
from urllib.parse import urlparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Dict

OPENROUTER_API_KEY = "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"  # 请先设置环境变量或直接替换
ENDPOINT = "https://openrouter.ai/api/v1/chat/completions"

# 定义多个支持图像生成的模型
# 注意：目前主要支持图像生成的是 Google Gemini 系列模型
MODELS = [
    "google/gemini-2.5-flash-image-preview"
]

def encode_image_to_base64(image_path: str) -> str:
    with open(image_path, "rb") as f:
        data = f.read()
    encoded = base64.b64encode(data).decode("utf‑8")
    # 假设为 jpeg，你也可以根据文件类型切换 data:image/png;base64,
    return f"data:image/jpeg;base64,{encoded}"

def save_base64_image(base64_data: str, output_path: str) -> None:
    """
    将 base64 编码的图片数据保存为文件
    """
    # 如果是 data:image/...;base64, 格式，需要去掉前缀
    if base64_data.startswith("data:image"):
        base64_data = base64_data.split(",", 1)[1]
    
    # 解码 base64 数据
    image_data = base64.b64decode(base64_data)
    
    # 保存为文件
    with open(output_path, "wb") as f:
        f.write(image_data)
    print(f"图片已保存到: {output_path}")

def generate_image_with_model(image_path: str, model: str, prompt: str = "吉卜力风格动画场景", output_path: str = None) -> Dict[str, any]:
    """
    使用指定模型生成图片
    返回包含模型名称、图片URL和成功状态的字典
    """
    try:
        image_b64 = encode_image_to_base64(image_path)

        headers = {
            "Authorization": f"Bearer {OPENROUTER_API_KEY}",
            "Content-Type": "application/json",
        }

        # 构造 messages，先文本提示，再图片输入
        messages = [
            {
                "role": "user",
                "content": [
                    { "type": "text", "text": prompt },
                    { "type": "image_url", "image_url": { "url": image_b64 } }
                ]
            }
        ]

        payload = {
            "model": model,
            "messages": messages,
            "modalities": ["image", "text"],
            # 你也可以加入 image_config 例如 aspect_ratio、输出数量等
            "image_config": {
                "aspect_ratio": "1:1"
            }
        }

        resp = requests.post(ENDPOINT, headers=headers, json=payload, timeout=120)
        resp.raise_for_status()
        result = resp.json()

        # 从响应里提取图片 URL 或 base64 数据
        choices = result.get("choices", [])
        if not choices:
            raise RuntimeError("No choices returned: {}".format(result))
        message = choices[0].get("message", {})
        images = message.get("images", [])
        if not images:
            raise RuntimeError("No images returned: {}".format(result))
        # 假设只取第一张
        image_url = images[0]["image_url"]["url"]
        
        # 如果指定了输出路径，保存图片
        if output_path:
            save_base64_image(image_url, output_path)
        
        return {
            "model": model,
            "success": True,
            "image_url": image_url,
            "output_path": output_path
        }
    except Exception as e:
        return {
            "model": model,
            "success": False,
            "error": str(e),
            "output_path": output_path
        }

def generate_with_multiple_models(image_path: str, models: List[str], prompt: str = "吉卜力风格动画场景", output_dir: str = None) -> List[Dict[str, any]]:
    """
    使用多个模型并发生成图片
    返回所有模型的结果列表
    """
    if output_dir is None:
        output_dir = os.path.dirname(image_path) if image_path else "."
    
    # 确保输出目录存在
    os.makedirs(output_dir, exist_ok=True)
    
    # 为每个模型生成输出路径，使用原始文件名
    original_filename = os.path.basename(image_path)
    original_name, original_ext = os.path.splitext(original_filename)
    model_tasks = []
    for i, model in enumerate(models):
        # 如果只有一个模型，使用原始文件名；如果有多个模型，添加模型标识
        if len(models) == 1:
            output_path = os.path.join(output_dir, original_filename)
        else:
            # 清理模型名称作为文件名
            safe_model_name = model.replace("/", "_").replace(":", "_")
            output_path = os.path.join(output_dir, f"{original_name}_{safe_model_name}{original_ext}")
        model_tasks.append((model, output_path))
    
    results = []
    
    # 使用线程池并发执行请求
    print(f"开始使用 {len(models)} 个模型生成图片...")
    with ThreadPoolExecutor(max_workers=len(models)) as executor:
        # 提交所有任务
        future_to_model = {
            executor.submit(generate_image_with_model, image_path, model, prompt, output_path): (model, output_path)
            for model, output_path in model_tasks
        }
        
        # 收集结果
        for future in as_completed(future_to_model):
            model, output_path = future_to_model[future]
            try:
                result = future.result()
                results.append(result)
                if result["success"]:
                    print(f"✓ {model} 生成成功: {result['output_path']}")
                else:
                    print(f"✗ {model} 生成失败: {result.get('error', '未知错误')}")
            except Exception as e:
                print(f"✗ {model} 执行异常: {str(e)}")
                results.append({
                    "model": model,
                    "success": False,
                    "error": str(e),
                    "output_path": output_path
                })
    
    return results

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="使用多个模型生成图片")
    parser.add_argument("input_path", help="输入图片路径")
    parser.add_argument("-o", "--output-dir", default=None, help="输出目录（默认：输入图片所在目录）")
    parser.add_argument("-p", "--prompt", default="吉卜力风格动画场景", help="生成提示词（默认：吉卜力风格动画场景）")
    
    args = parser.parse_args()
    
    input_path = args.input_path
    output_dir = args.output_dir if args.output_dir else os.path.dirname(input_path) if input_path else "."
    prompt = args.prompt
    
    print("=" * 60)
    print("多模型图片生成")
    print("=" * 60)
    print(f"输入图片: {input_path}")
    print(f"提示词: {prompt}")
    print(f"使用模型数量: {len(MODELS)}")
    print(f"输出目录: {output_dir}")
    print("=" * 60)
    print()
    
    # 使用多个模型并发生成图片
    results = generate_with_multiple_models(
        image_path=input_path,
        models=MODELS,
        prompt=prompt,
        output_dir=output_dir
    )
    
    # 统计结果
    print()
    print("=" * 60)
    print("生成结果统计")
    print("=" * 60)
    success_count = sum(1 for r in results if r["success"])
    fail_count = len(results) - success_count
    
    print(f"成功: {success_count}/{len(results)}")
    print(f"失败: {fail_count}/{len(results)}")
    print()
    
    if success_count > 0:
        print("成功生成的图片:")
        for result in results:
            if result["success"]:
                print(f"  - {result['model']}: {result['output_path']}")
    
    if fail_count > 0:
        print("\n失败的模型:")
        for result in results:
            if not result["success"]:
                print(f"  - {result['model']}: {result.get('error', '未知错误')}")
    
    print("=" * 60)
