import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../data/app_settings.dart';
import '../services/language.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/pressable_scale.dart';

/// The "যোগাযোগ" tab. No in-app chat — just the shop's WhatsApp support
/// numbers (set by the admin in the dashboard). Tapping one opens WhatsApp.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh the numbers in case the admin just changed them.
    AppSettings.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _openWhatsapp(String number) async {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$digits');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp খোলা যায়নি')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final numbers = <String>[
      if (AppSettings.supportWhatsapp1.trim().isNotEmpty) AppSettings.supportWhatsapp1.trim(),
      if (AppSettings.supportWhatsapp2.trim().isNotEmpty) AppSettings.supportWhatsapp2.trim(),
    ];

    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isEnglish,
      builder: (context, _, _) => Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(title: Text(AppLanguage.tr('যোগাযোগ'))),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.sm),
            children: [
              // Hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.support_agent_rounded, color: Colors.white, size: 34),
                    const SizedBox(height: 10),
                    Text(AppLanguage.tr('সাহায্য দরকার?'), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                      AppLanguage.tr('অর্ডার, পিকআপ বা যেকোনো বিষয়ে আমাদের WhatsApp-এ মেসেজ করুন — দ্রুত সাড়া দেব।'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(AppLanguage.tr('WhatsApp সাপোর্ট'), style: AppText.h3),
              const SizedBox(height: AppSpace.xs),
              if (numbers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
                  child: Text(AppLanguage.tr('সাপোর্ট নম্বর শীঘ্রই যোগ করা হবে।'), style: AppText.bodyMuted),
                )
              else
                for (int i = 0; i < numbers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FadeSlideIn(
                      delayMs: i * 60,
                      child: _whatsappCard(numbers[i], i == 0 ? AppLanguage.tr('সাপোর্ট লাইন ১') : AppLanguage.tr('সাপোর্ট লাইন ২')),
                    ),
                  ),
              const SizedBox(height: AppSpace.md),
              // Office hours note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.blueSoft.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 18, color: AppColors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLanguage.tr('অফিস সময়: প্রতিদিন সকাল ৯টা – রাত ৯টা'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _whatsappCard(String number, String label) {
    // Pretty display: +880 1XXXX-XXXXXX-ish, but keep it simple.
    final display = number.startsWith('+') ? number : '+$number';
    return PressableScale(
      onTap: () => _openWhatsapp(number),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: const Color(0xFF25D366).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(display, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF25D366), borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(AppLanguage.tr('মেসেজ'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
