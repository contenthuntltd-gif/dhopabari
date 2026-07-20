import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/fade_slide_in.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('ক্যাটালগ ব্যবস্থাপনা'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.blue,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.blue,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          tabs: const [
            Tab(text: 'সার্ভিস'),
            Tab(text: 'ক্যাটাগরি'),
            Tab(text: 'আইটেম'),
            Tab(text: 'মূল্য'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ServicesTab(onSnack: _snack),
          _CategoriesTab(onSnack: _snack),
          _ItemsTab(onSnack: _snack),
          _PricingTab(onSnack: _snack),
        ],
      ),
    );
  }
}

// ── Services ─────────────────────────────────────────────

class _ServicesTab extends StatefulWidget {
  final void Function(String) onSnack;
  const _ServicesTab({required this.onSnack});
  @override
  State<_ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<_ServicesTab> {
  Future<void> _editDialog({CatalogService? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final nameBnCtrl = TextEditingController(text: existing?.nameBn ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(existing == null ? 'নতুন সার্ভিস' : 'সার্ভিস সম্পাদনা', style: AppText.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'নাম (English)')),
            const SizedBox(height: 10),
            TextField(controller: nameBnCtrl, decoration: const InputDecoration(hintText: 'নাম (বাংলা)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('সংরক্ষণ করুন')),
        ],
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        if (existing != null) {
          existing.name = nameCtrl.text.trim();
          existing.nameBn = nameBnCtrl.text.trim();
        } else {
          AdminMockData.services.add(CatalogService(id: 's_${DateTime.now().millisecondsSinceEpoch}', name: nameCtrl.text.trim(), nameBn: nameBnCtrl.text.trim()));
        }
      });
      widget.onSnack('সার্ভিস সংরক্ষিত হয়েছে');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        for (int i = 0; i < AdminMockData.services.length; i++)
          FadeSlideIn(
            delayMs: i * 40,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _catalogTile(
                title: AdminMockData.services[i].nameBn,
                subtitle: AdminMockData.services[i].name,
                enabled: AdminMockData.services[i].enabled,
                onToggle: (v) => setState(() => AdminMockData.services[i].enabled = v),
                onEdit: () => _editDialog(existing: AdminMockData.services[i]),
                onDelete: () => setState(() => AdminMockData.services.removeAt(i)),
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => _editDialog(), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('নতুন সার্ভিস যোগ করুন')),
      ],
    );
  }
}

// ── Categories ───────────────────────────────────────────

class _CategoriesTab extends StatefulWidget {
  final void Function(String) onSnack;
  const _CategoriesTab({required this.onSnack});
  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  Future<void> _editDialog({CatalogCategory? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final nameBnCtrl = TextEditingController(text: existing?.nameBn ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(existing == null ? 'নতুন ক্যাটাগরি' : 'ক্যাটাগরি সম্পাদনা', style: AppText.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'নাম (English)')),
            const SizedBox(height: 10),
            TextField(controller: nameBnCtrl, decoration: const InputDecoration(hintText: 'নাম (বাংলা)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('সংরক্ষণ করুন')),
        ],
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        if (existing != null) {
          existing.name = nameCtrl.text.trim();
          existing.nameBn = nameBnCtrl.text.trim();
        } else {
          AdminMockData.categories.add(CatalogCategory(id: 'c_${DateTime.now().millisecondsSinceEpoch}', name: nameCtrl.text.trim(), nameBn: nameBnCtrl.text.trim()));
        }
      });
      widget.onSnack('ক্যাটাগরি সংরক্ষিত হয়েছে');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        for (int i = 0; i < AdminMockData.categories.length; i++)
          FadeSlideIn(
            delayMs: i * 40,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _catalogTile(
                title: AdminMockData.categories[i].nameBn,
                subtitle: AdminMockData.categories[i].name,
                enabled: AdminMockData.categories[i].enabled,
                onToggle: (v) => setState(() => AdminMockData.categories[i].enabled = v),
                onEdit: () => _editDialog(existing: AdminMockData.categories[i]),
                onDelete: () => setState(() => AdminMockData.categories.removeAt(i)),
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => _editDialog(), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('নতুন ক্যাটাগরি যোগ করুন')),
      ],
    );
  }
}

// ── Items ────────────────────────────────────────────────

