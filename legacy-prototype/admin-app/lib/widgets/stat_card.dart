import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Compact metric tile used all over the Dashboard (today's orders,
/// revenue, rider counts, etc).
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 10),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

/// Colored pill for order/rider/customer statuses — one canonical mapping
/// so the same status always gets the same color across every screen.
class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;
  const StatusBadge({super.key, required this.status, this.label});

  static const Map<String, Color> _colors = {
    'Pending': AppColors.amber,
    'Accepted': AppColors.blue,
    'Picked Up': AppColors.blue,
    'Processing': Color(0xFF7C5CFC),
    'Ready for Delivery': AppColors.teal,
    'Delivered': AppColors.green,
    'Cancelled': AppColors.danger,
    'Approved': AppColors.green,
    'Rejected': AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label ?? status, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w800)),
    );
  }
}
