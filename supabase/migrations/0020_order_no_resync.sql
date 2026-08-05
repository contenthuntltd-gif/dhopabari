-- ============================================================
-- Resync the auto order-number to a value an admin typed.
--
-- Order numbers come from `order_no_seq` (default: '#DB' || nextval(...)).
-- When an admin edits an order's ID to e.g. #DB50, the NEXT new order
-- should continue from there (#DB51, #DB52, …). This function lets the
-- app set the sequence's current value; setval(..., true) means the next
-- nextval() returns n+1.
--
-- Staff-only (checked inside, SECURITY DEFINER so it can touch the seq).
-- ============================================================
create or replace function public.set_order_no_seq(n bigint)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_staff() then
    raise exception 'only staff may resync the order number';
  end if;
  -- greatest(n, 1): sequences cannot be set below 1.
  perform setval('public.order_no_seq', greatest(n, 1), true);
end;
$$;

grant execute on function public.set_order_no_seq(bigint) to authenticated;
