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
