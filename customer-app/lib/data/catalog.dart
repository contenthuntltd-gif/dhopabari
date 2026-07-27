import 'package:supabase_flutter/supabase_flutter.dart';
import 'mock_data.dart' show PriceItem;

/// The official Dhopa Bari price list — the single source of truth for
/// items and prices across the whole app (order screen, admin catalog,
/// receipts, totals).
///
/// Two layers:
///   1. [official] — the bundled list, exactly matching the printed
///      Dhopa Bari price list. This is what ships with the app and what
///      seeds the database (supabase/migrations/0004_catalog.sql).
///   2. `catalog_items` table — once the migration is applied, [refresh]
///      pulls the live list so an admin price change reflects everywhere
///      without an app update. If the table doesn't exist yet (or the
///      device is offline), the bundled list keeps everything working.
///
/// Prices display in ENGLISH numerals by design (৳50, ৳300) — matching
/// the official price list typography.
class Catalog {
  Catalog._();

  /// The live list the UI reads. Starts as the official bundled list and
  /// is replaced wholesale by [refresh] when the DB copy loads.
  static List<PriceItem> items = List.of(official);

  static bool _loadedFromDb = false;

  /// True once [items] reflects the database rather than the bundle.
  static bool get isLive => _loadedFromDb;

  static List<PriceItem> forCategory(String category) =>
      items.where((p) => p.category == category).toList();

  static PriceItem? byId(String id) {
    for (final p in items) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Loads the catalog from Supabase, replacing [items]. Silently keeps
  /// the bundled list on any failure — a missing table or no network must
  /// never block ordering.
  static Future<void> refresh() async {
    try {
      final rows = await Supabase.instance.client
          .from('catalog_items')
          .select()
          .eq('enabled', true)
          .order('sort_order');
      final loaded = (rows as List)
          .map((r) => PriceItem(
                id: r['id'] as String,
                category: r['category'] as String,
                name: r['name'] as String,
                nameBn: r['name_bn'] as String,
                washPrice: (r['wash_price'] as num).toInt(),
                dryPrice: (r['dry_price'] as num).toInt(),
              ))
          .toList();
      if (loaded.isNotEmpty) {
        items = loaded;
        _loadedFromDb = true;
      }
    } catch (_) {
      // Table not created yet / offline — bundled list stays in effect.
    }
  }

  /// Admin price update. Writes to the DB first; the in-memory list only
  /// changes once the write succeeds (or the table doesn't exist yet, in
  /// which case the change is session-local until the migration runs).
  /// On a real DB failure nothing changes anywhere — screen and database
  /// can never disagree.
  static Future<void> updatePrices(String id,
      {required int washPrice, required int dryPrice}) async {
    try {
      await Supabase.instance.client
          .from('catalog_items')
          .update({'wash_price': washPrice, 'dry_price': dryPrice}).eq('id', id);
    } on PostgrestException catch (e) {
      // 42P01 = table doesn't exist yet — local-only until migration runs.
      if (e.code != '42P01') rethrow;
    }

    final idx = items.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      final old = items[idx];
      items[idx] = PriceItem(
        id: old.id,
        category: old.category,
        name: old.name,
        nameBn: old.nameBn,
        washPrice: washPrice,
        dryPrice: dryPrice,
      );
    }
  }

  /// Adds a brand-new item to the catalog (admin "New Item"). Persists to
  /// `catalog_items`, dropping it at the end of its category, then reloads so
  /// it appears everywhere (order screen, receipts, totals). Returns the new
  /// item's id.
  static Future<String> addItem({
    required String category,
    required String name,
    required String nameBn,
    required int washPrice,
    required int dryPrice,
  }) async {
    final id = 'item_${DateTime.now().millisecondsSinceEpoch}';
    final db = Supabase.instance.client;
    // Place it just after the current last item in its category.
    final rows = await db
        .from('catalog_items')
        .select('sort_order')
        .eq('category', category)
        .order('sort_order', ascending: false)
        .limit(1);
    final max = (rows as List).isNotEmpty ? ((rows.first['sort_order'] as num?)?.toInt() ?? 0) : 0;
    await db.from('catalog_items').insert({
      'id': id,
      'category': category,
      'name': name,
      'name_bn': nameBn,
      'wash_price': washPrice,
      'dry_price': dryPrice,
      'sort_order': max + 1,
      'enabled': true,
    });
    await refresh();
    return id;
  }

  /// Deletes a catalog item permanently, then reloads so it disappears
  /// everywhere. Old orders keep their stored line items unchanged.
  static Future<void> deleteItem(String id) async {
    await Supabase.instance.client.from('catalog_items').delete().eq('id', id);
    await refresh();
  }

