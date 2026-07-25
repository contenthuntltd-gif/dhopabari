import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../services/admin_service.dart';
import '../../widgets/bn_number.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/centered_max_width.dart';
import 'rider_form_screen.dart';

class RiderDetailScreen extends StatefulWidget {
  final AdminRider rider;
  const RiderDetailScreen({super.key, required this.rider});

  @override
  State<RiderDetailScreen> createState() => _RiderDetailScreenState();
}

class _RiderDetailScreenState extends State<RiderDetailScreen> {
  bool? _canSeeCustomers; // null until loaded
  bool _savingAccess = false;

  // Delivery / payment tracking.
  List<AdminOrder> _orders = const [];
  bool _ordersLoading = true;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAccess();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await AdminService.orders(riderId: widget.rider.id, limit: 500);
      if (mounted) setState(() { _orders = orders; _ordersLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _ordersLoading = false);
    }
  }

  bool _sameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  /// Delivered orders for the selected date (uses delivery time, falling back
  /// to order time for older rows).
  List<AdminOrder> get _deliveredOnDate => _orders
      .where((o) => o.status == 'Delivered' && _sameDay(o.deliveredAt ?? o.createdAt, _date))
      .toList();

  int get _collectedOnDate => _deliveredOnDate.where((o) {
        final p = o.paymentMethod.toLowerCase();
        return p.contains('cash') || p.contains('cod') || o.paymentMethod.contains('নগদ');
      }).fold(0, (s, o) => s + o.total);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  bool get _isToday => _sameDay(_date, DateTime.now());

  Future<void> _loadAccess() async {
    try {
      final allow = await AdminService.riderCanSeeCustomers(widget.rider.id);
      if (mounted) setState(() => _canSeeCustomers = allow);
    } catch (_) {
      if (mounted) setState(() => _canSeeCustomers = false);
    }
  }

  Future<void> _setAccess(bool allow) async {
    if (_savingAccess) return;
    setState(() {
      _canSeeCustomers = allow;
      _savingAccess = true;
    });
    try {
      await AdminService.setRiderCustomerAccess(widget.rider.id, allow);
      if (!mounted) return;
      setState(() => _savingAccess = false);
      _snack(allow ? 'রাইডার এখন সব কাস্টমার দেখতে পারবে' : 'রাইডারের কাস্টমার অ্যাক্সেস বন্ধ করা হয়েছে');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _canSeeCustomers = !allow;
        _savingAccess = false;
      });
      _snack(AdminService.messageFor(e));
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _toggleActive() {
    setState(() {
      widget.rider.active = !widget.rider.active;
      if (!widget.rider.active) widget.rider.online = false;
    });
    _snack(widget.rider.active ? 'রাইডার সক্রিয় করা হয়েছে' : 'রাইডার নিষ্ক্রিয় করা হয়েছে');
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('রাইডার মুছে ফেলবেন?', style: AppText.h2),
        content: const Text('এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।', style: AppText.bodyMuted),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('না')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: AppColors.danger), child: const Text('হ্যাঁ, মুছুন')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await AdminService.deleteUser(widget.rider.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminService.messageFor(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rider;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('রাইডার বিস্তারিত'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => Navigator.push(context, AppPageRoute(builder: (_) => RiderFormScreen(existing: r)))),
        ],
      ),
      body: CenteredMaxWidth(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(radius: 32, backgroundColor: AppColors.tealSoft, child: Icon(Icons.two_wheeler_rounded, color: AppColors.teal, size: 30)),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(color: r.online ? AppColors.green : AppColors.muted, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(r.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  Text(r.phone, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _pill(r.online ? 'অনলাইন' : 'অফলাইন', r.online ? AppColors.green : AppColors.muted),
                      _pill(r.active ? 'সক্রিয়' : 'নিষ্ক্রিয়', r.active ? AppColors.blue : AppColors.danger),
                      _pill(r.area, AppColors.teal),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _stat('${r.completedOrders}', 'সম্পন্ন ডেলিভারি')),
                      Container(width: 1, height: 30, color: AppColors.line),
                      Expanded(child: _stat('৳${r.totalEarnings}', 'সংগৃহীত ক্যাশ')),
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
              child: r.currentDeliveryId == null
                  ? const Row(
                      children: [
                        Icon(Icons.inbox_outlined, color: AppColors.muted),
                        SizedBox(width: 12),
                        Text('বর্তমানে কোনো ডেলিভারি চলছে না', style: TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
                      ],
                    )
                  : Row(
                      children: [
                        Container(width: 40, height: 40, decoration: const BoxDecoration(color: AppColors.blueSoft, shape: BoxShape.circle), child: const Icon(Icons.local_shipping_rounded, color: AppColors.blue)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('বর্তমান ডেলিভারি', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
                              Text(r.currentDeliveryId!, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delayMs: 100,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.teal, Color(0xFF0C8B85)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ওয়ালেট ব্যালেন্স', style: TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w700)),
                        Text('৳${r.walletBalance}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Delivery + collected-payment tracking, by date.
          FadeSlideIn(delayMs: 110, child: _paymentCard()),
          const SizedBox(height: 16),
          // Admin control: whether this rider may browse the full customer list.
          FadeSlideIn(
            delayMs: 120,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
              child: Row(
                children: [
                  const Icon(Icons.groups_outlined, color: AppColors.blue, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('সব কাস্টমার দেখতে পারবে', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        Text('চালু থাকলে রাইডার কাস্টমার তালিকা দেখে অর্ডার করতে পারবে', style: TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  _canSeeCustomers == null
                      ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                      : Switch(
                          value: _canSeeCustomers!,
                          onChanged: _savingAccess ? null : _setAccess,
                          activeTrackColor: AppColors.blue,
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FadeSlideIn(
            delayMs: 140,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: r.active ? AppColors.danger : AppColors.green, side: BorderSide(color: r.active ? AppColors.danger : AppColors.green)),
                    onPressed: _toggleActive,
                    icon: Icon(r.active ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded, size: 18),
                    label: Text(r.active ? 'নিষ্ক্রিয় করুন' : 'সক্রিয় করুন'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('রাইডার মুছে ফেলুন'),
                  ),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }

  Widget _paymentCard() {
    final delivered = _deliveredOnDate.length;
    final collected = _collectedOnDate;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppColors.blue, size: 20),
              const SizedBox(width: 8),
              const Text('ডেলিভারি ও হিসাব', style: AppText.h3),
            ],
          ),
          const SizedBox(height: 12),
          // Date selector: আজ / pick a date.
          Row(
            children: [
              _dateChip('আজ', selected: _isToday, onTap: () => setState(() => _date = DateTime.now())),
              const SizedBox(width: 8),
              _dateChip('📅 ${bnDate(_date)}', selected: !_isToday, onTap: _pickDate),
            ],
          ),
          const SizedBox(height: 14),
          if (_ordersLoading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.blueSoft.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(toBn(delivered), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.blue)),
                        const Text('ডেলিভারি সম্পন্ন', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('৳$collected', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.green)),
                        const Text('সংগৃহীত ক্যাশ', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _dateChip(String label, {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : Colors.white,
          border: Border.all(color: selected ? AppColors.blue : AppColors.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.ink)),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w800)),
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
