"""
账户管理 API
"""
from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel
from typing import List
import uuid
from datetime import datetime, timedelta
from app.schemas.user import (
    UserCreate, UserLogin, UserResponse, TransactionResponse,
    RechargeRequest, SubscriptionRequest, SubscriptionResponse
)
from app.models.user import User, Transaction, Subscription, SubscriptionType
from app.database import get_db
from sqlalchemy.orm import Session
from passlib.context import CryptContext
import jwt
from app.config import settings
from app.services.billing_service import billing_service
from app.utils.api_response import api_ok, api_error
from app.utils.error_codes import AvatarErrorCode

router = APIRouter()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# 计费配置
# 每次生成图像的费用（单位：积分）
GENERATE_IMAGE_COST = 5.0
WEEKLY_SUBSCRIPTION_PRICE = 9.9
MONTHLY_SUBSCRIPTION_PRICE = 29.9


def get_password_hash(password: str) -> str:
    """加密密码"""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """验证密码"""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(user_id: str) -> str:
    """创建访问令牌"""
    payload = {"user_id": user_id}
    return jwt.encode(payload, settings.SECRET_KEY, algorithm="HS256")


@router.post("/register")
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """用户注册"""
    # 检查用户名和邮箱是否已存在
    existing_user = db.query(User).filter(
        (User.username == user_data.username) | (User.email == user_data.email)
    ).first()
    
    if existing_user:
        return api_error(status_code=status.HTTP_400_BAD_REQUEST, code=AvatarErrorCode.INVALID_ARGUMENT, message="用户名或邮箱已存在")
    
    # 创建新用户
    user = User(
        id=str(uuid.uuid4()),
        username=user_data.username,
        email=user_data.email,
        hashed_password=get_password_hash(user_data.password),
        balance=0.0
    )
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return api_ok(data={"message": "注册成功", "user_id": user.id})


@router.post("/login")
async def login(login_data: UserLogin, db: Session = Depends(get_db)):
    """用户登录"""
    user = db.query(User).filter(User.username == login_data.username).first()
    
    if not user or not verify_password(login_data.password, user.hashed_password):
        return api_error(status_code=status.HTTP_401_UNAUTHORIZED, code=AvatarErrorCode.UNAUTHORIZED, message="用户名或密码错误")
    
    if not user.is_active:
        return api_error(status_code=status.HTTP_403_FORBIDDEN, code=AvatarErrorCode.FORBIDDEN, message="账户已被禁用")
    
    token = create_access_token(user.id)
    
    return api_ok(
        data={
            "access_token": token,
            "token_type": "bearer",
            "user": UserResponse.from_orm(user).model_dump(),
        }
    )


@router.get("/balance")
async def get_balance(user_id: str, db: Session = Depends(get_db)):
    """查询账户余额"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        return api_error(status_code=status.HTTP_404_NOT_FOUND, code=AvatarErrorCode.NOT_FOUND, message="用户不存在")
    
    return api_ok(data={"balance": user.balance})


@router.post("/recharge")
async def recharge(
    user_id: str,
    request: RechargeRequest,
    db: Session = Depends(get_db)
):
    """账户充值"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        return api_error(status_code=status.HTTP_404_NOT_FOUND, code=AvatarErrorCode.NOT_FOUND, message="用户不存在")
    
    # 创建支付订单
    from app.services.payment_service import payment_service
    payment = await payment_service.create_payment(
        amount=request.amount,
        payment_method=request.payment_method,
        user_id=user_id,
        description="账户充值"
    )
    
    # 创建交易记录
    transaction = Transaction(
        id=str(uuid.uuid4()),
        user_id=user_id,
        transaction_type="recharge",
        amount=request.amount,
        description="账户充值",
        payment_id=payment["payment_id"],
        status="pending"
    )
    
    db.add(transaction)
    db.commit()
    
    return api_ok(
        data={
            "message": "充值订单已创建",
            "payment_id": payment["payment_id"],
            "amount": request.amount,
        }
    )


@router.post("/recharge/callback")
async def recharge_callback(
    payment_id: str,
    status: str,
    db: Session = Depends(get_db)
):
    """充值回调（支付网关回调）"""
    transaction = db.query(Transaction).filter(
        Transaction.payment_id == payment_id
    ).first()
    
    if not transaction:
        return api_error(status_code=status.HTTP_404_NOT_FOUND, code=AvatarErrorCode.NOT_FOUND, message="交易记录不存在")
    
    if transaction.status != "pending":
        return api_ok(data={"message": "交易已处理"})
    
    if status == "completed":
        # 更新用户余额
        user = db.query(User).filter(User.id == transaction.user_id).first()
        user.balance += transaction.amount
        
        # 更新交易状态
        transaction.status = "completed"
        
        db.commit()
        
        return api_ok(data={"message": "充值成功", "new_balance": user.balance})
    else:
        transaction.status = "failed"
        db.commit()
        return api_ok(data={"message": "充值失败"})


