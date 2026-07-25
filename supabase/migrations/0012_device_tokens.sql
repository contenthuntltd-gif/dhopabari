-- ============================================================
-- 0012 — Device push tokens (FCM)
--
-- One row per phone that has opted into push, tied to the signed-in user.
-- The `send-push` Edge Function (service role) reads these to target a user
-- when their order changes. Users manage only their own rows via RLS.
--
-- Safe to re-run.
-- ============================================================

create table if not exists public.device_tokens (
  token      text primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  platform   text not null default 'android',
  updated_at timestamptz not null default now()
);

create index if not exists device_tokens_user_idx on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

-- A user may read/insert/update/delete only their own device tokens. The
-- Edge Function uses the service role, which bypasses RLS to read everyone's.
drop policy if exists "device_tokens_own" on public.device_tokens;
create policy "device_tokens_own"
  on public.device_tokens for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
