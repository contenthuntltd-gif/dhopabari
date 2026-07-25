import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/admin_mock_data.dart';
import '../../services/admin_service.dart';
import '../../widgets/bn_number.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/state_views.dart';
import '../../widgets/app_page_route.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _search = '';
  final _searchController = TextEditingController();
  Timer? _debounce;
  late Future<List<AdminCustomer>> _future = AdminService.customers();

  // Multi-select for bulk delete → recycle bin.
  bool _selectMode = false;
  final Set<String> _selected = {};
  List<AdminCustomer> _loaded = const [];

  void _reload() {
    setState(() => _future = AdminService.customers(search: _search));
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final count = _selected.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('কাস্টমার ডিলিট করবেন?'),
        content: Text('$count জন কাস্টমার রিসাইকেল বিনে যাবে। সেখান থেকে আবার ফিরিয়ে আনা যাবে।', style: const TextStyle(fontSize: 13.5, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(context, true), child: const Text('ডিলিট')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AdminService.trashCustomers(_selected.toList());
      if (!mounted) return;
      setState(() {
        _selectMode = false;
        _selected.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count জন কাস্টমার রিসাইকেল বিনে সরানো হয়েছে'), backgroundColor: AppColors.ink));
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AdminService.messageFor(e))));
    }
  }

  /// Search hits the database, so wait for a pause in typing rather than
  /// firing a query per keystroke.
  void _onSearchChanged(String value) {
    _search = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _selectMode
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.blue,
              onPressed: () async {
                final created = await Navigator.push(context, AppPageRoute(builder: (_) => const CustomerFormScreen()));
                if (created == true) _reload();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('নতুন কাস্টমার'),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'নাম বা ফোন নম্বর খুঁজুন',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.muted),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            }),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
              ],
            ),
          ),
          Expanded(child: _buildList()),
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
                        if (_selected.length == _loaded.length) {
                          _selected.clear();
                        } else {
                          _selected
                            ..clear()
                            ..addAll(_loaded.map((c) => c.id));
                        }
                      }),
                      child: Text(_selected.length == _loaded.length && _loaded.isNotEmpty ? 'সব বাদ' : 'সব নির্বাচন'),
                    ),
                    const Spacer(),
                    Text('${toBn(_selected.length)} জন নির্বাচিত', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
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
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<AdminCustomer>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return ErrorStateView(message: AdminService.messageFor(snap.error!), onRetry: _reload);
        }

        final customers = snap.data ?? const <AdminCustomer>[];
        _loaded = customers; // for "select all"
        if (customers.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline_rounded,
            title: _search.isEmpty ? 'এখনো কোনো কাস্টমার নেই' : 'কোনো কাস্টমার পাওয়া যায়নি',
            subtitle: _search.isEmpty
                ? 'নিচের বাটন থেকে নতুন কাস্টমার যোগ করুন।'
                : 'ভিন্ন সার্চ শব্দ ব্যবহার করে দেখুন।',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: customers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = customers[i];
                      final selected = _selected.contains(c.id);
                      return FadeSlideIn(
                        delayMs: i * 40,
                        child: PressableScale(
                          onTap: () {
                            if (_selectMode) {
                              setState(() {
                                if (selected) {
                                  _selected.remove(c.id);
                                } else {
                                  _selected.add(c.id);
                                }
                              });
                            } else {
                              Navigator.push(context, AppPageRoute(builder: (_) => CustomerDetailScreen(customer: c))).then((_) => _reload());
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.blueSoft.withValues(alpha: 0.5) : Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: selected ? AppColors.blue : (c.blocked ? AppColors.danger.withValues(alpha: 0.3) : AppColors.line), width: selected ? 1.5 : 1),
                              boxShadow: AppShadows.soft,
                            ),
                            child: Row(
                              children: [
                                if (_selectMode) ...[
                                  Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 22, color: selected ? AppColors.blue : AppColors.muted),
                                  const SizedBox(width: 10),
                                ],
                                CircleAvatar(radius: 22, backgroundColor: AppColors.blueSoft, child: Icon(Icons.person_rounded, color: AppColors.blue)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: Text(c.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink))),
                                          if (c.blocked)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(999)),
                                              child: const Text('ব্লকড', style: TextStyle(fontSize: 9.5, color: AppColors.danger, fontWeight: FontWeight.w800)),
                                            ),
                                        ],
                                      ),
                                      Text(c.phone, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 3),
                                      Text('${toBn(c.totalOrders)} অর্ডার • ${money(c.totalSpent)} খরচ', style: const TextStyle(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w700)),
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
        );
      },
    );
  }
}
