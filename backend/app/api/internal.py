"""
Internal-only APIs (dev/preprod). Provide QA points grant for guest/users.

POST /api/v1/internal/points/grant
- DEBUG only
- Requires header: X-Internal-Token = settings.INTERNAL_API_TOKEN
- Idempotent via optional request_id
"""
from __future__ import annotations

import uuid
from fastapi import APIRouter, Depends, Header, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from typing import Optional

from app.config import settings
from app.database import get_db
from app.models.user import User, Transaction
from app.utils.api_response import api_ok, api_error
from app.utils.error_codes import AvatarErrorCode


router = APIRouter(prefix="/internal", tags=["internal"])


class GrantPointsRequest(BaseModel):
    user_id: str = Field(..., description="目标游客/用户 ID")
    amount: float = Field(..., gt=0, description="发放积分（正数）")
    reason: Optional[str] = Field(default="QA", description="发放原因")
    request_id: Optional[str] = Field(default=None, description="幂等请求 ID，可选")


@router.post("/points/grant")
async def grant_points(
    req: GrantPointsRequest,
    db: Session = Depends(get_db),
    internal_token: Optional[str] = Header(default=None, alias="X-Internal-Token"),
):
    # Only allow in DEBUG builds to avoid accidental exposure
    if not settings.DEBUG:
        return api_error(
            status_code=status.HTTP_403_FORBIDDEN,
            code=AvatarErrorCode.FORBIDDEN,
            message="internal API disabled",
        )

    # Simple shared-secret check
    if not internal_token or internal_token != settings.INTERNAL_API_TOKEN:
        return api_error(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code=AvatarErrorCode.UNAUTHORIZED,
            message="invalid internal token",
        )

    # Load and (where supported) lock user row for safe balance update
    user = (
        db.query(User)
        .filter(User.id == req.user_id)
        .with_for_update()
        .first()
    )
    if not user:
        return api_error(
            status_code=status.HTTP_404_NOT_FOUND,
            code=AvatarErrorCode.NOT_FOUND,
            message="用户不存在",
        )

    # Idempotency: if request_id already used as a Transaction.id, return current snapshot
    if req.request_id:
        existed = db.query(Transaction).filter(Transaction.id == req.request_id).first()
        if existed is not None:
            db.refresh(user)
            return api_ok(
                data={
                    "user_id": user.id,
                    "granted": 0.0,
                    "new_balance": user.balance,
                    "transaction_id": existed.id,
                }
            )

    tx_id = req.request_id or str(uuid.uuid4())
    tx = Transaction(
        id=tx_id,
        user_id=user.id,
        transaction_type="admin_grant",
        amount=float(req.amount),  # positive: credit in
        description=f"Internal grant ({req.reason or 'QA'})",
        status="completed",
    )
    db.add(tx)

    # Apply balance
    user.balance += float(req.amount)

    db.commit()
    db.refresh(user)

    return api_ok(
        data={
            "user_id": user.id,
            "granted": float(req.amount),
            "new_balance": user.balance,
            "transaction_id": tx_id,
        }
    )
