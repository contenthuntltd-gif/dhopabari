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

  void _reload() {
    setState(() => _future = AdminService.customers(search: _search));
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
      floatingActionButton: FloatingActionButton.extended(
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
          Expanded(child: _buildList()),
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
                      return FadeSlideIn(
                        delayMs: i * 40,
                        child: PressableScale(
                          onTap: () => Navigator.push(context, AppPageRoute(builder: (_) => CustomerDetailScreen(customer: c))).then((_) => _reload()),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: c.blocked ? AppColors.danger.withValues(alpha: 0.3) : AppColors.line), boxShadow: AppShadows.soft),
                            child: Row(
                              children: [
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
