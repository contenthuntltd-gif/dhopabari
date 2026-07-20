import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single shimmering placeholder block. Compose several into a
/// `SkeletonList`/custom layout to mimic the shape of the real content
/// while it "loads" — used on Home, Orders, and Chat list initial states.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({super.key, this.width = double.infinity, this.height = 16, this.borderRadius});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.skeleton, const Color(0xFFE1E7F0), t),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

/// Ready-made skeleton for a "card row" (order card, chat row) so screens
/// don't hand-roll their loading layout every time.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SkeletonBox(width: 100, height: 14),
              SkeletonBox(width: 70, height: 20, borderRadius: BorderRadius.circular(999)),
            ],
          ),
          const SizedBox(height: 10),
          const SkeletonBox(width: 140, height: 11),
          const SizedBox(height: 12),
          const SkeletonBox(width: 180, height: 13),
        ],
      ),
    );
  }
}
