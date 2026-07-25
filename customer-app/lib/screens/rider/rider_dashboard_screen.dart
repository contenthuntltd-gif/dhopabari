import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../data/receipt_data.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/language.dart';
import '../../services/order_alerts.dart';
import '../../widgets/bn_number.dart';
import '../admin/customers_screen.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/state_views.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/app_logo.dart';
import '../login_screen.dart';
import '../receipt_screen.dart';

/// Which slice of the rider's orders the list shows. Mirrors the four stat
/// tiles: everything, delivered, still-active, cancelled.
enum _RiderFilter { pending, completed, failed, all }

/// Rider home — greeting, four live stats (total / completed / pending /
/// failed) and the assigned-deliveries list beneath. Every card is wired to
/// the real order: call the customer, advance the status, open receipts.
class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});
  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  AdminCustomer? _me;
  List<AdminOrder> _orders = const [];
  bool _loading = true;
  bool _canSeeCustomers = false;
  Object? _error;
  _RiderFilter _filter = _RiderFilter.pending;

  @override
  void initState() {
    super.initState();
    _load();
    OrderAlerts.start();
  }

  @override
  void dispose() {
    OrderAlerts.stop();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _error = null);
    try {
      final me = await AdminService.me();
      final orders = me == null ? <AdminOrder>[] : await AdminService.orders(riderId: me.id);
      final canSee = await AdminService.currentCanSeeCustomers();
      if (!mounted) return;
      setState(() {
        _me = me;
        _orders = orders;
        _canSeeCustomers = canSee;
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

  bool _isActive(AdminOrder o) => o.status != 'Delivered' && o.status != 'Cancelled';

  int get _total => _orders.length;
  int get _completed => _orders.where((o) => o.status == 'Delivered').length;
  int get _pending => _orders.where(_isActive).length;
  int get _failed => _orders.where((o) => o.status == 'Cancelled').length;

  List<AdminOrder> get _filtered {
    switch (_filter) {
      case _RiderFilter.pending:
        return _orders.where(_isActive).toList();
      case _RiderFilter.completed:
        return _orders.where((o) => o.status == 'Delivered').toList();
      case _RiderFilter.failed:
        return _orders.where((o) => o.status == 'Cancelled').toList();
      case _RiderFilter.all:
        return _orders;
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    AdminService.clearRoleCache();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(AppPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  void _openCustomers() {
    Navigator.push(context, AppPageRoute(builder: (_) => const CustomersScreen())).then((_) => _load());
  }

  // ── Order actions ──

  String? _nextStatusFor(AdminOrder o) {
    final idx = AdminMockData.orderStatuses.indexOf(o.status);
    if (idx < 0 || idx >= AdminMockData.orderStatuses.length - 2) return null;
    return AdminMockData.orderStatuses[idx + 1];
  }

  bool _riderCanAdvance(AdminOrder o) {
    final next = _nextStatusFor(o);
    return next != null && AdminMockData.riderAllowedStatuses.contains(next);
  }

  /// The action-button label for the rider's next move on this order.
  String _advanceLabel(AdminOrder o) {
    final next = _nextStatusFor(o);
    if (next == 'Picked Up') return AppLanguage.tr('পিকআপ শুরু');
    if (next == 'Delivered') return AppLanguage.tr('ডেলিভারি সম্পন্ন');
    return AppLanguage.tr('পরবর্তী ধাপ');
  }

  Future<void> _advance(AdminOrder o) async {
    final next = _nextStatusFor(o);
    if (next == null || !AdminMockData.riderAllowedStatuses.contains(next)) return;
    final prev = o.status;
    setState(() => o.status = next);
    try {
      await AdminService.updateOrderStatus(o.uuid, next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${o.id} → ${AdminMockData.orderStatusesBn[next]}')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() => o.status = prev);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AdminService.messageFor(e))));
    }
  }

  void _openReceipt(AdminOrder o, ReceiptType type) {
    final receipt = type == ReceiptType.pickup
        ? ReceiptData.pickupForAdminOrder(o)
        : ReceiptData.deliveryForAdminOrder(o);
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => ReceiptScreen(
          receipt: receipt,
          role: ReceiptViewerRole.rider,
          pickupConfirmed: o.status != 'Confirmed',
          onConfirmPickup: o.status == 'Confirmed' ? () => _advance(o) : null,
        ),
      ),
    );
  }

  void _openDetails(AdminOrder o) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Text('${AppLanguage.tr('অর্ডার')} ${o.id}', style: AppText.h2),
            const SizedBox(height: 4),
            Text('${o.customerName} · ${toBn(o.pieces)} ${AppLanguage.tr('টি আইটেম')} · ৳${toBn(o.total)}', style: AppText.bodyMuted),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openReceipt(o, ReceiptType.pickup);
              },
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: Text(AppLanguage.tr('পিকআপ রিসিট')),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _openReceipt(o, ReceiptType.delivery);
              },
              icon: const Icon(Icons.receipt_rounded, size: 18),
              label: Text(AppLanguage.tr('ডেলিভারি রিসিট')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppColors.paper, body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(child: ErrorStateView(message: AdminService.messageFor(_error!), onRetry: _load)),
      );
    }

    final list = _filtered;
    return Scaffold(
      backgroundColor: AppColors.paper,
      floatingActionButton: _canSeeCustomers
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.blue,
              onPressed: _openCustomers,
              icon: const Icon(Icons.people_alt_rounded),
              label: Text(AppLanguage.tr('কাস্টমার ও অর্ডার')),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.teal,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // Greeting header.
              FadeSlideIn(
                child: Row(
                  children: [
                    AppLogo(size: 46, padding: const EdgeInsets.all(4), rounded: true, shadow: AppShadows.soft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${AppLanguage.tr('হ্যালো')}, $_riderName', style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AppColors.ink)),
                          Text(AppLanguage.tr('ডেলিভারির জন্য প্রস্তুত?'), style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.language_rounded, color: AppColors.blue), onPressed: () => AppLanguage.showPicker(context), tooltip: 'ভাষা / Language'),
                    IconButton(icon: const Icon(Icons.logout_rounded, color: AppColors.danger), onPressed: _logout, tooltip: 'লগআউট'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Four live stats — tap to filter the list below.
              FadeSlideIn(
                delayMs: 40,
                child: Row(
                  children: [
                    Expanded(child: _stat(AppLanguage.tr('মোট ডেলিভারি'), _total, AppColors.blue, _RiderFilter.all)),
                    const SizedBox(width: 10),
                    Expanded(child: _stat(AppLanguage.tr('সম্পন্ন'), _completed, AppColors.green, _RiderFilter.completed)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delayMs: 60,
                child: Row(
                  children: [
                    Expanded(child: _stat(AppLanguage.tr('চলমান'), _pending, AppColors.amber, _RiderFilter.pending)),
                    const SizedBox(width: 10),
                    Expanded(child: _stat(AppLanguage.tr('বাতিল'), _failed, AppColors.danger, _RiderFilter.failed)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_filterTitle, style: AppText.h2),
                  if (_filter != _RiderFilter.all)
                    TextButton(
                      onPressed: () => setState(() => _filter = _RiderFilter.all),
                      child: Text(AppLanguage.tr('সব দেখুন'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: AppColors.muted, size: 42),
                      const SizedBox(height: 10),
                      Text(AppLanguage.tr('কোনো ডেলিভারি নেই'), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              else
                ...List.generate(list.length, (i) => FadeSlideIn(
                      delayMs: 80 + i * 40,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _orderCard(list[i]),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  String get _filterTitle {
    switch (_filter) {
      case _RiderFilter.pending:
        return AppLanguage.tr('নির্ধারিত ডেলিভারি');
      case _RiderFilter.completed:
        return AppLanguage.tr('সম্পন্ন ডেলিভারি');
      case _RiderFilter.failed:
        return AppLanguage.tr('বাতিল অর্ডার');
      case _RiderFilter.all:
        return AppLanguage.tr('সব অর্ডার');
    }
  }

  Widget _stat(String label, int value, Color color, _RiderFilter filter) {
    final selected = _filter == filter;
    return PressableScale(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? color : AppColors.line, width: selected ? 1.6 : 1),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(toBn(value), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(AdminOrder o) {
    return PressableScale(
      onTap: () => _openDetails(o),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.inventory_2_rounded, color: AppColors.blue, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppLanguage.tr('অর্ডার')} ${o.id}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.ink)),
                      Text(o.date, style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                StatusBadge(status: o.status, label: AdminMockData.orderStatusesBn[o.status]),
              ],
            ),
            const Divider(height: 18),
            Text(o.customerName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted),
                const SizedBox(width: 4),
                Expanded(child: Text(o.address, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 13, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(o.customerPhone, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 15, color: AppColors.ink),
                const SizedBox(width: 5),
                Text('${toBn(o.pieces)} ${AppLanguage.tr('টি আইটেম')} · ৳${toBn(o.total)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const Spacer(),
                IconButton(
                  onPressed: () => launchUrl(Uri.parse('tel:${o.customerPhone}')),
                  icon: const Icon(Icons.call_rounded, color: AppColors.teal),
                  visualDensity: VisualDensity.compact,
                  tooltip: AppLanguage.tr('কল করুন'),
                ),
                const SizedBox(width: 2),
                _riderCanAdvance(o)
                    ? ElevatedButton(
                        onPressed: () => _advance(o),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.ink, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                        child: Text(_advanceLabel(o), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      )
                    : OutlinedButton(
                        onPressed: () => _openDetails(o),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                        child: Text(AppLanguage.tr('বিস্তারিত'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
