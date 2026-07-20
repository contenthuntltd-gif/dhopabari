import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../services/admin_service.dart';
import '../../widgets/bn_number.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/centered_max_width.dart';
import '../../data/receipt_data.dart';
import '../receipt_screen.dart';
import 'customer_detail_screen.dart';
import 'rider_detail_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final AdminOrder order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _openReceipt(ReceiptType type) {
    final order = widget.order;
    final receipt = switch (type) {
      ReceiptType.pickup => ReceiptData.pickupForAdminOrder(order),
      ReceiptType.delivery => ReceiptData.deliveryForAdminOrder(order),
      ReceiptType.payment => ReceiptData.paymentForAdminOrder(order),
    };
    Navigator.push(context, AppPageRoute(builder: (_) => ReceiptScreen(receipt: receipt, role: ReceiptViewerRole.admin, pickupConfirmed: true)));
  }

  void _openReceiptPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('কোন রিসিট দেখতে চান?', style: AppText.h2),
            const SizedBox(height: 14),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _openReceipt(ReceiptType.pickup);
              },
              leading: const CircleAvatar(backgroundColor: AppColors.blueSoft, child: Icon(Icons.receipt_long_rounded, color: AppColors.blue)),
              title: const Text('পিকআপ রিসিট', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _openReceipt(ReceiptType.delivery);
              },
              leading: const CircleAvatar(backgroundColor: AppColors.tealSoft, child: Icon(Icons.receipt_rounded, color: AppColors.teal)),
              title: const Text('ডেলিভারি রিসিট', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _openReceipt(ReceiptType.payment);
              },
              leading: const CircleAvatar(backgroundColor: AppColors.amberSoft, child: Icon(Icons.payments_rounded, color: AppColors.amber)),
              title: const Text('পেমেন্ট রিসিট', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(String status) async {
    final previous = widget.order.status;
    setState(() => widget.order.status = status);
    try {
      await AdminService.updateOrderStatus(widget.order.uuid, status);
      _snack('অর্ডার স্ট্যাটাস আপডেট হয়েছে');
    } catch (e) {
      if (!mounted) return;
      setState(() => widget.order.status = previous);
      _snack(AdminService.messageFor(e));
    }
  }

  Future<void> _assignRider() async {
    final riders = await AdminService.riders();
    if (!mounted) return;

    if (riders.isEmpty) {
      _snack('কোনো রাইডার নেই — আগে রাইডার যোগ করুন');
      return;
    }

    final rider = await showModalBottomSheet<AdminRider>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('রাইডার নির্বাচন করুন', style: AppText.h2),
            const SizedBox(height: 14),
            ...riders.where((r) => r.active).map((r) => ListTile(
                  onTap: () => Navigator.pop(context, r),
                  leading: CircleAvatar(backgroundColor: AppColors.blueSoft, child: Icon(Icons.two_wheeler_rounded, color: AppColors.blue)),
                  title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  subtitle: Text(r.area.isEmpty ? r.phone : '${r.area} • ${r.phone}', style: const TextStyle(fontSize: 11.5)),
                  trailing: Text('${toBn(r.completedOrders)} অর্ডার', style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
                )),
          ],
        ),
      ),
    );
    if (rider == null) return;

    // Assigning a rider does not change the order status — the rider
    // still has to mark the order picked up themselves (see backend
    // orderController.assignRider).
    final previous = widget.order.riderName;
    setState(() => widget.order.riderName = rider.name);
    try {
      await AdminService.assignRider(widget.order.uuid, rider.id);
      _snack('${rider.name}-কে অর্ডার বরাদ্দ করা হয়েছে');
    } catch (e) {
      if (!mounted) return;
      setState(() => widget.order.riderName = previous);
      _snack(AdminService.messageFor(e));
    }
  }

  static const _cancellableStatuses = ['Confirmed', 'Picked Up'];
  bool get _canCancel => _cancellableStatuses.contains(widget.order.status);

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final statusIndex = AdminMockData.orderStatuses.indexOf(order.status);
    final isCancelled = order.status == 'Cancelled';
    final isTerminal = order.status == 'Delivered' || isCancelled;

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(order.id),
        actions: [
          IconButton(icon: const Icon(Icons.receipt_long_rounded), tooltip: 'রিসিট দেখুন', onPressed: _openReceiptPicker),
        ],
      ),
      body: CenteredMaxWidth(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order.id, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
                      StatusBadge(status: order.status, label: AdminMockData.orderStatusesBn[order.status]),
                    ],
                  ),
                  Text(order.date, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  const Divider(height: 24, color: AppColors.line),
                  _row('সার্ভিস', '${order.service} • ${order.category}'),
                  _row('আইটেম', order.itemsSummary),
                  _row('মোট পিস', '${order.pieces}'),
                  _row('ঠিকানা', order.address),
                  _row('পেমেন্ট', order.paymentMethod),
                  const Divider(height: 24, color: AppColors.line),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('সর্বমোট', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.ink)),
                      Text('৳${order.total}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.blue)),
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
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: AppColors.blueSoft, shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, color: AppColors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.customerName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        Text(order.customerPhone, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: order.customerId == null
                        ? null
                        : () async {
                            final c = await AdminService.customerById(order.customerId!);
                            if (!context.mounted) return;
                            if (c == null) {
                              _snack('কাস্টমার পাওয়া যায়নি');
                              return;
                            }
                            Navigator.push(
                              context,
                              AppPageRoute(builder: (_) => CustomerDetailScreen(customer: c)),
                            );
                          },
                    child: const Text('বিস্তারিত'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          FadeSlideIn(
            delayMs: 80,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
              child: order.riderName == null
                  ? Row(
                      children: [
                        const Icon(Icons.two_wheeler_outlined, color: AppColors.muted),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('এখনো কোনো রাইডার বরাদ্দ হয়নি', style: TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w700))),
                        TextButton(onPressed: _assignRider, child: const Text('বরাদ্দ করুন')),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
                          child: const Icon(Icons.two_wheeler_rounded, color: AppColors.teal),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.riderName!, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                              const Text('বরাদ্দকৃত রাইডার', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: order.riderId == null
                              ? null
                              : () async {
                                  final riders = await AdminService.riders();
                                  if (!context.mounted) return;
                                  final r = riders.where((r) => r.id == order.riderId).firstOrNull;
                                  if (r == null) {
                                    _snack('রাইডার পাওয়া যায়নি');
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    AppPageRoute(builder: (_) => RiderDetailScreen(rider: r)),
                                  );
                                },
                          child: const Text('বিস্তারিত'),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 18),
          if (!isTerminal) ...[
            FadeSlideIn(delayMs: 100, child: const Text('অর্ডার প্রসেসিং', style: AppText.h3)),
            const SizedBox(height: 10),
            FadeSlideIn(
              delayMs: 120,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(AdminMockData.orderStatuses.length - 1, (i) {
                    final status = AdminMockData.orderStatuses[i];
                    final done = i < statusIndex;
                    final current = i == statusIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            done ? Icons.check_circle_rounded : (current ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded),
                            size: 20,
                            color: done || current ? AppColors.blue : AppColors.line,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(AdminMockData.orderStatusesBn[status]!, style: TextStyle(fontSize: 13, fontWeight: current ? FontWeight.w900 : FontWeight.w600, color: done || current ? AppColors.ink : AppColors.muted))),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delayMs: 140,
              child: Row(
                children: [
                  if (_canCancel) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                        onPressed: () => _confirmCancel(),
                        icon: const Icon(Icons.cancel_outlined, size: 17),
                        label: const Text('বাতিল করুন'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      // Forward-only, one step at a time — never skip a status.
                      onPressed: statusIndex >= 0 && statusIndex < AdminMockData.orderStatuses.length - 2 ? () => _changeStatus(AdminMockData.orderStatuses[statusIndex + 1]) : null,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                      label: Text('পরবর্তী ধাপ: ${AdminMockData.orderStatusesBn[AdminMockData.orderStatuses[(statusIndex + 1).clamp(0, AdminMockData.orderStatuses.length - 1)]]}'),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            FadeSlideIn(
              delayMs: 100,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: isCancelled ? AppColors.dangerSoft : AppColors.tealSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Row(
                  children: [
                    Icon(isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded, color: isCancelled ? AppColors.danger : AppColors.teal, size: 20),
                    const SizedBox(width: 10),
                    Text(isCancelled ? 'এই অর্ডারটি বাতিল করা হয়েছে' : 'এই অর্ডারটি ডেলিভারি সম্পন্ন হয়েছে', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: isCancelled ? AppColors.danger : const Color(0xFF0C8B85))),
                  ],
                ),
              ),
            ),
        ],
      )),
    );
  }

  void _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('অর্ডার বাতিল করবেন?', style: AppText.h2),
        content: const Text('এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।', style: AppText.bodyMuted),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('না')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: AppColors.danger), child: const Text('হ্যাঁ, বাতিল করুন')),
        ],
      ),
    );
    if (confirmed == true) _changeStatus('Cancelled');
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
