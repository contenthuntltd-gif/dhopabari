-- ============================================================
-- 0013 — Order push trigger
--
-- Fires the `send-push` Edge Function on every order INSERT/UPDATE via pg_net,
-- passing { type, record, old_record } — the same shape a Supabase Database
-- Webhook would send. The function decides who to notify.
--
-- Requires: the `send-push` function deployed with "Verify JWT" OFF (so this
-- unauthenticated call is accepted).
--
-- Safe to re-run.
-- ============================================================

create extension if not exists pg_net with schema extensions;

create or replace function public.notify_order_push()
returns trigger
language plpgsql
security definer
as $$
begin
  perform net.http_post(
    url := 'https://stxzqmrnezedphysmczq.supabase.co/functions/v1/send-push',
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := jsonb_build_object(
      'type', TG_OP,
      'record', to_jsonb(NEW),
      'old_record', case when TG_OP = 'UPDATE' then to_jsonb(OLD) else null end
    )
  );
  return NEW;
end;
$$;

drop trigger if exists trg_order_push on public.orders;
create trigger trg_order_push
  after insert or update on public.orders
  for each row execute function public.notify_order_push();
