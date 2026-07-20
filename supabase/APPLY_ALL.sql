-- ============================================================
-- Dhopa Bari — সব মাইগ্রেশন একসাথে (APPLY_ALL)
-- Supabase Dashboard → SQL Editor → পুরোটা paste করে Run চাপুন।
-- Idempotent: একাধিকবার চালালেও সমস্যা নেই।
-- (0003 বাদ — ডেমো অ্যাডমিন 01700000001 আগে থেকেই আছে)
-- ============================================================

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

-- ============================================================
-- Dhopa Bari — Orders + staff (admin/rider) access
--
-- Builds on 0001 (profiles). Adds:
--   • is_staff() / is_admin() helpers  — SECURITY DEFINER so policies can
--     read a caller's role WITHOUT recursing into profiles' own RLS
--   • public.orders                    — real order history, replacing the
--                                        in-app AdminMockData lists
--   • staff RLS policies               — admin & rider can read every
--                                        profile and every order, and can
--                                        place an order on a customer's
--                                        behalf (orders.placed_by)
--
-- Run once, in order, after 0001.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Role helpers
--
-- A policy on `profiles` that does `select role from profiles ...` would
-- re-trigger profiles' RLS and recurse forever. SECURITY DEFINER runs the
-- lookup as the function owner, bypassing RLS, which breaks the cycle.
-- `set search_path` is required on SECURITY DEFINER functions so a caller
-- cannot shadow `public` with their own schema.
-- ------------------------------------------------------------

create or replace function public.current_role()
returns public.user_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role in ('admin', 'rider') from public.profiles where id = auth.uid()),
    false
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role = 'admin' from public.profiles where id = auth.uid()),
    false
  );
$$;

-- ------------------------------------------------------------
-- 2. Profile additions
--
-- `blocked` backs the admin panel's block/unblock action; `created_by`
-- records which staff member registered a walk-in customer (null when the
-- customer signed themselves up).
-- ------------------------------------------------------------

alter table public.profiles
  add column if not exists blocked    boolean not null default false,
  add column if not exists created_by uuid references auth.users (id) on delete set null;

create index if not exists idx_profiles_role  on public.profiles (role);
create index if not exists idx_profiles_phone on public.profiles (phone);

-- ------------------------------------------------------------
-- 3. Orders
--
-- `customer_id` is who the order is FOR. `placed_by` is who created it —
-- the same person for a normal self-service order, or the admin/rider who
-- entered it on the customer's behalf. Keeping both means a customer's
-- history is complete regardless of who typed it in, which is exactly the
-- "history user base thekei jabe" requirement.
--
-- `items` is jsonb rather than a child table on purpose: an order must
-- preserve what was bought at the price charged AT THE TIME. A foreign key
-- to a live catalog would silently rewrite past orders when prices change.
-- ------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_type where typname = 'order_status') then
    create type public.order_status as enum (
      'Confirmed',
      'Picked Up',
      'Cleaning',
      'Packaging Done',
      'Out for Delivery',
      'Delivered',
      'Cancelled'
    );
  end if;
end$$;

