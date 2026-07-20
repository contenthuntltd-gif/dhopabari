import 'package:supabase_flutter/supabase_flutter.dart';
import 'google_auth_service.dart';
import '../data/mock_data.dart';

/// The result of a completed sign-in (Google or verified phone OTP).
class AuthResult {
  final String name;
  final String phone;
  const AuthResult({required this.name, required this.phone});
}

/// Customer authentication via Supabase Auth.
///
///   • Continue with Google  — native Google Sign-In → Supabase session
///   • Phone number + OTP     — Supabase SMS OTP (requires an SMS provider
///                              configured in the Supabase Dashboard)
///
/// App-level profile data lives in the `profiles` table (see
/// supabase/migrations/0001_auth_profiles.sql). Supabase persists the
/// session on device automatically, so there is no token to store here.
class AuthService {
  static SupabaseClient get _supabase => Supabase.instance.client;

  /// Normalises a Bangladeshi number the customer typed (e.g. "01712-345678"
  /// or "1712345678") into E.164 form ("+8801712345678") for Supabase.
  static String normalizePhone(String input) {
    var digits = input.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('880')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return '+880$digits';
  }

  /// Whether there is an active session right now (e.g. after a Google
  /// redirect returns, or a previously saved session). Safe to call even if
  /// Supabase wasn't initialized (unconfigured) — returns false.
  static bool get isLoggedIn {
    try {
      return _supabase.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  /// True if a session was restored (Supabase does this from disk on init).
  /// Loads the user's profile into [MockData] for the UI.
  static Future<bool> restoreSession() async {
    if (_supabase.auth.currentSession == null) return false;
    await _loadProfile();
    return true;
  }

  /// Loads the signed-in user's profile into [MockData]. Safe to call from
  /// the auth-state listener after a fresh sign-in.
  static Future<void> syncProfile() async {
    if (_supabase.auth.currentSession == null) return;
    await _loadProfile();
  }

  static Future<void> logout() async {
    await GoogleAuthService.signOut();
    await _supabase.auth.signOut();
    // Wipe the previous user's identity + addresses so nothing carries into
    // the next login.
    MockData.resetUser();
  }

  // ----- Google -----

  /// Returns the [AuthResult] on success, or null if the user cancelled the
  /// Google account picker.
  static Future<AuthResult?> signInWithGoogle() async {
    final user = await GoogleAuthService.signIn();
    if (user == null) return null;
    return _loadProfile();
  }

  // ----- Phone OTP -----

  /// Sends a one-time SMS code to [phone]. On first sign-in from a number,
  /// [name] / [area] / [localAddress] / [whatsappNumber] are attached as
  /// signup metadata and used to seed the profile row.
  static Future<void> sendPhoneOtp({
    required String phone,
    String? name,
    String? area,
    String? localAddress,
    String? whatsappNumber,
  }) async {
    final data = <String, dynamic>{
      if (name != null && name.isNotEmpty) 'name': name,
      if (area != null && area.isNotEmpty) 'area': area,
      if (localAddress != null && localAddress.isNotEmpty) 'local_address': localAddress,
      if (whatsappNumber != null && whatsappNumber.isNotEmpty) 'whatsapp_number': whatsappNumber,
    };
    await _supabase.auth.signInWithOtp(
      phone: normalizePhone(phone),
      data: data.isEmpty ? null : data,
    );
  }

  /// Verifies the 6-digit [token] for [phone] and establishes the session.
  static Future<AuthResult> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    await _supabase.auth.verifyOTP(
      type: OtpType.sms,
      phone: normalizePhone(phone),
      token: token,
    );
    return _loadProfile();
  }

  // ----- Phone + Password (no OTP) -----

  /// Converts a normalised phone number into a pseudo-email so we can use
  /// Supabase's email+password auth without requiring SMS OTP verification.
  static String _phoneToEmail(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return '$digits@dhopabari.app';
  }

  /// Creates a new account with phone + password. Profile metadata (name,
  /// area, address, whatsapp) is attached and the `handle_new_user` trigger
  /// seeds the `profiles` row automatically.
  static Future<AuthResult> signUpWithPassword({
    required String phone,
    required String password,
    String? name,
    String? area,
    String? localAddress,
    String? whatsappNumber,
  }) async {
    final normalized = normalizePhone(phone);
    final email = _phoneToEmail(normalized);
    final data = <String, dynamic>{
      'phone': normalized,
      if (name != null && name.isNotEmpty) 'name': name,
      if (area != null && area.isNotEmpty) 'area': area,
      if (localAddress != null && localAddress.isNotEmpty) 'local_address': localAddress,
      if (whatsappNumber != null && whatsappNumber.isNotEmpty) 'whatsapp_number': whatsappNumber,
    };
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
    return _loadProfile();
  }

  /// Signs in an existing user with phone + password.
  static Future<AuthResult> signInWithPassword({
    required String phone,
    required String password,
  }) async {
    final email = _phoneToEmail(normalizePhone(phone));
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return _loadProfile();
  }

  // ----- Profile -----

  /// Reads the current user's profile row into [MockData] for the UI.
  /// Falls back to auth metadata if the profile row isn't ready yet.
  static Future<AuthResult> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('No authenticated user');
    }

    Map<String, dynamic>? profile;
    try {
      profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {
      profile = null;
    }

    final meta = user.userMetadata ?? const {};
    final name = (profile?['name'] as String?)?.trim().isNotEmpty == true
        ? (profile!['name'] as String).trim()
        : ((meta['name'] as String?) ??
            (meta['full_name'] as String?) ??
            'কাস্টমার');
    final phone = (profile?['phone'] as String?) ??
        (meta['phone'] as String?) ??
        user.phone ??
        '';
    final area =
        (profile?['area'] as String?) ?? (meta['area'] as String?) ?? '';
    final localAddress = (profile?['local_address'] as String?) ??
        (meta['local_address'] as String?) ??
        '';

    // Load THIS user's identity, replacing whatever was there before.
    MockData.userName = name;
    MockData.userPhone = phone;
    MockData.userArea = area;

    // Rebuild the saved-address list from the user's own profile. The order
    // flow indexes savedAddresses[0], so there is always exactly one entry:
    // the address they registered with. This is what guarantees a new login
    // never sees the previous user's addresses.
    MockData.savedAddresses
      ..clear()
      ..add({
        'label': 'Home',
        'labelBn': 'আমার ঠিকানা',
        'line': localAddress.isNotEmpty ? localAddress : area,
        'area': area,
      });

    return AuthResult(name: name, phone: phone);
  }

  /// Updates the current user's profile row (name/area/address/whatsapp).
  static Future<void> updateProfile({
    String? name,
    String? area,
    String? localAddress,
    String? whatsappNumber,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.from('profiles').update({
      if (name != null) 'name': name,
      if (area != null) 'area': area,
      if (localAddress != null) 'local_address': localAddress,
      if (whatsappNumber != null) 'whatsapp_number': whatsappNumber,
    }).eq('id', user.id);
  }
}
