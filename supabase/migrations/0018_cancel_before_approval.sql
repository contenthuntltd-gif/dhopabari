-- ============================================================
-- 0018 — Customer cancel only BEFORE admin approval
--
-- Tightens `orders_cancel_own` (0010): a customer may cancel only while the
-- order is Confirmed, NOT yet approved by an admin, and has no rider. Once the
-- shop approves it, the customer can no longer cancel.
--
-- Safe to re-run.
-- ============================================================

drop policy if exists "orders_cancel_own" on public.orders;
create policy "orders_cancel_own"
  on public.orders for update
  using (
    customer_id = auth.uid()
    and status = 'Confirmed'
    and approved = false
    and rider_id is null
  )
  with check (
    customer_id = auth.uid()
    and status = 'Cancelled'
  );
