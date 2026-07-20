import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/app_button.dart';

class CustomerFormScreen extends StatefulWidget {
  final AdminCustomer? existing;
  const CustomerFormScreen({super.key, this.existing});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late final _email = TextEditingController(text: widget.existing?.email ?? '');
  late final _area = TextEditingController(text: widget.existing?.area ?? '');
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  void _submit() {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('নাম ও ফোন নম্বর আবশ্যক')));
      return;
    }
    setState(() => _loading = true);
    Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (_isEdit) {
        // Mock in-place update.
      } else {
        AdminMockData.customers.add(AdminCustomer(
          id: 'cus_${DateTime.now().millisecondsSinceEpoch}',
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          area: _area.text.trim(),
          totalOrders: 0,
          totalSpent: 0,
          addresses: const [],
          joined: 'জুলাই ২০২৬',
        ));
      }
      Navigator.pop(context, true);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: Text(_isEdit ? 'কাস্টমার সম্পাদনা' : 'নতুন কাস্টমার')),
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
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'ইমেইল', prefixIcon: Icon(Icons.email_outlined, size: 20))),
                const SizedBox(height: 14),
                TextField(controller: _area, decoration: const InputDecoration(hintText: 'এলাকা', prefixIcon: Icon(Icons.location_on_outlined, size: 20))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton(label: _isEdit ? 'পরিবর্তন সংরক্ষণ করুন' : 'কাস্টমার তৈরি করুন', loading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}
