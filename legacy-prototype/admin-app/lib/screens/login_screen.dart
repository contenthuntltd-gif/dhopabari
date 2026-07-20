import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/app_page_route.dart';
import 'root_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _rememberMe = true;
  bool _loading = false;
  String? _usernameError;
  String? _passwordError;

  bool _validate() {
    setState(() {
      _usernameError = _username.text.trim().isEmpty ? 'ইউজারনেম অথবা ইমেইল দিন' : null;
      _passwordError = _password.text.isEmpty ? 'পাসওয়ার্ড দিন' : null;
    });
    return _usernameError == null && _passwordError == null;
  }

  void _handleLogin() {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() => _loading = true);
    Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(AppPageRoute(builder: (_) => const RootShell()), (r) => false);
    });
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1F3A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: AppMotion.slow,
                      curve: Curves.elasticOut,
                      builder: (context, t, child) => Transform.scale(scale: t.clamp(0, 1.15), child: child),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 42),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('ধোপা বাড়ি অ্যাডমিন', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                    const Text('PANEL LOGIN — SECURE ACCESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.teal, letterSpacing: 2)),
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
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 16))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('সাইন ইন করুন', style: AppText.h1),
                      const SizedBox(height: 4),
                      const Text('আপনার অ্যাডমিন অ্যাকাউন্ট দিয়ে লগইন করুন', style: AppText.bodyMuted),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _username,
                        onChanged: (_) {
                          if (_usernameError != null) setState(() => _usernameError = null);
                        },
                        decoration: InputDecoration(
                          hintText: 'ইউজারনেম / ইমেইল',
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.muted),
                          errorText: _usernameError,
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
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: AppMotion.fast,
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: _rememberMe ? AppColors.blue : Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: _rememberMe ? AppColors.blue : AppColors.line, width: 1.5),
                                    ),
                                    child: _rememberMe ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('মনে রাখুন', style: TextStyle(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('পাসওয়ার্ড রিসেট লিংক পাঠানো হয়েছে'))),
                            child: const Text('পাসওয়ার্ড ভুলেছেন?', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700, fontSize: 12.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppButton(label: 'লগইন করুন', trailingIcon: Icons.arrow_forward_rounded, loading: _loading, onPressed: _handleLogin),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(AppRadius.sm)),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.muted),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('OTP ভেরিফিকেশন শীঘ্রই আসছে', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700))),
                            Switch(
                              value: false,
                              onChanged: null,
                              activeTrackColor: AppColors.blue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('© ২০২৬ ধোপা বাড়ি — সকল অধিকার সংরক্ষিত', style: TextStyle(fontSize: 10.5, color: Colors.white38, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
