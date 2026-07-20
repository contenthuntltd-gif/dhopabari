import 'catalog.dart';

/// Local mock data for UI preview — no backend calls. Mirrors the shape of
/// the real API (see backend/prisma/schema.prisma) so swapping this for
/// real network calls later is a drop-in replacement, not a rewrite.
/// Items/prices are real, though: they come from [Catalog].

class PriceItem {
  final String id;
  final String category;
  final String name;
  final String nameBn;
  final int washPrice;
  final int dryPrice;
  const PriceItem({
    required this.id,
    required this.category,
    required this.name,
    required this.nameBn,
    required this.washPrice,
    required this.dryPrice,
  });
}

class OrderStatusStep {
  final String label;
  final bool done;
  final bool current;
  const OrderStatusStep({required this.label, required this.done, required this.current});
}

class MockOrder {
  final String id;
  final String date;
  final String service;
  final int pieces;
  final String area;
  final int total;
  final List<OrderStatusStep> timeline;
  // Populated once a rider has been assigned (i.e. mid-delivery); null
  // while the order is only pending/processing at the laundry.
  final String? riderName;
  final String? riderPhone;
  final String? etaLabel;

  /// Real line items (name/name_bn/service/qty/unit_price maps) when this
  /// order came from the database; empty for demo/mock orders. Receipts
  /// print these verbatim instead of reconstructing a guess.
  final List<Map<String, dynamic>> items;

  const MockOrder({
    required this.id,
    required this.date,
    required this.service,
    required this.pieces,
    required this.area,
    required this.total,
    required this.timeline,
    this.riderName,
    this.riderPhone,
    this.etaLabel,
    this.items = const [],
  });

  String get currentStatusLabel => timeline.firstWhere((s) => s.current, orElse: () => timeline.last).label;
  double get progress {
    final doneCount = timeline.where((s) => s.done).length;
    return doneCount / timeline.length;
  }
}

class ChatPreview {
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isRider;
  const ChatPreview({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.isRider,
  });
}

class MockData {
  static const categories = ['Men', 'Women', 'Kids', 'Home'];
  static const categoriesBn = {
    'Men': 'পুরুষ',
    'Women': 'মহিলা',
    'Kids': 'শিশু',
    'Home': 'ঘরের কাপড়',
  };

  /// The official Dhopa Bari price list — see [Catalog]. Everything that
  /// reads items/prices goes through here, so an admin price change (or a
  /// DB refresh) reflects everywhere at once.
  static List<PriceItem> get priceItems => Catalog.items;

  static List<PriceItem> itemsForCategory(String category) =>
      Catalog.forCategory(category);

  /// FINAL master order status flow — exactly six steps, used everywhere
  /// in the system. Mirrors `backend` `OrderStatus` enum:
  /// CONFIRMED -> PICKED_UP -> CLEANING -> PACKAGING_DONE
  ///   -> OUT_FOR_DELIVERY -> DELIVERED
  static const timelineLabels = [
    '✅ অর্ডার নিশ্চিত হয়েছে',
    '🚚 কাপড় সংগ্রহ করা হয়েছে',
    '🧺 কাপড় পরিষ্কার করা হচ্ছে',
    '📦 প্যাকেজিং সম্পন্ন',
    '🚛 ডেলিভারির পথে',
    '🏠 ডেলিভারি সম্পন্ন',
  ];

  /// Builds a timeline where every step up to (but excluding) [currentIndex]
  /// is done, the step at [currentIndex] is current, and the rest are
  /// pending. Pass `currentIndex == timelineLabels.length - 1` for a fully
  /// completed order.
  static List<OrderStatusStep> buildTimeline(int currentIndex) {
    final lastIndex = timelineLabels.length - 1;
    return List.generate(timelineLabels.length, (i) {
      // Reaching the final "সম্পন্ন" step means the order truly is done —
      // count it as `done` too so `MockOrder.progress` reads 1.0, not 0.9.
      final done = i < currentIndex || (i == currentIndex && i == lastIndex);
      return OrderStatusStep(label: timelineLabels[i], done: done, current: i == currentIndex);
    });
  }

  // Nullable on purpose: the Home screen's empty-state UI (`EmptyOngoingCard`)
  // depends on this being able to be null once a real API replaces this mock.
  // ignore: unnecessary_nullable_for_final_variable_declarations
  static final MockOrder? ongoingOrder = MockOrder(
    id: '#DB123456',
    date: '১২ জুন, ২০২৪ • ১০:০০ AM',
    service: 'Wash',
    pieces: 12,
    area: 'কলাতলী, কক্সবাজার সদর',
    total: 330,
    riderName: 'করিম ভাই',
    riderPhone: '+8801911111111',
    etaLabel: '১৫-২০ মিনিট',
    timeline: buildTimeline(4), // currently "ডেলিভারির পথে"
  );

  static final recentOrders = <MockOrder>[
    ongoingOrder!,
    MockOrder(
      id: '#DB123401',
      date: '৫ জুন, ২০২৪',
      service: 'Dry Clean',
      pieces: 4,
      area: 'কলাতলী, কক্সবাজার সদর',
      total: 420,
      timeline: buildTimeline(5), // ডেলিভারি সম্পন্ন
    ),
    MockOrder(
      id: '#DB123388',
      date: '২৮ মে, ২০২৪',
      service: 'Wash',
      pieces: 8,
      area: 'কলাতলী, কক্সবাজার সদর',
      total: 240,
      timeline: buildTimeline(5), // ডেলিভারি সম্পন্ন
    ),
  ];

  static const chats = <ChatPreview>[
    ChatPreview(name: 'সাপোর্ট টিম', lastMessage: 'আপনার অর্ডার ওয়াশ হচ্ছে', time: '১০:৪২ AM', unread: 1, isRider: false),
    ChatPreview(name: 'করিম ভাই (রাইডার)', lastMessage: 'আমি ১০ মিনিটে পৌঁছাব', time: 'গতকাল', unread: 0, isRider: true),
  ];

  // The signed-in user's identity + addresses. Populated from the user's
  // OWN Supabase profile on login (see AuthService._loadProfile) and wiped
  // on logout (see MockData.resetUser). Deliberately NOT seeded with demo
  // data — a fresh login must never surface a previous user's name, phone,
  // area or saved addresses.
  static final savedAddresses = <Map<String, String>>[];

  static String userName = '';
  static String userPhone = '';
  static String userArea = '';

  /// Clears every piece of the current user's in-memory identity. Called on
  /// logout so the next person to sign in starts from a clean slate.
  static void resetUser() {
    userName = '';
    userPhone = '';
    userArea = '';
    savedAddresses.clear();
  }

  /// Cox's Bazar service areas offered at signup / address selection.
  /// Mirrors the backend `Setting["service_areas"]` row (see
  /// `backend/prisma/seed.js`) — the single source of truth once the app
  /// is wired to the live API; kept as a plain list here so it stays
  /// trivially editable from the Admin Panel later without a schema change.
  static const serviceAreas = [
    'কলাতলী', 'সুগন্ধা', 'লাবণী', 'ঝাউতলা', 'বার্মিজ মার্কেট',
    'পানবাজার রোড', 'হলিডে মোড়', 'পিটি স্কুল', 'খালুর দোকান', 'রাস্তামাথা',
    'টার্মিনাল', 'টেকপাড়া', 'পাহাড়তলী', 'ঘোনারপাড়া', 'সমিতিপাড়া',
  ];
}
