"""
应用配置管理
"""
from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    """应用配置"""
    
    # 应用基本信息
    APP_NAME: str = "ArtMe API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    SECRET_KEY: str = "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"
    
    # 数据库配置
    DATABASE_URL: str = "sqlite:///./artme.db"
    
    # CORS 配置
    # 开发环境：允许所有来源（包括真机访问）
    # 生产环境：应该限制为特定域名
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        "http://192.168.31.147:8000",
        "http://192.168.31.128:8000",  # 当前 Mac IP
    ]
    
    # 大模型 API 配置
    OPENAI_API_KEY: str = ""
    CLAUDE_API_KEY: str = ""
    
    # OpenRouter API 配置（用于图像生成）
    OPENROUTER_API_KEY: str = "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"
    OPENROUTER_ENDPOINT: str = "https://openrouter.ai/api/v1/chat/completions"
    OPENROUTER_MODEL: str = "google/gemini-2.5-flash-image-preview"
    
    # 文件存储配置
    UPLOAD_DIR: str = "./uploads"
    STYLE_IMAGES_DIR: str = "./style_images"
    MAX_UPLOAD_SIZE: int = 10485760  # 10MB
    
    # 服务器配置
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()

