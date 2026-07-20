import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/receipt_data.dart';

/// Renders a [ReceiptData] to PDF bytes using the exact same information
/// as `widgets/receipt_view.dart`'s on-screen card — one layout, two
/// renderers — then exposes print/share/download actions built on top of
/// the `printing` package (works on web, Android and iOS).
class ReceiptPdfService {
  static const _blue = PdfColor.fromInt(0xFF1259E8);
  static const _blueDeep = PdfColor.fromInt(0xFF0A3FB0);
  static const _ink = PdfColor.fromInt(0xFF0B1F3A);
  static const _muted = PdfColor.fromInt(0xFF66748F);
  static const _line = PdfColor.fromInt(0xFFE7EBF3);
  static const _paper = PdfColor.fromInt(0xFFF5F7FB);
  static const _teal = PdfColor.fromInt(0xFF0EA5A0);
  static const _amber = PdfColor.fromInt(0xFFE8A93A);

  static Future<Uint8List> _logoBytes() async {
    final data = await rootBundle.load('assets/branding/dhopa_bari_logo.png');
    return data.buffer.asUint8List();
  }

  static Future<Uint8List> buildPdfBytes(ReceiptData receipt) async {
    final doc = pw.Document();
    final logo = pw.MemoryImage(await _logoBytes());
    final isPickup = receipt.type == ReceiptType.pickup;
    final isDelivery = receipt.type == ReceiptType.delivery;
    final isPayment = receipt.type == ReceiptType.payment;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _pdfHeader(logo, receipt, isPickup, isDelivery),
              pw.SizedBox(height: 16),
              _pdfInfoGrid(receipt, isPickup, isPayment),
              pw.SizedBox(height: 16),
              _sectionLabel('আইটেম সামারি'),
              pw.SizedBox(height: 8),
              _pdfItemsTable(receipt),
              pw.SizedBox(height: 10),
              _pdfTotals(receipt),
              if (_hasNotes(receipt)) ...[
                pw.SizedBox(height: 16),
                _sectionLabel('কাস্টমার নোট'),
                pw.SizedBox(height: 8),
                _pdfNotes(receipt),
              ],
              if (isDelivery) ...[
                pw.SizedBox(height: 16),
                _sectionLabel('ডেলিভারি নিশ্চিতকরণ'),
                pw.SizedBox(height: 8),
                _pdfDeliveryStatus(receipt),
              ],
              if (!isPayment) ...[
                pw.SizedBox(height: 16),
                _sectionLabel('স্বাক্ষর'),
                pw.SizedBox(height: 8),
                _pdfSignatureRow(),
              ],
              pw.SizedBox(height: 18),
              pw.Center(
                child: pw.Text('ধোপা বাড়ি — কাপড়ের যত্নে আপনার বিশ্বস্ত পার্টনার', style: const pw.TextStyle(color: _muted, fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  static bool _hasNotes(ReceiptData r) =>
      (r.specialInstructions?.isNotEmpty ?? false) || (r.stainNotes?.isNotEmpty ?? false) || (r.fragileNotes?.isNotEmpty ?? false) || (r.otherNotes?.isNotEmpty ?? false);

  static pw.Widget _sectionLabel(String label) {
    return pw.Row(children: [
      pw.Text(label, style: pw.TextStyle(color: _blue, fontSize: 10, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(width: 8),
      pw.Expanded(child: pw.Container(height: 0.75, color: _line)),
    ]);
  }

  static pw.Widget _pdfHeader(pw.MemoryImage logo, ReceiptData r, bool isPickup, bool isDelivery) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(colors: [_blue, _blueDeep], begin: pw.Alignment.topLeft, end: pw.Alignment.bottomRight),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 44, height: 44, decoration: const pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))), child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Image(logo))),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(isPickup ? 'PICKUP MEMO' : (isDelivery ? 'DELIVERY MEMO' : 'PAYMENT RECEIPT'), style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(r.receiptNumber, style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                pw.Text(_formatDateTime(r.issuedAt), style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
              ],
            ),
          ),
          pw.Container(
            width: 56,
            height: 56,
            padding: const pw.EdgeInsets.all(4),
            decoration: const pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
            child: pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: r.qrPayload),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfInfoGrid(ReceiptData r, bool isPickup, bool isPayment) {
    final rows = <List<String>>[
      ['অর্ডার আইডি', r.orderId, 'রিসিট আইডি', r.receiptNumber],
      ['কাস্টমার নাম', r.customerName, 'কাস্টমার ফোন', r.customerPhone],
      if (isPickup && r.pickupAddress != null) ['পিকআপ ঠিকানা', r.pickupAddress!, '', ''],
      if (isPickup && r.estimatedDelivery != null) ['আনুমানিক ডেলিভারি', r.estimatedDelivery!, '', ''],
      if (isPayment) ['পেমেন্ট পদ্ধতি', r.paymentMethod ?? '—', 'পেমেন্ট স্ট্যাটাস', r.paymentStatus ?? '—'],
      if (r.riderName != null) ['রাইডার নাম', r.riderName!, 'রাইডার আইডি', r.riderId ?? '—'],
      if (r.riderPhone != null) ['রাইডার ফোন', r.riderPhone!, '', ''],
    ];
    return pw.Column(
      children: rows
          .map((row) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(children: [
                  pw.Expanded(child: _pdfInfoTile(row[0], row[1])),
                  if (row[2].isNotEmpty) pw.SizedBox(width: 10),
                  if (row[2].isNotEmpty) pw.Expanded(child: _pdfInfoTile(row[2], row[3])),
                ]),
              ))
          .toList(),
    );
  }

