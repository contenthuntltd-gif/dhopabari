-- ============================================================
-- 0017 — Order approval gate + #DB1001 order-code series
--
-- 1. `approved` flag: an order must be approved by an admin before a rider
--    can be assigned to it.
-- 2. New order numbers run #DB1001, #DB1002, … (was #DB2026NN).
--
-- Safe to re-run (but the setval resets the counter — only run the counter
-- reset on a fresh start / after clearing test orders).
-- ============================================================

alter table public.orders add column if not exists approved boolean not null default false;

-- Order code: #DB1001, #DB1002, …
create sequence if not exists public.order_no_seq;
select setval('public.order_no_seq', 1000, true);  -- next nextval() -> 1001
alter table public.orders
  alter column order_no set default ('#DB' || nextval('public.order_no_seq')::text);
