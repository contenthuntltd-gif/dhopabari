import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_page_route.dart';
import 'root_shell.dart';

/// First screen shown on app launch. Displays the official brand mark, then
/// routes to the home shell if already signed in (returning user, or a
/// Google web-redirect that just completed) or the Login screen otherwise.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      // Always land on Home. Customers can browse and order as a guest;
      // logging in is optional (and reachable from the menu). A returning
      // signed-in user's session is already restored, so their data shows.
      Navigator.of(context).pushReplacement(
        AppPageRoute(builder: (_) => const RootShell()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Opacity(opacity: t.clamp(0, 1), child: Transform.scale(scale: 0.85 + 0.15 * t.clamp(0, 1), child: child)),
          child: const AppLogo(size: 220, padding: EdgeInsets.all(24)),
        ),
      ),
    );
  }
}
