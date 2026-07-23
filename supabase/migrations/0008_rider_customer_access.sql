-- ============================================================
-- Dhopa Bari — per-rider customer-list access
--
-- A rider can browse the full customer list (and place orders from it) ONLY
-- when an admin grants it. Off by default. Toggled from the rider's detail
-- screen in the admin panel.
-- Idempotent.
-- ============================================================

alter table public.profiles
  add column if not exists can_see_customers boolean not null default false;
