import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
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
import '../../widgets/app_logo.dart';
import '../login_screen.dart';
import 'rider_queue_screen.dart';

/// Rider's home base. Three tap-through cards — Pickup, Delivery and
/// Collection — each opening a two-tab (today / all) screen. No online toggle,
/// no invented wallet balance: everything is derived from the rider's real
/// assigned orders.
class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});
  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  AdminCustomer? _me;
  List<AdminOrder> _riderOrders = const [];
  bool _loading = true;
  bool _canSeeCustomers = false; // admin-controlled
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
    // Chime + banner on new orders / status changes while on the road.
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
        _riderOrders = orders;
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

  bool _isToday(DateTime? d) {
    if (d == null) return false;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  // Card metrics — pickups due today, deliveries ready to go, cash collected
  // today (delivered orders' totals).
  int get _pickupToday => _riderOrders.where((o) => o.status == 'Confirmed' && _isToday(o.createdAt)).length;
  int get _deliveryToday => _riderOrders.where((o) => o.status == 'Packaging Done' || o.status == 'Out for Delivery').length;
  int get _collectToday => _riderOrders.where((o) => o.status == 'Delivered' && _isToday(o.deliveredAt)).fold(0, (s, o) => s + o.total);

  Future<void> _logout() async {
    await AuthService.logout();
    AdminService.clearRoleCache();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(AppPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  void _openCustomers() {
    Navigator.push(context, AppPageRoute(builder: (_) => const CustomersScreen())).then((_) => _load());
  }

  void _openQueue(RiderQueueMode mode) {
    final id = _me?.id;
    if (id == null) return;
    Navigator.push(context, AppPageRoute(builder: (_) => RiderQueueScreen(mode: mode, riderId: id))).then((_) => _load());
  }

  void _openCollection() {
    final id = _me?.id;
    if (id == null) return;
    Navigator.push(context, AppPageRoute(builder: (_) => RiderCollectionScreen(riderId: id))).then((_) => _load());
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
                          Text(AppLanguage.tr('ডেলিভারি পার্টনার'), style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.language_rounded, color: AppColors.blue), onPressed: () => AppLanguage.showPicker(context), tooltip: 'ভাষা / Language'),
                    IconButton(icon: const Icon(Icons.logout_rounded, color: AppColors.danger), onPressed: _logout, tooltip: 'লগআউট'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideIn(
                delayMs: 40,
                child: _optionCard(
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.blue,
                  title: AppLanguage.tr('পিকআপ'),
                  subtitle: '${AppLanguage.tr('আজকে তুলতে হবে')}: ${toBn(_pickupToday)}',
                  onTap: () => _openQueue(RiderQueueMode.pickup),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delayMs: 70,
                child: _optionCard(
                  icon: Icons.local_shipping_rounded,
                  color: AppColors.teal,
                  title: AppLanguage.tr('ডেলিভারি'),
                  subtitle: '${AppLanguage.tr('আজকে দিতে হবে')}: ${toBn(_deliveryToday)}',
                  onTap: () => _openQueue(RiderQueueMode.delivery),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delayMs: 100,
                child: _optionCard(
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.green,
                  title: AppLanguage.tr('কালেক্ট'),
                  subtitle: '${AppLanguage.tr('আজকে কালেক্ট')}: ৳${toBn(_collectToday)}',
                  onTap: _openCollection,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 26),
          ],
        ),
      ),
    );
  }
}
