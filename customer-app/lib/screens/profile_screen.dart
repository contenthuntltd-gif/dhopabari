import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/app_page_route.dart';
import '../widgets/app_button.dart';
import '../widgets/app_logo.dart';
import '../services/auth_service.dart';
import '../services/language.dart';
import '../data/app_settings.dart';
import 'login_screen.dart';
import 'orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  final void Function(int tabIndex)? onSwitchTab;
  const ProfileScreen({super.key, this.onSwitchTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loggingOut = false;

  /// Logout — brand-new bottom-sheet flow. Tapping the button slides up a
  /// confirmation sheet (হ্যাঁ / না). On confirm we sign out and drop to the
  /// Home tab in-place (no route push, no page reload → no white/blank flash).
  Future<void> _logout() async {
    if (_loggingOut) return;

    final yes = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 14, 24, MediaQuery.of(sheetCtx).padding.bottom + 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 22),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: AppColors.dangerSoft, shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 30),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('লগআউট করবেন?', style: AppText.h1)),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'আপনি চাইলে যেকোনো সময় আবার মোবাইল নম্বর দিয়ে লগইন করতে পারবেন।',
                textAlign: TextAlign.center,
                style: AppText.bodyMuted,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                onPressed: () => Navigator.pop(sheetCtx, true),
                icon: const Icon(Icons.logout_rounded, size: 19),
                label: const Text('হ্যাঁ, লগআউট করুন', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.ink),
                onPressed: () => Navigator.pop(sheetCtx, false),
                child: const Text('না, থাক', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );

    if (yes != true || !mounted) return;

    _loggingOut = true;
    try {
      await AuthService.logout();
    } catch (_) {
      // Ignore — the local session is cleared regardless.
    }
    _loggingOut = false;
    if (!mounted) return;

    // Instant + in-place: this tab now renders the guest login, and we jump to
    // the Home tab. No navigation → no white/blank flash, no reload delay.
    setState(() {});
    widget.onSwitchTab?.call(0);

    // A brief confirmation so the action feels acknowledged.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('আপনি লগআউট হয়েছেন'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: MockData.userName);
    final areaCtrl = TextEditingController(text: MockData.userArea);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
          padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('প্রোফাইল সম্পাদনা করুন', style: AppText.h1),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'পূর্ণ নাম', prefixIcon: Icon(Icons.person_outline_rounded, size: 20))),
              const SizedBox(height: 14),
              TextField(controller: areaCtrl, decoration: const InputDecoration(hintText: 'এলাকা', prefixIcon: Icon(Icons.location_on_outlined, size: 20))),
              const SizedBox(height: 20),
              AppButton(
                label: 'সংরক্ষণ করুন',
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(context, true);
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) {
      setState(() {
        MockData.userName = nameCtrl.text.trim();
        MockData.userArea = areaCtrl.text.trim();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('প্রোফাইল আপডেট হয়েছে')));
    }
  }

  void _openAbout() => _openTextPage(
        title: AppLanguage.tr('সম্পর্কে'),
        text: AppSettings.aboutText.trim(),
        fallback: 'ধোপা বাড়ি — কাপড়ের যত্নে আপনার বিশ্বস্ত পার্টনার।\n\nবিস্তারিত তথ্য শীঘ্রই যোগ করা হবে।',
      );

  void _openPrivacy() => _openTextPage(
        title: AppLanguage.tr('প্রাইভেসি পলিসি'),
        text: AppSettings.privacyText.trim(),
        fallback: 'আমরা আপনার তথ্যের গোপনীয়তাকে সম্মান করি।\n\nবিস্তারিত প্রাইভেসি পলিসি শীঘ্রই যোগ করা হবে।',
      );

  /// Shows an admin-editable text page (About / Privacy) as a bottom sheet.
  void _openTextPage({required String title, required String text, required String fallback}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scroll) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(title, style: AppText.h1),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scroll,
                  child: Text(
                    text.isNotEmpty ? text : fallback,
                    style: const TextStyle(fontSize: 13.5, height: 1.6, color: AppColors.ink, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Guest (or a staff account, which is not a customer here): show the
    // login page DIRECTLY as the Profile tab — no intermediate "you're not
    // logged in" card, so it's one tap from the bottom nav to the login form.
    if (!AuthService.isCustomer) {
      return const LoginScreen();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isEnglish,
      builder: (context, _, _) => SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(AppLanguage.tr('প্রোফাইল'), style: AppText.h1),
          ),
          const SizedBox(height: AppSpace.sm),
          FadeSlideIn(child: _ProfileHero(onEdit: _editProfile)),
          const SizedBox(height: AppSpace.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
            child: Column(
              children: [
                FadeSlideIn(
                  delayMs: 60,
                  child: _menuGroup(
                    label: AppLanguage.tr('অ্যাকাউন্ট'),
                    tiles: [
                      _menuTile(context, Icons.person_outline_rounded, AppLanguage.tr('ব্যক্তিগত তথ্য'), AppColors.blue, onTap: _editProfile),
                      _menuTile(context, Icons.receipt_long_rounded, AppLanguage.tr('অর্ডার ইতিহাস'), AppColors.teal, isLast: true, onTap: () => Navigator.push(context, AppPageRoute(builder: (_) => const OrdersScreen()))),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                FadeSlideIn(
                  delayMs: 100,
                  child: _menuGroup(
                    label: AppLanguage.tr('সাপোর্ট'),
                    tiles: [
                      _menuTile(context, Icons.chat_bubble_rounded, AppLanguage.tr('লাইভ চ্যাট'), AppColors.teal, isLast: true, onTap: widget.onSwitchTab == null ? null : () => widget.onSwitchTab!(3)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                FadeSlideIn(
                  delayMs: 140,
                  child: _menuGroup(
                    label: AppLanguage.tr('সাধারণ'),
                    tiles: [
                      _menuTile(context, Icons.language_rounded, AppLanguage.tr('ভাষা'), AppColors.muted, trailing: AppLanguage.isEnglish.value ? 'English' : 'বাংলা', onTap: () => AppLanguage.showPicker(context)),
                      _menuTile(context, Icons.info_outline_rounded, AppLanguage.tr('সম্পর্কে'), AppColors.muted, onTap: _openAbout),
                      _menuTile(context, Icons.privacy_tip_outlined, AppLanguage.tr('প্রাইভেসি পলিসি'), AppColors.muted, isLast: true, onTap: _openPrivacy),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                FadeSlideIn(
                  delayMs: 180,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 15)),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(AppLanguage.tr('লগআউট'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                const Center(child: AppLogo(size: 36)),
                const SizedBox(height: AppSpace.xs),
                const Center(child: Text('সংস্করণ ১.০.০', style: AppText.caption)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _menuGroup({String? label, required List<Widget> tiles}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.6)),
          ),
        ],
        Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _menuTile(
    BuildContext context,
    IconData icon,
    String label,
    Color iconColor, {
    bool danger = false,
    bool isLast = false,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label শীঘ্রই আসছে'))),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : AppColors.line, width: 1))),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Semantics(
            button: true,
            label: label,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: (danger ? AppColors.danger : iconColor).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 17, color: danger ? AppColors.danger : iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: danger ? AppColors.danger : AppColors.ink))),
                if (trailing != null) ...[
                  Text(trailing, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                ],
                if (!danger) const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium profile hero: full gradient card with an avatar + profile
/// completion ring, a Gold Member badge, customer ID, phone and area, and
/// an Edit Profile action.
class _ProfileHero extends StatelessWidget {
  final VoidCallback onEdit;
  const _ProfileHero({required this.onEdit});

  static const double _completion = 0.9;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.32), blurRadius: 22, offset: const Offset(0, 12))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: _completion,
                          strokeWidth: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      Container(
                        width: 58,
                        height: 58,
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const CircleAvatar(backgroundColor: AppColors.blue, child: Icon(Icons.person_rounded, color: Colors.white, size: 28)),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Tooltip(
                          message: 'প্রোফাইল সম্পাদনা করুন',
                          child: PressableScale(
                            onTap: onEdit,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(color: AppColors.teal, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 11),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(MockData.userName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFF5C64B), borderRadius: BorderRadius.circular(999)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.workspace_premium_rounded, size: 10, color: Color(0xFF7A5B00)),
                                SizedBox(width: 3),
                                Text('গোল্ড মেম্বার', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF7A5B00))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('CUST-${MockData.userPhone}', style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Colors.white70, size: 12),
                          const SizedBox(width: 3),
                          Expanded(child: Text(MockData.userArea, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

