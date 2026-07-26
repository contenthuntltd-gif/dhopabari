import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Web: trigger a normal browser download of the PNG.
Future<void> downloadReceiptImage(Uint8List png, String name) async {
  final blob = html.Blob(<Object>[png], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = '$name.png'
    ..style.display = 'none'
    ..click();
  html.Url.revokeObjectUrl(url);
}