  /// Moves an item to the top of ITS category (an admin "pin to top").
  ///
  /// The in-memory [items] list's order IS the display order (PriceItem has no
  /// sort_order field), so we reorder it directly for an instant, reliable
  /// change — no waiting on a DB round-trip, and no risk of a reload re-tying
  /// equal sort_orders and appearing to "do nothing". The DB is then updated
  /// (sort_order one below the category's current minimum) so the new order
  /// survives a reload and reaches every device.
  static Future<void> moveToTop(String id) async {
    final item = byId(id);
    if (item == null) return;

    // 1. Instant local reorder: put the item just before the first item of
    //    its own category.
    final list = List<PriceItem>.of(items)..removeWhere((p) => p.id == id);
    final firstOfCat = list.indexWhere((p) => p.category == item.category);
    list.insert(firstOfCat < 0 ? list.length : firstOfCat, item);
    items = list;

    // 2. Persist to the DB. On failure, reload to restore the true order.
    try {
      final rows = await Supabase.instance.client
          .from('catalog_items')
          .select('sort_order')
          .eq('category', item.category)
          .order('sort_order')
          .limit(1);
      final min = (rows as List).isNotEmpty ? ((rows.first['sort_order'] as num?)?.toInt() ?? 0) : 0;
      await Supabase.instance.client
          .from('catalog_items')
          .update({'sort_order': min - 1}).eq('id', id);
    } catch (e) {
      await refresh();
      rethrow;
    }
  }

  /// Moves an item to an exact position (1-based) within its category, then
  /// re-numbers the whole category's sort_order so the order is exact and
  /// stable. Instant in-memory reorder + DB persist.
  static Future<void> moveToPosition(String id, int position1Based) async {
    final item = byId(id);
    if (item == null) return;
    final cat = forCategory(item.category);
    final from = cat.indexWhere((p) => p.id == id);
    if (from < 0) return;
    final to = (position1Based - 1).clamp(0, cat.length - 1);
    if (to == from) return;

    // Reorder within the category.
    final reordered = List<PriceItem>.of(cat)..removeAt(from);
    reordered.insert(to, item);

    // Rebuild the flat list: fill this category's slots with the reordered
    // items in order, leaving every other category untouched.
    final catIds = cat.map((p) => p.id).toSet();
    var i = 0;
    items = [
      for (final p in items) catIds.contains(p.id) ? reordered[i++] : p,
    ];

    // Persist: sequential sort_order across the category.
    try {
      final db = Supabase.instance.client;
      for (var n = 0; n < reordered.length; n++) {
        await db.from('catalog_items').update({'sort_order': n}).eq('id', reordered[n].id);
      }
    } catch (e) {
      await refresh();
      rethrow;
    }
  }

  /// Moves an item one place up within its category.
  static Future<void> moveUp(String id) => _shift(id, -1);

  /// Moves an item one place down within its category.
  static Future<void> moveDown(String id) => _shift(id, 1);

  /// Swaps an item with its neighbour ([dir] = -1 up, +1 down) inside its
  /// category. The in-memory list is reordered instantly (display order = list
  /// order), and the two rows' sort_order values are swapped in the DB so the
  /// new order survives a reload.
  static Future<void> _shift(String id, int dir) async {
    final item = byId(id);
    if (item == null) return;
    final cat = forCategory(item.category);
    final idx = cat.indexWhere((p) => p.id == id);
    final targetIdx = idx + dir;
    if (idx < 0 || targetIdx < 0 || targetIdx >= cat.length) return; // at an edge
    final other = cat[targetIdx];

    // 1. Instant in-memory swap.
    final list = List<PriceItem>.of(items);
    final gi = list.indexWhere((p) => p.id == id);
    final gj = list.indexWhere((p) => p.id == other.id);
    if (gi < 0 || gj < 0) return;
    final tmp = list[gi];
    list[gi] = list[gj];
    list[gj] = tmp;
    items = list;

    // 2. Persist: swap the two rows' sort_order values.
    try {
      final db = Supabase.instance.client;
      final rows = await db.from('catalog_items').select('id, sort_order').inFilter('id', [id, other.id]);
      final map = {for (final r in (rows as List)) r['id'] as String: (r['sort_order'] as num?)?.toInt() ?? 0};
      final soSelf = map[id] ?? 0;
      final soOther = map[other.id] ?? 0;
      // If they happen to be equal, nudge to guarantee a strict order.
      final newSelf = soOther == soSelf ? soOther + dir : soOther;
      await db.from('catalog_items').update({'sort_order': newSelf}).eq('id', id);
      await db.from('catalog_items').update({'sort_order': soSelf}).eq('id', other.id);
    } catch (e) {
      await refresh();
      rethrow;
    }
  }

