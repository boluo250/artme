"""
用户账户数据模型
"""
from sqlalchemy import Column, String, Float, Boolean, DateTime, Integer, Enum, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from app.database import Base


class SubscriptionType(str, enum.Enum):
    """订阅类型"""
    NONE = "none"
    WEEKLY = "weekly"
    MONTHLY = "monthly"


class User(Base):
    """用户模型"""
    __tablename__ = "users"
    
    id = Column(String, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    balance = Column(Float, default=0.0, nullable=False)
    subscription_type = Column(Enum(SubscriptionType), default=SubscriptionType.NONE)
    subscription_expires_at = Column(DateTime, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    # 关系
    transactions = relationship("Transaction", back_populates="user")
    subscriptions = relationship("Subscription", back_populates="user")


class Transaction(Base):
    """交易记录模型"""
    __tablename__ = "transactions"
    
    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"), index=True, nullable=False)
    transaction_type = Column(String, nullable=False)  # "recharge", "consume", "refund"
    amount = Column(Float, nullable=False)
    description = Column(String, nullable=True)
    payment_id = Column(String, nullable=True)  # 支付网关返回的ID
    status = Column(String, default="pending")  # "pending", "completed", "failed"
    created_at = Column(DateTime, server_default=func.now())
    
    # 关系
    user = relationship("User", back_populates="transactions")


class Subscription(Base):
    """订阅记录模型"""
    __tablename__ = "subscriptions"
    
    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id"), index=True, nullable=False)
    subscription_type = Column(Enum(SubscriptionType), nullable=False)
    price = Column(Float, nullable=False)
    started_at = Column(DateTime, server_default=func.now())
    expires_at = Column(DateTime, nullable=False)
    auto_renew = Column(Boolean, default=True)
    is_active = Column(Boolean, default=True)
    payment_id = Column(String, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    
    # 关系
    user = relationship("User", back_populates="subscriptions")

