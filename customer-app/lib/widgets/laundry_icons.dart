import 'package:flutter/material.dart';

/// Dedicated outline icons for every item on the official Dhopa Bari
/// price list — one hand-drawn icon per item, no generic placeholders.
///
/// Design system (matches the printed price list):
///   • 24×24 grid, ~3px margin
///   • single stroke weight (1.6 @ 24px, scales with size)
///   • round caps & joins, minimal geometry
///   • Dhopa Bari blue by default
///
/// Usage: `LaundryIcon('saree', size: 28)` — unknown ids fall back to a
/// neutral hanger icon so a new catalog row never renders blank.
class LaundryIcon extends StatelessWidget {
  final String itemId;
  final double size;
  final Color color;

  const LaundryIcon(
    this.itemId, {
    super.key,
    this.size = 24,
    this.color = const Color(0xFF0B5ED7),
  });

  static bool has(String id) => _drawers.containsKey(id);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _LaundryIconPainter(itemId, color),
    );
  }
}

class _LaundryIconPainter extends CustomPainter {
  final String itemId;
  final Color color;
  const _LaundryIconPainter(this.itemId, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    (_drawers[itemId] ?? _hanger)(canvas, paint);
  }

  @override
  bool shouldRepaint(_LaundryIconPainter old) =>
      old.itemId != itemId || old.color != color;
}

typedef _Draw = void Function(Canvas c, Paint p);

Path _poly(List<List<double>> pts, {bool close = true}) {
  final path = Path()..moveTo(pts.first[0], pts.first[1]);
  for (final pt in pts.skip(1)) {
    path.lineTo(pt[0], pt[1]);
  }
  if (close) path.close();
  return path;
}

void _dot(Canvas c, Paint p, double x, double y, [double r = 0.7]) {
  c.drawCircle(Offset(x, y), r, Paint()..color = p.color);
}

// ── Fallback ──
void _hanger(Canvas c, Paint p) {
  c.drawCircle(const Offset(12, 5), 1.6, p);
  c.drawPath(Path()..moveTo(12, 6.6)..lineTo(12, 9)..moveTo(12, 9)..lineTo(3.5, 16)..lineTo(20.5, 16)..close(), p);
}

// ── Men ──

void _shirt(Canvas c, Paint p) {
  c.drawPath(
    _poly([[9, 3.5], [5, 5.5], [3, 10.5], [6.2, 11.8], [6.2, 20.5], [17.8, 20.5], [17.8, 11.8], [21, 10.5], [19, 5.5], [15, 3.5], [12, 7.5]]),
    p,
  );
  c.drawPath(Path()..moveTo(12, 9.5)..lineTo(12, 19), p);
  _dot(c, p, 12, 11.5, 0.55);
  _dot(c, p, 12, 14.5, 0.55);
  _dot(c, p, 12, 17.5, 0.55);
}

void _pant(Canvas c, Paint p) {
  c.drawPath(_poly([[7, 3.5], [17, 3.5], [17.8, 20.5], [13.6, 20.5], [12, 10], [10.4, 20.5], [6.2, 20.5]]), p);
  c.drawPath(Path()..moveTo(7, 6.5)..lineTo(17, 6.5), p);
}

void _tshirt(Canvas c, Paint p) {
  c.drawPath(
    _poly([[8.5, 4], [4, 6], [5.5, 10.5], [7.5, 9.8], [7.5, 20], [16.5, 20], [16.5, 9.8], [18.5, 10.5], [20, 6], [15.5, 4]], close: false),
    p,
  );
  // crew neck
  c.drawPath(Path()..moveTo(8.5, 4)..arcToPoint(const Offset(15.5, 4), radius: const Radius.circular(3.6), clockwise: false), p);
}

void _panjabi(Canvas c, Paint p) {
  c.drawPath(
    _poly([[9.5, 3.5], [5.5, 5.5], [4, 12], [6.8, 12.6], [6.8, 21], [17.2, 21], [17.2, 12.6], [20, 12], [18.5, 5.5], [14.5, 3.5]], close: false),
    p,
  );
  // band collar + placket
  c.drawPath(Path()..moveTo(9.5, 3.5)..lineTo(12, 5)..lineTo(14.5, 3.5), p);
  c.drawPath(Path()..moveTo(12, 5)..lineTo(12, 12.5), p);
  _dot(c, p, 12, 7.2, 0.55);
  _dot(c, p, 12, 9.6, 0.55);
}

