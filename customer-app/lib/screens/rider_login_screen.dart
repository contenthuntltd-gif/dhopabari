import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/app_page_route.dart';
import '../widgets/app_logo.dart';
import 'rider/rider_dashboard_screen.dart';

/// Rider sign-in — reachable only from the Customer App's login screen via
/// the ⋮ menu ("Rider"). Lives inside the same Flutter app/port as the
/// customer experience; there is no separate rider URL or process.
class RiderLoginScreen extends StatefulWidget {
  const RiderLoginScreen({super.key});
  @override
  State<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends State<RiderLoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _loading = false;
  String? _phoneError;
  String? _passwordError;

  bool _validate() {
    setState(() {
      _phoneError = _phone.text.trim().replaceAll(RegExp(r'\D'), '').length >= 10 ? null : 'সঠিক মোবাইল নম্বর দিন';
      _passwordError = _password.text.isEmpty ? 'পাসওয়ার্ড দিন' : null;
    });
    return _phoneError == null && _passwordError == null;
  }

  void _handleLogin() {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() => _loading = true);
    Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(AppPageRoute(builder: (_) => const RiderDashboardScreen()), (r) => false);
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.teal,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: AppMotion.slow,
                      curve: Curves.elasticOut,
                      builder: (context, t, child) => Transform.scale(scale: t.clamp(0, 1.15), child: child),
                      child: const AppLogo(size: 108, padding: EdgeInsets.all(12), rounded: true),
                    ),
                    const SizedBox(height: 14),
                    const Text('রাইডার লগইন', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                    const Text('RIDER LOGIN — DELIVERY PARTNER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1.6)),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              FadeSlideIn(
                delayMs: 80,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 16))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('সাইন ইন করুন', style: AppText.h1),
                      const SizedBox(height: 4),
                      const Text('আপনার রাইডার অ্যাকাউন্ট দিয়ে লগইন করুন', style: AppText.bodyMuted),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) {
                          if (_phoneError != null) setState(() => _phoneError = null);
                        },
                        decoration: InputDecoration(
                          hintText: 'মোবাইল নাম্বার দিন',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.muted),
                          errorText: _phoneError,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _password,
                        obscureText: !_showPassword,
                        onSubmitted: (_) => _handleLogin(),
                        onChanged: (_) {
                          if (_passwordError != null) setState(() => _passwordError = null);
                        },
                        decoration: InputDecoration(
                          hintText: 'পাসওয়ার্ড',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.muted),
                          errorText: _passwordError,
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.muted),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('পাসওয়ার্ড রিসেট লিংক পাঠানো হয়েছে'))),
                          child: const Text('পাসওয়ার্ড ভুলেছেন?', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 12.5)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppButton(label: 'লগইন করুন', trailingIcon: Icons.arrow_forward_rounded, loading: _loading, onPressed: _handleLogin, color: AppColors.teal),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('© ২০২৬ ধোপা বাড়ি — সকল অধিকার সংরক্ষিত', style: TextStyle(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
