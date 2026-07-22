import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_service.dart';
import '../../data/admin_mock_data.dart';
import '../../widgets/bn_number.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/state_views.dart';

/// ক্যাশ হিসাব — rider cash settlement.
///
/// Riders collect Cash-on-Delivery money in the field and hand it in at the
/// office. This screen lists every delivered COD order whose cash has not
/// yet been received, grouped by the rider who delivered it. An admin ticks
/// "বুঝে পেয়েছি" on each order as the cash is handed over; settled orders
/// drop off the list. Cleared = cash reconciled.
class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});
  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _RiderGroup {
  final String? riderId;
  final String riderName;
  final List<AdminOrder> orders = [];
  _RiderGroup(this.riderId, this.riderName);

  int get totalDue => orders.fold(0, (s, o) => s + o.total);
}

class _SettlementScreenState extends State<SettlementScreen> {
  late Future<List<AdminOrder>> _future;
  List<AdminOrder> _orders = [];
  final Set<String> _settling = {}; // uuids currently being marked

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = AdminService.unsettledCodOrders().then((list) {
      _orders = list;
      return list;
    });
  }

  Future<void> _reload() async {
    setState(_load);
    await _future;
  }

  List<_RiderGroup> _grouped() {
    final map = <String, _RiderGroup>{};
    for (final o in _orders) {
      final key = o.riderId ?? '__none__';
      final g = map.putIfAbsent(
        key,
        () => _RiderGroup(o.riderId, o.riderName ?? 'রাইডার অ্যাসাইন করা হয়নি'),
      );
      g.orders.add(o);
    }
    // Riders who owe the most first.
    final list = map.values.toList()
      ..sort((a, b) => b.totalDue.compareTo(a.totalDue));
    return list;
  }

  Future<void> _settle(AdminOrder o) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('হিসাব বুঝে পেয়েছেন?'),
        content: Text(
          '${o.id} — ${o.customerName}\nটাকা: ৳${o.total}\n\nএই অর্ডারের নগদ টাকা অফিসে বুঝে পাওয়া হয়েছে বলে নিশ্চিত করুন।',
          style: const TextStyle(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('বুঝে পেয়েছি'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _settling.add(o.uuid));
    try {
      await AdminService.settleOrder(o.uuid);
      if (!mounted) return;
      setState(() {
        _orders.removeWhere((x) => x.uuid == o.uuid);
        _settling.remove(o.uuid);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${o.id} — ৳${o.total} হিসাবে বুঝে নেওয়া হয়েছে'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _settling.remove(o.uuid));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminService.messageFor(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('ক্যাশ হিসাব')),
      body: FutureBuilder<List<AdminOrder>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorStateView(
              message: AdminService.messageFor(snap.error!),
              onRetry: _reload,
            );
          }
          final groups = _grouped();
          if (groups.isEmpty) {
            return const EmptyState(
              icon: Icons.verified_outlined,
              title: 'সব হিসাব ক্লিয়ার',
              subtitle: 'বুঝে নেওয়ার মতো কোনো ক্যাশ অর্ডার বাকি নেই।',
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _summaryBar(groups),
                    const SizedBox(height: 14),
                    for (int i = 0; i < groups.length; i++)
                      FadeSlideIn(
                        delayMs: i * 40,
                        child: _riderCard(groups[i]),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _summaryBar(List<_RiderGroup> groups) {
    final totalDue = groups.fold<int>(0, (s, g) => s + g.totalDue);
    final orderCount = groups.fold<int>(0, (s, g) => s + g.orders.length);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue, Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('মোট বুঝে নেওয়া বাকি',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('৳$totalDue',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(toBn(orderCount),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              const Text('অর্ডার',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _riderCard(_RiderGroup g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rider header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.blue.withValues(alpha: 0.15),
                  child: const Icon(Icons.two_wheeler_rounded,
                      color: AppColors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.riderName,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink)),
                      Text('${toBn(g.orders.length)}টি অর্ডার বাকি',
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('৳${g.totalDue}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.blue)),
                    const Text('বুঝে নিতে হবে',
                        style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                  ],
                ),
              ],
            ),
          ),
          // Orders
          for (int i = 0; i < g.orders.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            _orderRow(g.orders[i]),
          ],
        ],
      ),
    );
  }

  Widget _orderRow(AdminOrder o) {
    final busy = _settling.contains(o.uuid);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(o.id,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink)),
                    const SizedBox(width: 8),
                    Text('৳${o.total}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.green)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${o.customerName} • ${o.service} • ${toBn(o.pieces)} পিস',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 34,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle:
                    const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
              onPressed: busy ? null : () => _settle(o),
              icon: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('বুঝে পেয়েছি'),
            ),
          ),
        ],
      ),
    );
  }
}
