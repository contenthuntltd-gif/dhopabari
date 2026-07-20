import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/app_button.dart';

class RiderFormScreen extends StatefulWidget {
  final AdminRider? existing;
  const RiderFormScreen({super.key, this.existing});

  @override
  State<RiderFormScreen> createState() => _RiderFormScreenState();
}

class _RiderFormScreenState extends State<RiderFormScreen> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late String _area = widget.existing?.area ?? AdminMockData.categories.first.nameBn;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  static const _areas = ["কক্সবাজার সদর", "কলাতলী", "সুগন্ধা", "লাবণী"];

  void _submit() {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('নাম ও ফোন নম্বর আবশ্যক')));
      return;
    }
    setState(() => _loading = true);
    Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (_isEdit) {
        widget.existing!.area = _area;
      } else {
        AdminMockData.riders.add(AdminRider(
          id: 'rider_${DateTime.now().millisecondsSinceEpoch}',
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          area: _area,
          online: false,
          rating: 5.0,
          completedOrders: 0,
          walletBalance: 0,
          totalEarnings: 0,
        ));
      }
      Navigator.pop(context, true);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
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
                TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'মোবাইল নম্বর', prefixIcon: Icon(Icons.phone_outlined, size: 20))),
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
          const SizedBox(height: 20),
          AppButton(label: _isEdit ? 'পরিবর্তন সংরক্ষণ করুন' : 'রাইডার তৈরি করুন', loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}
