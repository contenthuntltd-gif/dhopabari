/// A cross-platform "reload the app to home" — real implementation on web,
/// a no-op elsewhere. Used by logout to guarantee a clean fresh start.
export 'web_reload_stub.dart' if (dart.library.html) 'web_reload_html.dart';
