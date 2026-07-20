import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_page_route.dart';
import '../services/auth_service.dart';
import '../services/language.dart';
import 'root_shell.dart';

/// OTP verification step for phone sign-in / registration. The code has
/// already been sent (via [AuthService.sendPhoneOtp]) before this screen is
/// pushed; [onResend] re-sends it with the same parameters.
class OtpScreen extends StatefulWidget {
  final String phone;
  final Future<void> Function() onResend;
  const OtpScreen({super.key, required this.phone, required this.onResend});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  bool _loading = false;
  String? _error;
  int _resendIn = 45;
  Timer? _resendTimer;

  bool get _codeValid => _code.text.trim().length == 6;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
    _startResendCountdown();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 45);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendIn <= 1) {
        t.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn -= 1);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_loading || !_codeValid) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await AuthService.verifyPhoneOtp(phone: widget.phone, token: _code.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(builder: (_) => const RootShell()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLanguage.tr('কোড যাচাই করা যায়নি। আবার চেষ্টা করুন।');
      });
    }
  }

  Future<void> _resend() async {
    if (_resendIn > 0) return;
    try {
      await widget.onResend();
      if (!mounted) return;
      _startResendCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLanguage.tr('নতুন কোড পাঠানো হয়েছে'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLanguage.tr('কোড পাঠানো যায়নি। আবার চেষ্টা করুন।'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isEnglish,
      builder: (context, _, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.ink,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(color: AppColors.blueSoft, shape: BoxShape.circle),
                  child: const Icon(Icons.sms_rounded, color: AppColors.blue, size: 34),
                ),
                const SizedBox(height: 20),
                Text(AppLanguage.tr('কোড যাচাই করুন'), style: AppText.h1),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    text: AppLanguage.tr('আমরা একটি ৬-সংখ্যার কোড পাঠিয়েছি '),
                    style: AppText.bodyMuted,
                    children: [
                      TextSpan(
                        text: widget.phone,
                        style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _code,
                  focusNode: _codeFocus,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 10, color: AppColors.ink),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _verify(),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    hintStyle: const TextStyle(letterSpacing: 10, color: AppColors.muted),
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: AppLanguage.tr('যাচাই করুন'),
                  trailingIcon: Icons.check_rounded,
                  loading: _loading,
                  onPressed: _codeValid ? _verify : null,
                ),
                const SizedBox(height: 16),
                Center(
                  child: _resendIn > 0
                      ? Text(
                          '${AppLanguage.tr('আবার কোড পাঠান')} — ${_resendIn}s',
                          style: AppText.bodyMuted,
                        )
                      : TextButton(
                          onPressed: _resend,
                          child: Text(AppLanguage.tr('আবার কোড পাঠান'),
                              style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w900)),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
