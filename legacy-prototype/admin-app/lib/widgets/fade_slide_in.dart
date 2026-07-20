import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fades + slides its child in on first build. Give list items an
/// incrementing [delayMs] (e.g. `index * 40`) for a tasteful stagger
/// effect instead of everything popping in at once.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int delayMs;
  final double offsetY;

  const FadeSlideIn({super.key, required this.child, this.delayMs = 0, this.offsetY = 14});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow + Duration(milliseconds: delayMs),
      curve: AppMotion.entrance,
      builder: (context, t, child) {
        // Hold at 0 for the delay portion, then ease in for the remainder.
        final delayFraction = delayMs / (AppMotion.slow.inMilliseconds + delayMs).clamp(1, double.infinity);
        final adjusted = ((t - delayFraction) / (1 - delayFraction)).clamp(0.0, 1.0);
        return Opacity(
          opacity: adjusted,
          child: Transform.translate(offset: Offset(0, (1 - adjusted) * offsetY), child: child),
        );
      },
      child: child,
    );
  }
}
