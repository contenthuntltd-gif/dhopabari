import 'mock_data.dart';
import 'admin_mock_data.dart';
import 'business_info.dart';

enum ReceiptType { pickup, delivery, payment }

class ReceiptItem {
  final String itemName;
  final String service;
  final int quantity;
  final int unitPrice;
  const ReceiptItem({required this.itemName, required this.service, required this.quantity, required this.unitPrice});

  int get total => unitPrice * quantity;
}

/// A single pickup / delivery / payment memo. Mirrors
/// `backend/prisma/schema.prisma`'s `Receipt` model field-for-field so
/// wiring this up to the real API later is a drop-in replacement, not a
/// rewrite. Every memo ever generated is kept in [ReceiptData.all] for the
/// lifetime of the app session — mirrors the backend rule that memos are
/// permanent and never overwritten (see Admin > Memo Center).
class ReceiptData {
  final String receiptNumber;
  final String orderId;
  final ReceiptType type;
  final DateTime issuedAt;

  final String customerName;
  final String customerPhone;
  final String customerId;

  final String? riderName;
  final String? riderId;
  final String? riderPhone;

  final String? pickupAddress;
  final String? estimatedDelivery;
  final String? deliveredBy;
  final bool customerConfirmed;

  final List<ReceiptItem> items;
  final int deliveryFee;
  final int expressCharge;
  final int discount;

  final String? paymentMethod;
  final String? paymentStatus;

  final String? specialInstructions;
  final String? stainNotes;
  final String? fragileNotes;
  final String? otherNotes;

