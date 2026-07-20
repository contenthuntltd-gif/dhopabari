import 'package:flutter/material.dart';

/// The single official Dhopa Bari brand mark, used everywhere a logo is
/// shown (customer app, rider app, admin panel, invoices/print views).
/// Always renders the full, unmodified artwork via [BoxFit.contain] so it
/// is never stretched, cropped, or recolored — only scaled and padded.
class AppLogo extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry padding;
  final bool rounded;
  final List<BoxShadow>? shadow;

  /// Uniform scale applied to the artwork before it is clipped to [size].
  /// The source PNG has a generous built-in white margin around the mark;
  /// zooming in slightly (equally on every side, so proportions never
  /// change) trims that margin visually without cropping or distorting it.
  final double zoom;

  const AppLogo({super.key, this.size = 72, this.padding = EdgeInsets.zero, this.rounded = false, this.shadow, this.zoom = 1.0});

  static const _asset = 'assets/branding/dhopa_bari_logo.png';

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(_asset, width: size, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.high);
    if (zoom != 1.0) {
      image = ClipRect(child: Transform.scale(scale: zoom, child: image));
    }
    image = Padding(padding: padding, child: image);
    if (!rounded && shadow == null) return image;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: rounded ? BorderRadius.circular(size * 0.26) : null,
        boxShadow: shadow,
      ),
      child: ClipRRect(borderRadius: rounded ? BorderRadius.circular(size * 0.26) : BorderRadius.zero, child: image),
    );
  }
}
