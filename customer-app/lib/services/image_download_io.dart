import 'dart:typed_data';
import 'package:gal/gal.dart';

/// Mobile: save the PNG straight into the phone's photo gallery.
Future<void> downloadReceiptImage(Uint8List png, String name) async {
  await Gal.putImageBytes(png, name: name);
}
