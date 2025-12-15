"""
Pydantic schemas for Apple IAP validation and credits spend (guest-mode).
"""
from __future__ import annotations

from typing import Optional
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field


class ValidateReceiptRequest(BaseModel):
    receipt_base64: str = Field(..., description="Apple receipt (base64)")
    anon_user_id: Optional[UUID] = Field(None, description="Keychain-generated anon id (optional but recommended)")


class ReceiptSnapshot(BaseModel):
    original_transaction_id: str
    transaction_id: str
    product_id: str
    status: str  # 'active' | 'expired' | 'revoked'
    period_start: datetime
    period_end: datetime
    is_in_trial: bool = False
    auto_renew: Optional[bool] = None
    environment: str  # 'Production' | 'Sandbox'
    purchase_date: datetime


class ValidateReceiptResponse(BaseModel):
    original_transaction_id: str
    product_id: str
    status: str
    period_start: datetime
    period_end: datetime
    auto_renew: Optional[bool] = None
    gift_balance: int
    paid_balance: int


class RestoreRequest(ValidateReceiptRequest):
    pass


class SpendCreditsRequest(BaseModel):
    original_transaction_id: str
    amount: int
    reason: Optional[str] = "spend"
    anon_user_id: Optional[UUID] = None


class SpendCreditsResponse(BaseModel):
    gift_used: int
    paid_used: int
    gift_balance: int
    paid_balance: int

