import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/admin_service.dart';
import '../services/language.dart';
import '../widgets/app_page_route.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/app_logo.dart';
import 'root_shell.dart';

class OrderSuccessScreen extends StatefulWidget {
  final bool placedOffHours;

  /// The just-placed order's display code (#DB…) and DB uuid. When the uuid
  /// is present the screen offers a "cancel order" action (valid only while
  /// the order is still Confirmed with no rider — enforced by RLS).
  final String? orderNo;
  final String? orderUuid;
  const OrderSuccessScreen({super.key, this.placedOffHours = false, this.orderNo, this.orderUuid});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  bool _cancelled = false;
  bool _cancelling = false;

  String get _orderId => (widget.orderNo?.trim().isNotEmpty ?? false) ? widget.orderNo!.trim() : '#DB';
  bool get _canCancel => (widget.orderUuid?.trim().isNotEmpty ?? false) && !_cancelled;

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
    Clipboard.setData(ClipboardData(text: _orderId));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অর্ডার নম্বর কপি করা হয়েছে')));
  }

  Future<void> _cancelOrder() async {
    final uuid = widget.orderUuid?.trim();
    if (uuid == null || uuid.isEmpty || _cancelling) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(AppLanguage.tr('অর্ডার বাতিল করবেন?')),
        content: Text(AppLanguage.tr('অর্ডারটি বাতিল হয়ে যাবে। প্রয়োজনে বাতিল করে আবার নতুন করে অর্ডার করুন।'), style: const TextStyle(fontSize: 13.5, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLanguage.tr('না'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLanguage.tr('হ্যাঁ')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _cancelling = true);
    try {
      await AdminService.cancelOrder(uuid);
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _cancelled = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLanguage.tr('অর্ডার বাতিল করা হয়েছে'))));
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AdminService.messageFor(e))));
    }
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
                    Text('দারুণ! অর্ডারটি সফল হয়েছে 🎉', style: AppText.display, textAlign: TextAlign.center),
                    SizedBox(height: 6),
                    Text(
                      'আপনার কাপড় সংগ্রহ করতে আমরা আসছি আপনার দরজায়!',
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
                          'আমাদের \'ধোপা বাড়ি\' টিম খুব দ্রুতই আপনাকে কল করবে।',
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
                      children: [
                        Text(_orderId, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink, letterSpacing: 0.5)),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy_rounded, size: 14, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
              ),
              // Cancel — only while the order is still cancellable (uuid known
              // and not already cancelled here). RLS is the real gatekeeper.
              if (_canCancel) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _cancelling ? null : _cancelOrder,
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  icon: _cancelling
                      ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger))
                      : const Icon(Icons.cancel_outlined, size: 17),
                  label: Text(AppLanguage.tr('অর্ডার বাতিল করুন'), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                ),
              ],
              if (_cancelled) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                  child: Text('❌ ${AppLanguage.tr('অর্ডার বাতিল করা হয়েছে')}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.danger)),
                ),
              ],
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
                            Text('কাপড় সংগ্রহ', style: TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
                            SizedBox(height: 2),
                            Text(
                              'আপনার কাপড়গুলো প্রস্তুত রাখুন! আজ দুপুর ১টা থেকে রাত ৯টার মধ্যে আমাদের প্রতিনিধি এসে সেগুলো সংগ্রহ করে নিয়ে যাবেন।',
                              style: TextStyle(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w700, height: 1.45),
                            ),
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
