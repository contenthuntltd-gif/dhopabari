import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/root_shell.dart';
import 'screens/login_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/rider_login_screen.dart';
import 'widgets/phone_frame.dart';
import 'widgets/app_page_route.dart';
import 'data/app_settings.dart';
import 'data/cart.dart';
import 'data/catalog.dart';
import 'services/auth_service.dart';
import 'services/supabase_config.dart';
import 'services/language.dart';

/// Global navigator key so the auth listener can route from outside the
/// widget tree (e.g. when a Google web-redirect completes after startup).
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
        // Implicit flow returns the session token directly in the redirect
        // URL fragment (no PKCE code exchange), which avoids the web
        // `flow_state_already_used` error on the OAuth round-trip.
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
      await AuthService.restoreSession();
      // Live price list + admin-set support numbers — no await: they render
      // from defaults instantly and swap to the DB copy when it arrives.
      // ignore: unawaited_futures
      Catalog.refresh();
      // ignore: unawaited_futures
      AppSettings.load();
    } catch (e) {
      debugPrint('Supabase init/session restore failed: $e');
    }
  } else {
    debugPrint('SUPABASE_ANON_KEY not set — auth disabled. See lib/services/supabase_config.dart');
  }
  await AppLanguage.restore();
  await Cart.load(); // restore any order-in-progress
  runApp(const DhopaBariApp());
}

class DhopaBariApp extends StatefulWidget {
  const DhopaBariApp({super.key});

  @override
  State<DhopaBariApp> createState() => _DhopaBariAppState();
}

class _DhopaBariAppState extends State<DhopaBariApp> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    if (SupabaseConfig.isConfigured) {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        switch (data.event) {
          case AuthChangeEvent.signedIn:
            // A sign-in completed. Always refresh the profile. Only take over
            // navigation for sign-ins WE didn't drive from a screen (i.e. the
            // Google web-redirect returning) — password sign-ins (admin,
            // rider, guest order, login) navigate themselves, and hijacking
            // the navigator here would tear down their flow mid-step.
            await AuthService.syncProfile();
            if (!AuthService.recentlyProgrammatic) {
              navigatorKey.currentState?.pushAndRemoveUntil(
                AppPageRoute(builder: (_) => const RootShell()),
                (route) => false,
              );
            }
          case AuthChangeEvent.signedOut:
            navigatorKey.currentState?.pushAndRemoveUntil(
              AppPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          default:
            break;
        }
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// Deep-link entry by URL path (web):
  ///   dhopabari.bd/admin  → admin login
  ///   dhopabari.bd/rider  → rider login
  ///   everything else     → the customer app (splash → home)
  /// nginx serves index.html for every path, so the app just reads the path.
  Widget _initialScreen() {
    if (kIsWeb) {
      final path = Uri.base.path.toLowerCase();
      if (path.contains('admin')) return const AdminLoginScreen();
      if (path.contains('rider')) return const RiderLoginScreen();
    }
    return const SplashScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ধোপা বাড়ি — Dhopa Bari',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) => PhoneFrame(child: child!),
      home: _initialScreen(),
    );
  }
}
