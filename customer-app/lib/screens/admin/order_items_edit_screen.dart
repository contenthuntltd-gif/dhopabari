import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../data/catalog.dart';
import '../../data/catalog_meta.dart';
import '../../data/mock_data.dart' show PriceItem;
import '../../services/admin_service.dart';
import '../../widgets/centered_max_width.dart';

/// Admin edit of the items inside an EXISTING order — add a garment the
/// customer handed over at the door, drop one that was counted twice, fix a
/// quantity or a price.
///
/// Everything is edited on a local copy and written in a single save, so a
/// half-finished edit never reaches the database. Pieces and the total are
/// recomputed from the lines as you go: the numbers on the order always add
/// up to the items printed on the memo, which is the whole reason an admin
/// can be trusted to hand that memo to a customer.
///
/// Returns true if the order was changed and saved.
class OrderItemsEditScreen extends StatefulWidget {
  final AdminOrder order;
  const OrderItemsEditScreen({super.key, required this.order});

  @override
  State<OrderItemsEditScreen> createState() => _OrderItemsEditScreenState();
}

/// One editable line. Kept as a class rather than the raw jsonb map so the
/// arithmetic lives in one place and a typo in a key name can't silently
/// zero a price.
class _Line {
  String id;
  String name;
  String nameBn;
  String service;
  int qty;
  int unitPrice;

  _Line({
    required this.id,
    required this.name,
    required this.nameBn,
    required this.service,
    required this.qty,
    required this.unitPrice,
  });

  int get lineTotal => unitPrice * qty;

  String get label => nameBn.trim().isNotEmpty ? nameBn : name;

  factory _Line.fromJson(Map<String, dynamic> m) {
    final name = (m['name'] as String?) ?? '';
    final nameBn = (m['name_bn'] as String?) ?? '';
    final qty = (m['qty'] as num?)?.toInt() ?? 1;
    // Older rows may carry only line_total. Recover the unit price from it
    // rather than showing ৳0 and letting a save wipe a real amount.
    final unit = (m['unit_price'] as num?)?.toInt() ??
        (qty > 0 ? (((m['line_total'] as num?)?.toInt() ?? 0) ~/ qty) : 0);
    return _Line(
      id: (m['id'] as String?) ?? 'item_${DateTime.now().microsecondsSinceEpoch}',
      name: name.isEmpty ? nameBn : name,
      nameBn: nameBn.isEmpty ? name : nameBn,
      service: (m['service'] as String?) ?? 'Wash',
      qty: qty < 1 ? 1 : qty,
      unitPrice: unit < 0 ? 0 : unit,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_bn': nameBn,
        'service': service,
        'qty': qty,
        'unit_price': unitPrice,
        'line_total': lineTotal,
      };
}

class _OrderItemsEditScreenState extends State<OrderItemsEditScreen> {
  late List<_Line> _lines;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _lines = widget.order.items.map(_Line.fromJson).toList();
  }

  int get _pieces => _lines.fold(0, (sum, l) => sum + l.qty);
  int get _total => _lines.fold(0, (sum, l) => sum + l.lineTotal);

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _mutate(VoidCallback fn) => setState(() {
        fn();
        _dirty = true;
      });

  // ---------------------------------------------------------------- lines

  void _setQty(_Line line, int qty) {
    if (qty < 1) {
      _remove(line);
      return;
    }
    _mutate(() => line.qty = qty);
  }

