-- ============================================================
-- Dhopa Bari — promote the first admin
--
-- Chicken-and-egg: only an admin can create staff, so the very first
-- admin has to be made by hand, once.
--
-- DO NOT try to INSERT into auth.users directly — Supabase hashes
-- passwords and maintains identity rows there, and a hand-written insert
-- produces an account that cannot log in. Instead:
--
--   1. Open the app and register normally (phone + password) with the
--      number you want to be the admin.
--   2. Put that number in the line below, in the same E.164 form the app
--      stores: +880 followed by the 10 digits (drop the leading 0).
--         01712345678  ->  +8801712345678
--   3. Run this file in the Supabase SQL editor.
--
-- After this, every other admin and rider is created from the admin panel
-- and you never need to touch SQL again.
-- ============================================================

do $$
declare
  target_phone text := '+8801XXXXXXXXX';   -- <<< EDIT THIS
  hit          int;
begin
  if target_phone = '+8801XXXXXXXXX' then
    raise exception 'Edit target_phone first — put your real number in, then re-run.';
  end if;

  update public.profiles
     set role = 'admin'
   where phone = target_phone;

  get diagnostics hit = row_count;

  if hit = 0 then
    raise exception
      'No profile with phone %. Register through the app first, then re-run. (Stored numbers look like +8801712345678.)',
      target_phone;
  end if;

  raise notice 'Promoted % to admin.', target_phone;
end$$;
