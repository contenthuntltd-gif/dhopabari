import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_button.dart';

/// Creates a real, login-capable account (phone + password), or edits an
/// existing profile.
///
/// Creation goes through the `admin-create-user` Edge Function — see
/// [AdminService.createUser] for why it cannot happen directly from here.
/// Editing is a plain profile update, allowed by the staff RLS policy.
class CustomerFormScreen extends StatefulWidget {
  final AdminCustomer? existing;

  /// 'customer' or 'rider'. Only an admin may create a rider; the server
  /// rejects it otherwise, and [CustomersScreen] never passes 'rider'.
  final String role;

  const CustomerFormScreen({super.key, this.existing, this.role = 'customer'});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late final _password = TextEditingController();
  late final _area = TextEditingController(text: widget.existing?.area ?? '');
  late final _address = TextEditingController(text: widget.existing?.localAddress ?? '');
  late final _whatsapp = TextEditingController(text: widget.existing?.whatsappNumber ?? '');

  bool _showPassword = false;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.existing != null;
  bool get _isRider => widget.role == 'rider';
  String get _noun => _isRider ? 'রাইডার' : 'কাস্টমার';

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();

    final name = _name.text.trim();
    final phone = _phone.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      setState(() => _error = 'নাম ও ফোন নম্বর আবশ্যক');
      return;
    }
    if (!_isEdit && _password.text.length < 6) {
      setState(() => _error = 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isEdit) {
        await AdminService.updateCustomer(
          id: widget.existing!.id,
          name: name,
          area: _area.text.trim(),
          localAddress: _address.text.trim(),
          whatsappNumber: _whatsapp.text.trim(),
        );
      } else {
        await AdminService.createUser(
          name: name,
          phone: phone,
          password: _password.text,
          role: widget.role,
          area: _area.text.trim(),
          localAddress: _address.text.trim(),
          whatsappNumber: _whatsapp.text.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '$_noun আপডেট হয়েছে' : '$_noun তৈরি হয়েছে')),
      );
      Navigator.pop(context, true);
    } on AdminServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'সংরক্ষণ করা যায়নি — ইন্টারনেট সংযোগ দেখুন';
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _area.dispose();
    _address.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: Text(_isEdit ? '$_noun সম্পাদনা' : 'নতুন $_noun')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'পূর্ণ নাম',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  // The number is the login identity; changing it would mean
                  // moving the auth account, so it is fixed after creation.
                  enabled: !_isEdit,
                  decoration: InputDecoration(
                    hintText: 'মোবাইল নম্বর (যেমন 01712345678)',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    helperText: _isEdit ? 'নম্বর পরিবর্তন করা যাবে না' : null,
                  ),
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      hintText: 'পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      helperText: 'এই পাসওয়ার্ড দিয়েই $_noun নিজে লগইন করবেন',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.muted,
                        ),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: _area,
                  decoration: const InputDecoration(
                    hintText: 'এলাকা (যেমন কলাতলী)',
                    prefixIcon: Icon(Icons.map_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _address,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'বিস্তারিত ঠিকানা (বাসা, রোড)',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _whatsapp,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'হোয়াটসঅ্যাপ নম্বর (ঐচ্ছিক)',
                    prefixIcon: Icon(Icons.chat_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: _isEdit ? 'পরিবর্তন সংরক্ষণ করুন' : '$_noun তৈরি করুন',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
