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
    # 默认使用 PostgreSQL，方便后续迁移到阿里云 RDS / Supabase
    # 本地直接运行后端时，请确保本机已启动 Postgres 并存在 artme 数据库
    # 例：postgresql://用户名:密码@主机:端口/数据库名
    DATABASE_URL: str = "postgresql://artme:artme123@localhost:5432/artme"
    
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

    # -------------------------
    # RQ / Redis 配置（用于并发后台生图）
    # -------------------------
    REDIS_URL: str = "redis://localhost:6379/0"
    RQ_QUEUE_NAME: str = "artme_generate"
    # 说明：RQ 本身是“单进程单并发”，并发通常通过启动多个 worker 实现；
    # 该配置用于脚本一次性拉起多个 worker 进程。
    RQ_WORKER_CONCURRENCY: int = 1
    # 单个 Job 的默认超时（秒）
    RQ_JOB_TIMEOUT: int = 600

    # 可选：失败重试（由 enqueue 时传入 Retry 覆盖）
    RQ_RETRY_MAX: int = 2
    RQ_RETRY_INTERVAL: int = 10

    # -------------------------
    # Internal APIs (dev/preprod only)
    # -------------------------
    # A simple shared secret for enabling internal-only endpoints in DEBUG builds.
    # Override via env var INTERNAL_API_TOKEN in local/.env when needed.
    INTERNAL_API_TOKEN: str = "dev-internal-token"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
