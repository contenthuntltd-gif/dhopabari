-- ============================================================
-- Enable Supabase Realtime for the catalog price list.
--
-- With this, any admin edit to catalog_items (price change, new item,
-- delete, reorder) is pushed live to every open customer app and the
-- website, so the price list updates INSTANTLY — no restart, no
-- pull-to-refresh. The client subscribes in Catalog.subscribeLive().
--
-- Idempotent: safe to run more than once.
-- ============================================================
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'catalog_items'
  ) then
    alter publication supabase_realtime add table public.catalog_items;
  end if;
end $$;

-- DELETE events carry the full old row (so a deleted item disappears live).
alter table public.catalog_items replica identity full;
