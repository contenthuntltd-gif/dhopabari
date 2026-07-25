import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../services/admin_service.dart';
import '../../widgets/bn_number.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/state_views.dart';

/// রিসাইকেল বিন — deleted items wait here, split by category (Orders /
/// Customers). Each can be Restored (back to its list) or deleted Permanently.
class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});
  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> with SingleTickerProviderStateMixin {
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
        title: const Text('রিসাইকেল বিন'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.blue,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.blue,
          labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'অর্ডার'),
            Tab(text: 'কাস্টমার'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _TrashedOrdersTab(),
          _TrashedCustomersTab(),
        ],
      ),
    );
  }
}

// ── Orders ───────────────────────────────────────────────
class _TrashedOrdersTab extends StatefulWidget {
  const _TrashedOrdersTab();
  @override
  State<_TrashedOrdersTab> createState() => _TrashedOrdersTabState();
}

class _TrashedOrdersTabState extends State<_TrashedOrdersTab> {
  late Future<List<AdminOrder>> _future;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = AdminService.orders(trashed: true, limit: 500);
  Future<void> _reload() async {
    setState(_load);
    await _future;
  }

  Future<void> _restore(AdminOrder o) async {
    setState(() => _busy.add(o.uuid));
    try {
      await AdminService.restoreOrders([o.uuid]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${o.id} ফিরিয়ে আনা হয়েছে'), backgroundColor: AppColors.green));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy.remove(o.uuid));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AdminService.messageFor(e))));
    }
  }

  Future<void> _deleteForever(AdminOrder o) async {
    final ok = await _confirmForever(context, '${o.id} চিরতরে মুছে যাবে — আর ফেরানো যাবে না।');
    if (ok != true) return;
    setState(() => _busy.add(o.uuid));
    try {
      await AdminService.deleteOrdersForever([o.uuid]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${o.id} স্থায়ীভাবে মুছে ফেলা হয়েছে')));
      await _reload();
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
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return const EmptyState(icon: Icons.receipt_long_outlined, title: 'কোনো ডিলিট করা অর্ডার নেই', subtitle: 'ডিলিট করা অর্ডার এখানে জমা হবে।');
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final o = items[i];
                  final busy = _busy.contains(o.uuid);
                  return FadeSlideIn(
                    delayMs: i * 30,
                    child: _trashTile(
                      title: o.id,
                      trailing: '৳${o.total}',
                      subtitle: '${o.customerName} • ${o.service} • ${toBn(o.pieces)} পিস',
                      busy: busy,
                      onRestore: () => _restore(o),
                      onDelete: () => _deleteForever(o),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Customers ────────────────────────────────────────────
class _TrashedCustomersTab extends StatefulWidget {
  const _TrashedCustomersTab();
  @override
  State<_TrashedCustomersTab> createState() => _TrashedCustomersTabState();
}

class _TrashedCustomersTabState extends State<_TrashedCustomersTab> {
  late Future<List<AdminCustomer>> _future;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = AdminService.customers(trashed: true);
  Future<void> _reload() async {
    setState(_load);
    await _future;
  }

  Future<void> _restore(AdminCustomer c) async {
    setState(() => _busy.add(c.id));
    try {
      await AdminService.restoreCustomers([c.id]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c.name} ফিরিয়ে আনা হয়েছে'), backgroundColor: AppColors.green));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy.remove(c.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AdminService.messageFor(e))));
    }
  }

  Future<void> _deleteForever(AdminCustomer c) async {
    final ok = await _confirmForever(context, '${c.name}-এর অ্যাকাউন্ট ও সব অর্ডার চিরতরে মুছে যাবে — আর ফেরানো যাবে না।');
    if (ok != true) return;
    setState(() => _busy.add(c.id));
    try {
      await AdminService.deleteCustomersForever([c.id]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c.name} স্থায়ীভাবে মুছে ফেলা হয়েছে')));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy.remove(c.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AdminService.messageFor(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminCustomer>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return ErrorStateView(message: AdminService.messageFor(snap.error!), onRetry: _reload);
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return const EmptyState(icon: Icons.people_outline_rounded, title: 'কোনো ডিলিট করা কাস্টমার নেই', subtitle: 'ডিলিট করা কাস্টমার এখানে জমা হবে।');
        }
        return RefreshIndicator(
          onRefresh: _reload,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = items[i];
                  final busy = _busy.contains(c.id);
                  return FadeSlideIn(
                    delayMs: i * 30,
                    child: _trashTile(
                      title: c.name,
                      trailing: '${toBn(c.totalOrders)} অর্ডার',
                      subtitle: c.phone,
                      busy: busy,
                      onRestore: () => _restore(c),
                      onDelete: () => _deleteForever(c),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Shared ───────────────────────────────────────────────
Future<bool?> _confirmForever(BuildContext context, String message) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      title: const Text('স্থায়ীভাবে মুছবেন?'),
      content: Text(message, style: const TextStyle(fontSize: 13.5, height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('স্থায়ীভাবে মুছুন')),
      ],
    ),
  );
}

Widget _trashTile({
  required String title,
  required String trailing,
  required String subtitle,
  required bool busy,
  required VoidCallback onRestore,
  required VoidCallback onDelete,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink))),
            Text(trailing, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.blue)),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.green)),
                onPressed: busy ? null : onRestore,
                icon: busy ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.restore_rounded, size: 18),
                label: const Text('ফিরিয়ে আনুন'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                onPressed: busy ? null : onDelete,
                icon: const Icon(Icons.delete_forever_rounded, size: 18),
                label: const Text('স্থায়ীভাবে'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
