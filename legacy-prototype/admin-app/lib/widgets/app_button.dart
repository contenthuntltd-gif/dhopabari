import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Primary CTA button with a real loading state (spinner replaces the
/// label, button stays the same size so nothing jumps), a disabled state,
/// and a subtle press-scale — used for every "main action" button in the
/// app (Login, Confirm order, Save, etc) so they all feel identical.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? trailingIcon;
  final bool outlined;
  final Color? color;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.trailingIcon,
    this.outlined = false,
    this.color,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.blue;
    final child = AnimatedSwitcher(
      duration: AppMotion.fast,
      child: widget.loading
          ? const SizedBox(
              key: ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(Colors.white)),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.label),
                if (widget.trailingIcon != null) ...[
                  const SizedBox(width: 6),
                  Icon(widget.trailingIcon, size: 18),
                ],
              ],
            ),
    );

    final button = widget.outlined
        ? OutlinedButton(onPressed: _enabled ? widget.onPressed : null, style: OutlinedButton.styleFrom(side: BorderSide(color: color, width: 1.4), foregroundColor: color), child: child)
        : ElevatedButton(onPressed: _enabled ? widget.onPressed : null, style: ElevatedButton.styleFrom(backgroundColor: color), child: child);

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.loading ? '${widget.label} — লোড হচ্ছে' : widget.label,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: AppMotion.fast,
          curve: Curves.easeOut,
          child: SizedBox(width: double.infinity, child: button),
        ),
      ),
    );
  }
}