void _pajama(Canvas c, Paint p) {
  c.drawPath(_poly([[7.5, 5], [16.5, 5], [18, 20.5], [13.8, 20.5], [12, 11.5], [10.2, 20.5], [6, 20.5]]), p);
  c.drawPath(Path()..moveTo(7.5, 7.6)..lineTo(16.5, 7.6), p);
  // drawstring
  c.drawPath(Path()..moveTo(11, 7.6)..lineTo(10.4, 10.2)..moveTo(13, 7.6)..lineTo(13.6, 10.2), p);
}

void _jubbah(Canvas c, Paint p) {
  c.drawPath(
    _poly([[9, 3.5], [5, 5.5], [3, 13.5], [6.2, 14.2], [5.6, 21], [18.4, 21], [17.8, 14.2], [21, 13.5], [19, 5.5], [15, 3.5]], close: false),
    p,
  );
  c.drawPath(Path()..moveTo(9, 3.5)..lineTo(12, 5.5)..lineTo(15, 3.5), p);
  c.drawPath(Path()..moveTo(12, 5.5)..lineTo(12, 21), p);
}

void _fatua(Canvas c, Paint p) {
  c.drawPath(
    _poly([[9.5, 4.5], [5.5, 6.5], [4.5, 11], [7, 11.6], [7, 18.5], [17, 18.5], [17, 11.6], [19.5, 11], [18.5, 6.5], [14.5, 4.5]], close: false),
    p,
  );
  c.drawPath(Path()..moveTo(9.5, 4.5)..lineTo(12, 6)..lineTo(14.5, 4.5), p);
  c.drawPath(Path()..moveTo(12, 6)..lineTo(12, 10.5), p);
  // side slits
  c.drawPath(Path()..moveTo(7, 16.5)..lineTo(8.3, 16.5)..moveTo(17, 16.5)..lineTo(15.7, 16.5), p);
}

void _lungi(Canvas c, Paint p) {
  c.drawPath(_poly([[7.5, 5], [16.5, 5], [18.5, 20.5], [5.5, 20.5]]), p);
  c.drawPath(Path()..moveTo(7.3, 7.4)..lineTo(16.7, 7.4), p);
  // wrap fold
  c.drawPath(Path()..moveTo(11, 7.4)..lineTo(9, 20.5)..moveTo(13, 7.4)..quadraticBezierTo(14.5, 14, 13.5, 20.5), p);
}

void _suit(Canvas c, Paint p) {
  c.drawPath(
    _poly([[9, 4], [5, 6], [4, 12], [6.5, 12.5], [6.5, 20.5], [17.5, 20.5], [17.5, 12.5], [20, 12], [19, 6], [15, 4]], close: false),
    p,
  );
  // lapels
  c.drawPath(Path()..moveTo(9, 4)..lineTo(10.6, 9)..lineTo(9.2, 11)..lineTo(11.2, 15), p);
  c.drawPath(Path()..moveTo(15, 4)..lineTo(13.4, 9)..lineTo(14.8, 11)..lineTo(12.8, 15), p);
  // tie
  c.drawPath(_poly([[11.2, 5.2], [12.8, 5.2], [12.6, 7], [12, 12.5], [11.4, 7]]), p);
}

void _blazer(Canvas c, Paint p) {
  c.drawPath(
    _poly([[9, 4], [5, 6], [4, 12], [6.5, 12.5], [6.5, 20.5], [17.5, 20.5], [17.5, 12.5], [20, 12], [19, 6], [15, 4]], close: false),
    p,
  );
  // open front + notched lapels
  c.drawPath(Path()..moveTo(9, 4)..lineTo(11.5, 9)..lineTo(10.5, 20.5), p);
  c.drawPath(Path()..moveTo(15, 4)..lineTo(12.5, 9)..lineTo(13.5, 20.5), p);
  _dot(c, p, 12, 13.5, 0.55);
}

