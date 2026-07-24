import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin-controlled key/value settings, read from the `app_settings` table.
/// Holds: the two WhatsApp support numbers + Facebook page link shown on the
/// যোগাযোগ tab, and the About / Privacy Policy text shown in Profile.
///
/// Loaded once at startup ([load]); the admin support screen writes through
/// the setters (staff-only per RLS) and updates the in-memory copy.
class AppSettings {
  AppSettings._();

  static String supportWhatsapp1 = '';
  static String supportWhatsapp2 = '';
  static String facebookUrl = '';
  static String aboutText = '';
  static String privacyText = '';

  static SupabaseClient get _db => Supabase.instance.client;

  /// Best-effort load — a failure just leaves values blank rather than
  /// blocking app start.
  static Future<void> load() async {
    try {
      final rows = await _db.from('app_settings').select('key, value');
      for (final r in (rows as List)) {
        final v = (r['value'] as String?) ?? '';
        switch (r['key']) {
          case 'support_whatsapp_1':
            supportWhatsapp1 = v.trim();
          case 'support_whatsapp_2':
            supportWhatsapp2 = v.trim();
          case 'facebook_url':
            facebookUrl = v.trim();
          case 'about_text':
            aboutText = v;
          case 'privacy_text':
            privacyText = v;
        }
      }
    } catch (_) {
      // Table not there yet / offline — keep whatever we have.
    }
  }

  /// Saves the two support numbers + Facebook link (staff only). Empties are
  /// stored as '' so a value can be cleared. Updates the in-memory copy.
  static Future<void> setContact({
    required String whatsapp1,
    required String whatsapp2,
    required String facebook,
  }) async {
    final n1 = whatsapp1.trim();
    final n2 = whatsapp2.trim();
    final fb = facebook.trim();
    await _db.from('app_settings').upsert([
      {'key': 'support_whatsapp_1', 'value': n1},
      {'key': 'support_whatsapp_2', 'value': n2},
      {'key': 'facebook_url', 'value': fb},
    ]);
    supportWhatsapp1 = n1;
    supportWhatsapp2 = n2;
    facebookUrl = fb;
  }

  /// Saves the About + Privacy Policy text (staff only).
  static Future<void> setPages({required String about, required String privacy}) async {
    await _db.from('app_settings').upsert([
      {'key': 'about_text', 'value': about},
      {'key': 'privacy_text', 'value': privacy},
    ]);
    aboutText = about;
    privacyText = privacy;
  }
}
