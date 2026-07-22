import 'package:flutter/material.dart';
import '../data/receipt_data.dart';
import 'app_logo.dart';

/// A compact, 72mm-thermal-printer-styled receipt. Deliberately narrow,
/// black-on-white and tightly spaced so it fits a POS roll with little
/// wasted paper.
///
/// Crucially this is a real Flutter widget: rendered by Flutter it shapes
/// Bengali correctly (conjuncts and all). The PDF/download path captures
/// THIS widget to an image and drops it onto a 72mm page — which is why the
/// downloaded invoice no longer garbles Bangla the way a text-based PDF did.
class ReceiptPosView extends StatelessWidget {
  final ReceiptData receipt;

  /// Logical width of the render. ~300 keeps text crisp when scaled to 72mm.
  static const double width = 300;

  const ReceiptPosView({super.key, required this.receipt});

  static const _ink = Color(0xFF000000);
  static const _muted = Color(0xFF444444);

  bool get _isPickup => receipt.type == ReceiptType.pickup;
  bool get _isDelivery => receipt.type == ReceiptType.delivery;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand
          Center(child: AppLogo(size: 46)),
          const SizedBox(height: 6),
          const Center(child: Text('ধোপা বাড়ি', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink, height: 1.1))),
          const Center(child: Text('কাপড়ের যত্নে আপনার বিশ্বস্ত পার্টনার', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: _muted, height: 1.2))),
          const Center(child: Text('কক্সবাজার সদর • 01700000000', style: TextStyle(fontSize: 9, color: _muted))),
          const SizedBox(height: 8),
          _dashed(),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _isPickup ? 'পিকআপ মেমো' : (_isDelivery ? 'ডেলিভারি মেমো' : 'পেমেন্ট রিসিট'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _ink, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 6),
          _kv('রিসিট নং', receipt.receiptNumber),
          _kv('তারিখ', _fmtDate(receipt.issuedAt)),
          const SizedBox(height: 6),
          _dashed(),
          const SizedBox(height: 6),
          _kv('অর্ডার', receipt.orderId),
          _kv('কাস্টমার', receipt.customerName),
          _kv('ফোন', receipt.customerPhone),
          if (_isPickup && (receipt.pickupAddress?.isNotEmpty ?? false)) _kv('ঠিকানা', receipt.pickupAddress!),
          if (receipt.riderName != null) _kv('রাইডার', receipt.riderName!),
          const SizedBox(height: 6),
          _dashed(),
          const SizedBox(height: 4),
          // Items header
          Row(
            children: const [
              Expanded(flex: 5, child: Text('আইটেম', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: _ink))),
              Expanded(flex: 2, child: Text('পরিমাণ', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: _ink))),
              Expanded(flex: 3, child: Text('মোট', textAlign: TextAlign.right, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: _ink))),
            ],
          ),
          const SizedBox(height: 2),
          _thin(),
          for (final it in receipt.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.itemName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _ink, height: 1.15)),
                        Text('${it.service} • ৳${it.unitPrice}', style: const TextStyle(fontSize: 8.5, color: _muted)),
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: Text('${it.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _ink))),
                  Expanded(flex: 3, child: Text('৳${it.total}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _ink))),
                ],
              ),
            ),
          const SizedBox(height: 4),
          _dashed(),
          const SizedBox(height: 4),
          _total('মোট পরিমাণ', '${receipt.totalQuantity} পিস'),
          _total('সাবটোটাল', '৳${receipt.subtotal}'),
          _total('ডেলিভারি', receipt.deliveryFee == 0 ? 'ফ্রি' : '৳${receipt.deliveryFee}'),
          if (receipt.expressCharge > 0) _total('এক্সপ্রেস', '৳${receipt.expressCharge}'),
          if (receipt.discount > 0) _total('ছাড়', '-৳${receipt.discount}'),
          const SizedBox(height: 3),
          _thin(),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('সর্বমোট', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _ink)),
              Text('৳${receipt.grandTotal}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink)),
            ],
          ),
          const SizedBox(height: 10),
          _dashed(),
          const SizedBox(height: 6),
          const Center(child: Text('ধন্যবাদ! আবার আসবেন 🙏', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: _ink))),
          const SizedBox(height: 2),
          const Center(child: Text('অফিস সময়: ৯:০০ AM – ৯:০০ PM', style: TextStyle(fontSize: 8.5, color: _muted))),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 62, child: Text(k, style: const TextStyle(fontSize: 9.5, color: _muted))),
          const Text(': ', style: TextStyle(fontSize: 9.5, color: _muted)),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _ink, height: 1.2))),
        ],
      ),
    );
  }

  Widget _total(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontSize: 10, color: _muted)),
          Text(v, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _ink)),
        ],
      ),
    );
  }

  Widget _dashed() => const _DashedLine(color: _ink);
  Widget _thin() => Container(height: 0.6, color: const Color(0xFFBBBBBB));

  static String _fmtDate(DateTime dt) {
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day}/${dt.month}/${dt.year}, $h12:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}

class _DashedLine extends StatelessWidget {
  final Color color;
  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const dash = 3.0, gap = 2.5;
        final count = (c.maxWidth / (dash + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => SizedBox(width: dash, height: 1, child: DecoratedBox(decoration: BoxDecoration(color: color))),
          ),
        );
      },
    );
  }
}