void _koti(Canvas c, Paint p) {
  c.drawPath(
    _poly([[9, 4], [6.5, 6], [6.5, 20.5], [10.5, 20.5], [12, 18.5], [13.5, 20.5], [17.5, 20.5], [17.5, 6], [15, 4], [12, 9.5]]),
    p,
  );
  _dot(c, p, 12, 12.5, 0.55);
  _dot(c, p, 12, 15.2, 0.55);
}

void _tie(Canvas c, Paint p) {
  c.drawPath(_poly([[9.8, 3.5], [14.2, 3.5], [13.4, 7], [10.6, 7]]), p);
  c.drawPath(_poly([[10.6, 7], [13.4, 7], [14.6, 16.5], [12, 20.5], [9.4, 16.5]]), p);
}

void _sweater(Canvas c, Paint p) {
  c.drawPath(
    _poly([[8.5, 4.5], [4.5, 6.5], [3.5, 13], [6.5, 13.5], [6.5, 19.5], [17.5, 19.5], [17.5, 13.5], [20.5, 13], [19.5, 6.5], [15.5, 4.5]], close: false),
    p,
  );
  c.drawPath(Path()..moveTo(8.5, 4.5)..arcToPoint(const Offset(15.5, 4.5), radius: const Radius.circular(3.8), clockwise: false), p);
  // ribbed hem
  for (final x in [8.5, 10.5, 12.5, 14.5]) {
    c.drawPath(Path()..moveTo(x, 17.8)..lineTo(x, 19.5), p);
  }
}

void _jacket(Canvas c, Paint p) {
  c.drawPath(
    _poly([[9, 3.5], [5, 6], [3.5, 13], [6.5, 13.5], [6.5, 20.5], [17.5, 20.5], [17.5, 13.5], [20.5, 13], [19, 6], [15, 3.5]], close: false),
    p,
  );
  // high collar + zip
  c.drawPath(Path()..moveTo(9, 3.5)..lineTo(9.8, 5.8)..lineTo(14.2, 5.8)..lineTo(15, 3.5), p);
  c.drawPath(Path()..moveTo(12, 5.8)..lineTo(12, 20.5), p);
  _dot(c, p, 12.9, 9, 0.55);
  // pockets
  c.drawPath(Path()..moveTo(7.8, 15.5)..lineTo(9.8, 17)..moveTo(16.2, 15.5)..lineTo(14.2, 17), p);
}

void _shawl(Canvas c, Paint p) {
  c.drawPath(
    Path()
      ..moveTo(4, 5)
      ..quadraticBezierTo(12, 9, 20, 5)
      ..lineTo(20, 15.5)
      ..quadraticBezierTo(12, 19.5, 4, 15.5)
      ..close(),
    p,
  );
  // fringe
  for (final x in [6.0, 9.0, 12.0, 15.0, 18.0]) {
    final yTop = 15.5 + 2 * (1 - ((x - 12).abs() / 8) * ((x - 12).abs() / 8)) * 1.0;
    c.drawPath(Path()..moveTo(x, yTop + 0.8)..lineTo(x, yTop + 3.2), p);
  }
}

// ── Women ──

void _threePiece(Canvas c, Paint p) {
  c.drawPath(
    _poly([[9.5, 3.5], [6, 5.5], [4.5, 11], [7, 11.5], [5.8, 20.5], [18.2, 20.5], [17, 11.5], [19.5, 11], [18, 5.5], [14.5, 3.5], [12, 6.5]]),
    p,
  );
  // dupatta across
  c.drawPath(Path()..moveTo(15.5, 4.2)..quadraticBezierTo(10, 10, 7.2, 19), p);
}

void _borka(Canvas c, Paint p) {
  // head
  c.drawPath(Path()..addArc(const Rect.fromLTRB(9.2, 2.8, 14.8, 8.4), 3.5, 5.5), p);
  // face opening
  c.drawPath(Path()..addArc(const Rect.fromLTRB(10.3, 4, 13.7, 7.4), 0, 6.28), p);
  // flowing cloak
  c.drawPath(
    Path()
      ..moveTo(9.6, 7.4)
      ..quadraticBezierTo(5, 13, 4.5, 21)
      ..lineTo(19.5, 21)
      ..quadraticBezierTo(19, 13, 14.4, 7.4),
    p,
  );
}

