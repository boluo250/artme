"""
图像生成任务数据模型
"""
from sqlalchemy import Column, String, Text, DateTime, Boolean
from sqlalchemy.sql import func
from app.database import Base


class GenerationTask(Base):
    """图像生成任务模型"""
    __tablename__ = "generation_tasks"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, index=True, nullable=True)
    request_type = Column(String, nullable=False)  # text / upload
    prompt = Column(Text, nullable=False)
    style_id = Column(String, nullable=True)
    category = Column(String, nullable=True)
    subcategory = Column(String, nullable=True)
    # 任务状态与结果
    status = Column(String, default="pending", index=True)  # pending/processing/completed/failed
    image_urls = Column(Text, nullable=True)  # JSON 字符串存储图片 URL 数组
    error = Column(Text, nullable=True)
    notify_on_complete = Column(Boolean, default=False)

    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())


