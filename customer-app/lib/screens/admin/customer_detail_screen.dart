import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../services/admin_service.dart';
import '../../widgets/bn_number.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/centered_max_width.dart';
import '../new_order_screen.dart';
import 'customer_form_screen.dart';
import 'order_detail_screen.dart';

/// One customer's profile, their real order history, and the staff actions
/// available on them — including placing an order on their behalf.
class CustomerDetailScreen extends StatefulWidget {
  final AdminCustomer customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late AdminCustomer _c = widget.customer;
  late Future<List<AdminOrder>> _orders = AdminService.orders(customerId: _c.id);
  bool _busy = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _refresh() async {
    final fresh = await AdminService.customerById(_c.id);
    if (!mounted) return;
    setState(() {
      if (fresh != null) _c = fresh;
      _orders = AdminService.orders(customerId: _c.id);
    });
  }

  /// Opens the normal order flow, but targeted at this customer. The order
  /// is written with customer_id = them and placed_by = the signed-in staff
  /// member, so it shows up in their history exactly like a self-placed one.
  Future<void> _createOrderForCustomer() async {
    final placed = await Navigator.push<bool>(
      context,
      AppPageRoute(
        builder: (_) => NewOrderScreen(
          forCustomerId: _c.id,
          forCustomerName: _c.name,
          forCustomerAddress: _c.localAddress.isNotEmpty ? _c.localAddress : _c.area,
        ),
      ),
    );
    if (placed == true) {
      _snack('${_c.name}-এর জন্য অর্ডার তৈরি হয়েছে');
      await _refresh();
    }
  }

  Future<void> _toggleBlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    final next = !_c.blocked;
    try {
      await AdminService.setBlocked(_c.id, next);
      if (!mounted) return;
      setState(() {
        _c.blocked = next;
        _busy = false;
      });
      _snack(next ? 'কাস্টমার ব্লক করা হয়েছে' : 'কাস্টমার আনব্লক করা হয়েছে');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(AdminService.messageFor(e));
    }
  }

  Future<void> _setPassword() async {
    final controller = TextEditingController();
    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('নতুন পাসওয়ার্ড দিন', style: AppText.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_c.name} এই নতুন পাসওয়ার্ড দিয়ে লগইন করবেন। তাঁকে পাসওয়ার্ডটি জানিয়ে দিন।',
              style: AppText.bodyMuted,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'কমপক্ষে ৬ অক্ষর'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('সেট করুন'),
          ),
        ],
      ),
    );

    if (newPassword == null) return;
    if (newPassword.length < 6) {
      _snack('পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে');
      return;
    }

    setState(() => _busy = true);
    try {
      await AdminService.setPassword(_c.id, newPassword);
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('পাসওয়ার্ড পরিবর্তন হয়েছে');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(AdminService.messageFor(e));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('কাস্টমার মুছে ফেলবেন?', style: AppText.h2),
        content: Text(
          '${_c.name}-এর অ্যাকাউন্ট ও সব অর্ডার ইতিহাস স্থায়ীভাবে মুছে যাবে। '
          'এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।',
          style: AppText.bodyMuted,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('না')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('হ্যাঁ, মুছুন'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await AdminService.deleteUser(_c.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(AdminService.messageFor(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('কাস্টমার বিস্তারিত'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'সম্পাদনা করুন',
            onPressed: () async {
              final saved = await Navigator.push(
                context,
                AppPageRoute(builder: (_) => CustomerFormScreen(existing: c)),
              );
              if (saved == true) await _refresh();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.blue,
        onPressed: c.blocked ? null : _createOrderForCustomer,
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('এই কাস্টমারের অর্ডার'),
      ),
      body: CenteredMaxWidth(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              FadeSlideIn(child: _profileCard(c)),
              const SizedBox(height: 16),
              FadeSlideIn(delayMs: 60, child: _addressCard(c)),
              const SizedBox(height: 16),
              FadeSlideIn(delayMs: 90, child: _historyCard()),
              const SizedBox(height: 18),
              FadeSlideIn(delayMs: 120, child: _actions(c)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard(AdminCustomer c) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.blueSoft,
            child: Icon(Icons.person_rounded, color: AppColors.blue, size: 32),
          ),
          const SizedBox(height: 10),
          Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink)),
          Text(c.phone, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
          if (c.whatsappNumber.isNotEmpty)
            Text('হোয়াটসঅ্যাপ: ${c.whatsappNumber}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (c.blocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(999)),
              child: const Text('ব্লক করা হয়েছে',
                  style: TextStyle(fontSize: 10.5, color: AppColors.danger, fontWeight: FontWeight.w800)),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _stat(toBn(c.totalOrders), 'মোট অর্ডার')),
              Container(width: 1, height: 30, color: AppColors.line),
              Expanded(child: _stat(money(c.totalSpent), 'মোট খরচ')),
              Container(width: 1, height: 30, color: AppColors.line),
              Expanded(child: _stat(c.joined, 'যোগদান')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addressCard(AdminCustomer c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ঠিকানা', style: AppText.h3),
          const SizedBox(height: 10),
          if (c.area.isEmpty && c.localAddress.isEmpty)
            const Text('কোনো ঠিকানা সংরক্ষিত নেই', style: AppText.bodyMuted),
          if (c.area.isNotEmpty) _addressRow(Icons.map_rounded, c.area),
          if (c.localAddress.isNotEmpty) _addressRow(Icons.location_on_rounded, c.localAddress),
        ],
      ),
    );
  }

  Widget _addressRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.blue),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _historyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('অর্ডার ইতিহাস', style: AppText.h3),
          const SizedBox(height: 10),
          FutureBuilder<List<AdminOrder>>(
            future: _orders,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Text(AdminService.messageFor(snap.error!),
                    style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600));
              }
              final orders = snap.data ?? const <AdminOrder>[];
              if (orders.isEmpty) {
                return const Text('এখনো কোনো অর্ডার নেই', style: AppText.bodyMuted);
              }
              return Column(
                children: [
                  for (final o in orders)
                    InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          AppPageRoute(builder: (_) => OrderDetailScreen(order: o)),
                        );
                        await _refresh();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.id,
                                      style: const TextStyle(
                                          fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                                  Text('${o.date} • ${o.itemsSummary}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(money(o.total),
                                    style: const TextStyle(
                                        fontSize: 12.5, fontWeight: FontWeight.w900, color: AppColors.ink)),
                                Text(AdminMockData.orderStatusesBn[o.status] ?? o.status,
                                    style: const TextStyle(
                                        fontSize: 10, color: AppColors.blue, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actions(AdminCustomer c) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _setPassword,
            icon: const Icon(Icons.lock_reset_rounded, size: 18),
            label: const Text('পাসওয়ার্ড পরিবর্তন করুন'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: c.blocked ? AppColors.green : AppColors.amber,
              side: BorderSide(color: c.blocked ? AppColors.green : AppColors.amber),
            ),
            onPressed: _busy ? null : _toggleBlock,
            icon: Icon(c.blocked ? Icons.lock_open_rounded : Icons.block_rounded, size: 18),
            label: Text(c.blocked ? 'আনব্লক করুন' : 'ব্লক করুন'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            onPressed: _busy ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('কাস্টমার মুছে ফেলুন'),
          ),
        ),
      ],
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.ink),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
