import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/app_settings.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_button.dart';

/// Admin screen to set the two WhatsApp support numbers shown to customers
/// on the যোগাযোগ tab. Writes to `app_settings` (staff-only via RLS).
class SupportSettingsScreen extends StatefulWidget {
  const SupportSettingsScreen({super.key});

  @override
  State<SupportSettingsScreen> createState() => _SupportSettingsScreenState();
}

class _SupportSettingsScreenState extends State<SupportSettingsScreen> {
  late final _one = TextEditingController(text: AppSettings.supportWhatsapp1);
  late final _two = TextEditingController(text: AppSettings.supportWhatsapp2);
  late final _facebook = TextEditingController(text: AppSettings.facebookUrl);
  late final _email = TextEditingController(text: AppSettings.supportEmail);
  late final _about = TextEditingController(text: AppSettings.aboutText);
  late final _privacy = TextEditingController(text: AppSettings.privacyText);
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pull the freshest values before editing.
    AppSettings.load().then((_) {
      if (!mounted) return;
      setState(() {
        _one.text = AppSettings.supportWhatsapp1;
        _two.text = AppSettings.supportWhatsapp2;
        _facebook.text = AppSettings.facebookUrl;
        _email.text = AppSettings.supportEmail;
        _about.text = AppSettings.aboutText;
        _privacy.text = AppSettings.privacyText;
        _loading = false;
      });
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await AppSettings.setContact(
        whatsapp1: _one.text,
        whatsapp2: _two.text,
        facebook: _facebook.text,
        email: _email.text,
      );
      await AppSettings.setPages(about: _about.text, privacy: _privacy.text);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সব সেটিংস সংরক্ষণ হয়েছে')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminService.messageFor(e))),
      );
    }
  }

  @override
  void dispose() {
    _one.dispose();
    _two.dispose();
    _facebook.dispose();
    _email.dispose();
    _about.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('সাপোর্ট সেটিংস')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Hero
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.settings_suggest_rounded, color: Colors.white, size: 30),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('যোগাযোগ ও পেজ সেটিংস', style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w900)),
                            SizedBox(height: 3),
                            Text('কাস্টমার অ্যাপে যা দেখাবে — এখান থেকেই নিয়ন্ত্রণ করুন', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Contact section ──
                _sectionHeader(Icons.contact_phone_rounded, 'যোগাযোগ', 'কাস্টমার অ্যাপের "যোগাযোগ" ট্যাবে দেখাবে'),
                const SizedBox(height: 12),
                _card(children: [
                  TextField(
                    controller: _one,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'সাপোর্ট WhatsApp ১',
                      hintText: '8801XXXXXXXXX (দেশ কোড সহ)',
                      prefixIcon: Icon(Icons.chat_rounded, size: 20, color: Color(0xFF25D366)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _two,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'সাপোর্ট WhatsApp ২ (ঐচ্ছিক)',
                      hintText: '8801XXXXXXXXX',
                      prefixIcon: Icon(Icons.chat_rounded, size: 20, color: Color(0xFF25D366)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _facebook,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'ফেসবুক পেজ লিংক (ঐচ্ছিক)',
                      hintText: 'https://facebook.com/yourpage',
                      prefixIcon: Icon(Icons.facebook_rounded, size: 20, color: Color(0xFF1877F2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'সাপোর্ট ইমেইল (ঐচ্ছিক)',
                      hintText: 'support@dhopabari.com',
                      prefixIcon: Icon(Icons.email_rounded, size: 20, color: AppColors.blue),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'নম্বর ফরম্যাট: দেশ কোড সহ, + ছাড়া — যেমন 8801712345678। খালি রাখলে ওই লাইন দেখাবে না।',
                    style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 22),

                // ── Profile pages section ──
                _sectionHeader(Icons.article_rounded, 'প্রোফাইল পেজের লেখা', 'প্রোফাইল → "সম্পর্কে" ও "প্রাইভেসি পলিসি"-তে দেখাবে'),
                const SizedBox(height: 12),
                _card(children: [
                  TextField(
                    controller: _about,
                    maxLines: 5,
                    minLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'সম্পর্কে (About)',
                      hintText: 'ধোপা বাড়ি সম্পর্কে লিখুন…',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(padding: EdgeInsets.only(bottom: 60), child: Icon(Icons.info_outline_rounded, size: 20, color: AppColors.blue)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _privacy,
                    maxLines: 7,
                    minLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'প্রাইভেসি পলিসি',
                      hintText: 'প্রাইভেসি পলিসি লিখুন…',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(padding: EdgeInsets.only(bottom: 90), child: Icon(Icons.privacy_tip_outlined, size: 20, color: AppColors.blue)),
                    ),
                  ),
                ]),
                const SizedBox(height: 22),
                AppButton(label: 'সব সংরক্ষণ করুন', loading: _saving, onPressed: _save),
                const SizedBox(height: 8),
              ],
              ),
            ),
            ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 20, color: AppColors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.ink)),
              Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
      child: Column(children: children),
    );
  }
}
