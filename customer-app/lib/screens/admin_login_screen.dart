import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../widgets/app_button.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/app_page_route.dart';
import '../widgets/app_logo.dart';
import 'admin/admin_root_shell.dart';
import 'rider/rider_dashboard_screen.dart';

/// Admin sign-in — reachable only from the Customer App's login screen via
/// the ⋮ menu ("Admin"). Lives inside the same Flutter app/port as the
/// customer experience; there is no separate admin URL or process.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _rememberMe = true;
  bool _loading = false;
  String? _usernameError;
  String? _passwordError;

  bool _validate() {
    setState(() {
      _usernameError = _username.text.trim().isEmpty ? 'মোবাইল নম্বর দিন' : null;
      _passwordError = _password.text.isEmpty ? 'পাসওয়ার্ড দিন' : null;
    });
    return _usernameError == null && _passwordError == null;
  }

  /// Signs in against Supabase, then checks the account's role. Staff and
  /// customers share one credential system, so a successful password is not
  /// on its own permission to enter the panel — a customer who finds this
  /// screen gets signed straight back out.
  Future<void> _handleLogin() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() => _loading = true);

    try {
      await AuthService.signInWithPassword(
        phone: _username.text.trim(),
        password: _password.text,
      );

      AdminService.clearRoleCache();
      final role = await AdminService.currentRole();

      if (!mounted) return;

      if (role != 'admin' && role != 'rider') {
        await AuthService.logout();
        AdminService.clearRoleCache();
        if (!mounted) return;
        setState(() {
          _loading = false;
          _passwordError = 'এই অ্যাকাউন্টের প্যানেলে প্রবেশের অনুমতি নেই';
        });
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(builder: (_) => role == 'rider' ? const RiderDashboardScreen() : const AdminRootShell()),
        (r) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _passwordError = _authMessage(e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _passwordError = 'লগইন করা যায়নি — ইন্টারনেট সংযোগ দেখুন';
      });
    }
  }

  String _authMessage(String raw) {
    if (RegExp(r'invalid.*credential', caseSensitive: false).hasMatch(raw)) {
      return 'নম্বর বা পাসওয়ার্ড ভুল';
    }
    return raw;
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
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.08),
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
                    const Text('অ্যাডমিন প্যানেল', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
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
                        keyboardType: TextInputType.phone,
                        onChanged: (_) {
                          if (_usernameError != null) setState(() => _usernameError = null);
                        },
                        decoration: InputDecoration(
                          hintText: 'মোবাইল নম্বর',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.muted),
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
