-- ============================================================
-- Dhopa Bari — cash settlement (rider hands the day's COD cash to office)
--
-- Adds a per-order "settled" flag. A Cash-on-Delivery order that has been
-- Delivered holds cash the rider collected; when the rider hands it over at
-- the office, an admin ticks it settled. The হিসাব (accounts) screen lists
-- unsettled COD-delivered orders grouped by rider.
--
-- Run after 0002. Idempotent.
-- ============================================================

alter table public.orders
  add column if not exists cash_settled boolean not null default false,
  add column if not exists settled_at   timestamptz;

-- Speeds up the "unsettled COD delivered" lookup.
create index if not exists idx_orders_unsettled
  on public.orders (cash_settled, status)
  where cash_settled = false;
