import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_theme.dart';
import '../data/receipt_data.dart';
import '../widgets/receipt_view.dart';
import '../widgets/app_button.dart';
import '../services/receipt_pdf_service.dart';

enum ReceiptViewerRole { customer, rider, admin }

/// Displays a pickup/delivery receipt with role-appropriate actions:
///  - Customer: View · Download PDF · Share
///  - Rider: View · Share · Show Receipt to Customer · Pickup Confirmation
///  - Admin: Print · Download PDF · Share PDF · Email Receipt
class ReceiptScreen extends StatefulWidget {
  final ReceiptData receipt;
  final ReceiptViewerRole role;
  final bool pickupConfirmed;
  final VoidCallback? onConfirmPickup;

  const ReceiptScreen({
    super.key,
    required this.receipt,
    required this.role,
    this.pickupConfirmed = false,
    this.onConfirmPickup,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _presenting = false;
  bool _busy = false;
  late bool _confirmed = widget.pickupConfirmed;

  // Wraps the off-screen 72mm POS receipt so we can capture it to an image.
  final GlobalKey _posKey = GlobalKey();

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রিসিট প্রস্তুত করতে সমস্যা হয়েছে। আবার চেষ্টা করুন।')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Captures the off-screen POS receipt widget to PNG bytes (+ pixel size).
  /// Flutter shapes the Bangla into the image, so the PDF never garbles it.
  Future<({Uint8List png, int w, int h})?> _capturePos() async {
    final boundary = _posKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    // High pixelRatio → a crisp, high-resolution invoice image (≈1200px wide
    // from the 400px logical card) so the printed/downloaded invoice is sharp
    // rather than soft/pixelated.
    final image = await boundary.toImage(pixelRatio: 3.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return null;
    return (png: data.buffer.asUint8List(), w: image.width, h: image.height);
  }

  Future<void> _print() async {
    final cap = await _capturePos();
    if (cap == null) return;
    await ReceiptPdfService.printPos(cap.png, cap.w, cap.h, widget.receipt.receiptNumber);
  }

  Future<void> _share() async {
    final cap = await _capturePos();
    if (cap == null) return;
    await ReceiptPdfService.sharePos(cap.png, cap.w, cap.h, widget.receipt.receiptNumber);
  }

  Future<void> _emailReceipt() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('ইমেইল রিসিট', style: AppText.h2),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'customer@email.com', prefixIcon: Icon(Icons.email_outlined, size: 20)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('পাঠান')),
        ],
      ),
    );
    if (email == null || email.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('রিসিট $email -এ পাঠানো হয়েছে')));
  }

  void _confirmPickup() {
    setState(() => _confirmed = true);
    widget.onConfirmPickup?.call();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('পিকআপ নিশ্চিত করা হয়েছে')));
  }

  @override
  Widget build(BuildContext context) {
    if (_presenting) return _presentationMode();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: Text(widget.receipt.type == ReceiptType.pickup ? 'পিকআপ রিসিট' : 'ডেলিভারি রিসিট')),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(AppSpace.sm),
              children: [
                ReceiptView(receipt: widget.receipt),
                const SizedBox(height: AppSpace.sm),
                _actionBar(),
              ],
            ),
            // Off-screen copy of the full receipt CARD (painted but shifted
            // out of view) that the print/share actions capture to a
            // Bangla-perfect, high-resolution image — the downloaded invoice
            // looks exactly like the on-screen card.
            Positioned(
              left: -3000,
              top: 0,
              child: RepaintBoundary(
                key: _posKey,
                child: Container(
                  width: 400,
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: ReceiptView(receipt: widget.receipt),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBar() {
    switch (widget.role) {
      case ReceiptViewerRole.customer:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _runAction(_print),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('ডাউনলোড'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy ? null : () => _runAction(_share),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('শেয়ার করুন'),
              ),
            ),
          ],
        );
      case ReceiptViewerRole.rider:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _runAction(_share),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('শেয়ার করুন'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _presenting = true),
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('কাস্টমারকে দেখান'),
                  ),
                ),
              ],
            ),
            if (widget.receipt.type == ReceiptType.pickup) ...[
              const SizedBox(height: 10),
              AppButton(
                label: _confirmed ? 'পিকআপ নিশ্চিত হয়েছে' : 'পিকআপ নিশ্চিত করুন',
                trailingIcon: _confirmed ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                color: _confirmed ? AppColors.green : AppColors.blue,
                onPressed: _confirmed ? null : _confirmPickup,
              ),
            ],
          ],
        );
      case ReceiptViewerRole.admin:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _runAction(_print),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('প্রিন্ট'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _runAction(_print),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('ডাউনলোড'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _runAction(_share),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('শেয়ার'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _emailReceipt,
                    icon: const Icon(Icons.email_rounded, size: 18),
                    label: const Text('ইমেইল'),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _presentationMode() {
    return Scaffold(
      backgroundColor: AppColors.blueDeep,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpace.xs),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _presenting = false),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text('কাস্টমারকে রিসিট দেখান', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.sm),
                children: [ReceiptView(receipt: widget.receipt)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

