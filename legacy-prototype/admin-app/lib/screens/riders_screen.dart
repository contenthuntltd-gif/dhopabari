import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/state_views.dart';
import '../widgets/app_page_route.dart';
import 'rider_detail_screen.dart';
import 'rider_form_screen.dart';
import 'withdrawals_screen.dart';

class RidersScreen extends StatefulWidget {
  const RidersScreen({super.key});
  @override
  State<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends State<RidersScreen> {
  String _filter = 'All'; // All, Online, Offline

  List<AdminRider> get _filtered {
    if (_filter == 'Online') return AdminMockData.riders.where((r) => r.online).toList();
    if (_filter == 'Offline') return AdminMockData.riders.where((r) => !r.online).toList();
    return AdminMockData.riders;
  }

  @override
  Widget build(BuildContext context) {
    final riders = _filtered;
    final pendingWithdrawals = AdminMockData.withdrawals.where((w) => w.status == 'Pending').length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.blue,
        onPressed: () async {
          final created = await Navigator.push(context, AppPageRoute(builder: (_) => const RiderFormScreen()));
          if (created == true) setState(() {});
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('নতুন রাইডার'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: PressableScale(
              onTap: () => Navigator.push(context, AppPageRoute(builder: (_) => const WithdrawalsScreen())).then((_) => setState(() {})),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.amberSoft, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.amber.withValues(alpha: 0.35))),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: AppColors.amber),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pendingWithdrawals > 0 ? '$pendingWithdrawals টি উত্তোলন অনুরোধ অপেক্ষমাণ' : 'কোনো অপেক্ষমাণ উত্তোলন অনুরোধ নেই',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.amber),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: ['All', 'Online', 'Offline'].map((f) {
                final active = f == _filter;
                final label = f == 'All' ? 'সবাই' : (f == 'Online' ? 'অনলাইন' : 'অফলাইন');
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? AppColors.blue : Colors.white,
                        border: Border.all(color: active ? AppColors.blue : AppColors.line),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.ink)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: riders.isEmpty
                ? EmptyState(icon: Icons.two_wheeler_outlined, title: 'কোনো রাইডার পাওয়া যায়নি', subtitle: 'ভিন্ন ফিল্টার ব্যবহার করে দেখুন।')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: riders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final r = riders[i];
                      return FadeSlideIn(
                        delayMs: i * 40,
                        child: PressableScale(
                          onTap: () => Navigator.push(context, AppPageRoute(builder: (_) => RiderDetailScreen(rider: r))).then((_) => setState(() {})),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: !r.active ? AppColors.danger.withValues(alpha: 0.3) : AppColors.line), boxShadow: AppShadows.soft),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(radius: 22, backgroundColor: AppColors.tealSoft, child: Icon(Icons.two_wheeler_rounded, color: AppColors.teal)),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(width: 11, height: 11, decoration: BoxDecoration(color: r.online ? AppColors.green : AppColors.muted, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: Text(r.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink))),
                                          if (!r.active)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(999)),
                                              child: const Text('নিষ্ক্রিয়', style: TextStyle(fontSize: 9.5, color: AppColors.danger, fontWeight: FontWeight.w800)),
                                            ),
                                        ],
                                      ),
                                      Text('${r.area} • ${r.phone}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, size: 13, color: AppColors.amber),
                                          Text(' ${r.rating} • ${r.completedOrders} সম্পন্ন', style: const TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
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
