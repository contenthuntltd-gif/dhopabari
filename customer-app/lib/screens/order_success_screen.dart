import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/app_page_route.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/app_logo.dart';
import 'root_shell.dart';

class OrderSuccessScreen extends StatefulWidget {
  final bool placedOffHours;
  const OrderSuccessScreen({super.key, this.placedOffHours = false});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  static const _orderId = '#DB123457';

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  void _copyOrderId() {
    Clipboard.setData(const ClipboardData(text: _orderId));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অর্ডার নম্বর কপি করা হয়েছে')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
          child: Column(
            children: [
              const AppLogo(size: 44),
              const SizedBox(height: 14),
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _ringController,
                      builder: (context, child) {
                        final t = _ringController.value;
                        return Opacity(
                          opacity: (1 - t).clamp(0, 1),
                          child: Transform.scale(scale: 0.85 + t * 0.4, child: child),
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.teal, width: 2)),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.elasticOut,
                      builder: (context, t, child) => Transform.scale(scale: t, child: child),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(color: AppColors.tealSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: AppColors.teal, size: 56),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              FadeSlideIn(
                delayMs: 150,
                child: const Column(
                  children: [
                    Text('অর্ডার সফল হয়েছে! 🎉', style: AppText.display, textAlign: TextAlign.center),
                    SizedBox(height: 6),
                    Text(
                      'আমরা শীঘ্রই আপনার বাসায় পৌঁছে যাব।',
                      textAlign: TextAlign.center,
                      style: AppText.bodyMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delayMs: 180,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.blueSoft.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: AppColors.blue.withValues(alpha: 0.3))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.support_agent_rounded, size: 20, color: AppColors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'আমাদের ধোপা বাড়ি টিম শীঘ্রই আপনার সাথে যোগাযোগ করবে।',
                          style: const TextStyle(fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w700, height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FadeSlideIn(
                delayMs: 200,
                child: GestureDetector(
                  onTap: _copyOrderId,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.line)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(_orderId, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 0.5)),
                        SizedBox(width: 8),
                        Icon(Icons.copy_rounded, size: 14, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FadeSlideIn(
                delayMs: 250,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(AppRadius.md), boxShadow: AppShadows.soft),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                        child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('আনুমানিক পিকআপ', style: TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
                            Text('আজ, ১০:০০ AM - ১২:০০ PM', style: TextStyle(fontSize: 13.5, color: AppColors.ink, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FadeSlideIn(
                delayMs: 300,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line), boxShadow: AppShadows.soft),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('এরপর কী হবে', style: AppText.h3),
                      const SizedBox(height: 12),
                      _nextStep(Icons.check_circle_rounded, 'অর্ডার নিশ্চিত হয়েছে', done: true),
                      _nextStep(Icons.two_wheeler_rounded, 'রাইডার আপনার কাছে আসবে'),
                      _nextStep(Icons.local_laundry_service_rounded, 'কাপড় ধোয়া ও প্রক্রিয়াকরণ'),
                      _nextStep(Icons.home_rounded, 'আপনার বাসায় ডেলিভারি', isLast: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              FadeSlideIn(
                delayMs: 350,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pushAndRemoveUntil(AppPageRoute(builder: (_) => const RootShell()), (r) => false),
                        icon: const Icon(Icons.location_searching_rounded, size: 17),
                        label: const Text('অর্ডার ট্র্যাক করুন'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pushAndRemoveUntil(AppPageRoute(builder: (_) => const RootShell()), (r) => false),
                        child: const Text('হোমে ফিরে যান'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nextStep(IconData icon, String label, {bool done = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(shape: BoxShape.circle, color: done ? AppColors.teal : AppColors.paper, border: done ? null : Border.all(color: AppColors.line)),
                child: Icon(icon, size: 14, color: done ? Colors.white : AppColors.muted),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: AppColors.line)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18, top: 4),
              child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: done ? FontWeight.w800 : FontWeight.w600, color: done ? AppColors.ink : AppColors.muted)),
            ),
          ),
        ],
      ),
    );
  }
}