  static pw.Widget _pdfInfoTile(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(color: _muted, fontSize: 8)),
        pw.SizedBox(height: 1),
        pw.Text(value, style: pw.TextStyle(color: _ink, fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _pdfItemsTable(ReceiptData r) {
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.6),
      columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(1), 3: pw.FlexColumnWidth(1.6), 4: pw.FlexColumnWidth(1.6)},
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _paper),
          children: [
            _th('আইটেম'),
            _th('সার্ভিস'),
            _th('পরিমাণ'),
            _th('মূল্য'),
            _th('মোট'),
          ],
        ),
        for (final item in r.items)
          pw.TableRow(children: [
            _td(item.itemName, bold: true),
            _td(item.service),
            _td('${item.quantity}', align: pw.TextAlign.center),
            _td('৳${item.unitPrice}', align: pw.TextAlign.right),
            _td('৳${item.total}', align: pw.TextAlign.right, bold: true),
          ]),
      ],
    );
  }

  static pw.Widget _th(String text) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _muted)));

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text, textAlign: align, style: pw.TextStyle(fontSize: 9.5, color: _ink, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

  static pw.Widget _pdfTotals(ReceiptData r) {
    pw.Widget row(String label, String value, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: bold ? 11 : 9.5, color: bold ? _ink : _muted, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
              pw.Text(value, style: pw.TextStyle(fontSize: bold ? 13 : 10, color: bold ? _blue : _ink, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(color: _paper, borderRadius: pw.BorderRadius.all(pw.Radius.circular(6))),
      child: pw.Column(children: [
        row('মোট পরিমাণ', '${r.totalQuantity} পিস'),
        row('সাবটোটাল', '৳${r.subtotal}'),
        row('ডেলিভারি চার্জ', r.deliveryFee == 0 ? 'ফ্রি' : '৳${r.deliveryFee}'),
        if (r.expressCharge > 0) row('এক্সপ্রেস চার্জ', '৳${r.expressCharge}'),
        if (r.discount > 0) row('ছাড়', '-৳${r.discount}'),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Container(height: 0.75, color: _line)),
        row('সর্বমোট', '৳${r.grandTotal}', bold: true),
      ]),
    );
  }

  static pw.Widget _pdfNotes(ReceiptData r) {
    pw.Widget note(String label, String? value) {
      if (value == null || value.isEmpty) return pw.SizedBox();
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontSize: 9.5, color: _muted, fontWeight: pw.FontWeight.bold)),
            pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 9.5, color: _ink)),
          ]),
        ),
      );
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      note('বিশেষ নির্দেশনা', r.specialInstructions),
      note('দাগের নোট', r.stainNotes),
      note('ভঙ্গুর কাপড়', r.fragileNotes),
      note('অন্যান্য নোট', r.otherNotes),
    ]);
  }

  static pw.Widget _pdfDeliveryStatus(ReceiptData r) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: r.customerConfirmed ? PdfColor.fromInt(0xFFE1F7F4) : PdfColor.fromInt(0xFFFDF3E0), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
      child: pw.Text(
        r.customerConfirmed ? 'অর্ডার সম্পন্ন — কাস্টমার নিশ্চিত করেছেন (ডেলিভারি দিয়েছেন: ${r.deliveredBy ?? "—"})' : 'কাস্টমারের নিশ্চিতকরণের অপেক্ষায় (ডেলিভারি দিয়েছেন: ${r.deliveredBy ?? "—"})',
        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: r.customerConfirmed ? _teal : _amber),
      ),
    );
  }

  static pw.Widget _pdfSignatureRow() {
    pw.Widget box(String label) => pw.Expanded(
          child: pw.Container(
            height: 50,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(border: pw.Border.all(color: _line, width: 0.75), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
            child: pw.Text('$label (শীঘ্রই আসছে)', style: const pw.TextStyle(fontSize: 8, color: _muted)),
          ),
        );
    return pw.Row(children: [box('কাস্টমার স্বাক্ষর'), pw.SizedBox(width: 10), box('রাইডার স্বাক্ষর')]);
  }

  static String _formatDateTime(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day}/${dt.month}/${dt.year}, $hour12:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  // ── Actions ────────────────────────────────────────────────────────

  static Future<void> print(ReceiptData receipt) async {
    final bytes = await buildPdfBytes(receipt);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: '${receipt.receiptNumber}.pdf');
  }

  static Future<void> shareOrDownload(ReceiptData receipt) async {
    final bytes = await buildPdfBytes(receipt);
    await Printing.sharePdf(bytes: bytes, filename: '${receipt.receiptNumber}.pdf');
  }
}
