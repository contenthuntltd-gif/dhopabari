import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'google_auth_service.dart';
import 'supabase_config.dart';
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

  /// Timestamp of the last password sign-in / sign-up. Every such call is
  /// followed by the caller navigating itself (admin panel, rider dashboard,
  /// guest order success, login screen). The global auth listener uses this
  /// to know NOT to also yank the navigator to the customer home — otherwise
  /// a silent guest sign-in would tear down the order screen mid-checkout.
  static DateTime? _lastProgrammaticSignIn;
  static void _markProgrammatic() => _lastProgrammaticSignIn = DateTime.now();
  static bool get recentlyProgrammatic =>
      _lastProgrammaticSignIn != null &&
      DateTime.now().difference(_lastProgrammaticSignIn!) < const Duration(seconds: 10);

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

  /// The signed-in user's role ('customer' | 'rider' | 'admin'), loaded with
  /// the profile. Null when signed out or not yet loaded.
  static String? currentRole;

  /// True only for an actual CUSTOMER session. A staff member (admin/rider)
  /// who is signed in must NOT be treated as a customer in the customer app —
  /// otherwise the customer Profile shows their staff identity and the "My
  /// Orders" tab (staff RLS) lists every order in the system.
  static bool get isCustomer =>
      isLoggedIn && currentRole != 'admin' && currentRole != 'rider';

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
    currentRole = null;
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
    _markProgrammatic();
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
    _markProgrammatic();
    final email = _phoneToEmail(normalizePhone(phone));
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return _loadProfile();
  }

  // ----- Passwordless phone login (shop's chosen model) -----

  /// Logs a customer in with ONLY their phone number — no password. The
  /// public `phone-login` Edge Function finds (or creates) the account for
  /// this number, sets a fresh password server-side and returns it; we then
  /// establish the session with it. Optional [name]/[area]/[localAddress]/
  /// [whatsapp] (from the sign-up screen) seed a first-time account.
  ///
  /// Called as a CORS "simple request" (text/plain, no custom headers) so no
  /// preflight fires — see [AdminService.guestOrder] for the why.
  static Future<AuthResult> loginWithPhone({
    required String phone,
    String? name,
    String? area,
    String? localAddress,
    String? whatsapp,
  }) async {
    final uri = Uri.parse('${SupabaseConfig.url}/functions/v1/phone-login');
    final payload = jsonEncode({
      'phone': phone,
      if (name != null) 'name': name,
      if (area != null) 'area': area,
      if (localAddress != null) 'local_address': localAddress,
      if (whatsapp != null) 'whatsapp_number': whatsapp,
    });

    final http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: const {'Content-Type': 'text/plain;charset=UTF-8'},
            body: payload,
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const AuthException('সার্ভারে সংযোগ করা যায়নি — ইন্টারনেট দেখে আবার চেষ্টা করুন');
    }

    dynamic data;
    try {
      data = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      data = null;
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = (data is Map && data['error'] is String)
          ? data['error'] as String
          : 'লগইন করা যায়নি — আবার চেষ্টা করুন';
      throw AuthException(msg);
    }

    final ph = data is Map ? data['phone'] as String? : null;
    final pw = data is Map ? data['password'] as String? : null;
    if (ph == null || pw == null) {
      throw const AuthException('লগইন করা যায়নি — আবার চেষ্টা করুন');
    }
    return signInWithPassword(phone: ph, password: pw);
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

    // Remember the role so the customer app can avoid treating staff as a
    // customer (see [isCustomer]).
    currentRole = profile?['role'] as String?;

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
