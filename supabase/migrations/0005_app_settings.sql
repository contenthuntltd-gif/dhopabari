-- ============================================================
-- Dhopa Bari — app_settings (key/value config the admin controls)
--
-- Currently holds the two WhatsApp support numbers shown on the customer
-- "যোগাযোগ" tab. Everyone may read (the app needs them); only staff write.
--
-- Run after 0002 (needs public.is_staff()).
-- ============================================================

create table if not exists public.app_settings (
  key        text primary key,
  value      text,
  updated_at timestamptz not null default now()
);

alter table public.app_settings enable row level security;

drop policy if exists "settings_read_all" on public.app_settings;
create policy "settings_read_all"
  on public.app_settings for select
  using (true);

drop policy if exists "settings_write_staff" on public.app_settings;
create policy "settings_write_staff"
  on public.app_settings for all
  using (public.is_staff())
  with check (public.is_staff());

insert into public.app_settings (key, value) values
  ('support_whatsapp_1', '8801700000000'),
  ('support_whatsapp_2', '')
on conflict (key) do nothing;
