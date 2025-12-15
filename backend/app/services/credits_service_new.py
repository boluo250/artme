"""
Credits (gift/paid) + subscription persistence helpers on top of billing schema.
Use raw SQL to call stored procedures and insert purchase facts.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Optional
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.orm import Session


@dataclass(frozen=True)
class MembershipSnapshot:
    original_transaction_id: str
    product_id: str
    status: str
    period_start: datetime
    period_end: datetime
    auto_renew: Optional[bool]
    gift_balance: int
    paid_balance: int


class CreditsServiceNew:
    def upsert_subscription_and_reset(
        self,
        *,
        db: Session,
        otx: str,
        product_id: str,
        status: str,
        period_start: datetime,
        period_end: datetime,
        is_in_trial: bool,
        auto_renew: Optional[bool],
        environment: str,
        anon_user_id: Optional[UUID],
    ) -> None:
        q = text(
            """
            SELECT billing.upsert_subscription_and_reset_gift(
              :otx, :product_id, :status, :period_start, :period_end,
              :is_in_trial, :auto_renew, :environment, :anon
            )
            """
        )
        db.execute(
            q,
            {
                "otx": otx,
                "product_id": product_id,
                "status": status,
                "period_start": period_start,
                "period_end": period_end,
                "is_in_trial": is_in_trial,
                "auto_renew": auto_renew,
                "environment": environment,
                "anon": str(anon_user_id) if anon_user_id else None,
            },
        )

    def insert_subscription_order(
        self,
        *,
        db: Session,
        otx: str,
        tx_id: str,
        product_id: str,
        price_cents: int,
        purchase_date: datetime,
        environment: str,
        anon_user_id: Optional[UUID],
        raw_receipt_b64: Optional[str] = None,
    ) -> None:
        q = text(
            """
            INSERT INTO billing.iap_orders (
              original_transaction_id, transaction_id, product_id, order_type,
              quantity, price_cents, currency, purchase_date, environment,
              is_revoked, raw_receipt, anon_user_id
            ) VALUES (
              :otx, :tx, :product_id, 'subscription', 1, :price_cents, 'CNY', :purchase_date, :environment,
              false, :raw_receipt, :anon
            )
            ON CONFLICT (transaction_id) DO NOTHING
            """
        )
        db.execute(
            q,
            {
                "otx": otx,
                "tx": tx_id,
                "product_id": product_id,
                "price_cents": price_cents,
                "purchase_date": purchase_date,
                "environment": environment,
                "raw_receipt": raw_receipt_b64,
                "anon": str(anon_user_id) if anon_user_id else None,
            },
        )

    def spend(
        self,
        *,
        db: Session,
        otx: str,
        amount: int,
        reason: str,
        anon_user_id: Optional[UUID],
    ) -> tuple[int, int, int, int]:
        q = text(
            """
            SELECT gift_used, paid_used, gift_balance, paid_balance
            FROM billing.spend_credits(:otx, :amount, :reason, :anon)
            """
        )
        row = db.execute(
            q,
            {
                "otx": otx,
                "amount": amount,
                "reason": reason,
                "anon": str(anon_user_id) if anon_user_id else None,
            },
        ).first()
        if not row:
            raise ValueError("spend_failed")
        return int(row[0]), int(row[1]), int(row[2]), int(row[3])

    def get_balances(self, *, db: Session, otx: str) -> tuple[int, int]:
        q = text(
            """
            SELECT gift_balance, paid_balance
            FROM billing.credit_accounts
            WHERE original_transaction_id = :otx
            """
        )
        row = db.execute(q, {"otx": otx}).first()
        if not row:
            return 0, 0
        return int(row[0]), int(row[1])


credits_service_new = CreditsServiceNew()

