import 'package:flutter/material.dart';

/// Centers [child] and caps its width. On a phone (viewport narrower than
/// [maxWidth]) it is a transparent passthrough; on a wide desktop window it
/// keeps detail pages from stretching edge-to-edge into sparse, hard-to-read
/// full-width rows.
class CenteredMaxWidth extends StatelessWidget {
  final double maxWidth;
  final Widget child;
  const CenteredMaxWidth({super.key, this.maxWidth = 960, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
