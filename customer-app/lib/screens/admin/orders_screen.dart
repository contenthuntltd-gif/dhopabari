import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../services/admin_service.dart';
import '../../widgets/bn_number.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/state_views.dart';
import '../../widgets/app_page_route.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final String initialFilter;
  const OrdersScreen({super.key, this.initialFilter = 'All'});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late String _filter = widget.initialFilter;
  String _search = '';
  final _searchController = TextEditingController();

  /// Orders are fetched once and then filtered in memory: the status chips
  /// and search box should feel instant, and the result set is capped.
  List<AdminOrder> _all = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await AdminService.orders();
      if (!mounted) return;
      setState(() {
        _all = orders;
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

  List<AdminOrder> get _filtered {
    var list = _all;
    if (_filter != 'All') list = list.where((o) => o.status == _filter).toList();
    if (_search.trim().isNotEmpty) {
      final q = _search.trim().toLowerCase();
      list = list.where((o) => o.id.toLowerCase().contains(q) || o.customerName.toLowerCase().contains(q) || o.customerPhone.contains(q)).toList();
    }
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ['All', ...AdminMockData.orderStatuses];
    final orders = _filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'অর্ডার নম্বর, নাম বা ফোন খুঁজুন',
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.muted),
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
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final f = filters[i];
              final active = f == _filter;
              final label = f == 'All' ? 'সব' : AdminMockData.orderStatusesBn[f]!;
              return GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? AppColors.blue : Colors.white,
                    border: Border.all(color: active ? AppColors.blue : AppColors.line),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.ink)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? ErrorStateView(message: AdminService.messageFor(_error!), onRetry: _load)
              : orders.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: _all.isEmpty ? 'এখনো কোনো অর্ডার নেই' : 'কোনো অর্ডার পাওয়া যায়নি',
                  subtitle: _all.isEmpty
                      ? 'কাস্টমার অর্ডার করলে এখানে দেখা যাবে।'
                      : 'ভিন্ন ফিল্টার বা সার্চ শব্দ ব্যবহার করে দেখুন।',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final order = orders[i];
                    return FadeSlideIn(
                      delayMs: i * 40,
                      child: PressableScale(
                        onTap: () => Navigator.push(context, AppPageRoute(builder: (_) => OrderDetailScreen(order: order))).then((_) => _load()),
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
                              Text('${order.customerName} • ${order.customerPhone}', style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${order.service} • ${toBn(order.pieces)} পিস', style: const TextStyle(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w700)),
                                  Text(money(order.total), style: const TextStyle(fontSize: 13.5, color: AppColors.blue, fontWeight: FontWeight.w900)),
                                ],
                              ),
                              if (order.riderName != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.two_wheeler_rounded, size: 13, color: AppColors.teal),
                                    const SizedBox(width: 4),
                                    Text(order.riderName!, style: const TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  ),
                ),
        ),
      ],
    );
  }
}
