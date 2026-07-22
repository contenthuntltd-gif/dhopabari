import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin-controlled key/value settings, read from the `app_settings` table.
/// Right now: the two WhatsApp support numbers shown on the যোগাযোগ tab.
///
/// Loaded once at startup ([load]); the admin support screen writes through
/// [setSupportNumbers] (staff-only per RLS) and updates the in-memory copy.
class AppSettings {
  AppSettings._();

  static String supportWhatsapp1 = '';
  static String supportWhatsapp2 = '';

  static SupabaseClient get _db => Supabase.instance.client;

  /// Best-effort load — a failure just leaves the numbers blank rather than
  /// blocking app start.
  static Future<void> load() async {
    try {
      final rows = await _db.from('app_settings').select('key, value');
      for (final r in (rows as List)) {
        switch (r['key']) {
          case 'support_whatsapp_1':
            supportWhatsapp1 = (r['value'] as String?)?.trim() ?? '';
          case 'support_whatsapp_2':
            supportWhatsapp2 = (r['value'] as String?)?.trim() ?? '';
        }
      }
    } catch (_) {
      // Table not there yet / offline — keep whatever we have.
    }
  }

  /// Saves both support numbers (staff only). Empties are stored as '' so a
  /// number can be cleared. Updates the in-memory copy on success.
  static Future<void> setSupportNumbers(String one, String two) async {
    final n1 = one.trim();
    final n2 = two.trim();
    await _db.from('app_settings').upsert([
      {'key': 'support_whatsapp_1', 'value': n1},
      {'key': 'support_whatsapp_2', 'value': n2},
    ]);
    supportWhatsapp1 = n1;
    supportWhatsapp2 = n2;
  }
}
