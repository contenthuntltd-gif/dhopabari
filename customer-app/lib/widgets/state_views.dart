import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Generic "nothing here yet" view — used whenever a list is legitimately
/// empty (no orders, no chats, no notifications) so the user sees a
/// friendly prompt instead of a blank screen.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(color: AppColors.blueSoft, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.blue, size: 34),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: AppText.h2),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: AppText.bodyMuted),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Generic "something went wrong" view with a retry action — the shape
/// every list/detail screen should show for a failed load once this app
/// is wired to a real network layer.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(color: AppColors.dangerSoft, shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, color: AppColors.danger, size: 32),
            ),
            const SizedBox(height: 18),
            const Text('কিছু একটা সমস্যা হয়েছে', textAlign: TextAlign.center, style: AppText.h2),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: AppText.bodyMuted),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact inline error banner for form-submission failures (login,
/// register, etc) — replaces the plain red Container each screen used to
/// hand-roll, adds an entrance animation and a dismiss affordance.
class InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const InlineErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.base,
      curve: AppMotion.entrance,
      builder: (context, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, (1 - t) * -6), child: child)),
      child: Semantics(
        liveRegion: true,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(message, style: const TextStyle(color: AppColors.danger, fontSize: 12.5, fontWeight: FontWeight.w700))),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(Icons.close_rounded, color: AppColors.danger, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
