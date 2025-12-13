"""
ArtMe Backend API - 主应用入口
"""
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from app.config import settings
from app.middleware import (
    logging_middleware,
    validation_exception_handler,
    http_exception_handler,
    general_exception_handler
)

# 导入 API 路由
from app.api import generate, styles, account, subscription, static, prompts, auth, user_info

# -------------------------
# 日志配置
# -------------------------
# 根据配置中的 DEBUG 开关选择日志级别：
# - DEBUG=True  -> 日志级别 DEBUG（输出调试信息）
# - DEBUG=False -> 日志级别 INFO（只输出关键运行信息）
logging.basicConfig(
    level=logging.DEBUG if settings.DEBUG else logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)
logger.info("Logging initialized. DEBUG=%s", settings.DEBUG)

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="卡通头像生成应用的后端 API"
)

# 配置 CORS
# 开发环境：允许所有来源（方便真机测试）
# 生产环境：应该限制为特定域名
cors_origins = ["*"] if settings.DEBUG else settings.CORS_ORIGINS
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 添加日志中间件
app.middleware("http")(logging_middleware)

# 注册异常处理器
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(StarletteHTTPException, http_exception_handler)
app.add_exception_handler(Exception, general_exception_handler)


@app.on_event("startup")
async def startup_event():
    """
    应用启动事件
    说明：生图任务已迁移到 RQ/Redis，由独立 worker 进程消费队列。
    """
    return


@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "ArtMe API",
        "version": settings.APP_VERSION
    }


@app.get("/health")
async def health_check():
    """健康检查"""
    return {"status": "healthy"}


# 注册 API 路由
app.include_router(generate.router, prefix="/api/v1", tags=["generate"])
app.include_router(styles.router, prefix="/api/v1", tags=["styles"])
# 账户相关接口统一挂载到 /api/v1/account 前缀下，
# 以符合 API 文档与 iOS 客户端中的 Constants.API.account 定义
app.include_router(account.router, prefix="/api/v1/account", tags=["account"])
app.include_router(subscription.router, prefix="/api/v1", tags=["subscription"])
app.include_router(static.router, prefix="/api/v1", tags=["static"])
app.include_router(prompts.router, prefix="/api/v1", tags=["prompts"])
app.include_router(auth.router, prefix="/api/v1")
app.include_router(user_info.router, prefix="/api/v1")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )

