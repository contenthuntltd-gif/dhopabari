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
