import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../data/receipt_data.dart';
import '../widgets/bn_number.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/app_page_route.dart';
import 'chat_screen.dart';
import 'receipt_screen.dart';

class TrackingScreen extends StatefulWidget {
  final MockOrder order;
  const TrackingScreen({super.key, required this.order});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDone = order.progress >= 1;
    final hasRider = !isDone && order.riderName != null;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: Text('অর্ডার ${order.id}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.sm),
          children: [
            if (hasRider) ...[
              FadeSlideIn(child: _RiderCard(order: order)),
              const SizedBox(height: AppSpace.xs),
            ],
            FadeSlideIn(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.line),
                  boxShadow: AppShadows.soft,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle_rounded
                              : Icons.local_shipping_rounded,
                          color: isDone ? AppColors.green : AppColors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          order.currentStatusLabel,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: isDone ? AppColors.green : AppColors.blue,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Text(
                        order.date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...List.generate(order.timeline.length, (i) {
                      final step = order.timeline[i];
                      final isLast = i == order.timeline.length - 1;
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                if (step.current)
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) {
                                      final scale =
                                          1 + (_pulseController.value * 0.35);
                                      return Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Transform.scale(
                                            scale: scale,
                                            child: Container(
                                              width: 22,
                                              height: 22,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: AppColors.blue
                                                    .withValues(
                                                      alpha:
                                                          (1 -
                                                              _pulseController
                                                                  .value) *
                                                          0.4,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          child!,
                                        ],
                                      );
                                    },
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.blue,
                                      ),
                                      child: const Icon(
                                        Icons.circle,
                                        color: Colors.white,
                                        size: 8,
                                      ),
                                    ),
                                  )
                                else
                                  AnimatedContainer(
                                    duration: AppMotion.base,
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: step.done
                                          ? AppColors.blue
                                          : AppColors.line,
                                    ),
                                    child: step.done
                                        ? const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          )
                                        : null,
                                  ),
                                if (!isLast)
                                  Expanded(
                                    child: AnimatedContainer(
                                      duration: AppMotion.base,
                                      width: 2,
                                      color: step.done
                                          ? AppColors.blue
                                          : AppColors.line,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step.label,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: step.current
                                            ? FontWeight.w900
                                            : FontWeight.w600,
                                        color: step.done || step.current
                                            ? AppColors.ink
                                            : AppColors.muted,
                                      ),
                                    ),
                                    if (step.current)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Text(
                                          'বর্তমান ধাপ',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.blue,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            FadeSlideIn(
              delayMs: 80,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('অর্ডার বিস্তারিত', style: AppText.h3),
                    const SizedBox(height: 10),
                    _row('সার্ভিস', order.service),
                    _row('মোট পিস', '${toBn(order.pieces)} পিস'),
                    _row('ঠিকানা', order.area),
                    _row('সর্বমোট', money(order.total)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            FadeSlideIn(
              delayMs: 100,
              child: Row(
                children: [
                  if (order.progress > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (_) => ReceiptScreen(receipt: ReceiptData.pickupFor(order), role: ReceiptViewerRole.customer, pickupConfirmed: true),
                          ),
                        ),
                        icon: const Icon(Icons.receipt_long_rounded, size: AppIconSize.md),
                        label: const Text('পিকআপ রিসিট'),
                      ),
                    ),
                  if (order.progress > 0 && isDone) const SizedBox(width: 10),
                  if (isDone)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (_) => ReceiptScreen(receipt: ReceiptData.deliveryFor(order), role: ReceiptViewerRole.customer),
                          ),
                        ),
                        icon: const Icon(Icons.receipt_rounded, size: AppIconSize.md),
                        label: const Text('ডেলিভারি রিসিট'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            FadeSlideIn(
              delayMs: 120,
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (_) => ReceiptScreen(receipt: ReceiptData.paymentFor(order), role: ReceiptViewerRole.customer),
                    ),
                  ),
                  icon: const Icon(Icons.payments_rounded, size: AppIconSize.md),
                  label: const Text('পেমেন্ট রিসিট'),
                ),
              ),
            ),
            if (!isDone) ...[
              const SizedBox(height: AppSpace.xs),
              FadeSlideIn(
                delayMs: 140,
                child: SizedBox(
                  width: double.infinity,
                  // Contact the rider handling this order. If one is assigned we
                  // show a call button with their number; otherwise a note.
                  child: (order.riderPhone != null && order.riderPhone!.trim().isNotEmpty)
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 13)),
                          onPressed: () => launchUrl(Uri.parse('tel:${order.riderPhone!.replaceAll(' ', '')}')),
                          icon: const Icon(Icons.call_rounded, size: AppIconSize.md),
                          label: Text(
                            order.riderName != null
                                ? 'রাইডারকে কল করুন — ${order.riderName}'
                                : 'রাইডারকে কল করুন',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.two_wheeler_outlined, size: AppIconSize.md),
                          label: const Text('রাইডার নির্ধারিত হলে নম্বর এখানে দেখা যাবে'),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The food-delivery-style rider card — avatar, name, live "online" dot,
/// ETA, and direct call/chat actions. Only shown once a rider has actually
/// been assigned (see `hasRider` in `_TrackingScreenState.build`).
class _RiderCard extends StatelessWidget {
  final MockOrder order;
  const _RiderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.teal, Color(0xFF0C8B85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.two_wheeler_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.teal, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.riderName ?? '',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'আপনার ডেলিভারি রাইডার',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (order.etaLabel != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'আনুমানিক পৌঁছাবে ${order.etaLabel}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _riderActionButton(
            icon: Icons.chat_bubble_rounded,
            tooltip: 'রাইডারকে চ্যাট করুন',
            onTap: () => Navigator.push(
              context,
              AppPageRoute(
                builder: (_) => ChatScreen(
                  chat: MockData.chats.firstWhere((c) => c.isRider),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _riderActionButton(
            icon: Icons.call_rounded,
            tooltip: 'রাইডারকে কল করুন',
            onTap: order.riderPhone == null
                ? null
                : () => launchUrl(Uri.parse('tel:${order.riderPhone}')),
          ),
        ],
      ),
    );
  }

  Widget _riderActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: AppColors.teal, size: AppIconSize.lg),
          ),
        ),
      ),
    );
  }
}
