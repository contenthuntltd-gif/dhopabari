import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds a 72mm thermal-POS receipt PDF from an image captured off the
/// [ReceiptPosView] widget, then prints/shares it.
///
/// Why image-based: the `pdf` package can't shape Bengali conjuncts, so a
/// text-based invoice comes out garbled ("Gor Gor"). Rendering the receipt
/// as a Flutter widget shapes Bangla correctly; we capture that to an image
/// and drop it on a 72mm page — pixel-perfect Bangla, POS-printer sized.
class ReceiptPdfService {
  /// Wraps a captured receipt image onto a 72mm-wide page (zero margin),
  /// height following the image's aspect ratio.
  static Future<Uint8List> posPdfFromImage(Uint8List png, int pxW, int pxH) async {
    final doc = pw.Document();
    final img = pw.MemoryImage(png);
    const widthMm = 72.0;
    final heightMm = widthMm * pxH / pxW;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(widthMm * PdfPageFormat.mm, heightMm * PdfPageFormat.mm, marginAll: 0),
        build: (context) => pw.Image(img, fit: pw.BoxFit.fitWidth),
      ),
    );
    return doc.save();
  }

  static Future<void> printPos(Uint8List png, int w, int h, String name) async {
    final bytes = await posPdfFromImage(png, w, h);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: '$name.pdf');
  }

  static Future<void> sharePos(Uint8List png, int w, int h, String name) async {
    final bytes = await posPdfFromImage(png, w, h);
    await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
  }
}
