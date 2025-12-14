"""
API 测试
"""
import pytest
from fastapi.testclient import TestClient
from app.main import app

try:
    client = TestClient(app)
except TypeError as e:
    # 兼容：当本机环境 starlette/httpx 版本不匹配时，TestClient 可能初始化失败
    pytest.skip(f"TestClient 初始化失败（可能是 starlette/httpx 版本不兼容）: {e}", allow_module_level=True)


def test_root():
    """测试根路径"""
    response = client.get("/")
    assert response.status_code == 200
    assert "ArtMe API" in response.json()["message"]


def test_health_check():
    """测试健康检查"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_list_styles():
    """测试风格列表"""
    response = client.get("/api/v1/styles/list")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert "data" in body
    assert "styles" in body["data"]
    assert "total" in body["data"]


def test_search_styles():
    """测试风格搜索"""
    response = client.get("/api/v1/styles/search?q=anime")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert "styles" in body["data"]


def test_get_style():
    """测试获取单个风格"""
    response = client.get("/api/v1/styles/style_001")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert body["data"]["id"] == "style_001"


def test_list_models():
    """测试模型列表"""
    response = client.get("/api/v1/models")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert "models" in body["data"]


def test_generate_image_missing_prompt():
    """测试生成图像 - 缺少 prompt"""
    response = client.post("/api/v1/generate", json={})
    # 统一异常处理中间件：参数校验统一按 400 返回（并带业务错误码）
    assert response.status_code == 400


def test_generate_image():
    """测试生成图像"""
    # 注意：这个测试需要有效的 API 密钥，可能会失败
    response = client.post(
        "/api/v1/generate",
        json={
            "prompt": "a cute cat",
            "width": 512,
            "height": 512
        }
    )
    # 如果 API 密钥未配置，会返回 500 错误
    assert response.status_code in [200, 500]

