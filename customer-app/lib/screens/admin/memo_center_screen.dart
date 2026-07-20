import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/receipt_data.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/state_views.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/bn_number.dart';
import '../receipt_screen.dart';

/// Admin "মেমো সেন্টার" — search every pickup / delivery / payment memo
/// ever generated (memos are permanent and never overwritten) and reprint
/// or download any of them at any time.
class MemoCenterScreen extends StatefulWidget {
  const MemoCenterScreen({super.key});

  @override
  State<MemoCenterScreen> createState() => _MemoCenterScreenState();
}

enum _MemoFilter { all, memoNumber, orderId, customer, rider, phone }

class _MemoCenterScreenState extends State<MemoCenterScreen> {
  final _searchController = TextEditingController();
  _MemoFilter _filter = _MemoFilter.all;
  DateTime? _date;

  List<ReceiptData> get _filtered {
    final q = _searchController.text.trim();
    return ReceiptData.search(
      memoNumber: _filter == _MemoFilter.all || _filter == _MemoFilter.memoNumber ? q : null,
      orderId: _filter == _MemoFilter.all || _filter == _MemoFilter.orderId ? q : null,
      customer: _filter == _MemoFilter.all || _filter == _MemoFilter.customer ? q : null,
      rider: _filter == _MemoFilter.all || _filter == _MemoFilter.rider ? q : null,
      phone: _filter == _MemoFilter.all || _filter == _MemoFilter.phone ? q : null,
      date: _date,
    ).where((r) {
      if (_filter != _MemoFilter.all || q.isEmpty) return true;
      // "all" mode: OR across fields instead of AND (search() ANDs them).
      final lower = q.toLowerCase();
      return r.receiptNumber.toLowerCase().contains(lower) ||
          r.orderId.toLowerCase().contains(lower) ||
          r.customerName.toLowerCase().contains(lower) ||
          (r.riderName?.toLowerCase().contains(lower) ?? false) ||
          r.customerPhone.contains(q);
    }).toList();
  }

  static const _filterLabels = {
    _MemoFilter.all: 'সব',
    _MemoFilter.memoNumber: 'মেমো নম্বর',
    _MemoFilter.orderId: 'অর্ডার আইডি',
    _MemoFilter.customer: 'কাস্টমার',
    _MemoFilter.rider: 'রাইডার',
    _MemoFilter.phone: 'ফোন',
  };

  String _typeLabel(ReceiptType t) => switch (t) {
        ReceiptType.pickup => 'পিকআপ মেমো',
        ReceiptType.delivery => 'ডেলিভারি মেমো',
        ReceiptType.payment => 'পেমেন্ট রিসিট',
      };

  IconData _typeIcon(ReceiptType t) => switch (t) {
        ReceiptType.pickup => Icons.receipt_long_rounded,
        ReceiptType.delivery => Icons.receipt_rounded,
        ReceiptType.payment => Icons.payments_rounded,
      };

  Color _typeColor(ReceiptType t) => switch (t) {
        ReceiptType.pickup => AppColors.blue,
        ReceiptType.delivery => AppColors.teal,
        ReceiptType.payment => AppColors.amber,
      };

  Color _typeColorSoft(ReceiptType t) => switch (t) {
        ReceiptType.pickup => AppColors.blueSoft,
        ReceiptType.delivery => AppColors.tealSoft,
        ReceiptType.payment => AppColors.amberSoft,
      };

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memos = _filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('মেমো সেন্টার')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'মেমো নম্বর, অর্ডার আইডি, নাম বা ফোন খুঁজুন',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.muted),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in _MemoFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filterLabels[f]!),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: const Icon(Icons.event_rounded, size: 16),
                    label: Text(_date == null ? 'তারিখ' : '${_date!.day}/${_date!.month}/${_date!.year}'),
                    selected: _date != null,
                    onSelected: (_) => _pickDate(),
                  ),
                ),
                if (_date != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('মুছুন'),
                      onPressed: () => setState(() => _date = null),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: memos.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'কোনো মেমো পাওয়া যায়নি',
                    subtitle: 'ভিন্ন সার্চ শব্দ বা ফিল্টার ব্যবহার করে দেখুন।',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: memos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final r = memos[i];
                      return FadeSlideIn(
                        delayMs: i * 30,
                        child: PressableScale(
                          onTap: () => Navigator.push(
                            context,
                            AppPageRoute(builder: (_) => ReceiptScreen(receipt: r, role: ReceiptViewerRole.admin, pickupConfirmed: true)),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
                            child: Row(
                              children: [
                                CircleAvatar(radius: 22, backgroundColor: _typeColorSoft(r.type), child: Icon(_typeIcon(r.type), color: _typeColor(r.type))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: Text(r.receiptNumber, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink))),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: _typeColorSoft(r.type), borderRadius: BorderRadius.circular(999)),
                                            child: Text(_typeLabel(r.type), style: TextStyle(fontSize: 9.5, color: _typeColor(r.type), fontWeight: FontWeight.w800)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text('${r.orderId} • ${r.customerName}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                                      if (r.riderName != null) Text('রাইডার: ${r.riderName}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                      const SizedBox(height: 3),
                                      Text('${r.issuedAt.day}/${r.issuedAt.month}/${r.issuedAt.year} • ${toBn(r.issuedAt.hour)}:${r.issuedAt.minute.toString().padLeft(2, '0').split('').map((d) => toBn(int.parse(d))).join()}', style: const TextStyle(fontSize: 10.5, color: AppColors.blue, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
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
    );
  }
}