void _dupatta(Canvas c, Paint p) {
  c.drawPath(
    Path()
      ..moveTo(4.5, 4)
      ..quadraticBezierTo(9, 9, 7, 14)
      ..quadraticBezierTo(5.5, 17.5, 8, 20)
      ..moveTo(8.5, 4)
      ..quadraticBezierTo(13, 9, 11, 14)
      ..quadraticBezierTo(9.5, 17.5, 12, 20),
    p,
  );
  c.drawPath(
    Path()
      ..moveTo(4.5, 4)
      ..quadraticBezierTo(12, 2, 19.5, 5)
      ..quadraticBezierTo(20.5, 10, 17, 14)
      ..moveTo(8.5, 4)
      ..quadraticBezierTo(14, 3.4, 19.5, 5),
    p,
  );
}

void _hijab(Canvas c, Paint p) {
  // outer scarf
  c.drawPath(
    Path()
      ..moveTo(12, 3)
      ..quadraticBezierTo(4.5, 3.5, 5.5, 12)
      ..quadraticBezierTo(6, 17, 9, 20.5)
      ..lineTo(15, 20.5)
      ..quadraticBezierTo(18, 17, 18.5, 12)
      ..quadraticBezierTo(19.5, 3.5, 12, 3),
    p,
  );
  // face
  c.drawPath(
    Path()
      ..moveTo(12, 6)
      ..quadraticBezierTo(8.2, 6.3, 8.6, 11)
      ..quadraticBezierTo(8.9, 14.6, 12, 15.5)
      ..quadraticBezierTo(15.1, 14.6, 15.4, 11)
      ..quadraticBezierTo(15.8, 6.3, 12, 6),
    p,
  );
}

void _blouse(Canvas c, Paint p) {
  c.drawPath(
    _poly([[8.5, 4.5], [4.5, 6.5], [6, 10.5], [8, 9.9], [8, 16.5], [16, 16.5], [16, 9.9], [18, 10.5], [19.5, 6.5], [15.5, 4.5], [12, 9]]),
    p,
  );
  // waist knot ties
  c.drawPath(Path()..moveTo(10.5, 16.5)..lineTo(9, 19.5)..moveTo(13.5, 16.5)..lineTo(15, 19.5), p);
}

void _saree(Canvas c, Paint p) {
  // body drape
  c.drawPath(
    _poly([[10, 3.5], [7.5, 9], [6, 21], [18, 21], [16.5, 9], [14, 3.5]], close: false),
    p,
  );
  // pallu over shoulder
  c.drawPath(Path()..moveTo(14, 3.5)..quadraticBezierTo(9, 8, 8.8, 21), p);
  // pleats
  c.drawPath(Path()..moveTo(11.6, 12)..lineTo(11.2, 21)..moveTo(13.6, 12)..lineTo(13.8, 21)..moveTo(15.4, 12)..lineTo(16, 21), p);
}

void _lehenga(Canvas c, Paint p) {
  // waist
  c.drawPath(_poly([[9.5, 3.5], [14.5, 3.5], [15, 6.5], [9, 6.5]]), p);
  // bell skirt
  c.drawPath(
    Path()
      ..moveTo(9, 6.5)
      ..quadraticBezierTo(4.5, 14, 3.5, 20.5)
      ..lineTo(20.5, 20.5)
      ..quadraticBezierTo(19.5, 14, 15, 6.5),
    p,
  );
  // flare lines
  c.drawPath(Path()..moveTo(10.5, 8.5)..lineTo(8.5, 20.5)..moveTo(12, 8.5)..lineTo(12, 20.5)..moveTo(13.5, 8.5)..lineTo(15.5, 20.5), p);
}

// ── Kids ──

