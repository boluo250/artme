"""
Credits spend endpoint (gift-first then paid), backed by billing.spend_credits().
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.utils.api_response import api_ok, api_error
from app.utils.error_codes import AvatarErrorCode
from app.services.credits_service_new import credits_service_new
from app.schemas.iap import SpendCreditsRequest, SpendCreditsResponse


router = APIRouter(prefix="/credits", tags=["credits"])


@router.post("/spend")
async def spend(req: SpendCreditsRequest, db: Session = Depends(get_db)):
    if req.amount is None or req.amount <= 0:
        return api_error(
            status_code=status.HTTP_400_BAD_REQUEST,
            code=AvatarErrorCode.INVALID_ARGUMENT,
            message="amount must be > 0",
        )

    try:
        gift_used, paid_used, gift_bal, paid_bal = credits_service_new.spend(
            db=db,
            otx=req.original_transaction_id,
            amount=int(req.amount),
            reason=req.reason or "spend",
            anon_user_id=req.anon_user_id,
        )
        db.commit()
    except Exception as e:
        return api_error(
            status_code=status.HTTP_402_PAYMENT_REQUIRED if "insufficient" in str(e) else status.HTTP_400_BAD_REQUEST,
            code=AvatarErrorCode.CREDITS_INSUFFICIENT if "insufficient" in str(e) else AvatarErrorCode.INVALID_ARGUMENT,
            message=str(e),
        )

    resp = SpendCreditsResponse(
        gift_used=gift_used,
        paid_used=paid_used,
        gift_balance=gift_bal,
        paid_balance=paid_bal,
    )
    return api_ok(data=resp.model_dump())

