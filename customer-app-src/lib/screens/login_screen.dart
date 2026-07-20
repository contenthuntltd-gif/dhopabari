import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
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
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _loading = false;
  late final AnimationController _bubbleController;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() => _loading = true);
    Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootShell()),
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
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
        },
        onRider: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderLoginScreen()));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _Hero(bubbleController: _bubbleController, onMenu: _openAccountTypeSheet),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('স্বাগতম! 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink)),
                    const SizedBox(height: 6),
                    const Text(
                      'লগইন করে আমাদের প্রিমিয়াম লন্ড্রি সেবা উপভোগ করুন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: AppColors.muted, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          child: Text('🇧🇩 +৮৮০', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink)),
                        ),
                        prefixIconConstraints: BoxConstraints(minWidth: 0),
                        hintText: 'মোবাইল নাম্বার দিন',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.muted, size: 20),
                        hintText: 'পাসওয়ার্ড দিন',
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.muted, size: 20),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        child: const Text('পাসওয়ার্ড ভুলেছেন?', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDeep]),
                          boxShadow: AppShadows.button,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0),
                          onPressed: _loading ? null : _handleLogin,
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                              : const Text('লগইন করুন   →'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(children: const [
                      Expanded(child: Divider(color: AppColors.line)),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('অথবা', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5))),
                      Expanded(child: Divider(color: AppColors.line)),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.line, width: 1.2), foregroundColor: AppColors.ink),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('গুগল লগইন শীঘ্রই আসছে')));
                        },
                        icon: const Text('G', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.blue)),
                        label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text('নতুন অ্যাকাউন্ট তৈরি করুন'),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text('আমাদের সাথে যুক্ত থাকুন', style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _SocialCard(emoji: '💬', title: 'WhatsApp', subtitle: 'আমাদের সাথে চ্যাট করুন')),
                        const SizedBox(width: 10),
                        Expanded(child: _SocialCard(emoji: '📘', title: 'Facebook', subtitle: 'আমাদের পেজ ফলো করুন')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.blue.withOpacity(0.1)),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 10,
                        children: const [
                          _FeatureChip(emoji: '🚚', label: 'ফ্রি পিকআপ'),
                          _FeatureChip(emoji: '🧺', label: 'প্রিমিয়াম ওয়াশ'),
                          _FeatureChip(emoji: '🛡️', label: 'নিরাপদ সেবা'),
                          _FeatureChip(emoji: '⏰', label: 'সময়মতো ডেলিভারি'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('আপনার কাপড়, আমাদের দায়িত্ব। 💙', style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
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
    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        color: AppColors.blueSoft,
        padding: const EdgeInsets.only(top: 20, bottom: 26),
        child: Stack(
          children: [
            ..._bubbles(),
            Positioned(
              top: 16,
              left: 16,
              child: _RoundIconButton(icon: Icons.more_vert_rounded, onTap: onMenu),
            ),
            const Positioned(
              top: 16,
              right: 16,
              child: _LangPill(),
            ),
            Column(
              children: [
                const SizedBox(height: 22),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppShadows.card,
                  ),
                  child: const Icon(Icons.local_laundry_service_rounded, color: AppColors.blue, size: 46),
                ),
                const SizedBox(height: 10),
                const Text('ধোপা বাড়ি', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.blue)),
                const Text('PREMIUM LAUNDRY SERVICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.blue, letterSpacing: 2)),
                const SizedBox(height: 10),
                const Text('কাপড়ের যত্নে আপনার বিশ্বস্ত পার্টনার', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _bubbles() {
    return [
      _bubble(top: 18, left: 40, size: 14, delay: 0.0),
      _bubble(top: 50, left: 80, size: 9, delay: 0.3),
      _bubble(top: 26, right: 50, size: 11, delay: 0.6),
      _bubble(top: 64, right: 90, size: 7, delay: 0.15),
    ];
  }

  Widget _bubble({double? top, double? left, double? right, required double size, required double delay}) {
    return Positioned(
      top: top,
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
            color: AppColors.blue.withOpacity(0.14),
            border: Border.all(color: AppColors.blue.withOpacity(0.25)),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(7), child: Icon(icon, color: AppColors.blue, size: 20)),
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: const Text('🌐 বাংলা ⌄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.blue)),
    );
  }
}

class _SocialCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _SocialCard({required this.emoji, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                Text(subtitle, style: const TextStyle(fontSize: 9.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _FeatureChip({required this.emoji, required this.label});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.ink))),
        ],
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
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('লগইন করুন', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 4),
          const Text('আপনার অ্যাকাউন্ট টাইপ নির্বাচন করুন', style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          _sheetOption(bg: AppColors.blueSoft, iconBg: AppColors.blue, emoji: '🛠️', title: 'Admin Panel', titleColor: AppColors.blue, subtitle: 'অ্যাডমিন প্যানেলে লগইন করুন', onTap: onAdmin),
          const SizedBox(height: 12),
          _sheetOption(bg: AppColors.tealSoft, iconBg: AppColors.teal, emoji: '🏍️', title: 'Rider App', titleColor: AppColors.teal, subtitle: 'রাইডার অ্যাপে লগইন করুন', onTap: onRider),
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
              Icon(Icons.chevron_right_rounded, color: titleColor, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}
