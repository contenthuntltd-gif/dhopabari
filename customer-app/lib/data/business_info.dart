import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dhopa Bari office/shop hours — 1:00 PM to 9:00 PM, every day. Mirrors
/// `backend/src/utils/businessHours.js` (and the seeded
/// `Setting["business_hours"]` row) so the same rule is enforced/shown
/// consistently client- and server-side.
class BusinessHours {
  static const openHour = 13; // 24h clock
  static const closeHour = 21;
  static const label = '১:০০ PM - ৯:০০ PM';
  static const labelWithDays = '১:০০ PM - ৯:০০ PM (প্রতিদিন)';

  static const offHoursMessage =
      'আপনার অর্ডার গ্রহণ করা হয়েছে। অফিস খোলার সময় (১:০০ PM - ৯:০০ PM) আমাদের টিম এটি নিশ্চিত করবে।';

  static bool get isOpenNow {
    final hour = DateTime.now().hour;
    return hour >= openHour && hour < closeHour;
  }
}

enum DeliveryType { free, express }

class DeliveryOption {
  final DeliveryType type;
  String label;
  int charge;
  String eta;

  /// Whether the option is offered to customers at all. A disabled option is
  /// hidden from checkout entirely.
  bool enabled;

  /// Shown in checkout but locked — a "শীঘ্রই আসছে / Coming Soon" tile the
  /// customer can see but not pick yet.
  bool comingSoon;

  DeliveryOption({
    required this.type,
    required this.label,
    required this.charge,
    required this.eta,
    this.enabled = true,
    this.comingSoon = false,
  });

  Map<String, dynamic> toJson() =>
      {'label': label, 'charge': charge, 'eta': eta, 'enabled': enabled, 'comingSoon': comingSoon};

  /// Overlays saved values onto this instance (missing keys keep defaults).
  void applyJson(Map<String, dynamic> j) {
    if (j['label'] is String) label = j['label'] as String;
    if (j['eta'] is String) eta = j['eta'] as String;
    if (j['charge'] is num) charge = (j['charge'] as num).toInt();
    if (j['enabled'] is bool) enabled = j['enabled'] as bool;
    if (j['comingSoon'] is bool) comingSoon = j['comingSoon'] as bool;
  }
}

/// The delivery options a customer can pick during checkout. Free is the
/// always-available default; Express ships "coming soon" until an admin turns
/// it on. Both are **admin-configurable** (charge, availability, coming-soon)
/// and persisted to the `app_settings` table (key `delivery_options`), so a
/// change in the admin panel reflects in the customer app on next launch.
class DeliveryOptions {
  DeliveryOptions._();

  static final free = DeliveryOption(
      type: DeliveryType.free, label: 'ফ্রি ডেলিভারি', charge: 0, eta: '৩-৫ দিন', enabled: true, comingSoon: false);
  static final express = DeliveryOption(
      type: DeliveryType.express, label: 'এক্সপ্রেস ডেলিভারি', charge: 50, eta: '২ দিনের মধ্যে', enabled: true, comingSoon: true);

  static List<DeliveryOption> get all => [free, express];

  /// Options shown to the customer (enabled). Coming-soon ones stay in the
  /// list but render locked.
  static List<DeliveryOption> get visible => all.where((o) => o.enabled).toList();

  /// Options the customer can actually select right now.
  static List<DeliveryOption> get selectable =>
      all.where((o) => o.enabled && !o.comingSoon).toList();

  static SupabaseClient get _db => Supabase.instance.client;
  static const _key = 'delivery_options';

  /// Best-effort load of the admin's saved delivery config.
  static Future<void> load() async {
    try {
      final rows = await _db.from('app_settings').select('key, value').eq('key', _key);
      if ((rows as List).isEmpty) return;
      final raw = (rows.first['value'] as String?) ?? '';
      if (raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['free'] is Map) free.applyJson((map['free'] as Map).cast<String, dynamic>());
      if (map['express'] is Map) express.applyJson((map['express'] as Map).cast<String, dynamic>());
    } catch (_) {
      // Missing / offline / bad JSON — keep defaults.
    }
  }

  /// Persists the current delivery config (staff only per RLS).
  static Future<void> save() async {
    await _db.from('app_settings').upsert({
      'key': _key,
      'value': jsonEncode({'free': free.toJson(), 'express': express.toJson()}),
    });
  }
}
