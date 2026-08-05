-- ============================================================
-- Dhopa Bari — push every order (insert/update) to a Google Sheet.
--
-- Uses pg_net (net.http_post) to POST the order to your Apps Script Web App,
-- which upserts it as a row keyed by the order UUID.
--
-- BEFORE RUNNING: paste your Apps Script Web app URL below (ends with /exec).
-- Run this whole script in Supabase → SQL Editor.
-- ============================================================

-- pg_net must be enabled (it already is if push notifications work).
create extension if not exists pg_net with schema extensions;

create or replace function public.sync_order_to_sheet()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  -- Apps Script Web App URL (Dhopa Bari orders → Google Sheet).
  sheet_url text := 'https://script.google.com/macros/s/AKfycbyfnqjBM9PYPSEkHxoOuJ67fXKDyEpsxdxfrg-LoYU4uEc7YLsAlBMO55ngy_8FRkc-/exec';
  cust record;
  rid  record;
  items_text text;
  payload jsonb;
begin
  select name, phone into cust from public.profiles where id = new.customer_id;
  select name       into rid  from public.profiles where id = new.rider_id;

  -- Build a readable items summary from the jsonb snapshot, e.g. "শার্ট x২".
  select string_agg(
           coalesce(it->>'name_bn', it->>'name', 'আইটেম') || ' x' || coalesce(it->>'qty', '1'),
           ', ')
    into items_text
  from jsonb_array_elements(coalesce(new.items, '[]'::jsonb)) as it;

  payload := jsonb_build_object(
    'uuid',           new.id,
    'order_no',       coalesce(nullif(new.order_no, ''), 'অপেক্ষমাণ'),
    'customer_name',  coalesce(cust.name, ''),
    'customer_phone', coalesce(cust.phone, ''),
    'service',        coalesce(new.service, ''),
    'category',       coalesce(new.category, ''),
    'items',          coalesce(items_text, ''),
    'pieces',         coalesce(new.pieces, 0),
    'total',          coalesce(new.total, 0),
    'status',         coalesce(new.status, ''),
    'approved',       coalesce(new.approved, false),
    'rider_name',     coalesce(rid.name, ''),
    'address',        coalesce(new.address, ''),
    'payment_method', coalesce(new.payment_method, ''),
    'created_at',     to_char(new.created_at at time zone 'Asia/Dhaka', 'YYYY-MM-DD HH24:MI')
  );

  perform net.http_post(
    url     := sheet_url,
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body    := payload
  );

  return new;
end;
$$;

drop trigger if exists trg_sync_order_to_sheet on public.orders;
create trigger trg_sync_order_to_sheet
  after insert or update on public.orders
  for each row execute function public.sync_order_to_sheet();
