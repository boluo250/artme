"""
手机号登录与用户信息 API
"""
from datetime import datetime, timedelta
import uuid
import random
from typing import Dict, Tuple, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User, Transaction, SubscriptionType


router = APIRouter(prefix="/auth", tags=["auth"])

# 简单的内存验证码存储，仅用于开发环境和测试
_CODE_TTL_MINUTES = 10
_phone_codes: Dict[str, Tuple[str, datetime]] = {}


class SendCodeRequest(BaseModel):
    phone_number: str


class SendCodeResponse(BaseModel):
    message: str
    # 为了方便开发调试，返回验证码；正式环境可以去掉该字段
    debug_code: str


class VerifyCodeRequest(BaseModel):
    phone_number: str
    code: str


class AuthUserResponse(BaseModel):
    user_id: str
    phone_number: str
    balance: float
    subscription_type: str
    subscription_expires_at: Optional[datetime] = None


def _generate_code() -> str:
    """生成 6 位数字验证码"""
    return f"{random.randint(0, 999999):06d}"


def _store_code(phone_number: str, code: str) -> None:
    expires_at = datetime.utcnow() + timedelta(minutes=_CODE_TTL_MINUTES)
    _phone_codes[phone_number] = (code, expires_at)


def _verify_code(phone_number: str, code: str) -> bool:
    stored = _phone_codes.get(phone_number)
    if not stored:
        return False
    stored_code, expires_at = stored
    if datetime.utcnow() > expires_at:
        # 过期后删除
        _phone_codes.pop(phone_number, None)
        return False
    return stored_code == code


@router.post("/send_code", response_model=SendCodeResponse)
async def send_code(payload: SendCodeRequest) -> SendCodeResponse:
    """
    发送手机验证码（开发环境：直接返回 debug_code）

    未来接入短信服务时，可以在这里调用第三方短信网关。
    """
    code = _generate_code()
    _store_code(payload.phone_number, code)
    return SendCodeResponse(message="验证码已发送（开发环境）", debug_code=code)


@router.post("/verify_code", response_model=AuthUserResponse)
async def verify_code(
    payload: VerifyCodeRequest,
    db: Session = Depends(get_db),
) -> AuthUserResponse:
    """
    校验验证码并完成登录/注册：
    - 首次登录手机号：创建用户并发放 5 积分
    - 已存在用户：直接返回账户与订阅信息
    """
    if not _verify_code(payload.phone_number, payload.code):
        raise HTTPException(status_code=400, detail="验证码错误或已过期")

    # 验证成功后消费掉验证码，防止重复使用
    _phone_codes.pop(payload.phone_number, None)

    # 查找是否已有绑定该手机号的用户
    user = (
        db.query(User)
        .filter(User.phone_number == payload.phone_number)
        .first()
    )

    is_new_user = user is None

    if is_new_user:
        # 为新用户生成基础信息
        user_id = str(uuid.uuid4())
        # 简单生成一个用户名和占位邮箱，方便复用现有账户体系
        username = f"user_{payload.phone_number[-4:]}"
        placeholder_email = f"{payload.phone_number}@artme.local"

        user = User(
            id=user_id,
            username=username,
            email=placeholder_email,
            # 使用随机密码占位，用户不使用密码登录
            hashed_password=str(uuid.uuid4()),
            phone_number=payload.phone_number,
            balance=5.0,  # 新用户初始 5 积分
            subscription_type=SubscriptionType.NONE,
        )
        db.add(user)

        # 记录一条“注册奖励”交易流水，便于后续在前端展示积分来源
        bonus_tx = Transaction(
            id=str(uuid.uuid4()),
            user_id=user_id,
            transaction_type="bonus",
            amount=5.0,
            description="新用户注册奖励 5 积分",
            status="completed",
        )
        db.add(bonus_tx)
        db.commit()
        db.refresh(user)
    else:
        # 已存在用户，确保仍为激活状态
        if not user.is_active:
            raise HTTPException(status_code=403, detail="账户已被禁用")

    return AuthUserResponse(
        user_id=user.id,
        phone_number=user.phone_number or payload.phone_number,
        balance=user.balance,
        subscription_type=user.subscription_type.value
        if isinstance(user.subscription_type, SubscriptionType)
        else str(user.subscription_type),
        subscription_expires_at=user.subscription_expires_at,
    )