  void _remove(_Line line) {
    final index = _lines.indexOf(line);
    if (index < 0) return;
    _mutate(() => _lines.removeAt(index));
    // Removing an item is the one destructive action here, and a mis-tap on
    // a small stepper is easy — so it is undoable rather than confirmed.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${line.label} বাদ দেওয়া হয়েছে'),
        action: SnackBarAction(
          label: 'ফিরিয়ে আনুন',
          onPressed: () => _mutate(() => _lines.insert(index, line)),
        ),
      ));
  }

  Future<void> _editPrice(_Line line) async {
    final ctrl = TextEditingController(text: '${line.unitPrice}');
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('${line.label} — দাম', style: AppText.h2),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'প্রতি পিসের দাম (৳)',
            prefixIcon: Icon(Icons.payments_rounded, size: 20),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
    if (raw == null) return;
    final price = int.tryParse(raw);
    if (price == null || price < 0) {
      _snack('সঠিক একটি টাকার অঙ্ক লিখুন');
      return;
    }
    _mutate(() => line.unitPrice = price);
  }

  /// Adds a line, merging into an existing one when the same item is already
  /// in the order under the same service — two lines of "শার্ট (ওয়াশ)" would
  /// only confuse whoever reads the memo.
  void _add(_Line line) {
    final existing = _lines.where((l) => l.id == line.id && l.service == line.service).firstOrNull;
    if (existing != null) {
      _mutate(() => existing.qty += line.qty);
      _snack('${line.label} — পরিমাণ বেড়ে ${existing.qty} হয়েছে');
    } else {
      _mutate(() => _lines.add(line));
      _snack('${line.label} যোগ হয়েছে');
    }
  }

  // ------------------------------------------------------------- adding

  Future<void> _addFromCatalog() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CatalogPickerSheet(onPick: _add),
    );
  }

  Future<void> _addCustom() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    var service = CatalogMeta.services.isNotEmpty ? CatalogMeta.services.first.name : 'Wash';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: const Text('নিজে লিখে আইটেম যোগ', style: AppText.h2),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'আইটেমের নাম',
                    hintText: 'যেমন: কাঁথা',
                    prefixIcon: Icon(Icons.label_outline_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'দাম (৳)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'পিস'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final s in CatalogMeta.services)
                        ChoiceChip(
                          label: Text(s.nameBn),
                          selected: service == s.name,
                          onSelected: (_) => setLocal(() => service = s.name),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('যোগ করুন'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;

    final name = nameCtrl.text.trim();
    final price = int.tryParse(priceCtrl.text.trim());
    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
    if (name.isEmpty) {
      _snack('আইটেমের নাম লিখুন');
      return;
    }
    if (price == null || price < 0) {
      _snack('সঠিক একটি দাম লিখুন');
      return;
    }
    _add(_Line(
      // A manual item has no catalog id, so it gets its own — otherwise two
      // different typed items would merge into one line.
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      nameBn: name,
      service: service,
      qty: qty < 1 ? 1 : qty,
      unitPrice: price,
    ));
  }

  // -------------------------------------------------------------- saving

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final items = _lines.map((l) => l.toJson()).toList();
    final pieces = _pieces;
    final total = _total;
    try {
      await AdminService.updateOrderItems(
        widget.order.uuid,
        items: items,
        pieces: pieces,
        total: total,
      );
      if (!mounted) return;
      // Write back onto the order the previous screen is still holding, so
      // it shows the new items without a round trip to the server.
      widget.order.items
        ..clear()
        ..addAll(items);
      widget.order.pieces = pieces;
      widget.order.total = total;
      widget.order.itemsSummary = summarizeItems(items);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(AdminService.messageFor(e));
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('সেভ করা হয়নি', style: AppText.h2),
        content: const Text('আপনার পরিবর্তনগুলো সেভ হয়নি। বেরিয়ে গেলে সেগুলো থাকবে না।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('থাকুন')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('বাদ দিন', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    return leave == true;
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final originalTotal = widget.order.total;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Take the navigator before the dialog awaits, so nothing reaches
        // for a BuildContext that may be gone by the time it returns.
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(title: const Text('আইটেম এডিট')),
        body: CenteredMaxWidth(
          child: Column(
            children: [
              Expanded(
                child: _lines.isEmpty
                    ? const _EmptyLines()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _lines.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _LineCard(
                          line: _lines[i],
                          onQty: (q) => _setQty(_lines[i], q),
                          onPrice: () => _editPrice(_lines[i]),
                          onRemove: () => _remove(_lines[i]),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addFromCatalog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('ক্যাটালগ থেকে'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addCustom,
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('নিজে লিখে'),
                      ),
                    ),
                  ],
                ),
              ),
              _SummaryBar(
                pieces: _pieces,
                total: _total,
                originalTotal: originalTotal,
                saving: _saving,
                onSave: _dirty ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLines extends StatelessWidget {
  const _EmptyLines();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.inventory_2_outlined, size: 44, color: AppColors.muted),
              SizedBox(height: 12),
              Text('এই অর্ডারে কোনো আইটেম নেই', style: AppText.h3),
              SizedBox(height: 6),
              Text(
                'নিচের বোতাম দুটি দিয়ে আইটেম যোগ করুন।',
                textAlign: TextAlign.center,
                style: AppText.caption,
              ),
            ],
          ),
        ),
      );
}

class _LineCard extends StatelessWidget {
  final _Line line;
  final ValueChanged<int> onQty;
  final VoidCallback onPrice;
  final VoidCallback onRemove;

  const _LineCard({
    required this.line,
    required this.onQty,
    required this.onPrice,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final serviceBn = CatalogMeta.services
            .where((s) => s.name == line.service)
            .map((s) => s.nameBn)
            .firstOrNull ??
        line.service;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(line.label,
                    style: AppText.h3, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: 'বাদ দিন',
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 20, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(serviceBn,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue)),
              ),
              const SizedBox(width: 8),
              // Tap the unit price to change it — a price agreed at the door
              // can differ from the catalog.
              InkWell(
                onTap: onPrice,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('৳${line.unitPrice} / পিস', style: AppText.caption),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_rounded, size: 13, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StepButton(icon: Icons.remove_rounded, onTap: () => onQty(line.qty - 1)),
              SizedBox(
                width: 44,
                child: Text('${line.qty}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink)),
              ),
              _StepButton(icon: Icons.add_rounded, onTap: () => onQty(line.qty + 1)),
              const Spacer(),
              Text('৳${line.lineTotal}',
                  style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink)),
              const SizedBox(width: 6),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
      );
}

/// The running totals and the save button. The old total is shown beside the
/// new one whenever they differ, so an admin can see what the edit changed
/// before committing to it.
class _SummaryBar extends StatelessWidget {
  final int pieces;
  final int total;
  final int originalTotal;
  final bool saving;
  final VoidCallback? onSave;

  const _SummaryBar({
    required this.pieces,
    required this.total,
    required this.originalTotal,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final changed = total != originalTotal;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('মোট $pieces পিস', style: AppText.label),
              const Spacer(),
              if (changed) ...[
                Text('৳$originalTotal',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                        decoration: TextDecoration.lineThrough)),
                const SizedBox(width: 8),
              ],
              Text('৳$total',
                  style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppColors.blue)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saving ? null : onSave,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
              child: saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(onSave == null ? 'কোনো পরিবর্তন নেই' : 'সেভ করুন',
                      style: AppText.button),
            ),
          ),
        ],
      ),
    );
  }
}

