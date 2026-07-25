import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A catalog category (e.g. পুরুষ / Men). The English [name] is the identity
/// used to tag items in `catalog_items.category`, so an item added under a
/// category is grouped by that exact string everywhere (order screen, price
/// list, receipts).
class CatalogCategory {
  final String id;
  String name;
  String nameBn;
  bool enabled;
  CatalogCategory({required this.id, required this.name, required this.nameBn, this.enabled = true});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'nameBn': nameBn, 'enabled': enabled};
  factory CatalogCategory.fromJson(Map<String, dynamic> j) => CatalogCategory(
        id: j['id'] as String,
        name: j['name'] as String,
        nameBn: (j['nameBn'] ?? j['name']) as String,
        enabled: j['enabled'] as bool? ?? true,
      );
}

/// A wash service (ওয়াশ / Wash, ড্রাই ক্লিন / Dry Clean, …). Admin-managed.
class CatalogService {
  final String id;
  String name;
  String nameBn;
  bool enabled;
  CatalogService({required this.id, required this.name, required this.nameBn, this.enabled = true});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'nameBn': nameBn, 'enabled': enabled};
  factory CatalogService.fromJson(Map<String, dynamic> j) => CatalogService(
        id: j['id'] as String,
        name: j['name'] as String,
        nameBn: (j['nameBn'] ?? j['name']) as String,
        enabled: j['enabled'] as bool? ?? true,
      );
}

/// The single source of truth for catalog **categories** and **services**.
///
/// Both lists start as the official defaults and are replaced by the admin's
/// saved copy from the `app_settings` key/value table (keys `catalog_categories`
/// and `catalog_services`, stored as JSON). This reuses the existing settings
/// table — no new migration — and its staff-only RLS, so an admin add/edit/
/// toggle/delete persists and reflects in the customer app on next launch.
class CatalogMeta {
  CatalogMeta._();

  static SupabaseClient get _db => Supabase.instance.client;

  static const _kCategories = 'catalog_categories';
  static const _kServices = 'catalog_services';

  /// Live category list the whole app reads. English [name] tags items.
  static final List<CatalogCategory> categories = [
    CatalogCategory(id: 'men', name: 'Men', nameBn: 'পুরুষ'),
    CatalogCategory(id: 'women', name: 'Women', nameBn: 'মহিলা'),
    CatalogCategory(id: 'kids', name: 'Kids', nameBn: 'শিশু'),
    CatalogCategory(id: 'home', name: 'Home', nameBn: 'ঘরের কাপড়'),
  ];

  static final List<CatalogService> services = [
    CatalogService(id: 'wash', name: 'Wash', nameBn: 'ওয়াশ'),
    CatalogService(id: 'dry', name: 'Dry Clean', nameBn: 'ড্রাই ক্লিন'),
  ];

  /// Enabled category english-names — what customers see. Falls back to all
  /// categories if the admin has (accidentally) disabled every one, so the
  /// order screen never ends up with an empty category list.
  static List<String> get enabledCategoryNames {
    final on = categories.where((c) => c.enabled).map((c) => c.name).toList();
    return on.isNotEmpty ? on : categories.map((c) => c.name).toList();
  }

  /// English-name -> Bengali-name for every category (labels).
  static Map<String, String> get categoryBnByName => {
        for (final c in categories) c.name: c.nameBn,
      };

  /// Best-effort load of the admin's saved categories/services. A failure or
  /// missing rows just leaves the defaults in place — never blocks startup.
  static Future<void> load() async {
    try {
      final rows = await _db.from('app_settings').select('key, value');
      for (final r in (rows as List)) {
        final raw = (r['value'] as String?) ?? '';
        if (raw.isEmpty) continue;
        if (r['key'] == _kCategories) {
          final parsed = (jsonDecode(raw) as List)
              .map((e) => CatalogCategory.fromJson(e as Map<String, dynamic>))
              .toList();
          if (parsed.isNotEmpty) {
            categories
              ..clear()
              ..addAll(parsed);
          }
        } else if (r['key'] == _kServices) {
          final parsed = (jsonDecode(raw) as List)
              .map((e) => CatalogService.fromJson(e as Map<String, dynamic>))
              .toList();
          if (parsed.isNotEmpty) {
            services
              ..clear()
              ..addAll(parsed);
          }
        }
      }
    } catch (_) {
      // Table missing / offline / bad JSON — keep the defaults.
    }
  }

  /// Persists the current category list (staff only per RLS).
  static Future<void> saveCategories() async {
    await _db.from('app_settings').upsert({
      'key': _kCategories,
      'value': jsonEncode(categories.map((c) => c.toJson()).toList()),
    });
  }

  /// Persists the current service list (staff only per RLS).
  static Future<void> saveServices() async {
    await _db.from('app_settings').upsert({
      'key': _kServices,
      'value': jsonEncode(services.map((s) => s.toJson()).toList()),
    });
  }
}
