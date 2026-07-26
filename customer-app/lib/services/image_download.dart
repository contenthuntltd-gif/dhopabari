// Saves a receipt PNG to the device — a real "download as photo":
//   • mobile → the phone's gallery (via gal)
//   • web    → a normal browser file download
// The platform-specific implementation is picked at compile time.
export 'image_download_io.dart' if (dart.library.html) 'image_download_web.dart';
