-- ============================================================
-- 0014 — Catalog reset to the official printed price list
--
-- Wipes catalog_items and re-inserts every item in its correct category with
-- the exact wash/dry prices. sort_order follows the printed sheet's order.
-- Orders store their own line items (jsonb), so deleting catalog rows never
-- affects past orders.
--
-- Safe to re-run.
-- ============================================================

delete from public.catalog_items;

insert into public.catalog_items (id, category, name, name_bn, wash_price, dry_price, sort_order, enabled) values
  ('shirt',           'Men',   'Shirt',              'শার্ট',              50,  60,  1,  true),
  ('pant',            'Men',   'Pant',               'প্যান্ট',            50,  60,  2,  true),
  ('tshirt',          'Men',   'T-Shirt',            'গেঞ্জি',             50,  60,  3,  true),
  ('panjabi',         'Men',   'Panjabi',            'পাঞ্জাবী',           60,  70,  4,  true),
  ('pajama',          'Men',   'Pajama',             'পায়জামা',           50,  60,  5,  true),
  ('jubbah',          'Men',   'Jubbah',             'জুব্বা',             70,  80,  6,  true),
  ('fatua',           'Men',   'Fatua',              'ফতুয়া',             50,  60,  7,  true),
  ('lungi',           'Men',   'Lungi',              'লুঙ্গি',             50,  50,  8,  true),
  ('suit',            'Men',   'Suit',               'স্যুট',              300, 300, 9,  true),
  ('blazer',          'Men',   'Blazer / Coat',      'ব্লেজার / কোট',      250, 250, 10, true),
  ('koti',            'Men',   'Waistcoat (Kuti)',   'কটি',                130, 130, 11, true),
  ('tie',             'Men',   'Tie',                'টাই',                40,  40,  12, true),
  ('sweater',         'Men',   'Sweater',            'সুয়েটার',           120, 120, 13, true),
  ('jacket',          'Men',   'Jacket',             'জ্যাকেট',            200, 200, 14, true),
  ('shawl',           'Men',   'Shawl',              'শাল',                140, 140, 15, true),
  ('three_piece',     'Women', 'Three-Piece / Kamiz','থ্রি-পিস / কামিজ',   100, 120, 16, true),
  ('borka',           'Women', 'Borka',              'বোরকা',              100, 120, 17, true),
  ('dupatta',         'Women', 'Dupatta',            'ওড়না',              40,  40,  18, true),
  ('hijab',           'Women', 'Hijab',              'হিজাব',              50,  50,  19, true),
  ('blouse',          'Women', 'Blouse / Petticoat', 'ব্লাউজ / পেটিকোট',   50,  60,  20, true),
  ('saree',           'Women', 'Saree',              'শাড়ি',              300, 300, 21, true),
  ('lehenga',         'Women', 'Lehenga / Gown',     'লেহেঙ্গা / গাউন',    450, 450, 22, true),
  ('kids_wear',       'Kids',  'Kids Wear',          'বাচ্চাদের কাপড়',    50,  50,  23, true),
  ('bedsheet',        'Home',  'Bed Sheet',          'বেডশীট / চাদর',      80,  80,  24, true),
  ('pillow_cover',    'Home',  'Pillow Cover',       'বালিশের কভার',       25,  25,  25, true),
  ('towel',           'Home',  'Towel',              'টাওয়াল / তোয়ালে',  50,  50,  26, true),
  ('blanket_regular', 'Home',  'Blanket (Regular)',  'কম্বল - রেগুলার',    280, 280, 27, true),
  ('blanket_heavy',   'Home',  'Blanket (Heavy)',    'কম্বল - ভারী',       380, 380, 28, true),
  ('curtain',         'Home',  'Curtain',            'পর্দা',              150, 150, 29, true),
  ('sofa_cover',      'Home',  'Sofa Cover',         'সোফা কভার',          100, 100, 30, true),
  ('cushion_cover',   'Home',  'Cushion Cover',      'কুশন কভার',          25,  25,  31, true),
  ('table_cloth',     'Home',  'Table Cloth',        'টেবিল ক্লথ',         70,  70,  32, true);
