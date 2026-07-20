import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Wraps the app so that on Flutter **Web** it always renders inside a
/// fixed-width mobile-sized frame — centered on the page, rounded corners,
/// soft shadow — instead of stretching to fill the browser window. On real
/// mobile builds (Android/iOS) this is a no-op passthrough since the app is
/// already running at native phone size.
class PhoneFrame extends StatelessWidget {
  final Widget child;
  static const double frameWidth = 412;
  static const double verticalMargin = 24;

  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return ColoredBox(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < frameWidth ? constraints.maxWidth : frameWidth;
            final fitsMargin = constraints.maxHeight > verticalMargin * 2 + 200;
            final height = fitsMargin ? constraints.maxHeight - verticalMargin * 2 : constraints.maxHeight;

            return Container(
              width: width,
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 48, offset: const Offset(0, 20)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(size: Size(width, height)),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}
