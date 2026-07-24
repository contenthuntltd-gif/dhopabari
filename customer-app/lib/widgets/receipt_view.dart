import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../data/receipt_data.dart';
import 'bn_number.dart';
import 'app_logo.dart';

/// The premium on-screen receipt — a white card with a blue header,
/// item table, notes, and future-ready signature boxes. Used identically
/// by Customer, Rider and Admin (only the action bar below it differs per
/// role); `receipt_pdf_service.dart` renders the same layout to PDF.
class ReceiptView extends StatelessWidget {
  final ReceiptData receipt;
  const ReceiptView({super.key, required this.receipt});

  bool get _isPickup => receipt.type == ReceiptType.pickup;
  bool get _isDelivery => receipt.type == ReceiptType.delivery;
  bool get _isPayment => receipt.type == ReceiptType.payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          Padding(
            padding: const EdgeInsets.all(AppSpace.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _infoGrid(),
                const SizedBox(height: AppSpace.sm),
                const _SectionDivider(label: 'আইটেম সামারি'),
                const SizedBox(height: AppSpace.xs),
                _itemsTable(),
                const SizedBox(height: AppSpace.xs),
                _totalsBlock(),
                if (_hasNotes) ...[
                  const SizedBox(height: AppSpace.sm),
                  const _SectionDivider(label: 'কাস্টমার নোট'),
                  const SizedBox(height: AppSpace.xs),
                  _notesBlock(),
                ],
                if (_isDelivery) ...[
                  const SizedBox(height: AppSpace.sm),
                  const _SectionDivider(label: 'ডেলিভারি নিশ্চিতকরণ'),
                  const SizedBox(height: AppSpace.xs),
                  _deliveryConfirmationBlock(),
                ],
                if (!_isPayment) ...[
                  const SizedBox(height: AppSpace.sm),
                  const _SectionDivider(label: 'স্বাক্ষর'),
                  const SizedBox(height: AppSpace.xs),
                  _signatureRow(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasNotes =>
      (receipt.specialInstructions?.isNotEmpty ?? false) ||
      (receipt.stainNotes?.isNotEmpty ?? false) ||
      (receipt.fragileNotes?.isNotEmpty ?? false) ||
      (receipt.otherNotes?.isNotEmpty ?? false);

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.sm, AppSpace.sm, AppSpace.sm),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.blue, AppColors.blueDeep], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLogo(size: 46, rounded: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPickup ? 'PICKUP MEMO' : (_isDelivery ? 'DELIVERY MEMO' : 'PAYMENT RECEIPT'),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(receipt.receiptNumber, style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(_formatDateTime(receipt.issuedAt), style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: QrImageView(data: receipt.qrPayload, size: 56, backgroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _infoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [Expanded(child: _infoTile('অর্ডার আইডি', receipt.orderId)), const SizedBox(width: 10), Expanded(child: _infoTile('রিসিট আইডি', receipt.receiptNumber))]),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: _infoTile('কাস্টমার নাম', receipt.customerName)), const SizedBox(width: 10), Expanded(child: _infoTile('কাস্টমার ফোন', receipt.customerPhone))]),
        // Customer location — shown on every receipt type (pickup / delivery /
        // payment memo) whenever an address is available.
        if (receipt.pickupAddress != null && receipt.pickupAddress!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          _infoTile(_isPickup ? 'পিকআপ ঠিকানা' : 'কাস্টমার ঠিকানা', receipt.pickupAddress!),
        ],
        if (_isPickup && receipt.estimatedDelivery != null) ...[
          const SizedBox(height: 8),
          _infoTile('আনুমানিক ডেলিভারি', receipt.estimatedDelivery!),
        ],
        if (_isPayment) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _infoTile('পেমেন্ট পদ্ধতি', receipt.paymentMethod ?? '—')),
            const SizedBox(width: 10),
            Expanded(child: _infoTile('পেমেন্ট স্ট্যাটাস', receipt.paymentStatus ?? '—')),
          ]),
        ],
        if (receipt.riderName != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _infoTile('রাইডার নাম', receipt.riderName!)),
            const SizedBox(width: 10),
            Expanded(child: _infoTile('রাইডার আইডি', receipt.riderId ?? '—')),
          ]),
          const SizedBox(height: 8),
          _infoTile('রাইডার ফোন', receipt.riderPhone ?? '—'),
        ],
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _itemsTable() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(AppRadius.sm)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.paper,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('আইটেম', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted))),
                Expanded(flex: 2, child: Text('সার্ভিস', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted))),
                SizedBox(width: 34, child: Text('পরি', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('মূল্য', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text('মোট', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted), textAlign: TextAlign.right)),
              ],
            ),
          ),
          for (final item in receipt.items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(item.itemName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink))),
                  Expanded(flex: 2, child: Text(item.service, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600))),
                  SizedBox(width: 34, child: Text(toBn(item.quantity), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text(money(item.unitPrice), style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                  Expanded(flex: 2, child: Text(money(item.total), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink), textAlign: TextAlign.right)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _totalsBlock() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Column(
        children: [
          _totalRow('মোট পরিমাণ', '${toBn(receipt.totalQuantity)} পিস'),
          _totalRow('সাবটোটাল', money(receipt.subtotal)),
          _totalRow('ডেলিভারি চার্জ', receipt.deliveryFee == 0 ? 'ফ্রি' : money(receipt.deliveryFee), highlight: receipt.deliveryFee == 0),
          if (receipt.expressCharge > 0) _totalRow('⚡ এক্সপ্রেস চার্জ', money(receipt.expressCharge)),
          if (receipt.discount > 0) _totalRow('ছাড়', '-${money(receipt.discount)}', highlight: true),
          const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(height: 1, color: AppColors.line)),
          _totalRow('সর্বমোট', money(receipt.grandTotal), bold: true),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool highlight = false, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: bold ? 13.5 : 12, color: bold ? AppColors.ink : AppColors.muted, fontWeight: bold ? FontWeight.w900 : FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: bold ? 16 : 12.5, color: bold ? AppColors.blue : (highlight ? AppColors.teal : AppColors.ink), fontWeight: bold ? FontWeight.w900 : FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _notesBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (receipt.specialInstructions?.isNotEmpty ?? false) _noteRow(Icons.info_outline_rounded, 'বিশেষ নির্দেশনা', receipt.specialInstructions!),
        if (receipt.stainNotes?.isNotEmpty ?? false) _noteRow(Icons.water_drop_outlined, 'দাগের নোট', receipt.stainNotes!),
        if (receipt.fragileNotes?.isNotEmpty ?? false) _noteRow(Icons.warning_amber_rounded, 'ভঙ্গুর কাপড়', receipt.fragileNotes!),
        if (receipt.otherNotes?.isNotEmpty ?? false) _noteRow(Icons.notes_rounded, 'অন্যান্য নোট', receipt.otherNotes!),
      ],
    );
  }

  Widget _noteRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSize.sm, color: AppColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w700)),
                Text(value, style: const TextStyle(fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deliveryConfirmationBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: _infoTile('ডেলিভারি দিয়েছেন', receipt.deliveredBy ?? '—')),
          const SizedBox(width: 10),
          Expanded(child: _infoTile('ডেলিভারির সময়', _formatDateTime(receipt.issuedAt))),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: receipt.customerConfirmed ? AppColors.tealSoft : AppColors.amberSoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              Icon(
                receipt.customerConfirmed ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                size: AppIconSize.md,
                color: receipt.customerConfirmed ? AppColors.teal : AppColors.amber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  receipt.customerConfirmed ? 'অর্ডার সম্পন্ন — কাস্টমার নিশ্চিত করেছেন' : 'কাস্টমারের নিশ্চিতকরণের অপেক্ষায়',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: receipt.customerConfirmed ? const Color(0xFF0B6B62) : const Color(0xFF8A5A00)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _signatureRow() {
    return Row(
      children: [
        Expanded(child: _signatureBox('কাস্টমার স্বাক্ষর')),
        const SizedBox(width: 10),
        Expanded(child: _signatureBox('রাইডার স্বাক্ষর')),
      ],
    );
  }

  Widget _signatureBox(String label) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line, width: 1.2),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.draw_outlined, size: AppIconSize.md, color: AppColors.muted),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
          const Text('(শীঘ্রই আসছে)', style: TextStyle(fontSize: 8.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    const months = ['জানু', 'ফেব্রু', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    final minute = dt.minute.toString().padLeft(2, '0').split('').map((c) => bnDigits[int.parse(c)]).join();
    return '${toBn(dt.day)} ${months[dt.month - 1]}, ${toBn(hour12)}:$minute $ampm';
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.blue, letterSpacing: 0.3)),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: AppColors.line, height: 1)),
      ],
    );
  }
}
