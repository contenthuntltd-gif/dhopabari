import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../services/admin_service.dart';
import '../../widgets/bn_number.dart';
import '../../widgets/state_views.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/mini_charts.dart';
import '../../widgets/app_page_route.dart';
import 'order_detail_screen.dart';
import 'orders_screen.dart';

/// Table-header text style for the desktop recent-orders table.
const _thStyle = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.4);

class DashboardScreen extends StatefulWidget {
  /// When embedded in the desktop admin shell, tapping a status card should
  /// switch to the Orders tab rather than push a new route. The shell wires
  /// this up; when null (standalone) the dashboard pushes the orders screen.
  final VoidCallback? onOpenOrders;

  const DashboardScreen({super.key, this.onOpenOrders});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  List<AdminOrder> _recent = const [];
  bool _loading = true;
  Object? _error;

  // Selected reporting window for the KPI + status cards.
  DashPeriod _period = DashPeriod.today;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// Stats for the currently selected period, computed from the loaded data.
  PeriodStats get _periodStats {
    final r = _stats!.rangeFor(_period, customStart: _customStart, customEnd: _customEnd);
    return _stats!.forRange(r.start, r.end);
  }

  String get _periodLabel {
    switch (_period) {
      case DashPeriod.today:
        return 'আজ';
      case DashPeriod.week:
        return 'এই সপ্তাহ';
      case DashPeriod.month:
        return 'এই মাস';
      case DashPeriod.year:
        return 'এই বছর';
      case DashPeriod.custom:
        if (_customStart == null) return 'কাস্টম';
        return '${bnDate(_customStart!)} – ${bnDate(_customEnd ?? _customStart!)}';
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _customStart != null
          ? DateTimeRange(start: _customStart!, end: _customEnd ?? _customStart!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.blue)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _period = DashPeriod.custom;
        _customStart = picked.start;
        _customEnd = picked.end;
      });
    }
  }

  void _selectPeriod(DashPeriod p) {
    if (p == DashPeriod.custom) {
      _pickCustomRange();
    } else {
      setState(() => _period = p);
    }
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _error = null);
    try {
      final results = await Future.wait([
        AdminService.dashboardStats(),
        AdminService.orders(limit: 5),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as DashboardStats;
        _recent = results[1] as List<AdminOrder>;
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

  void _goToOrders(String status) {
    if (widget.onOpenOrders != null) {
      widget.onOpenOrders!();
    } else {
      Navigator.push(context, AppPageRoute(builder: (_) => OrdersScreen(initialFilter: status)))
          .then((_) => _refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ErrorStateView(message: AdminService.messageFor(_error!), onRetry: _refresh);
    }

    final s = _stats!;
    // One responsive layout for every width: the card grids reflow from a
    // single column on a phone up to five/six across on a wide monitor.
    return LayoutBuilder(
      builder: (context, constraints) => _buildDesktop(s, constraints.maxWidth),
    );
  }

  // ── Desktop dashboard ─────────────────────────────────────

  Widget _buildDesktop(DashboardStats s, double width) {
    // Content width after the 24px page padding on each side.
    final avail = width - 48;
    final chartsSideBySide = avail >= 860;
    final ps = _periodStats;

    final donut = _panel(
      'অর্ডার স্ট্যাটাস · $_periodLabel',
      StatusDonutChart(slices: [
        DonutSlice(label: 'সম্পন্ন', value: ps.status('Delivered'), color: AppColors.green),
        DonutSlice(label: 'পথে', value: ps.status('Out for Delivery'), color: AppColors.teal),
        DonutSlice(label: 'পরিষ্কার/প্যাক', value: ps.status('Cleaning') + ps.status('Packaging Done'), color: const Color(0xFF7C5CFC)),
        DonutSlice(label: 'সংগ্রহ', value: ps.status('Picked Up'), color: AppColors.blue),
        DonutSlice(label: 'নিশ্চিত', value: ps.status('Confirmed'), color: AppColors.amber),
        DonutSlice(label: 'বাতিল', value: ps.status('Cancelled'), color: AppColors.danger),
      ]),
    );
    final revenue = _panel(
      'সাপ্তাহিক আয় (গত ৭ দিন)',
      RevenueBarChart(values: s.revenueSeries, labels: s.revenueLabels),
    );

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _periodSelector(),
          const SizedBox(height: 16),
          // KPI cards — reflow to fill the available width at any size.
          // Revenue / orders / avg follow the selected period; customer &
          // rider totals are all-time head-counts.
          _grid(avail, minItem: 196, gap: 16, cards: [
            _kpi('আয় ($_periodLabel)', money(ps.revenue), Icons.payments_rounded, AppColors.blue, primary: true),
            _kpi('অর্ডার ($_periodLabel)', toBn(ps.orders), Icons.receipt_long_rounded, AppColors.teal),
            _kpi('গড় অর্ডার মূল্য', money(ps.avgOrderValue), Icons.insights_rounded, AppColors.green),
            _kpi('মোট কাস্টমার', toBn(s.totalCustomers), Icons.people_alt_rounded, AppColors.amber),
            _kpi('মোট রাইডার', toBn(s.totalRiders), Icons.two_wheeler_rounded, const Color(0xFF7C5CFC)),
          ]),
          const SizedBox(height: 26),
          Text('অর্ডার অবস্থা · $_periodLabel', style: AppText.h2),
          const SizedBox(height: 12),
          _grid(avail, minItem: 168, gap: 12, cards: [
            _statusCard('নিশ্চিত হয়েছে', ps.status('Confirmed'), Icons.check_circle_outline_rounded, AppColors.amber, 'Confirmed'),
            _statusCard('সংগ্রহ হয়েছে', ps.status('Picked Up'), Icons.local_shipping_outlined, AppColors.blue, 'Picked Up'),
            _statusCard('পরিষ্কার হচ্ছে', ps.status('Cleaning'), Icons.local_laundry_service_outlined, const Color(0xFF7C5CFC), 'Cleaning'),
            _statusCard('প্যাকেজিং সম্পন্ন', ps.status('Packaging Done'), Icons.inventory_2_outlined, AppColors.teal, 'Packaging Done'),
            _statusCard('ডেলিভারির পথে', ps.status('Out for Delivery'), Icons.local_shipping_rounded, AppColors.teal, 'Out for Delivery'),
            _statusCard('ডেলিভারি সম্পন্ন', ps.status('Delivered'), Icons.done_all_rounded, AppColors.green, 'Delivered'),
          ]),
          const SizedBox(height: 26),
          // Charts — side by side on wide screens, stacked when narrow.
          if (chartsSideBySide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: revenue),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: donut),
                ],
              ),
            )
          else ...[
            revenue,
            const SizedBox(height: 16),
            donut,
          ],
          const SizedBox(height: 26),
          _recentOrdersPanel(),
        ],
      ),
    );
  }

  /// The Today / Week / Month / Year / Custom segmented selector.
  Widget _periodSelector() {
    Widget chip(String label, DashPeriod p, {IconData? icon}) {
      final active = _period == p;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: active ? AppColors.blue : Colors.white,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => _selectPeriod(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: active ? AppColors.blue : AppColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: active ? Colors.white : AppColors.muted),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: active ? Colors.white : AppColors.ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('আজ', DashPeriod.today),
          chip('সপ্তাহ', DashPeriod.week),
          chip('মাস', DashPeriod.month),
          chip('বছর', DashPeriod.year),
          chip(_period == DashPeriod.custom ? _periodLabel : 'কাস্টম', DashPeriod.custom, icon: Icons.calendar_month_rounded),
        ],
      ),
    );
  }

  /// Lays [cards] into a wrap that always fills [avail] width: it fits as
  /// many columns of at least [minItem] as it can, then splits the width
  /// evenly among them. Cards reflow to more rows as the window narrows, so
  /// they are never stuck at a fixed mobile size.
  Widget _grid(double avail, {required List<Widget> cards, required double minItem, required double gap}) {
    if (avail <= 0) return Column(children: cards);
    int cols = ((avail + gap) / (minItem + gap)).floor();
    cols = cols.clamp(1, cards.length);
    final itemW = (avail - gap * (cols - 1)) / cols;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [for (final c in cards) SizedBox(width: itemW, child: c)],
    );
  }

  /// A desktop-scale order-status tile: colored icon, big count, label.
  Widget _statusCard(String label, int count, IconData icon, Color color, String statusKey) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _goToOrders(statusKey),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.line),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, size: 23, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(toBn(count), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink)),
                    const SizedBox(height: 1),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color color, {bool primary = false}) {
    final fg = primary ? Colors.white : AppColors.ink;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: primary ? const LinearGradient(colors: [AppColors.blue, AppColors.blueDeep], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        color: primary ? null : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: primary ? null : Border.all(color: AppColors.line),
        boxShadow: primary
            ? [BoxShadow(color: AppColors.blue.withValues(alpha: 0.28), blurRadius: 20, offset: const Offset(0, 10))]
            : AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary ? Colors.white.withValues(alpha: 0.18) : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: primary ? Colors.white : color),
          ),
          const SizedBox(height: 14),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: fg)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary ? Colors.white70 : AppColors.muted)),
        ],
      ),
    );
  }

  Widget _panel(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h3),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _recentOrdersPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('সাম্প্রতিক অর্ডার', style: AppText.h3),
              const Spacer(),
              if (widget.onOpenOrders != null)
                TextButton(onPressed: widget.onOpenOrders, child: const Text('সব দেখুন →')),
            ],
          ),
          const SizedBox(height: 8),
          if (_recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('এখনো কোনো অর্ডার নেই', style: AppText.bodyMuted)),
            )
          else ...[
            // Header row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
              child: Row(
                children: const [
                  Expanded(flex: 2, child: Text('অর্ডার', style: _thStyle)),
                  Expanded(flex: 3, child: Text('কাস্টমার', style: _thStyle)),
                  Expanded(flex: 3, child: Text('আইটেম', style: _thStyle)),
                  Expanded(flex: 2, child: Text('পরিমাণ', style: _thStyle)),
                  Expanded(flex: 2, child: Text('স্ট্যাটাস', style: _thStyle)),
                ],
              ),
            ),
            for (final o in _recent)
              InkWell(
                onTap: () => Navigator.push(context, AppPageRoute(builder: (_) => OrderDetailScreen(order: o))).then((_) => _refresh()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(o.id, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink))),
                      Expanded(flex: 3, child: Text(o.customerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w600))),
                      Expanded(flex: 3, child: Text(o.itemsSummary, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600))),
                      Expanded(flex: 2, child: Text(money(o.total), style: const TextStyle(fontSize: 12.5, color: AppColors.blue, fontWeight: FontWeight.w900))),
                      Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: StatusBadge(status: o.status, label: AdminMockData.orderStatusesBn[o.status]))),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
