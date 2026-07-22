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
        _loading = false;
      });
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await AppSettings.setSupportNumbers(_one.text, _two.text);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সাপোর্ট নম্বর সংরক্ষণ হয়েছে')),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('সাপোর্ট সেটিংস')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.blueSoft.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppColors.blue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'এই নম্বর দুটো কাস্টমার অ্যাপের "যোগাযোগ" ট্যাবে WhatsApp সাপোর্ট হিসেবে দেখাবে। খালি রাখলে ওই লাইনটি দেখাবে না।',
                          style: TextStyle(fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w600, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
                  child: Column(
                    children: [
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
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'ফরম্যাট: দেশ কোড সহ, + ছাড়া — যেমন 8801712345678',
                    style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(label: 'সংরক্ষণ করুন', loading: _saving, onPressed: _save),
              ],
            ),
    );
  }
}
