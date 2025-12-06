"""
ArtMe Backend API - 主应用入口
"""
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
from app.api import generate, styles, account, subscription, static, prompts
from app.services.task_service import task_manager

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
    """应用启动时初始化任务队列"""
    await task_manager.start()


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
app.include_router(account.router, prefix="/api/v1", tags=["account"])
app.include_router(subscription.router, prefix="/api/v1", tags=["subscription"])
app.include_router(static.router, prefix="/api/v1", tags=["static"])
app.include_router(prompts.router, prefix="/api/v1", tags=["prompts"])


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )

