-- ============================================================
-- Dhopa Bari — office order code format
--
-- New orders are numbered #DB2026 + a zero-padded counter:
--   #DB202601, #DB202602, #DB202603 …
-- Existing orders keep their old #DB123xxx numbers.
-- ============================================================

create sequence if not exists public.order_no_2026_seq start with 1;

alter table public.orders
  alter column order_no set default ('#DB2026' || lpad(nextval('public.order_no_2026_seq')::text, 2, '0'));