void _kidsWear(Canvas c, Paint p) {
  // onesie
  c.drawPath(
    _poly([[9, 4.5], [5.5, 6], [4.5, 10], [7, 10.6], [7, 15], [9.5, 15], [9.5, 19.5], [11.2, 19.5], [12, 15.8], [12.8, 19.5], [14.5, 19.5], [14.5, 15], [17, 15], [17, 10.6], [19.5, 10], [18.5, 6], [15, 4.5]], close: false),
    p,
  );
  c.drawPath(Path()..moveTo(9, 4.5)..arcToPoint(const Offset(15, 4.5), radius: const Radius.circular(3.2), clockwise: false), p);
  _dot(c, p, 12, 12.5, 0.55);
}

// ── Home ──

void _bedsheet(Canvas c, Paint p) {
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(4, 6, 20, 18), const Radius.circular(1.5)), p);
  // fold lines
  c.drawPath(Path()..moveTo(4, 10)..lineTo(20, 10)..moveTo(4, 14)..lineTo(20, 14), p);
  // turned corner
  c.drawPath(Path()..moveTo(16, 6)..lineTo(20, 10), p);
}

void _pillowCover(Canvas c, Paint p) {
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(3.5, 7, 20.5, 17), const Radius.circular(3.5)), p);
  // corner pinches
  c.drawPath(Path()..moveTo(3.5, 7)..lineTo(6, 9)..moveTo(20.5, 7)..lineTo(18, 9)..moveTo(3.5, 17)..lineTo(6, 15)..moveTo(20.5, 17)..lineTo(18, 15), p);
  // flap opening
  c.drawPath(Path()..moveTo(16.5, 8.5)..quadraticBezierTo(15.5, 12, 16.5, 15.5), p);
}

void _towel(Canvas c, Paint p) {
  // rail
  c.drawPath(Path()..moveTo(3, 5.5)..lineTo(21, 5.5), p);
  // hanging towel
  c.drawPath(
    _poly([[7, 5.5], [7, 19.5], [17, 19.5], [17, 5.5]], close: false),
    p,
  );
  // stripes
  c.drawPath(Path()..moveTo(7, 15.5)..lineTo(17, 15.5)..moveTo(7, 17.3)..lineTo(17, 17.3), p);
}

void _blanketRegular(Canvas c, Paint p) {
  // rolled blanket, side view
  c.drawPath(
    Path()
      ..moveTo(6.5, 8)
      ..lineTo(17, 8)
      ..arcToPoint(const Offset(17, 16), radius: const Radius.circular(4))
      ..lineTo(6.5, 16),
    p,
  );
  // spiral end
  c.drawCircle(const Offset(6.5, 12), 4, p);
  c.drawCircle(const Offset(6.5, 12), 1.6, p);
}

void _blanketHeavy(Canvas c, Paint p) {
  // thick folded stack
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(4, 5.5, 20, 12), const Radius.circular(2)), p);
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(4, 12, 20, 18.5), const Radius.circular(2)), p);
  // quilt stitches
  c.drawPath(Path()..moveTo(8, 7)..lineTo(10, 10.5)..moveTo(14, 7)..lineTo(16, 10.5)..moveTo(8, 13.5)..lineTo(10, 17)..moveTo(14, 13.5)..lineTo(16, 17), p);
}

void _curtain(Canvas c, Paint p) {
  // rod
  c.drawPath(Path()..moveTo(2.5, 4.5)..lineTo(21.5, 4.5), p);
  _dot(c, p, 3, 4.5, 0.7);
  _dot(c, p, 21, 4.5, 0.7);
  // left drape gathered
  c.drawPath(
    Path()
      ..moveTo(4.5, 4.5)
      ..quadraticBezierTo(6.5, 10, 5, 13.5)
      ..quadraticBezierTo(8.5, 16, 7.5, 20.5)
      ..moveTo(9.5, 4.5)
      ..quadraticBezierTo(8.5, 10, 5, 13.5),
    p,
  );
  // right drape gathered
  c.drawPath(
    Path()
      ..moveTo(19.5, 4.5)
      ..quadraticBezierTo(17.5, 10, 19, 13.5)
      ..quadraticBezierTo(15.5, 16, 16.5, 20.5)
      ..moveTo(14.5, 4.5)
      ..quadraticBezierTo(15.5, 10, 19, 13.5),
    p,
  );
}

