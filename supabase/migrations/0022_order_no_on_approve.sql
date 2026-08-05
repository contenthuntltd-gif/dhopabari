-- ============================================================
-- Assign the order number ONLY on admin approval (not at order time).
--
-- Before: every new order got '#DB<n>' from a column default at INSERT, so
-- unapproved / cancelled orders consumed serial numbers and left gaps.
-- After: a new order has order_no = NULL ("অপেক্ষমাণ"); when an admin
-- approves it, a trigger assigns the next number from order_no_seq. This
-- keeps the approved-order serial clean and gap-free.
-- ============================================================

-- 1. Stop auto-numbering at insert.
alter table public.orders alter column order_no drop default;

-- 2. On approval (approved flips to true) assign the next serial, but only
--    if one hasn't already been set (e.g. an admin typed it manually).
create or replace function public.assign_order_no_on_approve()
returns trigger
language plpgsql
as $$
begin
  if new.approved
     and (old.approved is distinct from new.approved)
     and (new.order_no is null or new.order_no = '') then
    new.order_no := '#DB' || nextval('public.order_no_seq')::text;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_assign_order_no on public.orders;
create trigger trg_assign_order_no
  before update on public.orders
  for each row
  execute function public.assign_order_no_on_approve();
