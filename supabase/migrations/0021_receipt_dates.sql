-- ============================================================
-- Admin-editable receipt dates.
--
-- Lets an admin set the pickup / delivery / payment dates on an order
-- (e.g. backdate a memo by a few days). delivered_at already exists; add
-- the pickup and paid timestamps. All nullable — an unset date means the
-- receipt falls back to "now" as before.
-- ============================================================
alter table public.orders
  add column if not exists picked_up_at timestamptz,
  add column if not exists paid_at timestamptz;
