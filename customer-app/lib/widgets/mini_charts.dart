import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Lightweight bar chart drawn with plain widgets (no chart package
/// dependency) — used for the Dashboard's revenue graph.
class RevenueBarChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;
  const RevenueBarChart({super.key, required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    final maxVal = values.reduce((a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final heightFraction = maxVal == 0 ? 0.0 : values[i] / maxVal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: heightFraction),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) => Container(
                      height: 96 * t,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [AppColors.blue, AppColors.blue.withValues(alpha: 0.55)],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(labels[i], style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// A single slice for [StatusDonutChart].
class DonutSlice {
  final String label;
  final int value;
  final Color color;
  const DonutSlice({required this.label, required this.value, required this.color});
}

/// Donut chart drawn with CustomPainter — used for the order-status
/// breakdown on the Dashboard.
class StatusDonutChart extends StatelessWidget {
  final List<DonutSlice> slices;
  const StatusDonutChart({super.key, required this.slices});

  int get _total => slices.fold(0, (a, b) => a + b.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(painter: _DonutPainter(slices: slices, progress: t)),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: slices.map((s) {
              final pct = _total == 0 ? 0 : (s.value / _total * 100).round();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(width: 9, height: 9, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.label, style: const TextStyle(fontSize: 11.5, color: AppColors.ink, fontWeight: FontWeight.w700))),
                    Text('$pct%', style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSlice> slices;
  final double progress;
  _DonutPainter({required this.slices, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold(0, (a, b) => a + b.value);
    if (total == 0) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height).deflate(6);
    var startAngle = -1.5708; // -90deg
    final strokeWidth = 16.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (final slice in slices) {
      final sweep = (slice.value / total) * 6.2832 * progress;
      paint.color = slice.color;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.slices != slices;
}