@router.post("/consume")
async def consume_balance(
    user_id: str,
    amount: float,
    description: str,
    db: Session = Depends(get_db)
):
    """扣除余额（用于图像生成等消费）"""
    if amount <= 0:
        return api_error(status_code=status.HTTP_400_BAD_REQUEST, code=AvatarErrorCode.INVALID_ARGUMENT, message="amount 必须为正数")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return api_error(status_code=status.HTTP_404_NOT_FOUND, code=AvatarErrorCode.NOT_FOUND, message="用户不存在")

    # 统一口径：用 available_balance（考虑 pending 预扣）做校验
    available = billing_service.get_available_balance(db, user_id)
    if available < amount:
        return api_error(status_code=status.HTTP_402_PAYMENT_REQUIRED, code=AvatarErrorCode.CREDITS_INSUFFICIENT, message="积分不足")

    # 统一扣费链路：创建 pending 预扣 -> 立即结算
    tx = billing_service.create_pending_consume_transaction(
        db=db,
        user_id=user_id,
        task_id=str(uuid.uuid4()),
        cost=float(amount),
        description=description or "手动扣费（预扣）",
    )
    db.commit()

    # 结算（使用 PG 行锁保证并发安全）
    billing_service.settle_pending_consume_transaction(db=db, tx=tx)
    db.commit()

    db.refresh(user)
    return api_ok(data={"message": "扣费成功", "new_balance": user.balance})


@router.get("/transactions")
async def get_transactions(
    user_id: str,
    limit: int = 20,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """获取交易记录"""
    transactions = db.query(Transaction).filter(
        Transaction.user_id == user_id
    ).order_by(Transaction.created_at.desc()).offset(offset).limit(limit).all()
    
    return api_ok(data=[TransactionResponse.from_orm(t).model_dump() for t in transactions])


@router.post("/subscription")
async def create_subscription(
    user_id: str,
    request: SubscriptionRequest,
    db: Session = Depends(get_db)
):
    """创建订阅"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        return api_error(status_code=status.HTTP_404_NOT_FOUND, code=AvatarErrorCode.NOT_FOUND, message="用户不存在")
    
    # 确定订阅价格和时长
    if request.subscription_type == SubscriptionType.WEEKLY:
        price = WEEKLY_SUBSCRIPTION_PRICE
        expires_at = datetime.now() + timedelta(days=7)
    elif request.subscription_type == SubscriptionType.MONTHLY:
        price = MONTHLY_SUBSCRIPTION_PRICE
        expires_at = datetime.now() + timedelta(days=30)
    else:
        return api_error(status_code=status.HTTP_400_BAD_REQUEST, code=AvatarErrorCode.INVALID_ARGUMENT, message="无效的订阅类型")
    
    # 检查余额
    if user.balance < price:
        return api_error(status_code=status.HTTP_402_PAYMENT_REQUIRED, code=AvatarErrorCode.CREDITS_INSUFFICIENT, message="积分不足")
    
    # 扣除费用
    user.balance -= price
    
    # 更新用户订阅信息
    user.subscription_type = request.subscription_type
    user.subscription_expires_at = expires_at
    
    # 创建订阅记录
    subscription = Subscription(
        id=str(uuid.uuid4()),
        user_id=user_id,
        subscription_type=request.subscription_type,
        price=price,
        expires_at=expires_at,
        auto_renew=True,
        is_active=True
    )
    
    # 创建交易记录
    transaction = Transaction(
        id=str(uuid.uuid4()),
        user_id=user_id,
        transaction_type="consume",
        amount=-price,
        description=f"订阅: {request.subscription_type.value}",
        status="completed"
    )
    
    db.add(subscription)
    db.add(transaction)
    db.commit()
    
    return api_ok(
        data={
            "message": "订阅成功",
            "subscription": SubscriptionResponse.from_orm(subscription).model_dump(),
        }
    )


@router.get("/subscription")
async def get_subscription(user_id: str, db: Session = Depends(get_db)):
    """获取当前订阅信息"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        return api_error(status_code=status.HTTP_404_NOT_FOUND, code=AvatarErrorCode.NOT_FOUND, message="用户不存在")
    
    if user.subscription_type == SubscriptionType.NONE:
        return api_error(status_code=status.HTTP_404_NOT_FOUND, code=AvatarErrorCode.NOT_FOUND, message="用户未订阅")
    
    # 检查订阅是否过期
    if user.subscription_expires_at and user.subscription_expires_at < datetime.now():
        user.subscription_type = SubscriptionType.NONE
        user.subscription_expires_at = None
        db.commit()
        return api_error(status_code=status.HTTP_404_NOT_FOUND, code=AvatarErrorCode.NOT_FOUND, message="订阅已过期")
    
    subscription = db.query(Subscription).filter(
        Subscription.user_id == user_id,
        Subscription.is_active == True
    ).order_by(Subscription.created_at.desc()).first()
    
    if not subscription:
        return api_error(status_code=status.HTTP_404_NOT_FOUND, code=AvatarErrorCode.NOT_FOUND, message="订阅记录不存在")
    
    return api_ok(data=SubscriptionResponse.from_orm(subscription).model_dump())


@router.post("/subscription/cancel")
async def cancel_subscription(user_id: str, db: Session = Depends(get_db)):
    """取消订阅"""
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user:
        return api_error(status_code=status.HTTP_404_NOT_FOUND, code=AvatarErrorCode.NOT_FOUND, message="用户不存在")
    
    # 取消自动续费
    subscription = db.query(Subscription).filter(
        Subscription.user_id == user_id,
        Subscription.is_active == True
    ).first()
    
    if subscription:
        subscription.auto_renew = False
        db.commit()
    
    return api_ok(data={"message": "订阅已取消自动续费"})
