-- ============================================================
-- 0010 — Customer-initiated order cancellation
--
-- A customer may cancel their OWN order, but only while it is still fresh:
-- status = 'Confirmed' and no rider assigned yet. Once staff/rider act on
-- it (status advances or a rider is assigned), the database rejects the
-- change — matching the app's `MockOrder.isCancellable` rule.
--
-- RLS combines multiple permissive UPDATE policies with OR, so this sits
-- alongside `orders_update_staff` (staff can still do everything).
--
-- Safe to re-run.
-- ============================================================

drop policy if exists "orders_cancel_own" on public.orders;
create policy "orders_cancel_own"
  on public.orders for update
  using (
    customer_id = auth.uid()
    and status = 'Confirmed'
    and rider_id is null
  )
  with check (
    customer_id = auth.uid()
    and status = 'Cancelled'
  );
