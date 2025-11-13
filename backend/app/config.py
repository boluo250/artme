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
    SECRET_KEY: str = "your-secret-key-change-in-production"
    
    # 数据库配置
    DATABASE_URL: str = "sqlite:///./artme.db"
    
    # CORS 配置
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
    ]
    
    # 大模型 API 配置
    OPENAI_API_KEY: str = ""
    CLAUDE_API_KEY: str = ""
    
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