class _ItemsTab extends StatefulWidget {
  final void Function(String) onSnack;
  const _ItemsTab({required this.onSnack});
  @override
  State<_ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<_ItemsTab> {
  String _categoryFilter = 'all';

  Future<void> _editDialog({CatalogItem? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final nameBnCtrl = TextEditingController(text: existing?.nameBn ?? '');
    String categoryId = existing?.categoryId ?? AdminMockData.categories.first.id;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Text(existing == null ? 'নতুন আইটেম' : 'আইটেম সম্পাদনা', style: AppText.h2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'নাম (English)')),
              const SizedBox(height: 10),
              TextField(controller: nameBnCtrl, decoration: const InputDecoration(hintText: 'নাম (বাংলা)')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: categoryId,
                items: AdminMockData.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameBn))).toList(),
                onChanged: (v) => setDialogState(() => categoryId = v!),
                decoration: const InputDecoration(hintText: 'ক্যাটাগরি'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('সংরক্ষণ করুন')),
          ],
        ),
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        if (existing != null) {
          existing.name = nameCtrl.text.trim();
          existing.nameBn = nameBnCtrl.text.trim();
          existing.categoryId = categoryId;
        } else {
          AdminMockData.items.add(CatalogItem(id: 'i_${DateTime.now().millisecondsSinceEpoch}', name: nameCtrl.text.trim(), nameBn: nameBnCtrl.text.trim(), categoryId: categoryId, washPrice: 0, dryPrice: 0));
        }
      });
      widget.onSnack('আইটেম সংরক্ষিত হয়েছে');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _categoryFilter == 'all' ? AdminMockData.items : AdminMockData.items.where((i) => i.categoryId == _categoryFilter).toList();
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            children: [
              _chip('সব', _categoryFilter == 'all', () => setState(() => _categoryFilter = 'all')),
              const SizedBox(width: 8),
              ...AdminMockData.categories.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _chip(c.nameBn, _categoryFilter == c.id, () => setState(() => _categoryFilter = c.id)),
                  )),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            children: [
              for (int i = 0; i < items.length; i++)
                FadeSlideIn(
                  delayMs: i * 30,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _catalogTile(
                      title: items[i].nameBn,
                      subtitle: '${items[i].name} • ৳${items[i].washPrice} / ৳${items[i].dryPrice}',
                      enabled: items[i].enabled,
                      onToggle: (v) => setState(() => items[i].enabled = v),
                      onEdit: () => _editDialog(existing: items[i]),
                      onDelete: () => setState(() => AdminMockData.items.remove(items[i])),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: () => _editDialog(), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('নতুন আইটেম যোগ করুন')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
  }
}

// ── Pricing ──────────────────────────────────────────────

class _PricingTab extends StatefulWidget {
  final void Function(String) onSnack;
  const _PricingTab({required this.onSnack});
  @override
  State<_PricingTab> createState() => _PricingTabState();
}

class _PricingTabState extends State<_PricingTab> {
  Future<void> _editPrice(CatalogItem item) async {
    final washCtrl = TextEditingController(text: '${item.washPrice}');
    final dryCtrl = TextEditingController(text: '${item.dryPrice}');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(item.nameBn, style: AppText.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: washCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'ওয়াশ মূল্য (৳)', prefixIcon: Icon(Icons.local_laundry_service_outlined, size: 20))),
            const SizedBox(height: 10),
            TextField(controller: dryCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'ড্রাই ক্লিন মূল্য (৳)', prefixIcon: Icon(Icons.dry_cleaning_outlined, size: 20))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('আপডেট করুন')),
        ],
      ),
    );
    if (result == true) {
      setState(() {
        item.washPrice = int.tryParse(washCtrl.text) ?? item.washPrice;
        item.dryPrice = int.tryParse(dryCtrl.text) ?? item.dryPrice;
      });
      widget.onSnack('${item.nameBn}-এর মূল্য তাৎক্ষণিকভাবে আপডেট হয়েছে');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (final category in AdminMockData.categories) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(category.nameBn, style: AppText.h3),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
            child: Column(
              children: AdminMockData.items.where((i) => i.categoryId == category.id).map((item) {
                final isLast = item == AdminMockData.items.where((i) => i.categoryId == category.id).last;
                return InkWell(
                  onTap: () => _editPrice(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : AppColors.line))),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.nameBn, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink))),
                        Text('৳${item.washPrice}', style: const TextStyle(fontSize: 12.5, color: AppColors.blue, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 10),
                        Text('৳${item.dryPrice}', style: const TextStyle(fontSize: 12.5, color: AppColors.teal, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit_rounded, size: 15, color: AppColors.muted),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

Widget _catalogTile({
  required String title,
  required String subtitle,
  required bool enabled,
  required ValueChanged<bool> onToggle,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Switch(value: enabled, onChanged: onToggle, activeTrackColor: AppColors.blue),
        IconButton(icon: const Icon(Icons.edit_outlined, size: 19, color: AppColors.muted), onPressed: onEdit),
        IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.danger), onPressed: onDelete),
      ],
    ),
  );
}
