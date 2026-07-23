import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/app_button.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/app_page_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/language.dart';
import 'root_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _localAddress = TextEditingController();
  final _whatsapp = TextEditingController();
  final _areaDisplay = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _localAddressFocus = FocusNode();
  final _whatsappFocus = FocusNode();

  bool _loading = false;
  String? _nameError;
  String? _phoneError;
  String? _areaError;
  String? _localAddressError;
  String? _whatsappError;
  String? _selectedArea;

  bool _validate() {
    final digits = _phone.text.trim().replaceAll(RegExp(r'\D'), '');
    final whatsappDigits = _whatsapp.text.trim().replaceAll(RegExp(r'\D'), '');
    setState(() {
      _nameError = _name.text.trim().isEmpty ? AppLanguage.tr('পূর্ণ নাম দিন') : null;
      _phoneError = digits.length < 10 ? AppLanguage.tr('সঠিক মোবাইল নম্বর দিন (১০-১১ ডিজিট)') : null;
      _areaError = _selectedArea == null ? AppLanguage.tr('এলাকা নির্বাচন করুন') : null;
      _localAddressError = _localAddress.text.trim().isEmpty ? AppLanguage.tr('বাসা/বিল্ডিং/রোড এর ঠিকানা দিন') : null;
      _whatsappError = whatsappDigits.isNotEmpty && whatsappDigits.length < 10 ? AppLanguage.tr('সঠিক হোয়াটসঅ্যাপ নাম্বার দিন') : null;
    });
    return _nameError == null && _phoneError == null && _areaError == null && _localAddressError == null && _whatsappError == null;
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    final phone = _phone.text.trim();
    final name = _name.text.trim();
    final area = _selectedArea!;
    final localAddress = _localAddress.text.trim();
    final whatsapp = _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim();

    setState(() => _loading = true);
    try {
      // Passwordless: create (or reuse) the account for this phone and sign in.
      await AuthService.loginWithPhone(
        phone: phone,
        name: name,
        area: area,
        localAddress: localAddress,
        whatsapp: whatsapp,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        AppPageRoute(builder: (_) => const RootShell()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLanguage.tr('সার্ভারের সাথে সংযোগ করা যায়নি। আবার চেষ্টা করুন।'))));
    }
  }

  Future<void> _pickArea() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AreaPickerSheet(selected: _selectedArea),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedArea = picked;
        _areaDisplay.text = picked;
        _areaError = null;
      });
      FocusScope.of(context).requestFocus(_localAddressFocus);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _localAddress.dispose();
    _whatsapp.dispose();
    _areaDisplay.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _localAddressFocus.dispose();
    _whatsappFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isEnglish,
      builder: (context, _, _) => Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: AppColors.blueSoft,
                padding: const EdgeInsets.only(top: 20, bottom: 22),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Tooltip(
                          message: AppLanguage.tr('ফিরে যান'),
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => Navigator.pop(context),
                              child: const Padding(padding: EdgeInsets.all(7), child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.ink, size: 16)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.local_laundry_service_rounded, color: AppColors.blue, size: 44),
                    const SizedBox(height: 8),
                    Text(AppLanguage.tr('ধোপা বাড়ি'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.blue)),
                    const Text('PREMIUM LAUNDRY SERVICE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.blue, letterSpacing: 2)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
                child: FadeSlideIn(
                  child: Column(
                    children: [
                      Text(AppLanguage.tr('একাউন্ট তৈরি করুন'), style: AppText.h1),
                      const SizedBox(height: 4),
                      Text(AppLanguage.tr('নতুন একাউন্ট খুলে অর্ডার শুরু করুন'), style: AppText.bodyMuted),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _name,
                        focusNode: _nameFocus,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_phoneFocus),
                        onChanged: (_) {
                          if (_nameError != null) setState(() => _nameError = null);
                        },
                        decoration: InputDecoration(
                          hintText: AppLanguage.tr('পূর্ণ নাম দিন'),
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.muted),
                          errorText: _nameError,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _phone,
                        focusNode: _phoneFocus,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _pickArea(),
                        onChanged: (_) {
                          if (_phoneError != null) setState(() => _phoneError = null);
                        },
                        decoration: InputDecoration(
                          hintText: AppLanguage.tr('মোবাইল নাম্বার দিন'),
                          prefixIcon: const Icon(Icons.phone_android_rounded, size: 20, color: AppColors.muted),
                          errorText: _phoneError,
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.line)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(AppLanguage.tr('ঠিকানার তথ্য'), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: AppColors.line)),
                        ],
                      ),
                      const SizedBox(height: AppSpace.sm),
                      // Area — searchable dropdown, not a free-text field.
                      TextField(
                        readOnly: true,
                        onTap: _pickArea,
                        controller: _areaDisplay,
                        decoration: InputDecoration(
                          hintText: AppLanguage.tr('এলাকা নির্বাচন করুন'),
                          prefixIcon: const Icon(Icons.map_outlined, size: 20, color: AppColors.muted),
                          suffixIcon: const Icon(Icons.expand_more_rounded, color: AppColors.muted),
                          errorText: _areaError,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _localAddress,
                        focusNode: _localAddressFocus,
                        textInputAction: TextInputAction.next,
                        maxLines: 2,
                        minLines: 1,
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_whatsappFocus),
                        onChanged: (_) {
                          if (_localAddressError != null) setState(() => _localAddressError = null);
                        },
                        decoration: InputDecoration(
                          hintText: AppLanguage.tr('বাসা/বিল্ডিং/ফ্ল্যাট/রোড (যেমন: বাসা ১২, রোড ৩)'),
                          prefixIcon: const Icon(Icons.home_outlined, size: 20, color: AppColors.muted),
                          errorText: _localAddressError,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _whatsapp,
                        focusNode: _whatsappFocus,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        onChanged: (_) {
                          if (_whatsappError != null) setState(() => _whatsappError = null);
                        },
                        decoration: InputDecoration(
                          hintText: AppLanguage.tr('হোয়াটসঅ্যাপ নাম্বার (ঐচ্ছিক)'),
                          prefixIcon: const Icon(Icons.chat_rounded, size: 20, color: AppColors.muted),
                          errorText: _whatsappError,
                        ),
                      ),
                      const SizedBox(height: 22),
                      AppButton(label: AppLanguage.tr('একাউন্ট তৈরি করুন'), trailingIcon: Icons.arrow_forward_rounded, loading: _loading, onPressed: _submit),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text.rich(
                          TextSpan(
                            text: AppLanguage.tr('ইতিমধ্যে একাউন্ট আছে? '),
                            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 13),
                            children: [TextSpan(text: AppLanguage.tr('লগইন করুন'), style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w900))],
                          ),
                        ),
                      ),
                    ],
                  ),
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

