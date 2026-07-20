import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/stat_card.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/state_views.dart';

class WithdrawalsScreen extends StatefulWidget {
  const WithdrawalsScreen({super.key});
  @override
  State<WithdrawalsScreen> createState() => _WithdrawalsScreenState();
}

class _WithdrawalsScreenState extends State<WithdrawalsScreen> {
  void _decide(WithdrawalRequest w, String status) {
    setState(() => w.status = status);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status == 'Approved' ? 'উত্তোলন অনুমোদিত হয়েছে' : 'উত্তোলন প্রত্যাখ্যাত হয়েছে')));
  }

  @override
  Widget build(BuildContext context) {
    final withdrawals = AdminMockData.withdrawals;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('রাইডার উত্তোলন অনুরোধ')),
      body: withdrawals.isEmpty
          ? const EmptyState(icon: Icons.account_balance_wallet_outlined, title: 'কোনো অনুরোধ নেই', subtitle: 'কোনো রাইডার এখনো উত্তোলনের অনুরোধ করেননি।')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: withdrawals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final w = withdrawals[i];
                return FadeSlideIn(
                  delayMs: i * 40,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(w.riderName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.ink)),
                            StatusBadge(status: w.status, label: w.status == 'Pending' ? 'পেন্ডিং' : (w.status == 'Approved' ? 'অনুমোদিত' : 'প্রত্যাখ্যাত')),
                          ],
                        ),
                        Text(w.date, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('৳${w.amount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.blue)),
                        if (w.status == 'Pending') ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                                  onPressed: () => _decide(w, 'Rejected'),
                                  child: const Text('প্রত্যাখ্যান'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                                  onPressed: () => _decide(w, 'Approved'),
                                  child: const Text('অনুমোদন করুন'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
