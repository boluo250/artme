"""
用户相关的 Pydantic 模型
"""
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
from app.models.user import SubscriptionType


class UserCreate(BaseModel):
    """用户注册模型"""
    username: str
    email: EmailStr
    password: str


class UserLogin(BaseModel):
    """用户登录模型"""
    username: str
    password: str


class UserResponse(BaseModel):
    """用户响应模型"""
    id: str
    username: str
    email: str
    balance: float
    subscription_type: str
    subscription_expires_at: Optional[datetime] = None
    is_active: bool
    
    class Config:
        from_attributes = True


class TransactionResponse(BaseModel):
    """交易记录响应模型"""
    id: str
    transaction_type: str
    amount: float
    description: Optional[str] = None
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True


class SubscriptionResponse(BaseModel):
    """订阅响应模型"""
    id: str
    subscription_type: str
    price: float
    started_at: datetime
    expires_at: datetime
    auto_renew: bool
    is_active: bool
    
    class Config:
        from_attributes = True


class RechargeRequest(BaseModel):
    """充值请求模型"""
    amount: float
    payment_method: str  # "apple", "alipay", "wechat", etc.


class SubscriptionRequest(BaseModel):
    """订阅请求模型"""
    subscription_type: SubscriptionType
    payment_method: str

