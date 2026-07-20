import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/app_page_route.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final AdminCustomer customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _toggleBlock() {
    setState(() => widget.customer.blocked = !widget.customer.blocked);
    _snack(widget.customer.blocked ? 'কাস্টমার ব্লক করা হয়েছে' : 'কাস্টমার আনব্লক করা হয়েছে');
  }

  void _resetPassword() {
    _snack('পাসওয়ার্ড রিসেট লিংক পাঠানো হয়েছে');
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('কাস্টমার মুছে ফেলবেন?', style: AppText.h2),
        content: const Text('এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।', style: AppText.bodyMuted),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('না')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: AppColors.danger), child: const Text('হ্যাঁ, মুছুন')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      AdminMockData.customers.removeWhere((c) => c.id == widget.customer.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('কাস্টমার বিস্তারিত'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'সম্পাদনা করুন',
            onPressed: () => Navigator.push(context, AppPageRoute(builder: (_) => CustomerFormScreen(existing: c))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
              child: Column(
                children: [
                  CircleAvatar(radius: 32, backgroundColor: AppColors.blueSoft, child: Icon(Icons.person_rounded, color: AppColors.blue, size: 32)),
                  const SizedBox(height: 10),
                  Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  Text(c.phone, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  Text(c.email, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  if (c.blocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(999)),
                      child: const Text('ব্লক করা হয়েছে', style: TextStyle(fontSize: 10.5, color: AppColors.danger, fontWeight: FontWeight.w800)),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _stat('${c.totalOrders}', 'মোট অর্ডার')),
                      Container(width: 1, height: 30, color: AppColors.line),
                      Expanded(child: _stat('৳${c.totalSpent}', 'মোট খরচ')),
                      Container(width: 1, height: 30, color: AppColors.line),
                      Expanded(child: _stat(c.joined, 'যোগদান')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delayMs: 60,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('সংরক্ষিত ঠিকানা', style: AppText.h3),
                  const SizedBox(height: 10),
                  if (c.addresses.isEmpty) const Text('কোনো ঠিকানা সংরক্ষিত নেই', style: AppText.bodyMuted),
                  for (final a in c.addresses)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 15, color: AppColors.blue),
                          const SizedBox(width: 6),
                          Expanded(child: Text(a, style: const TextStyle(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FadeSlideIn(
            delayMs: 100,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _resetPassword,
                    icon: const Icon(Icons.lock_reset_rounded, size: 18),
                    label: const Text('পাসওয়ার্ড রিসেট করুন'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: c.blocked ? AppColors.green : AppColors.amber, side: BorderSide(color: c.blocked ? AppColors.green : AppColors.amber)),
                    onPressed: _toggleBlock,
                    icon: Icon(c.blocked ? Icons.lock_open_rounded : Icons.block_rounded, size: 18),
                    label: Text(c.blocked ? 'আনব্লক করুন' : 'ব্লক করুন'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('কাস্টমার মুছে ফেলুন'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.ink), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
