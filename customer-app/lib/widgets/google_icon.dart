import 'package:flutter/material.dart';

/// Multi-color Google "G" mark drawn with basic shapes (no image asset
/// needed) — used on the "Continue with Google" button so it reads as a
/// real branded button rather than a generic OutlinedButton.
class GoogleIcon extends StatelessWidget {
  final double size;
  const GoogleIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final strokeWidth = size.width * 0.22;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: r - strokeWidth / 2);

    // Four arcs approximating Google's brand colors around the ring.
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.35, 1.7, false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.35, 1.3, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.65, 1.05, false, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.7, 1.55, false, paint);

    // Horizontal bar (the "G" crossbar).
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(r - strokeWidth * 0.1, r - strokeWidth / 2, r + strokeWidth * 0.6, strokeWidth), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
