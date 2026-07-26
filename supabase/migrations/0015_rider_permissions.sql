-- ============================================================
-- 0015 — Granular rider permissions
--
-- Beyond `can_see_customers` (0008), an admin can now grant each rider access
-- to the pickup, delivery and collection sections individually. Core rider
-- functions default ON; customer access stays OFF by default.
--
-- Safe to re-run.
-- ============================================================

alter table public.profiles add column if not exists can_see_pickup   boolean not null default true;
alter table public.profiles add column if not exists can_see_delivery boolean not null default true;
alter table public.profiles add column if not exists can_see_collect  boolean not null default true;

-- ------------------------------------------------------------
-- Riders may create customers but never delete them. `profiles_update_staff`
-- (0002) lets any staff member update any profile row, including soft-delete
-- (deleted_at) — this guard narrows that one column to admin only, mirroring
-- guard_role_change's pattern. Hard delete is separately admin-gated in the
-- admin-manage-user Edge Function.
-- ------------------------------------------------------------

create or replace function public.guard_customer_delete()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.deleted_at is distinct from old.deleted_at
     and auth.uid() is not null
     and not public.is_admin() then
    raise exception 'Only an admin can delete or restore a customer';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_guard_delete on public.profiles;
create trigger trg_profiles_guard_delete
  before update on public.profiles
  for each row execute function public.guard_customer_delete();
