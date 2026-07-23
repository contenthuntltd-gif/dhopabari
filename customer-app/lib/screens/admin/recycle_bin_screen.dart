import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../services/admin_service.dart';
import '../../widgets/bn_number.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/state_views.dart';

/// রিসাইকেল বিন — deleted orders wait here. An admin can Restore them (back
/// to the normal lists) or delete them Permanently (gone for good).
///
/// Anything the admin "deletes" is soft-deleted (deleted_at set) rather than
/// removed, so a mistaken delete is never final until confirmed here.
class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});
  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  late Future<List<AdminOrder>> _future;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = AdminService.orders(trashed: true, limit: 500);
  }

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('স্থায়ীভাবে মুছবেন?'),
        content: Text('${o.id} চিরতরে মুছে যাবে — আর ফেরানো যাবে না।', style: const TextStyle(fontSize: 13.5, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('স্থায়ীভাবে মুছুন')),
        ],
      ),
    );
    if (confirm != true) return;
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
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('রিসাইকেল বিন')),
      body: FutureBuilder<List<AdminOrder>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorStateView(message: AdminService.messageFor(snap.error!), onRetry: _reload);
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.delete_outline_rounded,
              title: 'রিসাইকেল বিন খালি',
              subtitle: 'ডিলিট করা অর্ডার এখানে জমা হবে — ফিরিয়ে আনা বা স্থায়ীভাবে মোছা যাবে।',
            );
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
                  itemBuilder: (context, i) => FadeSlideIn(delayMs: i * 30, child: _tile(items[i])),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(AdminOrder o) {
    final busy = _busy.contains(o.uuid);
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
              Text('৳${o.total}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.blue)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${o.customerName} • ${o.service} • ${toBn(o.pieces)} পিস', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.green)),
                  onPressed: busy ? null : () => _restore(o),
                  icon: busy ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('ফিরিয়ে আনুন'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                  onPressed: busy ? null : () => _deleteForever(o),
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
}
