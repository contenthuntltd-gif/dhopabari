import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/bn_number.dart';
import '../admin/customers_screen.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/app_logo.dart';
import '../../data/receipt_data.dart';
import '../login_screen.dart';
import '../receipt_screen.dart';

/// Rider's home base after logging in via the ⋮ menu → Rider flow.
/// Lives inside the same app/port as the customer & admin experiences.
class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});
  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  // Presence is not persisted anywhere yet — this toggle is local to the
  // session until a rider presence table exists.
  bool _online = true;

  AdminCustomer? _me;
  List<AdminOrder> _riderOrders = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _error = null);
    try {
      final me = await AdminService.me();
      final orders = me == null
          ? <AdminOrder>[]
          : await AdminService.orders(riderId: me.id);
      if (!mounted) return;
      setState(() {
        _me = me;
        _riderOrders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  String get _riderName => _me?.name ?? 'রাইডার';

  List<AdminOrder> get _assigned =>
      _riderOrders.where((o) => o.status != 'Delivered' && o.status != 'Cancelled').toList();

  // "Today's pickups": orders confirmed and waiting for this rider to collect.
  int get _todaysPickups => _riderOrders.where((o) => o.status == 'Confirmed').length;
  // "Today's deliveries": orders packaged and ready to go out with this rider.
  int get _todaysDeliveries => _riderOrders.where((o) => o.status == 'Out for Delivery').length;
  int get _completedToday => _riderOrders.where((o) => o.status == 'Delivered').length;

  Future<void> _logout() async {
    await AuthService.logout();
    AdminService.clearRoleCache();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(AppPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  /// Riders have the same customer-facing powers as an admin here: browse
  /// every customer, register a new one, and place an order from a
  /// customer's profile.
  void _openCustomers() {
    Navigator.push(context, AppPageRoute(builder: (_) => const CustomersScreen()))
        .then((_) => _load());
  }

  void _callCustomer(String phone) => launchUrl(Uri.parse('tel:$phone'));

  void _openReceipt(AdminOrder order, ReceiptType type) {
    final receipt = type == ReceiptType.pickup ? ReceiptData.pickupForAdminOrder(order) : ReceiptData.deliveryForAdminOrder(order);
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => ReceiptScreen(
          receipt: receipt,
          role: ReceiptViewerRole.rider,
          pickupConfirmed: order.status != 'Confirmed',
          onConfirmPickup: order.status == 'Confirmed' ? () => _updateStatus(order) : null,
        ),
      ),
    );
  }

  /// Riders can only move an order forward one step at a time, and only
  /// into a rider-owned status (Picked Up / Out for Delivery / Delivered).
  /// When the next step in the flow belongs to laundry staff/admin
  /// (Cleaning, Packaging Done), there is nothing for the rider to do —
  /// the button is hidden (see `_riderCanAdvance`).
  String? _nextStatusFor(AdminOrder order) {
    final idx = AdminMockData.orderStatuses.indexOf(order.status);
    if (idx < 0 || idx >= AdminMockData.orderStatuses.length - 2) return null; // last real step or already Cancelled
    return AdminMockData.orderStatuses[idx + 1];
  }

  bool _riderCanAdvance(AdminOrder order) {
    final next = _nextStatusFor(order);
    return next != null && AdminMockData.riderAllowedStatuses.contains(next);
  }

  Future<void> _updateStatus(AdminOrder order) async {
    final next = _nextStatusFor(order);
    if (next == null || !AdminMockData.riderAllowedStatuses.contains(next)) return;

    final previous = order.status;
    setState(() => order.status = next);
    try {
      await AdminService.updateOrderStatus(order.uuid, next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${order.id} → ${AdminMockData.orderStatusesBn[next]}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => order.status = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminService.messageFor(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: ErrorStateView(message: AdminService.messageFor(_error!), onRetry: _load),
        ),
      );
    }

    final assigned = _assigned;
    return Scaffold(
      backgroundColor: AppColors.paper,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.blue,
        onPressed: _openCustomers,
        icon: const Icon(Icons.people_alt_rounded),
        label: const Text('কাস্টমার ও অর্ডার'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.teal,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              FadeSlideIn(
                child: Row(
                  children: [
                    AppLogo(size: 46, padding: const EdgeInsets.all(4), rounded: true, shadow: AppShadows.soft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_riderName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink)),
                          const Text('ডেলিভারি পার্টনার', style: TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.logout_rounded, color: AppColors.danger), onPressed: _logout, tooltip: 'লগআউট'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delayMs: 40,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: _online ? [AppColors.teal, const Color(0xFF0C8A86)] : [AppColors.muted, const Color(0xFF6B7280)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [BoxShadow(color: (_online ? AppColors.teal : AppColors.muted).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_online ? 'অনলাইন আছেন' : 'অফলাইন আছেন', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(height: 3),
                            Text(_online ? 'নতুন অর্ডার পাবেন' : 'কোনো নতুন অর্ডার পাবেন না', style: const TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Switch(value: _online, onChanged: (v) => setState(() => _online = v), activeTrackColor: Colors.white38, activeThumbColor: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeSlideIn(
                delayMs: 50,
                child: Row(
                  children: [
                    Expanded(child: StatCard(label: "আজকের পিকআপ", value: toBn(_todaysPickups), icon: Icons.inventory_2_outlined, color: AppColors.blue, onTap: () {})),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(label: "আজকের ডেলিভারি", value: toBn(_todaysDeliveries), icon: Icons.local_shipping_outlined, color: AppColors.teal, onTap: () {})),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(label: 'সম্পন্ন অর্ডার', value: toBn(_completedToday), icon: Icons.done_all_rounded, color: AppColors.green, onTap: () {})),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delayMs: 60,
                child: Row(
                  children: [
                    // Ratings are not collected anywhere yet, so the second
                    // tile shows total assigned orders instead of a made-up
                    // star score.
                    Expanded(child: StatCard(label: 'সম্পন্ন ডেলিভারি', value: toBn(_completedToday), icon: Icons.done_all_rounded, color: AppColors.green, onTap: () {})),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(label: 'মোট অর্ডার', value: toBn(_riderOrders.length), icon: Icons.receipt_long_rounded, color: AppColors.amber, onTap: () {})),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delayMs: 80,
                child: PressableScale(
                  onTap: () => _showWallet(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.blue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ওয়ালেট ব্যালেন্স', style: TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
                              // Earnings and payouts have no database tables
                              // yet, so this deliberately shows a dash rather
                              // than a ৳0 that would read as "you earned
                              // nothing".
                              const Text('—', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FadeSlideIn(delayMs: 100, child: const Text('আজকের ডেলিভারি', style: AppText.h2)),
              const SizedBox(height: 10),
              if (assigned.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: const [
                      Icon(Icons.local_shipping_outlined, color: AppColors.muted, size: 40),
                      SizedBox(height: 10),
                      Text('কোনো সক্রিয় ডেলিভারি নেই', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              else
                ...List.generate(assigned.length, (i) {
                  final order = assigned[i];
                  return FadeSlideIn(
                    delayMs: 120 + i * 40,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(order.id, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink)),
                                StatusBadge(status: order.status, label: AdminMockData.orderStatusesBn[order.status]),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(order.customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted),
                                const SizedBox(width: 3),
                                Expanded(child: Text(order.address, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _callCustomer(order.customerPhone),
                                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.teal, side: const BorderSide(color: AppColors.teal)),
                                    icon: const Icon(Icons.call_outlined, size: 16),
                                    label: const Text('কল করুন'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _riderCanAdvance(order)
                                      ? ElevatedButton(
                                          onPressed: () => _updateStatus(order),
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
                                          child: const Text('পরবর্তী ধাপ'),
                                        )
                                      : OutlinedButton(
                                          onPressed: null,
                                          child: Text(
                                            order.status == 'Delivered' ? 'সম্পন্ন হয়েছে' : 'লন্ড্রিতে প্রসেসিং হচ্ছে',
                                            style: const TextStyle(fontSize: 11.5),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _openReceipt(order, ReceiptType.pickup),
                                    icon: const Icon(Icons.receipt_long_rounded, size: 15),
                                    label: const Text('পিকআপ রিসিট', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _openReceipt(order, ReceiptType.delivery),
                                    icon: const Icon(Icons.receipt_rounded, size: 15),
                                    label: const Text('ডেলিভারি রিসিট', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _showWallet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('ওয়ালেট বিস্তারিত', style: AppText.h1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _walletStat('বর্তমান ব্যালেন্স', '—', AppColors.blue)),
                const SizedBox(width: 10),
                Expanded(child: _walletStat('মোট আয়', '—', AppColors.green)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('উত্তোলন অনুরোধ পাঠানো হয়েছে')));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
                child: const Text('উত্তোলনের অনুরোধ করুন'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
