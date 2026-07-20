import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/stat_card.dart';
import '../widgets/mini_charts.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/app_page_route.dart';
import 'order_detail_screen.dart';
import 'orders_screen.dart';
import 'customers_screen.dart';
import 'riders_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  void _goToOrders(String status) {
    Navigator.push(context, AppPageRoute(builder: (_) => OrdersScreen(initialFilter: status)));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          FadeSlideIn(
            child: Row(
              children: [
                Expanded(
                  child: PressableScale(
                    onTap: () => _goToOrders('Delivered'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('আজকের আয়', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('৳${AdminMockData.todayRevenue}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 4),
                          Row(
                            children: const [
                              Icon(Icons.trending_up_rounded, size: 14, color: AppColors.tealSoft),
                              SizedBox(width: 3),
                              Text('মাসিক ৳182,400', style: TextStyle(fontSize: 10.5, color: AppColors.tealSoft, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PressableScale(
                    onTap: () => _goToOrders('All'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('আজকের অর্ডার', style: TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          const Text('${AdminMockData.todayOrders}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink)),
                          const SizedBox(height: 4),
                          Row(
                            children: const [
                              Icon(Icons.people_alt_rounded, size: 14, color: AppColors.blue),
                              SizedBox(width: 3),
                              Text('৫ জন কাস্টমার', style: TextStyle(fontSize: 10.5, color: AppColors.blue, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FadeSlideIn(
            delayMs: 60,
            child: const Text('অর্ডার অবস্থা', style: AppText.h2),
          ),
          const SizedBox(height: 10),
          FadeSlideIn(
            delayMs: 80,
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                StatCard(label: 'পেন্ডিং', value: '${AdminMockData.pendingOrders}', icon: Icons.hourglass_empty_rounded, color: AppColors.amber, onTap: () => _goToOrders('Pending')),
                StatCard(label: 'গৃহীত', value: '${AdminMockData.acceptedOrders}', icon: Icons.check_circle_outline_rounded, color: AppColors.blue, onTap: () => _goToOrders('Accepted')),
                StatCard(label: 'পিকআপ হয়েছে', value: '${AdminMockData.pickedUpOrders}', icon: Icons.local_shipping_outlined, color: AppColors.blue, onTap: () => _goToOrders('Picked Up')),
                StatCard(label: 'প্রসেসিং', value: '${AdminMockData.processingOrders}', icon: Icons.local_laundry_service_outlined, color: Color(0xFF7C5CFC), onTap: () => _goToOrders('Processing')),
                StatCard(label: 'ডেলিভারির জন্য প্রস্তুত', value: '${AdminMockData.readyForDeliveryOrders}', icon: Icons.inventory_2_outlined, color: AppColors.teal, onTap: () => _goToOrders('Ready for Delivery')),
                StatCard(label: 'ডেলিভারি হয়েছে', value: '${AdminMockData.deliveredOrders}', icon: Icons.done_all_rounded, color: AppColors.green, onTap: () => _goToOrders('Delivered')),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FadeSlideIn(
            delayMs: 100,
            child: Row(
              children: [
                Expanded(child: StatCard(label: 'মোট কাস্টমার', value: '${AdminMockData.totalCustomers}', icon: Icons.people_alt_rounded, color: AppColors.blue, onTap: () => Navigator.push(context, AppPageRoute(builder: (_) => const CustomersScreen())))),
                const SizedBox(width: 10),
                Expanded(child: StatCard(label: 'সক্রিয় রাইডার', value: '${AdminMockData.activeRiders}', icon: Icons.two_wheeler_rounded, color: AppColors.teal, onTap: () => Navigator.push(context, AppPageRoute(builder: (_) => const RidersScreen())))),
                const SizedBox(width: 10),
                Expanded(child: StatCard(label: 'বাতিল', value: '${AdminMockData.cancelledOrders}', icon: Icons.cancel_outlined, color: AppColors.danger, onTap: () => _goToOrders('Cancelled'))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FadeSlideIn(
            delayMs: 120,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('${AdminMockData.onlineRiders} অনলাইন', style: const TextStyle(fontSize: 11.5, color: AppColors.ink, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.muted, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('${AdminMockData.offlineRiders} অফলাইন', style: const TextStyle(fontSize: 11.5, color: AppColors.ink, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delayMs: 140,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('সাপ্তাহিক আয়', style: AppText.h3),
                  const SizedBox(height: 14),
                  RevenueBarChart(values: AdminMockData.revenueSeries, labels: AdminMockData.revenueSeriesLabels),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delayMs: 160,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('অর্ডার স্ট্যাটাস বিভাজন', style: AppText.h3),
                  const SizedBox(height: 14),
                  StatusDonutChart(slices: const [
                    DonutSlice(label: 'ডেলিভারি হয়েছে', value: AdminMockData.deliveredOrders, color: AppColors.green),
                    DonutSlice(label: 'প্রসেসিং', value: AdminMockData.processingOrders, color: Color(0xFF7C5CFC)),
                    DonutSlice(label: 'পিকআপ হয়েছে', value: AdminMockData.pickedUpOrders, color: AppColors.blue),
                    DonutSlice(label: 'পেন্ডিং', value: AdminMockData.pendingOrders, color: AppColors.amber),
                    DonutSlice(label: 'বাতিল', value: AdminMockData.cancelledOrders, color: AppColors.danger),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delayMs: 180,
            child: const Text('সাম্প্রতিক অর্ডার', style: AppText.h2),
          ),
          const SizedBox(height: 10),
          ...List.generate(AdminMockData.orders.length > 4 ? 4 : AdminMockData.orders.length, (i) {
            final order = AdminMockData.orders[i];
            return FadeSlideIn(
              delayMs: 200 + i * 40,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PressableScale(
                  onTap: () => Navigator.push(context, AppPageRoute(builder: (_) => OrderDetailScreen(order: order))),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.id, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.ink)),
                              const SizedBox(height: 2),
                              Text(order.customerName, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        StatusBadge(status: order.status, label: AdminMockData.orderStatusesBn[order.status]),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
