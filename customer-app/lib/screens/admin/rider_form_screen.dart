import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/state_views.dart';

class RiderFormScreen extends StatefulWidget {
  final AdminRider? existing;
  const RiderFormScreen({super.key, this.existing});

  @override
  State<RiderFormScreen> createState() => _RiderFormScreenState();
}

class _RiderFormScreenState extends State<RiderFormScreen> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late final _password = TextEditingController();
  late String _area = widget.existing?.area.isNotEmpty == true ? widget.existing!.area : _areas.first;
  bool _showPassword = false;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  static const _areas = ["কক্সবাজার সদর", "কলাতলী", "সুগন্ধা", "লাবণী"];

  /// Creating a rider grants staff powers, so the server only allows it for
  /// an admin — a rider creating another rider is rejected there.
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
        await AdminService.updateCustomer(id: widget.existing!.id, name: name, area: _area);
        widget.existing!.area = _area;
      } else {
        await AdminService.createUser(
          name: name,
          phone: phone,
          password: _password.text,
          role: 'rider',
          area: _area,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'রাইডার আপডেট হয়েছে' : 'রাইডার তৈরি হয়েছে')),
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
        _error = AdminService.messageFor(e);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: Text(_isEdit ? 'রাইডার সম্পাদনা' : 'নতুন রাইডার')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
            child: Column(
              children: [
                TextField(controller: _name, decoration: const InputDecoration(hintText: 'পূর্ণ নাম', prefixIcon: Icon(Icons.person_outline_rounded, size: 20))),
                const SizedBox(height: 14),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
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
                      helperText: 'এই পাসওয়ার্ড দিয়েই রাইডার লগইন করবেন',
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('সার্ভিস এলাকা নির্ধারণ করুন', style: AppText.label),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _areas.map((a) {
                    final active = a == _area;
                    return GestureDetector(
                      onTap: () => setState(() => _area = a),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: active ? AppColors.blueSoft : AppColors.paper,
                          border: Border.all(color: active ? AppColors.blue : AppColors.line),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(a, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? AppColors.blue : AppColors.ink)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            InlineErrorBanner(message: _error!, onDismiss: () => setState(() => _error = null)),
          ],
          const SizedBox(height: 20),
          AppButton(label: _isEdit ? 'পরিবর্তন সংরক্ষণ করুন' : 'রাইডার তৈরি করুন', loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}
