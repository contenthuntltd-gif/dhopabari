-- ============================================================
-- 0011 — Realtime order alerts (admin + rider chime/banner)
--
-- 1. Add `orders` to the supabase_realtime publication so INSERT/UPDATE
--    events stream to subscribed staff clients (RLS still applies — staff
--    see everything via `orders_select`).
-- 2. REPLICA IDENTITY FULL so an UPDATE payload carries the OLD row too,
--    letting the app tell a real status change from other column bumps.
--
-- Safe to re-run.
-- ============================================================

do $$
begin
  begin
    alter publication supabase_realtime add table public.orders;
  exception
    when duplicate_object then null;   -- already in the publication
    when undefined_object then null;   -- publication missing (unusual) — ignore
  end;
end $$;

alter table public.orders replica identity full;
