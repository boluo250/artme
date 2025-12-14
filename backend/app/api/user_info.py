"""
用户信息聚合 API（用于「我的」页面）
"""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User, SubscriptionType

from app.utils.api_response import api_ok, api_error
from app.utils.error_codes import AvatarErrorCode


router = APIRouter(prefix="/user", tags=["user"])


class UserMeResponse(BaseModel):
    id: str
    phone_number: Optional[str] = None
    balance: float
    subscription_type: str
    subscription_expires_at: Optional[str] = None


@router.get("/me")
async def get_me(user_id: str, db: Session = Depends(get_db)) -> UserMeResponse:
    """
    获取「我的」页面所需的基础用户信息：
    - 当前积分（balance）
    - 会员状态与到期时间

    目前通过 user_id 查询，后续可以改为基于 Token 的鉴权。
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return api_error(status_code=404, code=AvatarErrorCode.NOT_FOUND, message="用户不存在")

    subscription_type = (
        user.subscription_type.value
        if isinstance(user.subscription_type, SubscriptionType)
        else str(user.subscription_type)
    )

    data = UserMeResponse(
        id=user.id,
        phone_number=user.phone_number,
        balance=user.balance,
        subscription_type=subscription_type,
        subscription_expires_at=(
            user.subscription_expires_at.isoformat()
            if user.subscription_expires_at is not None
            else None
        ),
    ).model_dump()
    return api_ok(data=data)


