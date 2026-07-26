-- ============================================================
-- 0016 — Bulk catalog items + Hotel category
--
-- Adds/updates the full Men, Home, Kids and (new) Hotel item lists. Women is
-- left untouched. Uses UPSERT so nothing existing is deleted — the shop tunes
-- the rest (names, prices, extra items) from the admin panel afterwards.
--
-- Pure data: no app rebuild / deploy needed — the app reads catalog_items and
-- the category list (app_settings) live on next launch.
--
-- Safe to re-run.
-- ============================================================

-- 1. Register the Hotel category (alongside Men/Women/Kids/Home) so it shows
--    as a tab in the customer + admin apps. CatalogMeta reads this JSON.
insert into public.app_settings (key, value) values (
  'catalog_categories',
  '[{"id":"men","name":"Men","nameBn":"পুরুষ","enabled":true},{"id":"women","name":"Women","nameBn":"মহিলা","enabled":true},{"id":"kids","name":"Kids","nameBn":"শিশু","enabled":true},{"id":"home","name":"Home","nameBn":"ঘরের কাপড়","enabled":true},{"id":"hotel","name":"Hotel","nameBn":"হোটেল","enabled":true}]'
)
on conflict (key) do update set value = excluded.value;

-- 2. Items — insert new, update existing (by id).
insert into public.catalog_items (id, category, name, name_bn, wash_price, dry_price, sort_order, enabled) values
  -- ── পুরুষ / Men ──
  ('shirt',            'Men',   'Shirt',              'শার্ট',              50,  60,  1,  true),
  ('tshirt',           'Men',   'T-Shirt',            'টি-শার্ট',           50,  60,  2,  true),
  ('pant',             'Men',   'Pant',               'প্যান্ট',            50,  60,  3,  true),
  ('jeans_pant',       'Men',   'Jeans Pant',         'জিন্স প্যান্ট',      60,  70,  4,  true),
  ('panjabi',          'Men',   'Regular Panjabi',    'পাঞ্জাবি (রেগুলার)', 50,  60,  5,  true),
  ('panjabi_starched', 'Men',   'Starched Panjabi',   'পাঞ্জাবি (মাড়সহ)',  70,  80,  6,  true),
  ('jubbah',           'Men',   'Jubbah',             'জুব্বা',             70,  80,  7,  true),
  ('fatua',            'Men',   'Fatua',              'ফতুয়া',             50,  60,  8,  true),
  ('pajama',           'Men',   'Pajama',             'পায়জামা',           50,  60,  9,  true),
  ('lungi',            'Men',   'Lungi',              'লুঙ্গি',             50,  50,  10, true),
  ('blazer',           'Men',   'Blazer',             'ব্লেজার',            250, 250, 11, true),
  ('coat',             'Men',   'Coat',               'কোট',                250, 250, 12, true),
  ('suit',             'Men',   'Suit',               'স্যুট',              300, 300, 13, true),
  ('koti',             'Men',   'Waistcoat',          'কটি',                130, 130, 14, true),
  ('tie',              'Men',   'Tie',                'টাই',                40,  40,  15, true),
  ('sweater',          'Men',   'Sweater',            'সোয়েটার',           120, 120, 16, true),
  ('jacket',           'Men',   'Jacket',             'জ্যাকেট',            200, 200, 17, true),
  -- ── ঘরের কাপড় / Home ──
  ('bedsheet',           'Home', 'Bed Sheet',          'বেডশিট / চাদর',      80,  80,  101, true),
  ('pillow_cover',       'Home', 'Pillow Cover',       'বালিশের কভার',       25,  25,  102, true),
  ('bolster_cover',      'Home', 'Bolster Cover',      'বোলস্টার কভার',      30,  30,  103, true),
  ('towel',              'Home', 'Towel',              'তোয়ালে',            50,  50,  104, true),
  ('hand_towel',         'Home', 'Hand Towel',         'হাত তোয়ালে',        30,  30,  105, true),
  ('bath_towel',         'Home', 'Bath Towel',         'বাথ তোয়ালে',        60,  60,  106, true),
  ('blanket_regular',    'Home', 'Blanket (Regular)',  'কম্বল (রেগুলার)',    280, 280, 107, true),
  ('blanket_heavy',      'Home', 'Blanket (Heavy)',    'কম্বল (ভারী)',       380, 380, 108, true),
  ('quilt',              'Home', 'Quilt',              'কাঁথা',              250, 250, 109, true),
  ('bed_cover',          'Home', 'Bed Cover',          'বেড কভার',           150, 150, 110, true),
  ('sofa_cover',         'Home', 'Sofa Cover',         'সোফা কভার',          100, 100, 111, true),
  ('cushion_cover',      'Home', 'Cushion Cover',      'কুশন কভার',          25,  25,  112, true),
  ('curtain',            'Home', 'Curtain',            'পর্দা',              150, 150, 113, true),
  ('table_cloth',        'Home', 'Table Cloth',        'টেবিল ক্লথ',         70,  70,  114, true),
  ('dining_table_cover', 'Home', 'Dining Table Cover', 'ডাইনিং টেবিল কভার',  100, 100, 115, true),
  ('mattress_cover',     'Home', 'Mattress Cover',     'ম্যাট্রেস কভার',     200, 200, 116, true),
  -- ── শিশু / Baby & Kids ──
  ('baby_shirt',       'Kids', 'Baby Shirt',        'বেবি জামা',          40,  40,  201, true),
  ('baby_pant',        'Kids', 'Baby Pant',         'বেবি প্যান্ট',        40,  40,  202, true),
  ('baby_frock',       'Kids', 'Baby Frock',        'বেবি ফ্রক',           50,  50,  203, true),
  ('baby_three_piece', 'Kids', 'Baby Three-Piece',  'বেবি থ্রি-পিস',       60,  70,  204, true),
  ('baby_romper',      'Kids', 'Baby Romper',       'বেবি রম্পার',         40,  40,  205, true),
  ('baby_jumpsuit',    'Kids', 'Baby Jumpsuit',     'বেবি জাম্পসুট',       50,  50,  206, true),
  ('baby_sweater',     'Kids', 'Baby Sweater',      'বেবি সোয়েটার',       60,  60,  207, true),
  ('baby_jacket',      'Kids', 'Baby Jacket',       'বেবি জ্যাকেট',        80,  80,  208, true),
  ('school_uniform',   'Kids', 'School Uniform',    'স্কুল ইউনিফর্ম',      60,  70,  209, true),
  ('school_shirt',     'Kids', 'School Shirt',      'স্কুল শার্ট',         40,  50,  210, true),
  ('school_pant',      'Kids', 'School Pant',       'স্কুল প্যান্ট',       40,  50,  211, true),
  ('school_skirt',     'Kids', 'School Skirt',      'স্কুল স্কার্ট',       40,  50,  212, true),
  ('school_tie',       'Kids', 'School Tie',        'স্কুল টাই',           20,  20,  213, true),
  ('baby_blanket',     'Kids', 'Baby Blanket',      'বেবি কম্বল',          100, 100, 214, true),
  ('baby_towel',       'Kids', 'Baby Towel',        'বেবি তোয়ালে',        30,  30,  215, true),
  ('baby_bedsheet',    'Kids', 'Baby Bed Sheet',    'বেবি বেডশিট',         50,  50,  216, true),
  -- ── হোটেল / Hotel ──
  ('hotel_bedsheet',      'Hotel', 'Hotel Bed Sheet', 'বেডশিট',            100, 100, 301, true),
  ('hotel_pillow_cover',  'Hotel', 'Pillow Cover',    'বালিশের কভার',      30,  30,  302, true),
  ('hotel_duvet_cover',   'Hotel', 'Duvet Cover',     'ডুভে কভার',         180, 180, 303, true),
  ('hotel_blanket',       'Hotel', 'Hotel Blanket',   'কম্বল',             300, 300, 304, true),
  ('hotel_bath_towel',    'Hotel', 'Bath Towel',      'তোয়ালে',           60,  60,  305, true),
  ('hotel_hand_towel',    'Hotel', 'Hand Towel',      'হাত তোয়ালে',       30,  30,  306, true),
  ('hotel_face_towel',    'Hotel', 'Face Towel',      'ফেস তোয়ালে',       20,  20,  307, true),
  ('hotel_bath_mat',      'Hotel', 'Bath Mat',        'বাথ ম্যাট',         50,  50,  308, true),
  ('hotel_table_cloth',   'Hotel', 'Table Cloth',     'টেবিল ক্লথ',        100, 100, 309, true),
  ('hotel_table_runner',  'Hotel', 'Table Runner',    'টেবিল রানার',       60,  60,  310, true),
  ('hotel_napkin',        'Hotel', 'Napkin',          'ন্যাপকিন',          20,  20,  311, true),
  ('hotel_chair_cover',   'Hotel', 'Chair Cover',     'চেয়ার কভার',        50,  50,  312, true),
  ('hotel_curtain',       'Hotel', 'Curtain',         'পর্দা',             180, 180, 313, true),
  ('hotel_sofa_cover',    'Hotel', 'Sofa Cover',      'সোফা কভার',         120, 120, 314, true),
  ('hotel_cushion_cover', 'Hotel', 'Cushion Cover',   'কুশন কভার',         30,  30,  315, true),
  ('hotel_chef_uniform',  'Hotel', 'Chef Uniform',    'শেফ ইউনিফর্ম',      100, 120, 316, true),
  ('hotel_waiter_uniform','Hotel', 'Waiter Uniform',  'ওয়েটার ইউনিফর্ম',   80,  100, 317, true),
  ('hotel_apron',         'Hotel', 'Apron',           'এপ্রন',             40,  40,  318, true)
on conflict (id) do update set
  category   = excluded.category,
  name       = excluded.name,
  name_bn    = excluded.name_bn,
  wash_price = excluded.wash_price,
  dry_price  = excluded.dry_price,
  sort_order = excluded.sort_order,
  enabled    = true;
