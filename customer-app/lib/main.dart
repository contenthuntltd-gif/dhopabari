import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/root_shell.dart';
import 'screens/admin_login_screen.dart';
import 'screens/rider_login_screen.dart';
import 'screens/admin/admin_root_shell.dart';
import 'screens/rider/rider_dashboard_screen.dart';
import 'widgets/phone_frame.dart';
import 'widgets/app_page_route.dart';
import 'data/app_settings.dart';
import 'data/cart.dart';
import 'data/catalog.dart';
import 'data/catalog_meta.dart';
import 'data/business_info.dart';
import 'app_globals.dart';
import 'app_flavor.dart';
import 'services/auth_service.dart';
import 'services/push_service.dart';
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
        //
        // The session is persisted in the browser's local storage by default
        // and auto-refreshed, so a logged-in user STAYS logged in across
        // refreshes and restarts — no sudden logouts.
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
          autoRefreshToken: true,
        ),
      );
    } catch (e) {
      debugPrint('Supabase.initialize failed: $e');
    }

    // Session restore gets its OWN try/catch — a hiccup loading the price
    // list or app settings below must never be able to make a real,
    // persisted login look "logged out". Each of these is independent and
    // one failing must not skip (or be skipped by) the others.
    try {
      await AuthService.restoreSession();
    } catch (e) {
      debugPrint('Session restore failed: $e');
    }
    // Live price list + admin-set support numbers — no await: they render
    // from defaults instantly and swap to the DB copy when it arrives.
    // ignore: unawaited_futures
    Catalog.refresh();
    // Live price list: an admin edit reaches every open app/website instantly.
    Catalog.subscribeLive();
    // ignore: unawaited_futures
    AppSettings.load();
    // Categories/services drive the customer order screen's tabs, so load
    // them before first paint (a single, quick key/value read).
    try {
      await CatalogMeta.load();
      await DeliveryOptions.load();
    } catch (e) {
      debugPrint('Catalog meta / delivery options load failed: $e');
    }
    // Phone push (FCM) — Android only; registers this device's token for the
    // signed-in user. No-op on web.
    // ignore: unawaited_futures
    PushService.init();
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

  /// True in an admin/rider build or on the /admin, /rider web URLs — where
  /// the staff screens own navigation and the customer-home auto-route must
  /// stay out of the way.
  bool get _isStaffContext {
    if (isAdminApp || isRiderApp) return true;
    if (kIsWeb) {
      final path = Uri.base.path.toLowerCase();
      return path.contains('admin') || path.contains('rider');
    }
    return false;
  }

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
            // Bind this phone's push token to the freshly signed-in user.
            // ignore: unawaited_futures
            PushService.onLogin();
            // Only auto-route to the CUSTOMER home for a sign-in we didn't
            // drive from a screen (the Google web-redirect returning). In an
            // admin/rider context (dedicated APK or /admin, /rider URL) this
            // must never fire — otherwise a restored staff session would get
            // yanked to the customer home on a page refresh.
            if (!AuthService.recentlyProgrammatic && !_isStaffContext) {
              navigatorKey.currentState?.pushAndRemoveUntil(
                AppPageRoute(builder: (_) => const RootShell()),
                (route) => false,
              );
            }
          case AuthChangeEvent.signedOut:
            // Stop pushes reaching this now-signed-out phone.
            // ignore: unawaited_futures
            PushService.onLogout();
            // Each logout site drives its own navigation (profile → guest
            // home, rider/admin → their login). Navigating here too would
            // race that and briefly leave a blank white page. So do nothing.
            break;
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
  ///   dhopabari.bd/admin  → admin panel (login if not already an admin)
  ///   dhopabari.bd/rider  → rider panel (login if not already a rider)
  ///   everything else     → the customer app (splash → home)
  /// nginx serves index.html for every path, so the app just reads the path.
  ///
  /// The session is restored (and its role loaded) in [main] before this runs,
  /// so a still-signed-in admin/rider lands straight on their panel — a page
  /// refresh (web) or app restart no longer bounces them back to the login
  /// screen, which read as "logged out on every refresh".
  Widget _initialScreen() {
    final loggedIn = AuthService.isLoggedIn;
    final role = AuthService.currentRole;

    final wantsAdmin = isAdminApp || (kIsWeb && Uri.base.path.toLowerCase().contains('admin'));
    final wantsRider = isRiderApp || (kIsWeb && Uri.base.path.toLowerCase().contains('rider'));

    if (wantsAdmin) {
      return (loggedIn && role == 'admin') ? const AdminRootShell() : const AdminLoginScreen();
    }
    if (wantsRider) {
      return (loggedIn && role == 'rider') ? const RiderDashboardScreen() : const RiderLoginScreen();
    }
    return const SplashScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'ধোপা বাড়ি — Dhopa Bari',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) => PhoneFrame(child: child!),
      home: _initialScreen(),
    );
  }
}
