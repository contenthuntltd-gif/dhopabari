-- ============================================================
-- Dhopa Bari — order recycle bin (soft delete)
--
-- Deleting an order from the admin panel no longer removes it immediately.
-- Instead it is soft-deleted (deleted_at set) and moves to a recycle bin,
-- from which an admin can Restore it or delete it Permanently.
--
-- Normal order lists filter out rows where deleted_at is not null.
-- Idempotent.
-- ============================================================

alter table public.orders add column if not exists deleted_at timestamptz;
create index if not exists idx_orders_deleted on public.orders (deleted_at);