void _sofaCover(Canvas c, Paint p) {
  // backrest
  c.drawPath(
    Path()
      ..moveTo(5.5, 12)
      ..lineTo(5.5, 7.5)
      ..quadraticBezierTo(5.5, 5.5, 7.5, 5.5)
      ..lineTo(16.5, 5.5)
      ..quadraticBezierTo(18.5, 5.5, 18.5, 7.5)
      ..lineTo(18.5, 12),
    p,
  );
  // arms + seat base
  c.drawPath(
    Path()
      ..moveTo(3, 12.5)
      ..quadraticBezierTo(3, 10.5, 5, 10.5)
      ..quadraticBezierTo(6.8, 10.5, 6.8, 12.5)
      ..lineTo(6.8, 13.5)
      ..lineTo(17.2, 13.5)
      ..lineTo(17.2, 12.5)
      ..quadraticBezierTo(17.2, 10.5, 19, 10.5)
      ..quadraticBezierTo(21, 10.5, 21, 12.5)
      ..lineTo(21, 17.5)
      ..lineTo(3, 17.5)
      ..close(),
    p,
  );
  // legs
  c.drawPath(Path()..moveTo(5.5, 17.5)..lineTo(5.5, 19.5)..moveTo(18.5, 17.5)..lineTo(18.5, 19.5), p);
}

void _cushionCover(Canvas c, Paint p) {
  // soft square cushion
  c.drawPath(
    Path()
      ..moveTo(5, 5)
      ..quadraticBezierTo(12, 7, 19, 5)
      ..quadraticBezierTo(17, 12, 19, 19)
      ..quadraticBezierTo(12, 17, 5, 19)
      ..quadraticBezierTo(7, 12, 5, 5),
    p,
  );
  _dot(c, p, 12, 12, 0.8);
  // corner ticks
  c.drawPath(Path()..moveTo(5, 5)..lineTo(3.3, 3.3)..moveTo(19, 5)..lineTo(20.7, 3.3)..moveTo(5, 19)..lineTo(3.3, 20.7)..moveTo(19, 19)..lineTo(20.7, 20.7), p);
}

void _tableCloth(Canvas c, Paint p) {
  // tabletop with draped cloth
  c.drawPath(
    Path()
      ..moveTo(3, 8)
      ..lineTo(21, 8)
      ..lineTo(21, 13)
      ..quadraticBezierTo(19.8, 14.5, 21, 16)
      ..moveTo(3, 8)
      ..lineTo(3, 13)
      ..quadraticBezierTo(4.2, 14.5, 3, 16),
    p,
  );
  // cloth hem wave
  c.drawPath(Path()..moveTo(3, 12)..lineTo(21, 12), p);
  // table legs
  c.drawPath(Path()..moveTo(7.5, 12.5)..lineTo(7.5, 20)..moveTo(16.5, 12.5)..lineTo(16.5, 20), p);
}

const Map<String, _Draw> _drawers = {
  // Men
  'shirt': _shirt,
  'pant': _pant,
  'tshirt': _tshirt,
  'panjabi': _panjabi,
  'pajama': _pajama,
  'jubbah': _jubbah,
  'fatua': _fatua,
  'lungi': _lungi,
  'suit': _suit,
  'blazer': _blazer,
  'koti': _koti,
  'tie': _tie,
  'sweater': _sweater,
  'jacket': _jacket,
  'shawl': _shawl,
  // Women
  'three_piece': _threePiece,
  'borka': _borka,
  'dupatta': _dupatta,
  'hijab': _hijab,
  'blouse': _blouse,
  'saree': _saree,
  'lehenga': _lehenga,
  // Kids
  'kids_wear': _kidsWear,
  // Home
  'bedsheet': _bedsheet,
  'pillow_cover': _pillowCover,
  'towel': _towel,
  'blanket_regular': _blanketRegular,
  'blanket_heavy': _blanketHeavy,
  'curtain': _curtain,
  'sofa_cover': _sofaCover,
  'cushion_cover': _cushionCover,
  'table_cloth': _tableCloth,
};
