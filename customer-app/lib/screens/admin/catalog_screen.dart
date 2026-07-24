import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../data/catalog.dart';
import '../../data/mock_data.dart';
import '../../services/admin_service.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/laundry_icons.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

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
            Tab(text: 'মূল্য তালিকা'),
            Tab(text: 'সার্ভিস'),
            Tab(text: 'ক্যাটাগরি'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PriceListTab(onSnack: _snack),
          _ServicesTab(onSnack: _snack),
          _CategoriesTab(onSnack: _snack),
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


// ── Official price list (single source of truth) ─────────
//
// Reads Catalog.items and writes price edits through Catalog.updatePrices,
// which hits the `catalog_items` table — so a change here reflects in the
// customer order screen, receipts and totals immediately.

class _PriceListTab extends StatefulWidget {
  final void Function(String) onSnack;
  const _PriceListTab({required this.onSnack});
  @override
  State<_PriceListTab> createState() => _PriceListTabState();
}

class _PriceListTabState extends State<_PriceListTab> {
  bool _saving = false;

  /// Pins an item to the top of its category (persists via Catalog.moveToTop).
  Future<void> _moveToTop(PriceItem item) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await Catalog.moveToTop(item.id);
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSnack('${item.nameBn} উপরে তোলা হয়েছে');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSnack(AdminService.messageFor(e));
    }
  }

  /// Adds a brand-new catalog item (name, category, wash + dry price).
  Future<void> _addItem() async {
    final nameCtrl = TextEditingController();
    final nameBnCtrl = TextEditingController();
    final washCtrl = TextEditingController();
    final dryCtrl = TextEditingController();
    String category = MockData.categories.first;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: const Text('নতুন আইটেম', style: AppText.h2),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'ক্যাটাগরি', prefixIcon: Icon(Icons.category_outlined, size: 20)),
                  items: [
                    for (final c in MockData.categories)
                      DropdownMenuItem(value: c, child: Text(MockData.categoriesBn[c] ?? c)),
                  ],
                  onChanged: (v) => setLocal(() => category = v ?? category),
                ),
                const SizedBox(height: 10),
                TextField(controller: nameBnCtrl, decoration: const InputDecoration(hintText: 'নাম (বাংলা) — যেমন শার্ট', prefixIcon: Icon(Icons.label_outline_rounded, size: 20))),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'নাম (English) — e.g. Shirt', prefixIcon: Icon(Icons.label_outline_rounded, size: 20))),
                const SizedBox(height: 10),
                TextField(controller: washCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'ওয়াশ মূল্য (৳)', prefixIcon: Icon(Icons.local_laundry_service_outlined, size: 20))),
                const SizedBox(height: 10),
                TextField(controller: dryCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'ড্রাই ক্লিন মূল্য (৳)', prefixIcon: Icon(Icons.dry_cleaning_outlined, size: 20))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('যোগ করুন')),
          ],
        ),
      ),
    );
    if (result != true || _saving) return;

    final nameBn = nameBnCtrl.text.trim();
    final name = nameCtrl.text.trim().isEmpty ? nameBn : nameCtrl.text.trim();
    if (nameBn.isEmpty) {
      widget.onSnack('আইটেমের নাম দিন');
      return;
    }
    final wash = int.tryParse(washCtrl.text) ?? 0;
    final dry = int.tryParse(dryCtrl.text) ?? wash;

    setState(() => _saving = true);
    try {
      await Catalog.addItem(category: category, name: name, nameBn: nameBn, washPrice: wash, dryPrice: dry);
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSnack('$nameBn যোগ হয়েছে — সব জায়গায় দেখা যাবে');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSnack(AdminService.messageFor(e));
    }
  }

  Future<void> _deleteItem(PriceItem item) async {
    if (_saving) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('আইটেম মুছবেন?'),
        content: Text('${item.nameBn} মূল্য তালিকা থেকে স্থায়ীভাবে মুছে যাবে।', style: const TextStyle(fontSize: 13.5, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('মুছুন')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await Catalog.deleteItem(item.id);
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSnack('${item.nameBn} মুছে ফেলা হয়েছে');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSnack(AdminService.messageFor(e));
    }
  }

  Future<void> _editPrice(PriceItem item) async {
    final washCtrl = TextEditingController(text: '${item.washPrice}');
    final dryCtrl = TextEditingController(text: '${item.dryPrice}');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            LaundryIcon(item.id, size: 26),
            const SizedBox(width: 10),
            Expanded(child: Text(item.nameBn, style: AppText.h2)),
          ],
        ),
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
    if (result != true || _saving) return;

    final wash = int.tryParse(washCtrl.text) ?? item.washPrice;
    final dry = int.tryParse(dryCtrl.text) ?? item.dryPrice;
    setState(() => _saving = true);
    try {
      await Catalog.updatePrices(item.id, washPrice: wash, dryPrice: dry);
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSnack('${item.nameBn}-এর মূল্য সব জায়গায় আপডেট হয়েছে');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSnack(AdminService.messageFor(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Constrain the width so item name, prices and action buttons stay in a
    // tidy line on a wide desktop instead of spreading far apart.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Add a brand-new item to the catalog.
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: _saving ? null : _addItem,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text('নতুন আইটেম যোগ করুন', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 12),
        // column headers, price-list style
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: const [
              Expanded(child: Text('আইটেম', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w800))),
              SizedBox(width: 46, child: Text('ওয়াশ', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w800))),
              SizedBox(width: 56, child: Text('ড্রাই', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w800))),
              SizedBox(width: 24),
            ],
          ),
        ),
        for (final category in MockData.categories) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 10),
            child: Text(MockData.categoriesBn[category] ?? category, style: AppText.h3),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
            child: Column(
              children: [
                for (final item in Catalog.forCategory(category))
                  InkWell(
                    onTap: _saving ? null : () => _editPrice(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: item == Catalog.forCategory(category).last ? Colors.transparent : AppColors.line),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: AppColors.blueSoft.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                            child: LaundryIcon(item.id, size: 23),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.nameBn, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                                Text(item.name, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          // English numerals — official price list typography
                          SizedBox(width: 44, child: Text('৳${item.washPrice}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, color: AppColors.blue, fontWeight: FontWeight.w900))),
                          SizedBox(width: 52, child: Text('৳${item.dryPrice}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, color: AppColors.teal, fontWeight: FontWeight.w900))),
                          // Pin to top / edit / delete.
                          IconButton(
                            tooltip: 'উপরে তুলুন',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.vertical_align_top_rounded, size: 19, color: AppColors.blue),
                            onPressed: _saving ? null : () => _moveToTop(item),
                          ),
                          IconButton(
                            tooltip: 'মূল্য সম্পাদনা',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.muted),
                            onPressed: _saving ? null : () => _editPrice(item),
                          ),
                          IconButton(
                            tooltip: 'মুছুন',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.danger),
                            onPressed: _saving ? null : () => _deleteItem(item),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.blueSoft.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Row(
            children: const [
              Icon(Icons.sync_rounded, size: 16, color: AppColors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'এখানে মূল্য পরিবর্তন করলে অর্ডার স্ক্রিন, রিসিট ও হিসাব — সব জায়গায় সাথে সাথে কার্যকর হবে। পুরনো অর্ডারের দাম অপরিবর্তিত থাকবে।',
                  style: TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
        ),
      ),
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
