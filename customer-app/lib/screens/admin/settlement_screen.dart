import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_service.dart';
import '../../data/admin_mock_data.dart';
import '../../widgets/bn_number.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/state_views.dart';

/// ক্যাশ হিসাব — rider cash settlement, split into two tabs:
///   • বুঝে পাইনি  (waiting)  — delivered COD orders whose cash the office
///     hasn't received yet. Tapping "বুঝে পেয়েছি" moves it to received.
///   • বুঝে পেয়েছি (received) — already handed in; can be moved back.
class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});
  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('ক্যাশ হিসাব'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.blue,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.blue,
          labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'বুঝে পাইনি'),
            Tab(text: 'বুঝে পেয়েছি'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _SettleTab(settled: false),
          _SettleTab(settled: true),
        ],
      ),
    );
  }
}

class _RiderGroup {
  final String riderName;
  final List<AdminOrder> orders = [];
  _RiderGroup(this.riderName);
  int get total => orders.fold(0, (s, o) => s + o.total);
}

class _SettleTab extends StatefulWidget {
  final bool settled;
  const _SettleTab({required this.settled});
  @override
  State<_SettleTab> createState() => _SettleTabState();
}

class _SettleTabState extends State<_SettleTab> {
  late Future<List<AdminOrder>> _future;
  List<AdminOrder> _orders = [];
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = AdminService.codOrders(settled: widget.settled).then((list) {
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
      final g = map.putIfAbsent(key, () => _RiderGroup(o.riderName ?? 'রাইডার অ্যাসাইন করা হয়নি'));
      g.orders.add(o);
    }
    return map.values.toList()..sort((a, b) => b.total.compareTo(a.total));
  }

  Future<void> _toggle(AdminOrder o) async {
    setState(() => _busy.add(o.uuid));
    try {
      if (widget.settled) {
        await AdminService.unsettleOrder(o.uuid);
      } else {
        await AdminService.settleOrder(o.uuid);
      }
      if (!mounted) return;
      setState(() {
        _orders.removeWhere((x) => x.uuid == o.uuid);
        _busy.remove(o.uuid);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.settled ? '${o.id} আবার "বুঝে পাইনি"-তে সরানো হয়েছে' : '${o.id} — ৳${o.total} বুঝে নেওয়া হয়েছে'),
        backgroundColor: widget.settled ? AppColors.ink : AppColors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy.remove(o.uuid));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AdminService.messageFor(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminOrder>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return ErrorStateView(message: AdminService.messageFor(snap.error!), onRetry: _reload);
        final groups = _grouped();
        if (groups.isEmpty) {
          return EmptyState(
            icon: widget.settled ? Icons.verified_outlined : Icons.account_balance_wallet_outlined,
            title: widget.settled ? 'এখনো কিছু বুঝে নেওয়া হয়নি' : 'সব হিসাব ক্লিয়ার',
            subtitle: widget.settled ? 'বুঝে নেওয়া অর্ডার এখানে জমা হবে।' : 'বুঝে নেওয়ার মতো কোনো ক্যাশ অর্ডার বাকি নেই।',
          );
        }
        final total = groups.fold<int>(0, (s, g) => s + g.total);
        final count = groups.fold<int>(0, (s, g) => s + g.orders.length);
        return RefreshIndicator(
          onRefresh: _reload,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _summaryBar(total, count),
                  const SizedBox(height: 14),
                  for (int i = 0; i < groups.length; i++)
                    FadeSlideIn(delayMs: i * 40, child: _riderCard(groups[i])),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryBar(int total, int count) {
    final green = widget.settled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: green ? [AppColors.green, const Color(0xFF0B8A43)] : [AppColors.blue, const Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Icon(green ? Icons.verified_rounded : Icons.account_balance_wallet_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(green ? 'মোট বুঝে নেওয়া হয়েছে' : 'মোট বুঝে নেওয়া বাকি', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('৳$total', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(toBn(count), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              const Text('অর্ডার', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _riderCard(_RiderGroup g) {
    final green = widget.settled;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: (green ? AppColors.green : AppColors.blue).withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 18, backgroundColor: (green ? AppColors.green : AppColors.blue).withValues(alpha: 0.15), child: Icon(Icons.two_wheeler_rounded, color: green ? AppColors.green : AppColors.blue, size: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g.riderName, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.ink)),
                      Text('${toBn(g.orders.length)}টি অর্ডার', style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Text('৳${g.total}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: green ? AppColors.green : AppColors.blue)),
              ],
            ),
          ),
          for (int i = 0; i < g.orders.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            _orderRow(g.orders[i]),
          ],
        ],
      ),
    );
  }

  Widget _orderRow(AdminOrder o) {
    final busy = _busy.contains(o.uuid);
    final green = widget.settled;
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
                    Text(o.id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(width: 8),
                    Text('৳${o.total}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.green)),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${o.customerName} • ${o.service} • ${toBn(o.pieces)} পিস', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 34,
            child: green
                ? OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line), padding: const EdgeInsets.symmetric(horizontal: 10), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    onPressed: busy ? null : () => _toggle(o),
                    icon: busy ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.undo_rounded, size: 15),
                    label: const Text('ফেরত'),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12), textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                    onPressed: busy ? null : () => _toggle(o),
                    icon: busy ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('বুঝে পেয়েছি'),
                  ),
          ),
        ],
      ),
    );
  }
}