/// Searchable area picker — bottom sheet with a search box + filtered list,
/// so the customer must select from the actual service area list instead
/// of free-typing one.
class _AreaPickerSheet extends StatefulWidget {
  final String? selected;
  const _AreaPickerSheet({this.selected});

  @override
  State<_AreaPickerSheet> createState() => _AreaPickerSheetState();
}

class _AreaPickerSheetState extends State<_AreaPickerSheet> {
  final _search = TextEditingController();
  late List<String> _filtered = MockData.serviceAreas;

  void _onSearchChanged(String q) {
    setState(() {
      _filtered = q.trim().isEmpty ? MockData.serviceAreas : MockData.serviceAreas.where((a) => a.contains(q.trim())).toList();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(AppLanguage.tr('এলাকা নির্বাচন করুন'), style: AppText.h1),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            autofocus: true,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(hintText: AppLanguage.tr('এলাকা খুঁজুন...'), prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.muted)),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(AppLanguage.tr('কোনো এলাকা পাওয়া যায়নি'), textAlign: TextAlign.center, style: AppText.bodyMuted),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.line),
                    itemBuilder: (context, i) {
                      final area = _filtered[i];
                      final selected = area == widget.selected;
                      return ListTile(
                        onTap: () => Navigator.pop(context, area),
                        title: Text(area, style: TextStyle(fontSize: 13.5, fontWeight: selected ? FontWeight.w900 : FontWeight.w600, color: selected ? AppColors.blue : AppColors.ink)),
                        trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppColors.blue, size: 20) : null,
                        leading: Icon(Icons.location_on_outlined, size: 20, color: selected ? AppColors.blue : AppColors.muted),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
