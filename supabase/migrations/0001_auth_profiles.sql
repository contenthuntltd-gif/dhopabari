-- ============================================================
-- Dhopa Bari — Supabase Auth + profiles
-- Run once (via authorized Supabase MCP or the SQL editor).
--
-- Supabase Auth owns `auth.users` (identity: phone, email, google).
-- We keep app-level customer data in `public.profiles`, one row per
-- auth user, auto-created on signup and protected by RLS so a user can
-- only ever read/update their own row.
-- ============================================================

-- --- Role enum (customer / rider / admin), mirrors backend Prisma Role ---
do $$
begin
  if not exists (select 1 from pg_type where typname = 'user_role') then
    create type public.user_role as enum ('customer', 'rider', 'admin');
  end if;
end$$;

-- --- Profiles table ---
create table if not exists public.profiles (
  id              uuid primary key references auth.users (id) on delete cascade,
  role            public.user_role not null default 'customer',
  name            text,
  phone           text,
  whatsapp_number text,
  area            text,
  local_address   text,
  avatar_url      text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

comment on table public.profiles is 'App profile for each auth user (customer/rider/admin).';

-- --- keep updated_at fresh ---
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- --- Auto-create a profile row whenever a new auth user signs up ---
-- Pulls name/phone from the signup metadata the Flutter app sends
-- (Google gives full_name/avatar; phone-OTP gives the phone number).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, phone, whatsapp_number, area, local_address, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'name', new.raw_user_meta_data ->> 'full_name'),
    coalesce(new.phone, new.raw_user_meta_data ->> 'phone'),
    new.raw_user_meta_data ->> 'whatsapp_number',
    new.raw_user_meta_data ->> 'area',
    new.raw_user_meta_data ->> 'local_address',
    coalesce(new.raw_user_meta_data ->> 'avatar_url', new.raw_user_meta_data ->> 'picture')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- --- Row Level Security: a user only sees/edits their own profile ---
alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Insert is normally done by the signup trigger (security definer, bypasses
-- RLS). This policy also lets the client upsert its own row if needed.
drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);
