import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../data/receipt_data.dart';
import '../../services/admin_service.dart';
import '../../services/language.dart';
import '../../widgets/bn_number.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/state_views.dart';
import '../../widgets/stat_card.dart';
import '../receipt_screen.dart';

// ── Shared helpers ───────────────────────────────────────

bool _isToday(DateTime? d) {
  if (d == null) return false;
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

bool _isYesterday(DateTime? d) {
  if (d == null) return false;
  final y = DateTime.now().subtract(const Duration(days: 1));
  return d.year == y.year && d.month == y.month && d.day == y.day;
}

const _bnMonths = [
  'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
  'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
];

String _bnDate(DateTime d) => '${toBn(d.day)} ${_bnMonths[d.month - 1]} ${toBn(d.year)}';

String _bnDayLabel(DateTime d) {
  if (_isToday(d)) return AppLanguage.tr('আজ');
  if (_isYesterday(d)) return AppLanguage.tr('গতকাল');
  return _bnDate(d);
}

// ── Pickup / Delivery queue (two tabs: today / all) ──────

enum RiderQueueMode { pickup, delivery }

class RiderQueueScreen extends StatefulWidget {
  final RiderQueueMode mode;
  final String riderId;
  const RiderQueueScreen({super.key, required this.mode, required this.riderId});

  @override
  State<RiderQueueScreen> createState() => _RiderQueueScreenState();
}

class _RiderQueueScreenState extends State<RiderQueueScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  List<AdminOrder> _orders = const [];
  bool _loading = true;
  Object? _error;

  bool get _isPickup => widget.mode == RiderQueueMode.pickup;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _error = null);
    try {
      final orders = await AdminService.orders(riderId: widget.riderId);
      if (!mounted) return;
      setState(() {
        _orders = orders;
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

  List<AdminOrder> get _today {
    if (_isPickup) {
      return _orders.where((o) => o.status == 'Confirmed' && _isToday(o.createdAt)).toList();
    }
    return _orders.where((o) => o.status == 'Packaging Done' || o.status == 'Out for Delivery').toList();
  }

  List<AdminOrder> get _all {
    if (_isPickup) {
      return _orders.where((o) => o.status == 'Confirmed').toList();
    }
    return _orders.where((o) => o.status == 'Delivered').toList();
  }

  String? _nextStatusFor(AdminOrder o) {
    final idx = AdminMockData.orderStatuses.indexOf(o.status);
    if (idx < 0 || idx >= AdminMockData.orderStatuses.length - 2) return null;
    return AdminMockData.orderStatuses[idx + 1];
  }

  // Riders can advance an order through every step now.
  bool _riderCanAdvance(AdminOrder o) => _nextStatusFor(o) != null;

  String _advanceLabel(AdminOrder o) {
    final next = _nextStatusFor(o);
    if (next == 'Picked Up') return AppLanguage.tr('পিকআপ সম্পন্ন');
    if (next == 'Delivered') return AppLanguage.tr('ডেলিভারি সম্পন্ন');
    if (next != null) return AdminMockData.orderStatusesBn[next] ?? AppLanguage.tr('পরবর্তী ধাপ');
    return AppLanguage.tr('পরবর্তী ধাপ');
  }

  Future<void> _advance(AdminOrder o) async {
    final next = _nextStatusFor(o);
    if (next == null) return;
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

  @override
  Widget build(BuildContext context) {
    final title = _isPickup ? AppLanguage.tr('পিকআপ') : AppLanguage.tr('ডেলিভারি');
    final todayTab = _isPickup ? AppLanguage.tr('আজকের পিকআপ') : AppLanguage.tr('আজকের ডেলিভারি');
    final allTab = _isPickup ? AppLanguage.tr('সব পিকআপ') : AppLanguage.tr('সম্পন্ন ডেলিভারি');
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(title),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.teal,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.teal,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          tabs: [Tab(text: todayTab), Tab(text: allTab)],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorStateView(message: AdminService.messageFor(_error!), onRetry: _load)
              : TabBarView(
                  controller: _tab,
                  children: [_list(_today), _list(_all)],
                ),
    );
  }

  Widget _list(List<AdminOrder> orders) {
    return RefreshIndicator(
      color: AppColors.teal,
      onRefresh: _load,
      child: orders.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 90),
                  child: Column(
                    children: [
                      Icon(_isPickup ? Icons.inventory_2_outlined : Icons.local_shipping_outlined, size: 44, color: AppColors.muted),
                      const SizedBox(height: 12),
                      Text(
                        _isPickup ? AppLanguage.tr('কোনো পিকআপ নেই') : AppLanguage.tr('কোনো ডেলিভারি নেই'),
                        style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              itemCount: orders.length,
              itemBuilder: (context, i) => FadeSlideIn(
                delayMs: i * 40,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _orderCard(orders[i]),
                ),
              ),
            ),
    );
  }

  Widget _orderCard(AdminOrder o) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(o.id, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink)),
              StatusBadge(status: o.status, label: AdminMockData.orderStatusesBn[o.status]),
            ],
          ),
          const SizedBox(height: 6),
          Text(o.customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted),
              const SizedBox(width: 3),
              Expanded(child: Text(o.address, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600))),
              Text('৳${toBn(o.total)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.teal)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:${o.customerPhone}')),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.teal, side: const BorderSide(color: AppColors.teal)),
                  icon: const Icon(Icons.call_outlined, size: 16),
                  label: Text(AppLanguage.tr('কল করুন')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _riderCanAdvance(o)
                    ? ElevatedButton(
                        onPressed: () => _advance(o),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
                        child: Text(_advanceLabel(o), style: const TextStyle(fontSize: 12)),
                      )
                    : OutlinedButton(
                        onPressed: null,
                        child: Text(AppLanguage.tr('সম্পন্ন হয়েছে'), style: const TextStyle(fontSize: 11.5)),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _openReceipt(o, ReceiptType.pickup),
                  icon: const Icon(Icons.receipt_long_rounded, size: 15),
                  label: Text(AppLanguage.tr('পিকআপ রিসিট'), style: const TextStyle(fontSize: 12)),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _openReceipt(o, ReceiptType.delivery),
                  icon: const Icon(Icons.receipt_rounded, size: 15),
                  label: Text(AppLanguage.tr('ডেলিভারি রিসিট'), style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Collection / wallet (two tabs: today / all-by-date) ──

class RiderCollectionScreen extends StatefulWidget {
  final String riderId;
  const RiderCollectionScreen({super.key, required this.riderId});

  @override
  State<RiderCollectionScreen> createState() => _RiderCollectionScreenState();
}

class _RiderCollectionScreenState extends State<RiderCollectionScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  List<AdminOrder> _delivered = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _error = null);
    try {
      final orders = await AdminService.orders(riderId: widget.riderId);
      if (!mounted) return;
      setState(() {
        _delivered = orders.where((o) => o.status == 'Delivered').toList();
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

  List<AdminOrder> get _todayDelivered => _delivered.where((o) => _isToday(o.deliveredAt)).toList();
  int get _todayTotal => _todayDelivered.fold(0, (s, o) => s + o.total);

  List<_DayCollection> get _byDay {
    final map = <String, _DayCollection>{};
    for (final o in _delivered) {
      final d = o.deliveredAt;
      if (d == null) continue;
      final key = '${d.year}-${d.month}-${d.day}';
      final day = map[key] ??= _DayCollection(DateTime(d.year, d.month, d.day));
      day.total += o.total;
      day.count += 1;
    }
    final list = map.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text(AppLanguage.tr('কালেক্ট')),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.blue,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.blue,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          tabs: [Tab(text: AppLanguage.tr('আজকের কালেক্ট')), Tab(text: AppLanguage.tr('সব কালেক্ট'))],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorStateView(message: AdminService.messageFor(_error!), onRetry: _load)
              : TabBarView(controller: _tab, children: [_todayTab(), _allTab()]),
    );
  }

  Widget _summaryBanner(String label, int amount, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('৳${toBn(amount)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _todayTab() {
    final orders = _todayDelivered;
    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _summaryBanner(AppLanguage.tr('আজকে কালেক্ট হয়েছে'), _todayTotal, AppColors.teal),
          const SizedBox(height: 8),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(child: Text(AppLanguage.tr('আজকে কোনো ডেলিভারি হয়নি'), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))),
            )
          else
            for (final o in orders)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: _collectRow(o.id, o.customerName, o.total),
              ),
        ],
      ),
    );
  }

  Widget _allTab() {
    final days = _byDay;
    final grand = _delivered.fold(0, (s, o) => s + o.total);
    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _summaryBanner(AppLanguage.tr('মোট কালেক্ট'), grand, AppColors.blue),
          const SizedBox(height: 8),
          if (days.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(child: Text(AppLanguage.tr('কোনো হিসাব নেই'), style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700))),
            )
          else
            for (final day in days)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: _dayRow(day),
              ),
        ],
      ),
    );
  }

  Widget _collectRow(String id, String name, int amount) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.ink)),
                Text(name, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text('৳${toBn(amount)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.teal)),
        ],
      ),
    );
  }

  Widget _dayRow(_DayCollection day) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.event_rounded, color: AppColors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_bnDayLabel(day.date), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.ink)),
                Text('${toBn(day.count)} ${AppLanguage.tr('টি ডেলিভারি')}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text('৳${toBn(day.total)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.teal)),
        ],
      ),
    );
  }
}

class _DayCollection {
  final DateTime date;
  int total = 0;
  int count = 0;
  _DayCollection(this.date);
}
