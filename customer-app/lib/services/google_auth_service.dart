import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Thrown when native (mobile) Google Sign-In can't proceed because the
/// Google OAuth client IDs haven't been configured yet.
class GoogleAuthNotConfigured implements Exception {
  @override
  String toString() => 'Google সাইন-ইন এখনো সেটআপ করা হয়নি। অ্যাডমিনকে জানান।';
}

/// Google sign-in via Supabase, per platform:
///
///   • Web    — full-page OAuth redirect to Google and back. Nothing extra
///              is needed in the app; the Google client ID/secret live in
///              the Supabase Dashboard (Authentication → Providers → Google).
///   • Mobile — native Google picker → `signInWithIdToken` (needs the Google
///              client IDs in [SupabaseConfig]).
class GoogleAuthService {
  static SupabaseClient get _supabase => Supabase.instance.client;

  /// Starts the sign-in. On web the browser navigates away and this returns
  /// null (the session is restored from the URL when the app reloads — see
  /// SplashScreen). On mobile it returns the signed-in [User], or null if
  /// the user cancelled the picker.
  static Future<User?> signIn() async {
    if (kIsWeb) {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,
      );
      return null; // redirecting to Google…
    }

    if (SupabaseConfig.googleWebClientId.isEmpty) {
      throw GoogleAuthNotConfigured();
    }

    final googleSignIn = GoogleSignIn(
      // On Android the serverClientId must be the *web* client ID so the
      // returned idToken has the right audience for Supabase to verify.
      serverClientId: SupabaseConfig.googleWebClientId,
      clientId: SupabaseConfig.googleIosClientId.isEmpty
          ? null
          : SupabaseConfig.googleIosClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw GoogleAuthNotConfigured();
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
    return response.user;
  }

  static Future<void> signOut() async {
    try {
      if (!kIsWeb) await GoogleSignIn().signOut();
    } catch (_) {
      // ignore — Supabase session is the source of truth
    }
  }
}