  ReceiptData({
    required this.receiptNumber,
    required this.orderId,
    required this.type,
    required this.issuedAt,
    required this.customerName,
    required this.customerPhone,
    required this.customerId,
    this.riderName,
    this.riderId,
    this.riderPhone,
    this.pickupAddress,
    this.estimatedDelivery,
    this.deliveredBy,
    this.customerConfirmed = false,
    required this.items,
    this.deliveryFee = 0,
    this.expressCharge = 0,
    this.discount = 0,
    this.paymentMethod,
    this.paymentStatus,
    this.specialInstructions,
    this.stainNotes,
    this.fragileNotes,
    this.otherNotes,
  }) {
    _all.add(this);
  }

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);
  int get subtotal => items.fold(0, (sum, i) => sum + i.total);
  int get grandTotal => (subtotal + deliveryFee + expressCharge - discount).clamp(0, 1 << 31);

  /// Encoded into the on-receipt QR code — order, customer and receipt
  /// identity in one scan, per the spec.
  String get qrPayload => 'orderId:$orderId;customerId:$customerId;receiptId:$receiptNumber';

  // ── Permanent, append-only, in-memory "database" of every memo ─────
  // generated this session (stands in for the backend `receipts` table
  // until this screen is wired to the live API).
  static final List<ReceiptData> _all = [];
  static List<ReceiptData> get all => List.unmodifiable(_all.reversed);

  static List<ReceiptData> search({String? memoNumber, String? orderId, String? customer, String? rider, String? phone, DateTime? date}) {
    return _all.reversed.where((r) {
      if (memoNumber != null && memoNumber.isNotEmpty && !r.receiptNumber.toLowerCase().contains(memoNumber.toLowerCase())) return false;
      if (orderId != null && orderId.isNotEmpty && !r.orderId.toLowerCase().contains(orderId.toLowerCase())) return false;
      if (customer != null && customer.isNotEmpty && !r.customerName.toLowerCase().contains(customer.toLowerCase())) return false;
      if (rider != null && rider.isNotEmpty && !(r.riderName?.toLowerCase().contains(rider.toLowerCase()) ?? false)) return false;
      if (phone != null && phone.isNotEmpty && !r.customerPhone.contains(phone)) return false;
      if (date != null && !(r.issuedAt.year == date.year && r.issuedAt.month == date.month && r.issuedAt.day == date.day)) return false;
      return true;
    }).toList();
  }

  static int _receiptSeq = 122;
  static String _nextNumber() {
    _receiptSeq++;
    return 'DB-MEMO-2026-${_receiptSeq.toString().padLeft(6, '0')}';
  }

  /// Best-effort reconstruction of a line-item breakdown for a [MockOrder]
  /// that only carries aggregate pieces/total (no per-item mock data
  /// exists yet). Once orders are backed by the real API this factory is
  /// replaced by simply reading `Receipt.items` from the server.
  static List<ReceiptItem> _reconstructItems(MockOrder order) {
    // Real orders carry their exact items — print those, never a guess.
    if (order.items.isNotEmpty) {
      return [
        for (final it in order.items)
          ReceiptItem(
            itemName: (it['name_bn'] as String?) ?? (it['name'] as String?) ?? '—',
            service: (it['service'] as String?) ?? order.service,
            quantity: (it['qty'] as num?)?.toInt() ?? 1,
            unitPrice: (it['unit_price'] as num?)?.toInt() ?? 0,
          ),
      ];
    }

    final candidates = MockData.priceItems.toList();
    final items = <ReceiptItem>[];
    var remainingPieces = order.pieces;
    var i = 0;
    while (remainingPieces > 0 && candidates.isNotEmpty) {
      final item = candidates[i % candidates.length];
      final qty = remainingPieces >= 2 ? 2 : remainingPieces;
      final price = order.service == 'Wash' ? item.washPrice : item.dryPrice;
      items.add(ReceiptItem(itemName: item.nameBn, service: order.service, quantity: qty, unitPrice: price));
      remainingPieces -= qty;
      i++;
    }
    return items;
  }

  factory ReceiptData.pickupFor(MockOrder order, {String? specialInstructions, String? stainNotes, String? fragileNotes, String? otherNotes}) {
    return ReceiptData(
      receiptNumber: _nextNumber(),
      orderId: order.id,
      type: ReceiptType.pickup,
      issuedAt: DateTime.now(),
      customerName: MockData.userName,
      customerPhone: MockData.userPhone,
      customerId: 'CUST-${MockData.userPhone}',
      riderName: order.riderName,
      riderId: order.riderName == null ? null : 'RDR-1042',
      riderPhone: order.riderPhone,
      pickupAddress: order.area,
      estimatedDelivery: DeliveryOptions.free.eta,
      items: _reconstructItems(order),
      specialInstructions: specialInstructions,
      stainNotes: stainNotes,
      fragileNotes: fragileNotes,
      otherNotes: otherNotes,
    );
  }

  factory ReceiptData.deliveryFor(MockOrder order) {
    return ReceiptData(
      receiptNumber: _nextNumber(),
      orderId: order.id,
      type: ReceiptType.delivery,
      issuedAt: DateTime.now(),
      customerName: MockData.userName,
      customerPhone: MockData.userPhone,
      customerId: 'CUST-${MockData.userPhone}',
      riderName: order.riderName ?? 'করিম ভাই',
      riderId: 'RDR-1042',
      riderPhone: order.riderPhone,
      deliveredBy: order.riderName ?? 'করিম ভাই',
      customerConfirmed: order.progress >= 1,
      items: _reconstructItems(order),
    );
  }

  factory ReceiptData.paymentFor(MockOrder order) {
    return ReceiptData(
      receiptNumber: _nextNumber(),
      orderId: order.id,
      type: ReceiptType.payment,
      issuedAt: DateTime.now(),
      customerName: MockData.userName,
      customerPhone: MockData.userPhone,
      customerId: 'CUST-${MockData.userPhone}',
      items: _reconstructItems(order),
      paymentMethod: 'নগদ (COD)',
      paymentStatus: order.progress >= 1 ? 'পরিশোধিত' : 'বাকি',
    );
  }

  /// Line items for an [AdminOrder]'s memo. Real orders carry their actual
  /// items (snapshotted at placement, each with its own service and price) —
  /// those are printed verbatim. Only legacy/mock orders with no stored
  /// items fall back to the old best-effort reconstruction.
  static List<ReceiptItem> _reconstructAdminItems(AdminOrder order) {
    if (order.items.isNotEmpty) {
      return [
        for (final it in order.items)
          ReceiptItem(
            itemName: (it['name_bn'] as String?) ?? (it['name'] as String?) ?? '—',
            service: (it['service'] as String?) ?? order.service,
            quantity: (it['qty'] as num?)?.toInt() ?? 1,
            unitPrice: (it['unit_price'] as num?)?.toInt() ?? 0,
          ),
      ];
    }

    final candidates = MockData.priceItems.toList();
    final items = <ReceiptItem>[];
    var remainingPieces = order.pieces;
    var i = 0;
    while (remainingPieces > 0 && candidates.isNotEmpty) {
      final item = candidates[i % candidates.length];
      final qty = remainingPieces >= 2 ? 2 : remainingPieces;
      final price = order.service == 'Wash' ? item.washPrice : item.dryPrice;
      items.add(ReceiptItem(itemName: item.nameBn, service: order.service, quantity: qty, unitPrice: price));
      remainingPieces -= qty;
      i++;
    }
    return items;
  }

  factory ReceiptData.pickupForAdminOrder(AdminOrder order) {
    return ReceiptData(
      receiptNumber: _nextNumber(),
      orderId: order.id,
      type: ReceiptType.pickup,
      issuedAt: DateTime.now(),
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      customerId: 'CUST-${order.customerPhone}',
      riderName: order.riderName,
      riderId: order.riderName == null ? null : 'RDR-1042',
      riderPhone: null,
      pickupAddress: order.address,
      estimatedDelivery: DeliveryOptions.free.eta,
      items: _reconstructAdminItems(order),
    );
  }

  factory ReceiptData.deliveryForAdminOrder(AdminOrder order) {
    return ReceiptData(
      receiptNumber: _nextNumber(),
      orderId: order.id,
      type: ReceiptType.delivery,
      issuedAt: DateTime.now(),
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      customerId: 'CUST-${order.customerPhone}',
      riderName: order.riderName,
      riderId: order.riderName == null ? null : 'RDR-1042',
      deliveredBy: order.riderName,
      customerConfirmed: order.status == 'Delivered',
      items: _reconstructAdminItems(order),
    );
  }

  factory ReceiptData.paymentForAdminOrder(AdminOrder order) {
    return ReceiptData(
      receiptNumber: _nextNumber(),
      orderId: order.id,
      type: ReceiptType.payment,
      issuedAt: DateTime.now(),
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      customerId: 'CUST-${order.customerPhone}',
      items: _reconstructAdminItems(order),
      paymentMethod: order.paymentMethod,
      paymentStatus: order.status == 'Delivered' ? 'পরিশোধিত' : 'বাকি',
    );
  }
}