-- Human-readable order numbers (#DB123456), matching the existing UI format.
create sequence if not exists public.order_number_seq start with 123456;

create table if not exists public.orders (
  id             uuid primary key default gen_random_uuid(),
  order_no       text unique not null default ('#DB' || nextval('public.order_number_seq')),

  customer_id    uuid not null references public.profiles (id) on delete cascade,
  placed_by      uuid references public.profiles (id) on delete set null,
  rider_id       uuid references public.profiles (id) on delete set null,

  status         public.order_status not null default 'Confirmed',
  service        text not null,
  category       text,
  items          jsonb not null default '[]'::jsonb,
  pieces         integer not null default 0,
  total          integer not null default 0,

  address        text,
  area           text,
  payment_method text not null default 'Cash on Delivery',
  note           text,

  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  delivered_at   timestamptz
);

comment on table  public.orders            is 'Customer orders. Source of truth for order history.';
comment on column public.orders.placed_by  is 'Who created the order: the customer, or the admin/rider who entered it for them.';
comment on column public.orders.items      is 'Snapshot of line items at the price charged; deliberately not FK-linked to the live catalog.';

create index if not exists idx_orders_customer on public.orders (customer_id, created_at desc);
create index if not exists idx_orders_rider    on public.orders (rider_id, created_at desc);
create index if not exists idx_orders_status   on public.orders (status);

drop trigger if exists trg_orders_updated_at on public.orders;
create trigger trg_orders_updated_at
  before update on public.orders
  for each row execute function public.set_updated_at();

-- Stamp delivered_at exactly when an order first reaches 'Delivered'.
create or replace function public.stamp_delivered_at()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'Delivered' and coalesce(old.status, 'Confirmed') <> 'Delivered' then
    new.delivered_at = now();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_orders_delivered_at on public.orders;
create trigger trg_orders_delivered_at
  before update on public.orders
  for each row execute function public.stamp_delivered_at();

-- ------------------------------------------------------------
-- 4. RLS — profiles
--
-- 0001 gave every user access to their own row only. Staff need to see the
-- whole customer base, so we ADD staff policies alongside. Postgres ORs
-- multiple permissive policies together, so the 0001 "own row" policies
-- keep working untouched for customers.
-- ------------------------------------------------------------

drop policy if exists "profiles_select_staff" on public.profiles;
create policy "profiles_select_staff"
  on public.profiles for select
  using (public.is_staff());

drop policy if exists "profiles_insert_staff" on public.profiles;
create policy "profiles_insert_staff"
  on public.profiles for insert
  with check (public.is_staff());

drop policy if exists "profiles_update_staff" on public.profiles;
create policy "profiles_update_staff"
  on public.profiles for update
  using (public.is_staff())
  with check (public.is_staff());

-- A customer must not be able to promote themselves to admin. The own-row
-- update policy from 0001 would otherwise allow `update profiles set
-- role='admin' where id = auth.uid()`. This trigger is the guard: only
-- an existing admin may change a role.
create or replace function public.guard_role_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- auth.uid() is null when the change comes from the service_role key
  -- (Edge Functions) or the SQL editor — those are trusted server-side
  -- paths and must NOT be blocked; this guard exists only to stop a
  -- signed-in client from promoting themselves.
  if new.role is distinct from old.role
     and auth.uid() is not null
     and not public.is_admin() then
    raise exception 'Only an admin can change a user role';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_guard_role on public.profiles;
create trigger trg_profiles_guard_role
  before update on public.profiles
  for each row execute function public.guard_role_change();

-- ------------------------------------------------------------
-- 5. RLS — orders
-- ------------------------------------------------------------

alter table public.orders enable row level security;

-- Customers see their own orders; staff see everything.
drop policy if exists "orders_select" on public.orders;
create policy "orders_select"
  on public.orders for select
  using (customer_id = auth.uid() or public.is_staff());

-- A customer may only create orders for themselves. Staff may create an
-- order for any customer — this is the "admin/rider places an order from
-- the user's profile" path.
drop policy if exists "orders_insert" on public.orders;
create policy "orders_insert"
  on public.orders for insert
  with check (
    (customer_id = auth.uid() and placed_by = auth.uid())
    or (public.is_staff() and placed_by = auth.uid())
  );

-- Only staff change orders after creation (status moves, rider assignment).
drop policy if exists "orders_update_staff" on public.orders;
create policy "orders_update_staff"
  on public.orders for update
  using (public.is_staff())
  with check (public.is_staff());

drop policy if exists "orders_delete_admin" on public.orders;
create policy "orders_delete_admin"
  on public.orders for delete
  using (public.is_admin());

-- ------------------------------------------------------------
-- 6. Customer summary view
--
-- Powers the admin customer list (order count + lifetime spend) in one
-- round trip instead of an N+1 query per customer. security_invoker makes
-- the view respect the caller's RLS rather than the view owner's.
-- ------------------------------------------------------------

create or replace view public.customer_summary
with (security_invoker = true)
as
select
  p.id,
  p.name,
  p.phone,
  p.whatsapp_number,
  p.area,
  p.local_address,
  p.role,
  p.blocked,
  p.created_at,
  count(o.id) filter (where o.status <> 'Cancelled')                as total_orders,
  coalesce(sum(o.total) filter (where o.status <> 'Cancelled'), 0)  as total_spent,
  max(o.created_at)                                                 as last_order_at
from public.profiles p
left join public.orders o on o.customer_id = p.id
group by p.id;

comment on view public.customer_summary is 'Profile plus aggregated order stats, for the admin customer list.';

-- ============================================================
-- Dhopa Bari — catalog_items (official price list)
--
-- The single source of truth for laundry items and prices. Seeded from
-- the official printed Dhopa Bari price list; after this, the admin
-- panel edits THESE rows and every client (customer app, rider app,
-- website, receipts, APIs) reads the same data.
--
-- Note: orders store an items SNAPSHOT (orders.items jsonb) at the price
-- charged at the time — editing this table changes future orders only,
-- never history.
--
-- Run after 0002. Idempotent.
-- ============================================================

create table if not exists public.catalog_items (
  id          text primary key,          -- stable slug, e.g. 'shirt'
  category    text not null,             -- Men | Women | Kids | Home
  name        text not null,
  name_bn     text not null,
  wash_price  integer not null check (wash_price >= 0),
  dry_price   integer not null check (dry_price >= 0),
  enabled     boolean not null default true,
  sort_order  integer not null default 0,
  updated_at  timestamptz not null default now()
);

comment on table public.catalog_items is 'Official Dhopa Bari price list — single source of truth for items/prices.';

drop trigger if exists trg_catalog_updated_at on public.catalog_items;
create trigger trg_catalog_updated_at
  before update on public.catalog_items
  for each row execute function public.set_updated_at();

-- RLS: everyone (even signed-out browsers on the website) may read the
-- price list; only staff may change it.
alter table public.catalog_items enable row level security;

drop policy if exists "catalog_select_all" on public.catalog_items;
create policy "catalog_select_all"
  on public.catalog_items for select
  using (true);

drop policy if exists "catalog_write_staff" on public.catalog_items;
create policy "catalog_write_staff"
  on public.catalog_items for all
  using (public.is_staff())
  with check (public.is_staff());

-- ── Seed: the official price list, verbatim ──
-- upsert so re-running refreshes names/order but keeps admin price edits
-- ONLY if you remove the price columns from the update — here prices are
-- reset to the official list on purpose (this migration IS the source).
insert into public.catalog_items (id, category, name, name_bn, wash_price, dry_price, sort_order) values
  ('shirt',           'Men',   'Shirt',               'শার্ট',             50,  60,  10),
  ('pant',            'Men',   'Pant',                'প্যান্ট',           50,  60,  20),
  ('tshirt',          'Men',   'T-Shirt',             'টি-শার্ট',          50,  60,  30),
  ('three_piece',     'Women', 'Three-Piece / Kamiz', 'থ্রি-পিস / কামিজ', 100, 120,  40),
  ('kids_wear',       'Kids',  'Kids Wear',           'বাচ্চাদের পোশাক',   50,  50,  50),
  ('panjabi',         'Men',   'Panjabi',             'পাঞ্জাবি',          60,  70,  60),
  ('pajama',          'Men',   'Pajama',              'পায়জামা',          50,  60,  70),
  ('borka',           'Women', 'Borka',               'বোরকা',            100, 120,  80),
  ('jubbah',          'Men',   'Jubbah',              'জুব্বা',            70,  80,  90),
  ('fatua',           'Men',   'Fatua',               'ফতুয়া',            50,  60, 100),
  ('lungi',           'Men',   'Lungi',               'লুঙ্গি',            50,  50, 110),
  ('dupatta',         'Women', 'Dupatta',             'ওড়না',             40,  40, 120),
  ('hijab',           'Women', 'Hijab',               'হিজাব',            50,  50, 130),
  ('blouse',          'Women', 'Blouse / Petticoat',  'ব্লাউজ / পেটিকোট',  50,  60, 140),
  ('bedsheet',        'Home',  'Bed Sheet',           'বেডশিট',           80,  80, 150),
  ('pillow_cover',    'Home',  'Pillow Cover',        'বালিশের কভার',      25,  25, 160),
  ('towel',           'Home',  'Towel',               'তোয়ালে',           50,  50, 170),
  ('saree',           'Women', 'Saree',               'শাড়ি',            300, 300, 180),
  ('blazer',          'Men',   'Blazer / Coat',       'ব্লেজার / কোট',    250, 250, 190),
  ('suit',            'Men',   'Suit',                'স্যুট',            300, 300, 200),
  ('koti',            'Men',   'Waistcoat (Koti)',    'কটি',              130, 130, 210),
  ('tie',             'Men',   'Tie',                 'টাই',               40,  40, 220),
  ('lehenga',         'Women', 'Lehenga / Gown',      'লেহেঙ্গা / গাউন',  450, 450, 230),
  ('sweater',         'Men',   'Sweater',             'সোয়েটার',         120, 120, 240),
  ('jacket',          'Men',   'Jacket',              'জ্যাকেট',          200, 200, 250),
  ('shawl',           'Men',   'Shawl',               'শাল',              140, 140, 260),
  ('blanket_regular', 'Home',  'Blanket (Regular)',   'কম্বল (রেগুলার)',  280, 280, 270),
  ('blanket_heavy',   'Home',  'Blanket (Heavy)',     'কম্বল (ভারী)',     380, 380, 280),
  ('curtain',         'Home',  'Curtain',             'পর্দা',            150, 150, 290),
  ('sofa_cover',      'Home',  'Sofa Cover',          'সোফা কভার',        100, 100, 300),
  ('cushion_cover',   'Home',  'Cushion Cover',       'কুশন কভার',         25,  25, 310),
  ('table_cloth',     'Home',  'Table Cloth',         'টেবিল ক্লথ',        70,  70, 320)
on conflict (id) do update set
  category   = excluded.category,
  name       = excluded.name,
  name_bn    = excluded.name_bn,
  wash_price = excluded.wash_price,
  dry_price  = excluded.dry_price,
  sort_order = excluded.sort_order;
