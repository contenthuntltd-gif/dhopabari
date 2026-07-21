import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Wraps the app so that on Flutter **Web** it always renders inside a
/// fixed-width mobile-sized frame — centered on the page, rounded corners,
/// soft shadow — instead of stretching to fill the browser window. On real
/// mobile builds (Android/iOS) this is a no-op passthrough since the app is
/// already running at native phone size.
///
/// Exception: the **Admin panel** is a desktop product. While it is on
/// screen it flips [fullScreen] on, and the frame steps aside so the admin
/// dashboard fills the whole browser window. The customer/rider apps stay
/// phone-framed.
class PhoneFrame extends StatelessWidget {
  final Widget child;
  static const double frameWidth = 412;
  static const double verticalMargin = 24;

  /// At or below this viewport width we treat it as a real phone and fill
  /// the whole screen — no mock frame, no rounded corners, no margins. Wider
  /// viewports (tablet / desktop) get the centered phone mock-up.
  static const double phoneBreakpoint = 500;

  /// When true, the web phone frame is bypassed and [child] fills the
  /// window. Toggled by the admin shell (see AdminRootShell) on mount/unmount.
  static final ValueNotifier<bool> fullScreen = ValueNotifier(false);

  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return ValueListenableBuilder<bool>(
      valueListenable: fullScreen,
      builder: (context, isFull, _) {
        // Admin panel → always full screen. A phone-sized browser → full
        // screen too, so mobile users get a native, edge-to-edge app.
        if (isFull) return child;
        final width = MediaQuery.sizeOf(context).width;
        if (width <= phoneBreakpoint) return child;
        return _framed();
      },
    );
  }

  Widget _framed() {
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
