-- Guest‑Mode Membership + Credits Schema (PostgreSQL)
-- Schema: billing (to avoid collision with legacy public.subscriptions)

-- Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- for gen_random_uuid

-- Dedicated schema
CREATE SCHEMA IF NOT EXISTS billing;

-- 1) anon_devices (auxiliary device registry; not authoritative)
CREATE TABLE IF NOT EXISTS billing.anon_devices (
  anon_user_id uuid PRIMARY KEY,
  note text,
  app_version text,
  locale text,
  last_seen_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE billing.anon_devices IS '游客设备标识（仅定位/追溯）';
COMMENT ON COLUMN billing.anon_devices.anon_user_id IS 'Keychain 生成的 UUID（辅助定位）';

-- 2) iap_orders (subscription and credit pack purchase facts)
CREATE TABLE IF NOT EXISTS billing.iap_orders (
  id bigserial PRIMARY KEY,
  original_transaction_id text NOT NULL,
  transaction_id text NOT NULL UNIQUE,
  product_id text NOT NULL,
  order_type text NOT NULL CHECK (order_type IN ('subscription','credit_pack')),
  quantity integer NOT NULL DEFAULT 1 CHECK (quantity > 0),
  price_cents integer NOT NULL CHECK (price_cents >= 0),
  currency char(3) NOT NULL DEFAULT 'CNY',
  purchase_date timestamptz NOT NULL,
  environment text NOT NULL CHECK (environment IN ('Production','Sandbox')),
  is_revoked boolean NOT NULL DEFAULT false,
  raw_receipt text,
  anon_user_id uuid,
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE billing.iap_orders IS 'IAP 购买事实（订阅/积分包）';
COMMENT ON COLUMN billing.iap_orders.original_transaction_id IS 'otx：订阅全局唯一标识（权威归属）';
COMMENT ON COLUMN billing.iap_orders.anon_user_id IS 'anon：下单时设备标识（辅助定位）';

CREATE INDEX IF NOT EXISTS idx_iap_orders_otx ON billing.iap_orders(original_transaction_id);
CREATE INDEX IF NOT EXISTS idx_iap_orders_anon ON billing.iap_orders(anon_user_id);
CREATE INDEX IF NOT EXISTS idx_iap_orders_type ON billing.iap_orders(order_type);

-- 3) subscriptions (authoritative cache by otx) -- in schema billing to avoid name clash
CREATE TABLE IF NOT EXISTS billing.subscriptions (
  original_transaction_id text PRIMARY KEY,
  product_id text NOT NULL,
  status text NOT NULL CHECK (status IN ('active','expired','revoked')),
  current_period_start timestamptz NOT NULL,
  current_period_end timestamptz NOT NULL,
  is_in_trial boolean NOT NULL DEFAULT false,
  auto_renew boolean,
  environment text NOT NULL CHECK (environment IN ('Production','Sandbox')),
  last_receipt_validation_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (current_period_end > current_period_start)
);
COMMENT ON TABLE billing.subscriptions IS '订阅状态缓存（Apple receipt 为唯一权威）';
COMMENT ON COLUMN billing.subscriptions.original_transaction_id IS 'otx：订阅/资产权威主键';

-- 4) credit_accounts (split balances; authoritative by otx)
CREATE TABLE IF NOT EXISTS billing.credit_accounts (
  original_transaction_id text PRIMARY KEY REFERENCES billing.subscriptions(original_transaction_id) ON DELETE CASCADE,
  gift_balance integer NOT NULL DEFAULT 0 CHECK (gift_balance >= 0),
  paid_balance integer NOT NULL DEFAULT 0 CHECK (paid_balance >= 0),
  last_gift_reset_at timestamptz,
  current_anon_user_id uuid REFERENCES billing.anon_devices(anon_user_id) ON DELETE SET NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE billing.credit_accounts IS '积分账户（gift=会员赠送；paid=购买）';
COMMENT ON COLUMN billing.credit_accounts.current_anon_user_id IS 'anon：当前设备绑定（辅助定位）';

CREATE INDEX IF NOT EXISTS idx_credit_accounts_anon ON billing.credit_accounts(current_anon_user_id);

-- 5) credit_ledger (journal per otx; records gift/paid movements)
CREATE TABLE IF NOT EXISTS billing.credit_ledger (
  id bigserial PRIMARY KEY,
  original_transaction_id text NOT NULL REFERENCES billing.credit_accounts(original_transaction_id) ON DELETE CASCADE,
  entry_type text NOT NULL CHECK (entry_type IN ('gift','paid')),
  direction text NOT NULL CHECK (direction IN ('in','out')),
  amount integer NOT NULL CHECK (amount > 0),
  balance_after_gift integer NOT NULL CHECK (balance_after_gift >= 0),
  balance_after_paid integer NOT NULL CHECK (balance_after_paid >= 0),
  reason text NOT NULL DEFAULT 'unknown',
  ref_order_id bigint REFERENCES billing.iap_orders(id),
  anon_user_id uuid,
  operation_id uuid NOT NULL DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE billing.credit_ledger IS '积分流水（gift/paid 分账，含方向与期末余额）';

CREATE INDEX IF NOT EXISTS idx_credit_ledger_otx ON billing.credit_ledger(original_transaction_id);
CREATE INDEX IF NOT EXISTS idx_credit_ledger_created ON billing.credit_ledger(created_at);
CREATE INDEX IF NOT EXISTS idx_credit_ledger_op ON billing.credit_ledger(operation_id);
