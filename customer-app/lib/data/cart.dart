import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'catalog.dart';
import 'mock_data.dart' show PriceItem;

/// One line in the cart: an item taken under a specific service.
/// The same garment can appear twice — once as Wash, once as Dry Clean —
/// each priced by its own service. That is the whole point: a customer can
/// mix services inside a single order.
class CartLine {
  final PriceItem item;
  final String service; // 'Wash' | 'Dry Clean'
  final int qty;
  const CartLine({required this.item, required this.service, required this.qty});

  int get unitPrice => service == 'Wash' ? item.washPrice : item.dryPrice;
  int get lineTotal => unitPrice * qty;
}

/// The order-in-progress. Global and persistent:
///
///   • Leaving the order screen (or even closing the app) keeps the cart —
///     it is saved to SharedPreferences on every change.
///   • It is cleared in exactly one place: [clear], called right after an
///     order is successfully placed. Abandoning the flow never clears it.
///
/// Quantities are keyed by "itemId|service", so wash and dry-clean lines of
/// the same item are independent.
class Cart {
  Cart._();

  static const _prefsKey = 'cart_v1';

  /// "itemId|service" → qty. Values are always > 0 (zero removes the key).
  static final Map<String, int> _qty = {};

  /// Bumped on every mutation so screens can listen and rebuild.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static String _key(String itemId, String service) => '$itemId|$service';

  static int qtyOf(String itemId, String service) =>
      _qty[_key(itemId, service)] ?? 0;

  static void setQty(String itemId, String service, int qty) {
    final key = _key(itemId, service);
    if (qty <= 0) {
      _qty.remove(key);
    } else {
      _qty[key] = qty;
    }
    revision.value++;
    _save();
  }

  static bool get isEmpty => _qty.isEmpty;

  /// All lines, resolved against the live [Catalog]. A line whose item has
  /// been removed from the catalog is silently dropped rather than crashing
  /// the order flow.
  static List<CartLine> get lines {
    final result = <CartLine>[];
    _qty.forEach((key, qty) {
      final sep = key.lastIndexOf('|');
      if (sep < 0) return;
      final item = Catalog.byId(key.substring(0, sep));
      if (item == null) return;
      result.add(CartLine(item: item, service: key.substring(sep + 1), qty: qty));
    });
    // Wash lines first, then dry — stable grouped display everywhere.
    result.sort((a, b) {
      final s = a.service.compareTo(b.service);
      return s != 0 ? -s.sign : a.item.name.compareTo(b.item.name);
    });
    return result;
  }

  static List<CartLine> linesFor(String service) =>
      lines.where((l) => l.service == service).toList();

  static int get totalPieces => _qty.values.fold(0, (a, b) => a + b);

  static int get subtotal => lines.fold(0, (sum, l) => sum + l.lineTotal);

  /// Pieces of one item across BOTH services (for category badges).
  static int piecesOfItem(String itemId) =>
      qtyOf(itemId, 'Wash') + qtyOf(itemId, 'Dry Clean');

  /// What the order's `service` column should say.
  static String get serviceLabel {
    final hasWash = _qty.keys.any((k) => k.endsWith('|Wash'));
    final hasDry = _qty.keys.any((k) => k.endsWith('|Dry Clean'));
    if (hasWash && hasDry) return 'Wash + Dry Clean';
    if (hasDry) return 'Dry Clean';
    return 'Wash';
  }

  /// Snapshot for orders.items — per line: what, which service, at what
  /// price. Frozen at placement so later catalog edits can't rewrite it.
  static List<Map<String, dynamic>> toOrderItems() => [
        for (final l in lines)
          {
            'id': l.item.id,
            'name': l.item.name,
            'name_bn': l.item.nameBn,
            'service': l.service,
            'qty': l.qty,
            'unit_price': l.unitPrice,
            'line_total': l.lineTotal,
          }
      ];

  /// Called ONLY after an order is successfully placed.
  static Future<void> clear() async {
    _qty.clear();
    revision.value++;
    await _save();
  }

  // ── persistence ──

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _qty
        ..clear()
        ..addAll(decoded.map((k, v) => MapEntry(k, (v as num).toInt())));
      _qty.removeWhere((_, v) => v <= 0);
      revision.value++;
    } catch (_) {
      // Corrupt/old data — start with an empty cart rather than crash.
    }
  }

  static Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_qty));
    } catch (_) {
      // Persistence is best-effort; the in-memory cart still works.
    }
  }
}