/// Catalog picker. Category chips, a search box and a service toggle — the
/// same three choices the order screen offers, so an admin adding an item
/// later does it the way they already know.
class _CatalogPickerSheet extends StatefulWidget {
  final ValueChanged<_Line> onPick;
  const _CatalogPickerSheet({required this.onPick});

  @override
  State<_CatalogPickerSheet> createState() => _CatalogPickerSheetState();
}

class _CatalogPickerSheetState extends State<_CatalogPickerSheet> {
  late String _category;
  late String _service;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final cats = CatalogMeta.enabledCategoryNames;
    _category = cats.isNotEmpty ? cats.first : 'Men';
    _service = CatalogMeta.services.isNotEmpty ? CatalogMeta.services.first.name : 'Wash';
  }

  int _priceOf(PriceItem item) => _service == 'Wash' ? item.washPrice : item.dryPrice;

  List<PriceItem> get _results {
    final q = _query.trim().toLowerCase();
    return Catalog.items.where((p) {
      if (q.isEmpty) return p.category == _category;
      // A search looks across every category — when someone types a garment
      // name they want that garment, not that garment inside one tab.
      return p.name.toLowerCase().contains(q) || p.nameBn.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = CatalogMeta.enabledCategoryNames;
    final bn = CatalogMeta.categoryBnByName;
    final results = _results;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('আইটেম যোগ করুন', style: AppText.h2),
                      const Spacer(),
                      for (final s in CatalogMeta.services)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            label: Text(s.nameBn),
                            selected: _service == s.name,
                            onSelected: (_) => setState(() => _service = s.name),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'আইটেম খুঁজুন',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // The category row is only meaningful while browsing — a search
            // already spans every category, so it would be a lie there.
            if (_query.trim().isEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final c in categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(bn[c] ?? c),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Text('কোনো আইটেম পাওয়া যায়নি', style: AppText.bodyMuted))
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final item = results[i];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: () {
                              widget.onPick(_Line(
                                id: item.id,
                                name: item.name,
                                nameBn: item.nameBn,
                                service: _service,
                                qty: 1,
                                unitPrice: _priceOf(item),
                              ));
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.nameBn, style: AppText.h3),
                                        Text(bn[item.category] ?? item.category,
                                            style: AppText.caption),
                                      ],
                                    ),
                                  ),
                                  Text('৳${_priceOf(item)}',
                                      style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.blue)),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.add_circle_rounded,
                                      color: AppColors.blue, size: 22),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
