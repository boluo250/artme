"""
Apple IAP validation service (guest-mode).

Notes:
- In production, always validate receipts with Apple servers and parse
  `latest_receipt_info` for auto-renewable subscriptions.
- Here we provide a parsing helper capable of decoding a base64 JSON
  payload shaped like the sample in the spec for local testing.
"""
from __future__ import annotations

import base64
import json
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any, Optional


@dataclass
class ParsedReceipt:
    original_transaction_id: str
    transaction_id: str
    product_id: str
    environment: str
    purchase_date: datetime
    expires_at: Optional[datetime]
    is_in_trial: bool
    auto_renew: Optional[bool]


class IAPService:
    MEMBERSHIP_WEEKLY_PRODUCT = "membership.weekly.cn"
    MEMBERSHIP_WEEKLY_PRICE_CENTS = 1800

    def _b64_to_json(self, b64: str) -> dict[str, Any]:
        try:
            data = base64.b64decode(b64 + "==")  # tolerant padding
            s = data.decode("utf-8", errors="ignore")
            return json.loads(s)
        except Exception:
            # Not a base64 JSON payload; assume caller posted raw JSON text
            try:
                return json.loads(b64)
            except Exception as e:
                raise ValueError("invalid_receipt_payload") from e

    def parse_local_json_receipt(self, receipt_base64_or_json: str) -> ParsedReceipt:
        payload = self._b64_to_json(receipt_base64_or_json)

        env_raw = payload.get("environment") or payload.get("receipt", {}).get("receipt_type") or "Production"
        env = "Sandbox" if str(env_raw).lower().find("sandbox") >= 0 else "Production"

        # Prefer App Store's latest_receipt_info which includes expiration for subscriptions
        info_list = payload.get("latest_receipt_info") or payload.get("receipt", {}).get("in_app") or []
        if not info_list:
            raise ValueError("missing_in_app")

        # Choose the latest by purchase_date_ms if present
        def parse_ms(v: Optional[str]) -> int:
            try:
                return int(v or "0")
            except Exception:
                return 0

        latest = max(info_list, key=lambda x: parse_ms(x.get("purchase_date_ms")))

        product_id = latest.get("product_id") or self.MEMBERSHIP_WEEKLY_PRODUCT
        otx = latest.get("original_transaction_id")
        tx = latest.get("transaction_id") or otx
        if not otx:
            raise ValueError("missing_original_transaction_id")

        # Purchase date
        purchase_ms = parse_ms(latest.get("purchase_date_ms"))
        if purchase_ms > 0:
            purchased_at = datetime.fromtimestamp(purchase_ms / 1000.0, tz=timezone.utc)
        else:
            purchased_at = datetime.now(tz=timezone.utc)

        # Expiration
        exp_ms_raw = latest.get("expires_date_ms") or latest.get("expiration_date_ms")
        expires_at: Optional[datetime] = None
        if exp_ms_raw:
            try:
                expires_at = datetime.fromtimestamp(int(exp_ms_raw) / 1000.0, tz=timezone.utc)
            except Exception:
                expires_at = None

        # Fallback: if expiration is missing and looks like a weekly membership product,
        # assume 7 days from purchase for local testing.
        if not expires_at and product_id == self.MEMBERSHIP_WEEKLY_PRODUCT:
            expires_at = purchased_at + timedelta(days=7)

        is_trial = str(latest.get("is_trial_period", "false")).lower() == "true"
        auto_renew = None  # May be supplemented from App Store Server Notifications V2

        return ParsedReceipt(
            original_transaction_id=otx,
            transaction_id=tx,
            product_id=product_id,
            environment=str(env),
            purchase_date=purchased_at,
            expires_at=expires_at,
            is_in_trial=is_trial,
            auto_renew=auto_renew,
        )


iap_service = IAPService()
