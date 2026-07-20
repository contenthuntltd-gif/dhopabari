/// Supabase project configuration.
///
/// The URL and anon key are safe to ship in a client (the anon key only
/// grants what Row Level Security allows). They default to the Dhopa Bari
/// project but can be overridden at build time, e.g.:
///
///   flutter run --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// Get the anon key from: Supabase Dashboard → Project Settings → API.
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://stxzqmrnezedphysmczq.supabase.co',
  );

  /// The publishable (client-safe) key. This is Supabase's new API key
  /// format (`sb_publishable_...`), the drop-in replacement for the legacy
  /// `anon` JWT key — safe to ship in the app since Row Level Security
  /// governs what it can access. Override at build time if needed:
  /// --dart-define=SUPABASE_ANON_KEY=...
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_j51tE9pIaYYkXQmcA8R6jw_dOnkqOF6',
  );

  /// Google OAuth Web client ID (from Google Cloud Console → Credentials).
  /// Required for native "Continue with Google": Supabase verifies the ID
  /// token issued for this client. On Android also add the Android client
  /// ID's SHA-1; on iOS set the iOS client ID in Info.plist.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  static bool get isConfigured => anonKey.isNotEmpty;
}