  /// The official Dhopa Bari price list. Ordered so the everyday items sit
  /// at the top of each category; admins can re-pin from the catalog screen.
  /// This is the bundled fallback — the live order comes from catalog_items.
  static const official = <PriceItem>[
    // ── পুরুষ / Men (regular first) ──
    PriceItem(id: 'shirt', category: 'Men', name: 'Shirt', nameBn: 'শার্ট', washPrice: 50, dryPrice: 60),
    PriceItem(id: 'pant', category: 'Men', name: 'Pant', nameBn: 'প্যান্ট', washPrice: 50, dryPrice: 60),
    PriceItem(id: 'tshirt', category: 'Men', name: 'T-Shirt', nameBn: 'টি-শার্ট', washPrice: 50, dryPrice: 60),
    PriceItem(id: 'panjabi', category: 'Men', name: 'Panjabi', nameBn: 'পাঞ্জাবি', washPrice: 60, dryPrice: 70),
    PriceItem(id: 'pajama', category: 'Men', name: 'Pajama', nameBn: 'পায়জামা', washPrice: 50, dryPrice: 60),
    PriceItem(id: 'fatua', category: 'Men', name: 'Fatua', nameBn: 'ফতুয়া', washPrice: 50, dryPrice: 60),
    PriceItem(id: 'lungi', category: 'Men', name: 'Lungi', nameBn: 'লুঙ্গি', washPrice: 50, dryPrice: 50),
    PriceItem(id: 'sweater', category: 'Men', name: 'Sweater', nameBn: 'সোয়েটার', washPrice: 120, dryPrice: 120),
    PriceItem(id: 'jacket', category: 'Men', name: 'Jacket', nameBn: 'জ্যাকেট', washPrice: 200, dryPrice: 200),
    PriceItem(id: 'koti', category: 'Men', name: 'Waistcoat (Koti)', nameBn: 'কটি', washPrice: 130, dryPrice: 130),
    PriceItem(id: 'blazer', category: 'Men', name: 'Blazer / Coat', nameBn: 'ব্লেজার / কোট', washPrice: 250, dryPrice: 250),
    PriceItem(id: 'suit', category: 'Men', name: 'Suit', nameBn: 'স্যুট', washPrice: 300, dryPrice: 300),
    PriceItem(id: 'jubbah', category: 'Men', name: 'Jubbah', nameBn: 'জুব্বা', washPrice: 70, dryPrice: 80),
    PriceItem(id: 'shawl', category: 'Men', name: 'Shawl', nameBn: 'শাল', washPrice: 140, dryPrice: 140),
    PriceItem(id: 'tie', category: 'Men', name: 'Tie', nameBn: 'টাই', washPrice: 40, dryPrice: 40),

    // ── মহিলা / Women (regular first) ──
    PriceItem(id: 'three_piece', category: 'Women', name: 'Three-Piece / Kamiz', nameBn: 'থ্রি-পিস / কামিজ', washPrice: 100, dryPrice: 120),
    PriceItem(id: 'saree', category: 'Women', name: 'Saree', nameBn: 'শাড়ি', washPrice: 300, dryPrice: 300),
    PriceItem(id: 'borka', category: 'Women', name: 'Borka', nameBn: 'বোরকা', washPrice: 100, dryPrice: 120),
    PriceItem(id: 'blouse', category: 'Women', name: 'Blouse / Petticoat', nameBn: 'ব্লাউজ / পেটিকোট', washPrice: 50, dryPrice: 60),
    PriceItem(id: 'hijab', category: 'Women', name: 'Hijab', nameBn: 'হিজাব', washPrice: 50, dryPrice: 50),
    PriceItem(id: 'dupatta', category: 'Women', name: 'Dupatta', nameBn: 'ওড়না', washPrice: 40, dryPrice: 40),
    PriceItem(id: 'lehenga', category: 'Women', name: 'Lehenga / Gown', nameBn: 'লেহেঙ্গা / গাউন', washPrice: 450, dryPrice: 450),

    // ── শিশু / Kids ──
    PriceItem(id: 'kids_wear', category: 'Kids', name: 'Kids Wear', nameBn: 'বাচ্চাদের পোশাক', washPrice: 50, dryPrice: 50),

    // ── ঘরের কাপড় / Home (regular first) ──
    PriceItem(id: 'bedsheet', category: 'Home', name: 'Bed Sheet', nameBn: 'বেডশিট', washPrice: 80, dryPrice: 80),
    PriceItem(id: 'pillow_cover', category: 'Home', name: 'Pillow Cover', nameBn: 'বালিশের কভার', washPrice: 25, dryPrice: 25),
    PriceItem(id: 'towel', category: 'Home', name: 'Towel', nameBn: 'তোয়ালে', washPrice: 50, dryPrice: 50),
    PriceItem(id: 'curtain', category: 'Home', name: 'Curtain', nameBn: 'পর্দা', washPrice: 150, dryPrice: 150),
    PriceItem(id: 'blanket_regular', category: 'Home', name: 'Blanket (Regular)', nameBn: 'কম্বল (রেগুলার)', washPrice: 280, dryPrice: 280),
    PriceItem(id: 'blanket_heavy', category: 'Home', name: 'Blanket (Heavy)', nameBn: 'কম্বল (ভারী)', washPrice: 380, dryPrice: 380),
    PriceItem(id: 'sofa_cover', category: 'Home', name: 'Sofa Cover', nameBn: 'সোফা কভার', washPrice: 100, dryPrice: 100),
    PriceItem(id: 'cushion_cover', category: 'Home', name: 'Cushion Cover', nameBn: 'কুশন কভার', washPrice: 25, dryPrice: 25),
    PriceItem(id: 'table_cloth', category: 'Home', name: 'Table Cloth', nameBn: 'টেবিল ক্লথ', washPrice: 70, dryPrice: 70),
  ];
}
