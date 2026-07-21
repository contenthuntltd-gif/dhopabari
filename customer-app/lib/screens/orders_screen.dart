import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/admin_mock_data.dart';
import '../data/mock_data.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../widgets/bn_number.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/skeleton.dart';
import '../widgets/state_views.dart';
import '../widgets/app_page_route.dart';
import '../services/language.dart';
import 'tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

enum _OrderFilter { all, ongoing, delivered }

class _OrdersScreenState extends State<OrdersScreen> {
  bool _loading = true;
  Object? _error;
  List<MockOrder> _orders = const [];
  String _search = '';
  _OrderFilter _filter = _OrderFilter.all;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Real order history from the database — RLS scopes the query to the
  /// signed-in user's own orders. The signed-out preview keeps the demo
  /// list so the screen is still browsable.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (AuthService.isLoggedIn) {
        final rows = await AdminService.orders(limit: 100);
        _orders = rows.map((o) => o.toMockOrder()).toList();
      } else {
        // Guest: no order history yet.
        _orders = const [];
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() => _load();

  List<MockOrder> get _filtered {
    var list = _orders;
    switch (_filter) {
      case _OrderFilter.ongoing:
        list = list.where((o) => o.progress < 1).toList();
      case _OrderFilter.delivered:
        list = list.where((o) => o.progress >= 1).toList();
      case _OrderFilter.all:
        break;
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      list = list
          .where(
            (o) =>
                o.id.toLowerCase().contains(q) ||
                o.service.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filtered;
    final hasAnyOrders = _orders.isNotEmpty;
    final isFiltering =
        _search.trim().isNotEmpty || _filter != _OrderFilter.all;

    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isEnglish,
      builder: (context, _, _) => Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: Text(AppLanguage.tr('আমার অর্ডার'))),
      body: SafeArea(
        child: Column(
          children: [
            if (hasAnyOrders) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.sm,
                  AppSpace.xs,
                  AppSpace.sm,
                  0,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: AppLanguage.tr('অর্ডার নম্বর বা সার্ভিস খুঁজুন'),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: AppIconSize.md,
                      color: AppColors.muted,
                    ),
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.sm,
                  AppSpace.xs,
                  AppSpace.sm,
                  0,
                ),
                child: Row(
                  children: [
                    _FilterChip(
                      label: AppLanguage.tr('সব'),
                      selected: _filter == _OrderFilter.all,
                      onTap: () => setState(() => _filter = _OrderFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: AppLanguage.tr('চলমান'),
                      selected: _filter == _OrderFilter.ongoing,
                      onTap: () =>
                          setState(() => _filter = _OrderFilter.ongoing),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: AppLanguage.tr('সম্পন্ন'),
                      selected: _filter == _OrderFilter.delivered,
                      onTap: () =>
                          setState(() => _filter = _OrderFilter.delivered),
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.base,
                child: _loading
                    ? ListView.separated(
                        key: const ValueKey('skeleton'),
                        padding: const EdgeInsets.all(AppSpace.sm),
                        itemCount: 4,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => const SkeletonCard(),
                      )
                    : _error != null
                    ? ErrorStateView(
                        key: const ValueKey('error'),
                        message: AdminService.messageFor(_error!),
                        onRetry: _load,
                      )
                    : orders.isEmpty
                    ? EmptyState(
                        key: const ValueKey('empty'),
                        icon: isFiltering
                            ? Icons.search_off_rounded
                            : Icons.receipt_long_rounded,
                        title: isFiltering
                            ? AppLanguage.tr('কোনো অর্ডার পাওয়া যায়নি')
                            : AppLanguage.tr('এখনো কোনো অর্ডার নেই'),
                        subtitle: isFiltering
                            ? AppLanguage.tr('ভিন্ন ফিল্টার বা সার্চ শব্দ ব্যবহার করে দেখুন।')
                            : AppLanguage.tr('আপনার প্রথম অর্ডার দিন এবং প্রিমিয়াম লন্ড্রি সেবা উপভোগ করুন।'),
                        actionLabel: isFiltering ? null : AppLanguage.tr('নতুন অর্ডার করুন'),
                        onAction: isFiltering
                            ? null
                            : () => Navigator.pop(context),
                      )
                    : RefreshIndicator(
                        key: const ValueKey('content'),
                        color: AppColors.blue,
                        onRefresh: _refresh,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppSpace.sm),
                          itemCount: orders.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpace.xs),
                          itemBuilder: (context, i) => FadeSlideIn(
                            delayMs: i * 50,
                            child: _OrderCard(order: orders[i]),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue : Colors.white,
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.line,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final MockOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDone = order.progress >= 1;
    final accent = isDone ? AppColors.green : AppColors.blue;
    final isDry = order.service == 'Dry Clean';
    final serviceColors = isDry
        ? const [AppColors.teal, Color(0xFF0C8B85)]
        : const [AppColors.blue, AppColors.blueDeep];

    return Semantics(
      button: true,
      label: 'অর্ডার ${order.id}, অবস্থা ${order.currentStatusLabel}',
      child: PressableScale(
        onTap: () => Navigator.push(
          context,
          AppPageRoute(builder: (_) => TrackingScreen(order: order)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: Colors.white,
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: serviceColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      isDry
                          ? Icons.dry_cleaning_rounded
                          : Icons.local_laundry_service_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.id,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          order.date,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.service} • ${toBn(order.pieces)} পিস',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    money(order.total),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle_rounded
                              : Icons.autorenew_rounded,
                          size: 12,
                          color: accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.currentStatusLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniTimeline(order: order, accent: accent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact row of dots representing the order's status timeline, so
/// list cards hint at progress without needing to open the full
/// Tracking screen.
class _MiniTimeline extends StatelessWidget {
  final MockOrder order;
  final Color accent;
  const _MiniTimeline({required this.order, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(order.timeline.length, (i) {
        final step = order.timeline[i];
        final filled = step.done || step.current;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: i == order.timeline.length - 1 ? 0 : 4,
            ),
            child: AnimatedContainer(
              duration: AppMotion.base,
              height: 4,
              decoration: BoxDecoration(
                color: filled ? accent : AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }),
    );
  }
}
