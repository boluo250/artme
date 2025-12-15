# Guest‑Mode Subscription + Credits — Implementation Plan

Owner: iOS + Backend
Status: Draft
Target: iOS 16+, StoreKit2, PostgreSQL (Supabase‑compatible)

## 0) Product Setup (App Store Connect)
- Create IAP products
  - `membership.weekly.cn` (auto‑renewable, CNY 18 / week)
  - `credits.100.cn`, `credits.300.cn`, `credits.1000.cn` (non‑consumable / non‑renewing? sold as durable credits via our backend)
- Localize display names/descriptions; upload screenshots.
- Enable App Store Server Notifications V2; configure endpoint `/iap/assn`.

## 1) Database (PostgreSQL)
- Enable `pgcrypto` (for `gen_random_uuid`).
- Apply schema:
  - `anon_devices`, `iap_orders`, `subscriptions`, `credit_accounts`, `credit_ledger` (see architecture doc).
- Create read models / views (optional): `v_credit_balances` (join subscriptions + accounts).

## 2) Backend APIs
- POST `/v1/devices/register` {anon_user_id, note?}
- POST `/v1/iap/validate` {base64_receipt, anon_user_id}
  - Validate with Apple → parse OTX, periods, environment
  - Upsert `subscriptions`
  - Initialize/refresh gift cycle (88) in `credit_accounts`
  - Insert `iap_orders` (subscription events)
  - Bind `credit_accounts.current_anon_user_id = anon_user_id`
  - Return membership snapshot + credit balances
- POST `/v1/iap/credit-pack` {transaction_id, product_id, anon_user_id}
  - Verify with Apple; require `subscriptions.status = active`
  - Insert `iap_orders` (credit pack)
  - Credit `paid_balance` (+100/300/1000) + ledger
- POST `/v1/credits/spend` {otx, amount, reason, anon_user_id?}
  - Call DB RPC: atomic spend (gift→paid)
  - Return gift_used, paid_used, balances
- GET `/v1/credits/balance?otx=...` → balances snapshot
- POST `/v1/iap/restore` {base64_receipt, anon_user_id} → same as validate; rebind anon id
- POST `/admin/credits/grant` {otx or anon_user_id, amount, kind: paid|gift, reason}

## 3) Schedulers / Webhooks
- Daily job: expire gift for `subscriptions.status = expired` (set gift_balance=0 + ledger)
- ASSN handler: listen to renewal, expiration, revocation; drive `subscriptions` + gift reset

## 4) iOS (SwiftUI + StoreKit2)
- Generate `anon_user_id` (Keychain) on first launch; POST `/devices/register`.
- Purchase flow
  - For membership: purchase `membership.weekly.cn`; submit latest receipt to `/iap/validate`; update local state
  - For credit packs: only when backend says membership active; purchase → verify → `/iap/credit-pack`
- Restore Purchases: request latest receipt; `/iap/restore` → update Membership + balances
- Spend credits: call `/credits/spend` before starting a paid task; handle insufficient balance
- UI
  - Profile page shows membership status, gift 88 counter, paid credits, ledgers
  - Disable credit-pack rows if not member

## 5) Security / Ops
- Always server‑side verify receipts (bundle id, product id, environment)
- Persist and sign responses (request id)
- Rate limit spend endpoint; idempotency keys for purchases

## 6) Test Plan
- Cases: new member, renew, expire, restore on new device, buy packs, spend across gift→paid, insufficient funds, admin grant by anon/otx
- Time‑travel tests for period boundaries

## 7) Rollout
- Stage in Sandbox; seed test users; flip to Prod after validation

