-- Functions / RPCs for credits & subscription lifecycle (billing schema)

-- Atomic spend credits: gift-first then paid
CREATE OR REPLACE FUNCTION billing.spend_credits(
  p_otx text,
  p_amount integer,
  p_reason text DEFAULT 'spend',
  p_anon uuid DEFAULT NULL
) RETURNS TABLE (
  gift_used integer,
  paid_used integer,
  gift_balance integer,
  paid_balance integer
) LANGUAGE plpgsql AS $$
DECLARE
  v_gift int;
  v_paid int;
  v_need int;
  v_use_gift int := 0;
  v_use_paid int := 0;
  v_op uuid := gen_random_uuid();
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'amount must be > 0';
  END IF;

  -- lock account row
  SELECT gift_balance, paid_balance
    INTO v_gift, v_paid
  FROM billing.credit_accounts
  WHERE original_transaction_id = p_otx
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'credit account not found for otx=%', p_otx;
  END IF;

  v_need := p_amount;
  v_use_gift := LEAST(v_gift, v_need);
  v_need := v_need - v_use_gift;
  v_use_paid := v_need;

  IF v_use_paid > v_paid THEN
    RAISE EXCEPTION 'insufficient_credits';
  END IF;

  -- apply balances
  UPDATE billing.credit_accounts
  SET gift_balance = gift_balance - v_use_gift,
      paid_balance = paid_balance - v_use_paid,
      updated_at = now()
  WHERE original_transaction_id = p_otx;

  -- ledger gift
  IF v_use_gift > 0 THEN
    INSERT INTO billing.credit_ledger (
      original_transaction_id, entry_type, direction, amount,
      balance_after_gift, balance_after_paid, reason, anon_user_id, operation_id
    )
    SELECT p_otx, 'gift', 'out', v_use_gift,
           ca.gift_balance, ca.paid_balance, p_reason, p_anon, v_op
    FROM billing.credit_accounts ca
    WHERE ca.original_transaction_id = p_otx;
  END IF;

  -- ledger paid
  IF v_use_paid > 0 THEN
    INSERT INTO billing.credit_ledger (
      original_transaction_id, entry_type, direction, amount,
      balance_after_gift, balance_after_paid, reason, anon_user_id, operation_id
    )
    SELECT p_otx, 'paid', 'out', v_use_paid,
           ca.gift_balance, ca.paid_balance, p_reason, p_anon, v_op
    FROM billing.credit_accounts ca
    WHERE ca.original_transaction_id = p_otx;
  END IF;

  -- return snapshot
  RETURN QUERY
  SELECT v_use_gift, v_use_paid, ca.gift_balance, ca.paid_balance
  FROM billing.credit_accounts ca
  WHERE ca.original_transaction_id = p_otx;
END$$;

-- Upsert subscription snapshot and reset gift to 88 when entering a new period
CREATE OR REPLACE FUNCTION billing.upsert_subscription_and_reset_gift(
  p_otx text,
  p_product_id text,
  p_status text,
  p_period_start timestamptz,
  p_period_end timestamptz,
  p_is_in_trial boolean,
  p_auto_renew boolean,
  p_environment text,
  p_anon uuid
) RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_reset_needed boolean := false;
  v_gift_after int;
BEGIN
  -- upsert subscription
  INSERT INTO billing.subscriptions (
    original_transaction_id, product_id, status, current_period_start, current_period_end,
    is_in_trial, auto_renew, environment
  ) VALUES (p_otx, p_product_id, p_status, p_period_start, p_period_end,
            p_is_in_trial, p_auto_renew, p_environment)
  ON CONFLICT (original_transaction_id) DO UPDATE SET
    product_id = EXCLUDED.product_id,
    status = EXCLUDED.status,
    current_period_start = EXCLUDED.current_period_start,
    current_period_end = EXCLUDED.current_period_end,
    is_in_trial = EXCLUDED.is_in_trial,
    auto_renew = EXCLUDED.auto_renew,
    environment = EXCLUDED.environment,
    last_receipt_validation_at = now(),
    updated_at = now();

  -- ensure account row
  INSERT INTO billing.credit_accounts (original_transaction_id, gift_balance, paid_balance, last_gift_reset_at, current_anon_user_id)
  VALUES (p_otx, 88, 0, p_period_start, p_anon)
  ON CONFLICT (original_transaction_id) DO NOTHING;

  -- lock account, decide reset
  PERFORM 1 FROM billing.credit_accounts WHERE original_transaction_id = p_otx FOR UPDATE;
  SELECT (last_gift_reset_at IS NULL OR last_gift_reset_at < p_period_start) INTO v_reset_needed
  FROM billing.credit_accounts WHERE original_transaction_id = p_otx;

  IF v_reset_needed THEN
    -- reset gift to 88
    UPDATE billing.credit_accounts
    SET gift_balance = 88,
        last_gift_reset_at = p_period_start,
        current_anon_user_id = p_anon,
        updated_at = now()
    WHERE original_transaction_id = p_otx;

    -- ledger +88 gift
    INSERT INTO billing.credit_ledger (
      original_transaction_id, entry_type, direction, amount,
      balance_after_gift, balance_after_paid, reason, anon_user_id, operation_id
    )
    SELECT p_otx, 'gift', 'in', 88, ca.gift_balance, ca.paid_balance, 'subscription_init', p_anon, gen_random_uuid()
    FROM billing.credit_accounts ca WHERE ca.original_transaction_id = p_otx;
  END IF;
END$$;

-- Expire gift for subscriptions no longer active (safe to run daily)
CREATE OR REPLACE FUNCTION billing.expire_gift_for_expired()
RETURNS integer LANGUAGE plpgsql AS $$
DECLARE
  v_rows int := 0;
  v_op uuid := gen_random_uuid();
BEGIN
  WITH expired AS (
    SELECT s.original_transaction_id
    FROM billing.subscriptions s
    WHERE s.status IN ('expired','revoked') OR now() >= s.current_period_end
  ), sel AS (
    SELECT ca.original_transaction_id, ca.gift_balance AS gift_before, ca.paid_balance
    FROM billing.credit_accounts ca
    JOIN expired e ON e.original_transaction_id = ca.original_transaction_id
    WHERE ca.gift_balance > 0
  ), upd AS (
    UPDATE billing.credit_accounts ca
    SET gift_balance = 0,
        updated_at = now()
    FROM sel
    WHERE ca.original_transaction_id = sel.original_transaction_id
    RETURNING ca.original_transaction_id, sel.gift_before, ca.paid_balance
  )
  INSERT INTO billing.credit_ledger (
    original_transaction_id, entry_type, direction, amount,
    balance_after_gift, balance_after_paid, reason, operation_id
  )
  SELECT u.original_transaction_id, 'gift', 'out', u.gift_before,
         0, u.paid_balance, 'gift_expire', v_op
  FROM upd u;

  GET DIAGNOSTICS v_rows = ROW_COUNT;
  RETURN v_rows;
END$$;
