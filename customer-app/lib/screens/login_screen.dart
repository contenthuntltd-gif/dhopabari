import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/app_page_route.dart';
import '../widgets/google_icon.dart';
import '../widgets/app_logo.dart';
import '../widgets/support_fab.dart';
import '../services/language.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import 'register_screen.dart';
import 'admin_login_screen.dart';
import 'rider_login_screen.dart';
import 'root_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _loading = false;
  bool _success = false;
  bool _passwordVisible = false;
  String? _phoneError;
  String? _passwordError;
  late final AnimationController _bubbleController;

  bool get _phoneValid => _phoneController.text.trim().replaceAll(RegExp(r'\D'), '').length >= 10;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _phoneController.dispose();
    _phoneFocus.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _phoneError = _phoneValid ? null : AppLanguage.tr('সঠিক মোবাইল নম্বর দিন (১০-১১ ডিজিট)');
      _passwordError = _passwordController.text.trim().length < 6
          ? AppLanguage.tr('পাসওয়ার্ড অন্তত ৬ অক্ষরের হতে হবে')
          : null;
    });
    return _phoneError == null && _passwordError == null;
  }

  /// Signs in with phone number + password.
  Future<void> _handleLogin() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    setState(() => _loading = true);
    try {
      await AuthService.signInWithPassword(phone: phone, password: password);
      await _onLoginSucceeded();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLanguage.tr('লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।'))));
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final result = await AuthService.signInWithGoogle();
      if (result == null) {
        // user cancelled the Google account picker
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }
      await _onLoginSucceeded();
    } on GoogleAuthNotConfigured catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।')));
    }
  }

  Future<void> _onLoginSucceeded() async {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _success = true;
    });
    Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(builder: (_) => const RootShell()),
        (route) => false,
      );
    });
  }

  void _openAccountTypeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountTypeSheet(
        onAdmin: () {
          Navigator.pop(context);
          Navigator.push(context, AppPageRoute(builder: (_) => const AdminLoginScreen()));
        },
        onRider: () {
          Navigator.pop(context);
          Navigator.push(context, AppPageRoute(builder: (_) => const RiderLoginScreen()));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _Hero(bubbleController: _bubbleController, onMenu: _openAccountTypeSheet),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FadeSlideIn(
                          child: ValueListenableBuilder<bool>(
                            valueListenable: AppLanguage.isEnglish,
                            builder: (context, isEnglish, _) => Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(isEnglish ? 'Welcome!' : 'স্বাগতম!', style: AppText.display),
                                    const SizedBox(width: 6),
                                    const _WaveEmoji(),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isEnglish
                                      ? 'Log in to enjoy our premium laundry service.'
                                      : 'লগইন করে আমাদের প্রিমিয়াম লন্ড্রি সেবা উপভোগ করুন।',
                                  textAlign: TextAlign.center,
                                  style: AppText.bodyMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeSlideIn(
                          delayMs: 60,
                          child: Column(
                            children: [
                              Semantics(
                                textField: true,
                                label: AppLanguage.tr('মোবাইল নাম্বার'),
                                child: TextField(
                                  controller: _phoneController,
                                  focusNode: _phoneFocus,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                                  onChanged: (_) {
                                    if (_phoneError != null) setState(() => _phoneError = null);
                                  },
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 12, right: 10),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('🇧🇩 ${AppLanguage.tr('+৮৮০')}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.muted),
                                          const SizedBox(width: 10),
                                          Container(width: 1, height: 20, color: AppColors.line),
                                        ],
                                      ),
                                    ),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 0),
                                    hintText: AppLanguage.tr('মোবাইল নাম্বার দিন'),
                                    errorText: _phoneError,
                                    suffixIcon: _phoneController.text.isEmpty
                                        ? null
                                        : AnimatedSwitcher(
                                            duration: AppMotion.fast,
                                            child: _phoneValid
                                                ? const Icon(Icons.check_circle_rounded, key: ValueKey('ok'), color: AppColors.green, size: 20)
                                                : const SizedBox.shrink(key: ValueKey('none')),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // ─── Password field ───
                              TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: !_passwordVisible,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _handleLogin(),
                                onChanged: (_) {
                                  if (_passwordError != null) setState(() => _passwordError = null);
                                },
                                decoration: InputDecoration(
                                  hintText: AppLanguage.tr('পাসওয়ার্ড দিন'),
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.muted),
                                  errorText: _passwordError,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _passwordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      size: 20,
                                      color: AppColors.muted,
                                    ),
                                    onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              ValueListenableBuilder<bool>(
                                valueListenable: AppLanguage.isEnglish,
                                builder: (context, isEnglish, _) => _GradientButton(
                                  loading: _loading,
                                  success: _success,
                                  label: isEnglish ? 'Login' : 'লগইন',
                                  onPressed: _handleLogin,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(children: [
                          const Expanded(child: Divider(color: AppColors.line)),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(AppLanguage.tr('অথবা'), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5))),
                          const Expanded(child: Divider(color: AppColors.line)),
                        ]),
                        const SizedBox(height: 16),
                        _GoogleButton(onPressed: _handleGoogleLogin),
                        const SizedBox(height: 16),
                        // ─── Sign up with phone (prominent) ───
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00C853), Color(0xFF009624)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00C853).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                              ),
                              onPressed: () => Navigator.push(context, AppPageRoute(builder: (_) => const RegisterScreen())),
                              icon: const Icon(Icons.phone_android_rounded, size: 20),
                              label: ValueListenableBuilder<bool>(
                                valueListenable: AppLanguage.isEnglish,
                                builder: (context, isEnglish, _) => Text(
                                  isEnglish ? 'Sign up with Phone' : 'ফোন নম্বর দিয়ে সাইন আপ',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_success) const Positioned(bottom: 2, right: 16, child: SupportFab()),
          if (_success) const _SuccessOverlay(),
        ],
      ),
    );
  }
}

