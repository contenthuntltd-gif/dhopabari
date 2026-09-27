-- ============================================================
-- 0023 — Admin-editable customer name / phone on a single order.
--
-- The name and phone shown on an order come from the customer's profile
-- (a join on customer_id). That is right most of the time, but it means an
-- admin who fixes a typo on one order would rewrite the customer's account
-- and silently change every past order and receipt with it.
--
-- So the correction is stored ON THE ORDER instead. Both columns are
-- nullable, and null keeps the old behaviour exactly: fall back to the
-- profile. Only an order an admin has actually edited carries a value.
--
-- The admin UI still offers to push the change to the profile as well —
-- that path uses the existing profiles update, not these columns.
--
-- The price (orders.total) needs no new column; it already exists and the
-- orders_update_staff policy from 0002 already allows staff to change it.
-- ============================================================

alter table public.orders
  add column if not exists customer_name  text,
  add column if not exists customer_phone text;

comment on column public.orders.customer_name  is
  'Admin override for the name shown on THIS order. Null = use the profile.';
comment on column public.orders.customer_phone is
  'Admin override for the phone shown on THIS order. Null = use the profile.';
