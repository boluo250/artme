"""
IAP endpoints for guest-mode membership lifecycle.

POST /api/v1/iap/validate  - validate receipt, upsert subscription, reset gift=88
POST /api/v1/iap/restore   - same as validate, bind anon to account
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.database import get_db
from app.utils.api_response import api_ok, api_error
from app.utils.error_codes import AvatarErrorCode
from app.services.iap_service import iap_service
from app.services.credits_service_new import credits_service_new
from app.schemas.iap import (
    ValidateReceiptRequest,
    ValidateReceiptResponse,
    RestoreRequest,
)


router = APIRouter(prefix="/iap", tags=["iap"])


def _status_from_expiry(expires_at: Optional[datetime]) -> str:
    if not expires_at:
        return "expired"
    return "active" if expires_at > datetime.now(tz=timezone.utc) else "expired"


@router.post("/validate")
async def validate_receipt(req: ValidateReceiptRequest, db: Session = Depends(get_db)):
    try:
        parsed = iap_service.parse_local_json_receipt(req.receipt_base64)
    except Exception as e:
        return api_error(
            status_code=status.HTTP_400_BAD_REQUEST,
            code=AvatarErrorCode.INVALID_ARGUMENT,
            message=f"invalid receipt: {e}",
        )

    # Only handle weekly membership here
    if parsed.product_id != iap_service.MEMBERSHIP_WEEKLY_PRODUCT:
        return api_error(
            status_code=status.HTTP_400_BAD_REQUEST,
            code=AvatarErrorCode.INVALID_ARGUMENT,
            message="unsupported product_id for this endpoint",
        )

    status_str = _status_from_expiry(parsed.expires_at)

    # Persist order (idempotent by transaction_id)
    credits_service_new.insert_subscription_order(
        db=db,
        otx=parsed.original_transaction_id,
        tx_id=parsed.transaction_id,
        product_id=parsed.product_id,
        price_cents=iap_service.MEMBERSHIP_WEEKLY_PRICE_CENTS,
        purchase_date=parsed.purchase_date,
        environment=parsed.environment,
        anon_user_id=req.anon_user_id,
        raw_receipt_b64=req.receipt_base64,
    )

    # Upsert subscription snapshot + reset gift if new period
    credits_service_new.upsert_subscription_and_reset(
        db=db,
        otx=parsed.original_transaction_id,
        product_id=parsed.product_id,
        status=status_str,
        period_start=parsed.purchase_date,
        period_end=parsed.expires_at or parsed.purchase_date,
        is_in_trial=parsed.is_in_trial,
        auto_renew=parsed.auto_renew,
        environment=parsed.environment,
        anon_user_id=req.anon_user_id,
    )

    # Fetch balances
    gift, paid = credits_service_new.get_balances(db=db, otx=parsed.original_transaction_id)

    resp = ValidateReceiptResponse(
        original_transaction_id=parsed.original_transaction_id,
        product_id=parsed.product_id,
        status=status_str,
        period_start=parsed.purchase_date,
        period_end=parsed.expires_at or parsed.purchase_date,
        auto_renew=parsed.auto_renew,
        gift_balance=gift,
        paid_balance=paid,
    )
    db.commit()
    return api_ok(data=resp.model_dump())


@router.post("/restore")
async def restore(req: RestoreRequest, db: Session = Depends(get_db)):
    # Restore uses the same flow as validate
    return await validate_receipt(req, db)