class _WaveEmoji extends StatefulWidget {
  const _WaveEmoji();
  @override
  State<_WaveEmoji> createState() => _WaveEmojiState();
}

class _WaveEmojiState extends State<_WaveEmoji> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final angle = (t < 0.5 ? (t * 4 - 1) : (3 - t * 4)) * 0.35;
        return Transform.rotate(angle: t < 0.6 ? angle : 0, child: child);
      },
      child: const Text('👋', style: TextStyle(fontSize: 22)),
    );
  }
}

/// Full-bleed brief "logged in" confirmation shown between the loading
/// state resolving and the actual navigation, so success feels like a
/// deliberate moment rather than an instant screen swap.
class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.base,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 550),
              curve: Curves.elasticOut,
              builder: (context, t, child) => Transform.scale(scale: t, child: child),
              child: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: AppColors.teal, size: 46),
              ),
            ),
            const SizedBox(height: 16),
            const Text('সফলভাবে লগইন হয়েছে!', style: AppText.h2),
          ],
        ),
      ),
    );
  }
}

/// The primary login CTA keeps its bespoke blue gradient (brand moment).
/// While loading, it morphs into a compact circle around the spinner
/// (a common premium-app pattern) instead of just swapping its label.
class _GradientButton extends StatefulWidget {
  final bool loading;
  final bool success;
  final String label;
  final VoidCallback onPressed;
  const _GradientButton({required this.loading, required this.success, required this.label, required this.onPressed});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final busy = widget.loading || widget.success;
    return Semantics(
      button: true,
      label: widget.loading ? '${widget.label} — লোড হচ্ছে' : widget.label,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: GestureDetector(
              onTapDown: busy ? null : (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              child: AnimatedScale(
                scale: _pressed ? 0.98 : 1.0,
                duration: AppMotion.fast,
                child: AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.curve,
                  width: busy ? 56 : constraints.maxWidth,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(busy ? 27 : AppRadius.sm),
                    gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDeep]),
                    boxShadow: AppShadows.button,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(busy ? 27 : AppRadius.sm),
                      onTap: busy ? null : widget.onPressed,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: AppMotion.fast,
                          child: widget.loading
                              ? const SizedBox(key: ValueKey('loading'), width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                              : widget.success
                                  ? const Icon(Icons.check_rounded, key: ValueKey('success'), color: Colors.white, size: 24)
                                  : Text('${widget.label}   →', key: const ValueKey('label'), style: AppText.button),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.line, width: 1.2),
          foregroundColor: AppColors.ink,
          backgroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const GoogleIcon(size: 19),
            const SizedBox(width: 10),
            ValueListenableBuilder<bool>(
              valueListenable: AppLanguage.isEnglish,
              builder: (context, isEnglish, _) => Text(
                isEnglish ? 'Continue with Google' : 'Google দিয়ে চালিয়ে যান',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final AnimationController bubbleController;
  final VoidCallback onMenu;
  const _Hero({required this.bubbleController, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow,
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(opacity: t.clamp(0, 1), child: child),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
        child: Container(
          width: double.infinity,
          height: 280,
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(0, -0.4), radius: 1.3, colors: [AppColors.blue, AppColors.blueDeep]),
          ),
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Stack(
            children: [
              ..._bubbles(),
              Positioned(
                top: 20,
                left: 20,
                child: _TouchTarget(child: _RoundIconButton(icon: Icons.more_vert_rounded, tooltip: 'লগইন অপশন দেখুন', onTap: onMenu)),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: _LangPill(),
              ),
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: AppMotion.slow,
                  curve: Curves.elasticOut,
                  builder: (context, t, child) => Opacity(opacity: t.clamp(0, 1), child: Transform.scale(scale: t.clamp(0, 1.1), child: child)),
                  child: AppLogo(
                    size: 114,
                    padding: const EdgeInsets.all(12),
                    rounded: true,
                    zoom: 1.12,
                    shadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 26, offset: const Offset(0, 12)), ...AppShadows.card],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _bubbles() {
    return [
      _bubble(top: 18, left: 32, size: 14, delay: 0.0),
      _bubble(top: 64, left: 78, size: 8, delay: 0.3),
      _bubble(top: 26, right: 46, size: 11, delay: 0.6),
      _bubble(top: 74, right: 90, size: 7, delay: 0.15),
      _bubble(bottom: 30, left: 24, size: 6, delay: 0.45),
      _bubble(bottom: 24, right: 30, size: 9, delay: 0.75),
    ];
  }

  Widget _bubble({double? top, double? bottom, double? left, double? right, required double size, required double delay}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: bubbleController,
        builder: (context, child) {
          final t = (bubbleController.value + delay) % 1.0;
          final dy = -10 * (0.5 - (t - 0.5).abs()) * 2;
          return Transform.translate(offset: Offset(0, dy), child: child);
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
        ),
      ),
    );
  }
}

/// Expands the tappable region to a 44x44 minimum touch target without
/// changing the visible size of the child (accessibility best practice).
class _TouchTarget extends StatelessWidget {
  final Widget child;
  const _TouchTarget({required this.child});
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 44, height: 44, child: Center(child: child));
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.blueDeep.withValues(alpha: 0.14), blurRadius: 8, offset: const Offset(0, 3))]),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(7), child: Icon(icon, color: AppColors.blue, size: 20)),
          ),
        ),
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill();
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isEnglish,
      builder: (context, isEnglish, _) => Semantics(
        button: true,
        label: 'ভাষা পরিবর্তন করুন',
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          elevation: 0,
          shadowColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.blueDeep.withValues(alpha: 0.14), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => AppLanguage.showPicker(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text(
                  isEnglish ? '🌐 English ⌄' : '🌐 বাংলা ⌄',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.blue),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountTypeSheet extends StatelessWidget {
  final VoidCallback onAdmin;
  final VoidCallback onRider;
  const _AccountTypeSheet({required this.onAdmin, required this.onRider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(22, 12, 22, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('লগইন করুন', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 4),
          const Text('আপনার অ্যাকাউন্ট টাইপ নির্বাচন করুন', style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          _sheetOption(
            bg: AppColors.amberSoft,
            iconBg: AppColors.amber,
            emoji: '👤',
            title: 'Customer',
            titleColor: const Color(0xFFB5760A),
            subtitle: 'আপনি এখন এখানেই আছেন',
            onTap: () => Navigator.pop(context),
            trailing: const Icon(Icons.check_circle_rounded, color: AppColors.amber, size: 22),
          ),
          const SizedBox(height: 12),
          _sheetOption(bg: AppColors.tealSoft, iconBg: AppColors.teal, emoji: '🏍️', title: 'Rider', titleColor: AppColors.teal, subtitle: 'রাইডার অ্যাপে লগইন করুন', onTap: onRider),
          const SizedBox(height: 12),
          _sheetOption(bg: AppColors.blueSoft, iconBg: AppColors.blue, emoji: '🛠️', title: 'Admin', titleColor: AppColors.blue, subtitle: 'অ্যাডমিন প্যানেলে লগইন করুন', onTap: onAdmin),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line), foregroundColor: AppColors.ink),
              onPressed: () => Navigator.pop(context),
              child: const Text('বাতিল করুন'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetOption({
    required Color bg,
    required Color iconBg,
    required String emoji,
    required String title,
    required Color titleColor,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: titleColor)),
                    Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              trailing ?? Icon(Icons.chevron_right_rounded, color: titleColor, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}
