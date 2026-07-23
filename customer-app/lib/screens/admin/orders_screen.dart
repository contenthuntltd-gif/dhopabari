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
import 'customers_screen.dart';

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

  // Multi-select for bulk delete → recycle bin.
  bool _selectMode = false;
  final Set<String> _selected = {};

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final count = _selected.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('অর্ডার ডিলিট করবেন?'),
        content: Text('$count টি অর্ডার রিসাইকেল বিনে যাবে। সেখান থেকে আবার ফিরিয়ে আনা যাবে।', style: const TextStyle(fontSize: 13.5, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('ডিলিট')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AdminService.trashOrders(_selected.toList());
      if (!mounted) return;
      setState(() {
        _selectMode = false;
        _selected.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count টি অর্ডার রিসাইকেল বিনে সরানো হয়েছে'), backgroundColor: AppColors.ink));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AdminService.messageFor(e))));
    }
  }

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
          child: Row(
            children: [
              Expanded(
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
              const SizedBox(width: 8),
              // Toggle multi-select mode (bulk delete → recycle bin).
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _selectMode ? AppColors.danger : AppColors.ink,
                    side: BorderSide(color: _selectMode ? AppColors.danger : AppColors.line),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => setState(() {
                    _selectMode = !_selectMode;
                    _selected.clear();
                  }),
                  child: Icon(_selectMode ? Icons.close_rounded : Icons.checklist_rounded, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              // Admin places an order: pick the customer, then their order form.
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, padding: const EdgeInsets.symmetric(horizontal: 14)),
                  onPressed: () async {
                    // Pick the customer to order for; their detail screen has
                    // the "নতুন অর্ডার" form (creates the order under them).
                    await Navigator.push(context, AppPageRoute(builder: (_) => const CustomersScreen()));
                    if (mounted) _load();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('নতুন অর্ডার', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
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
                    final selected = _selected.contains(order.uuid);
                    return FadeSlideIn(
                      delayMs: i * 40,
                      child: PressableScale(
                        onTap: () {
                          if (_selectMode) {
                            setState(() {
                              if (selected) {
                                _selected.remove(order.uuid);
                              } else {
                                _selected.add(order.uuid);
                              }
                            });
                          } else {
                            Navigator.push(context, AppPageRoute(builder: (_) => OrderDetailScreen(order: order))).then((_) => _load());
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.blueSoft.withValues(alpha: 0.5) : Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: selected ? AppColors.blue : AppColors.line, width: selected ? 1.5 : 1),
                            boxShadow: AppShadows.soft,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      if (_selectMode) ...[
                                        Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 20, color: selected ? AppColors.blue : AppColors.muted),
                                        const SizedBox(width: 8),
                                      ],
                                      Text(order.id, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink)),
                                    ],
                                  ),
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
        // Bulk-action bar (select mode).
        if (_selectMode)
          Material(
            elevation: 8,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
              color: Colors.white,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      if (_selected.length == orders.length) {
                        _selected.clear();
                      } else {
                        _selected
                          ..clear()
                          ..addAll(orders.map((o) => o.uuid));
                      }
                    }),
                    child: Text(_selected.length == orders.length && orders.isNotEmpty ? 'সব বাদ' : 'সব নির্বাচন'),
                  ),
                  const Spacer(),
                  Text('${toBn(_selected.length)} টি নির্বাচিত', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                    onPressed: _selected.isEmpty ? null : _deleteSelected,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('ডিলিট'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
