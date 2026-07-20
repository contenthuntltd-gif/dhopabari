import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../data/business_info.dart';
import 'pressable_scale.dart';

/// The one shared "সাহায্য ও সাপোর্ট" bottom sheet (call / WhatsApp / email)
/// — used by the Support Center menu tile on Profile *and* by
/// [SupportFab], the floating bot icon that's always on-screen so users
/// don't have to dig through the menu to reach it.
void showSupportSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('সাহায্য ও সাপোর্ট', style: AppText.h1),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled_rounded, size: 14, color: AppColors.blue),
                const SizedBox(width: 6),
                Text('অফিস সময়: ${BusinessHours.labelWithDays}', style: const TextStyle(fontSize: 11.5, color: AppColors.blue, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _supportTile(context, Icons.call_rounded, 'কল করুন', '+৮৮০ ১৭০০-০০০০০০', AppColors.blue, () => launchUrl(Uri.parse('tel:+8801700000000'))),
          _supportTile(context, Icons.chat_rounded, 'WhatsApp', 'সরাসরি চ্যাট করুন', const Color(0xFF25D366), () => launchUrl(Uri.parse('https://wa.me/8801700000000'), mode: LaunchMode.externalApplication)),
          _supportTile(context, Icons.email_rounded, 'ইমেইল', 'support@dhopabari.com', AppColors.amber, () => launchUrl(Uri.parse('mailto:support@dhopabari.com'))),
        ],
      ),
    ),
  );
}

Widget _supportTile(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );
}

/// Floating "bot" support button — always available (Home, Login, ...)
/// so help is never more than one tap away, without waiting for a real
/// chat-bot backend to exist yet.
class SupportFab extends StatelessWidget {
  const SupportFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'সাহায্য ও সাপোর্ট',
      child: PressableScale(
        onTap: () => showSupportSheet(context),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
            border: Border.all(color: Colors.white, width: 2.5),
          ),
          child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
