/// Local mock data for UI preview — no backend calls. Mirrors the shape of
/// the real API (see backend/prisma/schema.prisma) so swapping this for
/// real network calls later is a drop-in replacement, not a rewrite.

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
  const MockOrder({
    required this.id,
    required this.date,
    required this.service,
    required this.pieces,
    required this.area,
    required this.total,
    required this.timeline,
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

  static const priceItems = <PriceItem>[
    PriceItem(id: 'shirt', category: 'Men', name: 'Shirt', nameBn: 'শার্ট', washPrice: 30, dryPrice: 60),
    PriceItem(id: 'pant', category: 'Men', name: 'Pant', nameBn: 'প্যান্ট', washPrice: 30, dryPrice: 60),
    PriceItem(id: 'tshirt', category: 'Men', name: 'T-shirt', nameBn: 'টি-শার্ট', washPrice: 20, dryPrice: 50),
    PriceItem(id: 'panjabi', category: 'Men', name: 'Panjabi', nameBn: 'পাঞ্জাবি', washPrice: 50, dryPrice: 80),
    PriceItem(id: 'jeans', category: 'Men', name: 'Jeans', nameBn: 'জিন্স', washPrice: 40, dryPrice: 70),
    PriceItem(id: 'saree', category: 'Women', name: 'Saree', nameBn: 'শাড়ি', washPrice: 80, dryPrice: 150),
    PriceItem(id: 'salwar', category: 'Women', name: 'Salwar Kameez', nameBn: 'সালোয়ার কামিজ', washPrice: 60, dryPrice: 100),
    PriceItem(id: 'borka', category: 'Women', name: 'Borka', nameBn: 'বোরকা', washPrice: 50, dryPrice: 90),
    PriceItem(id: 'blouse', category: 'Women', name: 'Blouse', nameBn: 'ব্লাউজ', washPrice: 25, dryPrice: 40),
    PriceItem(id: 'kids_shirt', category: 'Kids', name: 'Kids Shirt', nameBn: 'বাচ্চাদের শার্ট', washPrice: 20, dryPrice: 40),
    PriceItem(id: 'kids_frock', category: 'Kids', name: 'Kids Frock', nameBn: 'বাচ্চাদের ফ্রক', washPrice: 25, dryPrice: 45),
    PriceItem(id: 'bedsheet', category: 'Home', name: 'Bedsheet', nameBn: 'বেডশিট', washPrice: 40, dryPrice: 70),
    PriceItem(id: 'pillow', category: 'Home', name: 'Pillow Cover', nameBn: 'বালিশ কভার', washPrice: 20, dryPrice: 30),
    PriceItem(id: 'curtain', category: 'Home', name: 'Curtain', nameBn: 'পর্দা', washPrice: 100, dryPrice: 180),
    PriceItem(id: 'blanket', category: 'Home', name: 'Blanket', nameBn: 'কম্বল', washPrice: 150, dryPrice: 300),
  ];

  static List<PriceItem> itemsForCategory(String category) =>
      priceItems.where((p) => p.category == category).toList();

  static final ongoingOrder = MockOrder(
    id: '#DB123456',
    date: '১২ জুন, ২০২৪ • ১০:০০ AM',
    service: 'Wash',
    pieces: 12,
    area: 'কলাতলী, কক্সবাজার সদর',
    total: 330,
    timeline: const [
      OrderStatusStep(label: 'পিকআপ হয়েছে', done: true, current: false),
      OrderStatusStep(label: 'ওয়াশ হচ্ছে', done: false, current: true),
      OrderStatusStep(label: 'ইস্ত্রি', done: false, current: false),
      OrderStatusStep(label: 'ডেলিভারির পথে', done: false, current: false),
      OrderStatusStep(label: 'ডেলিভারি', done: false, current: false),
    ],
  );

  static final recentOrders = <MockOrder>[
    ongoingOrder,
    MockOrder(
      id: '#DB123401',
      date: '৫ জুন, ২০২৪',
      service: 'Dry Clean',
      pieces: 4,
      area: 'কলাতলী, কক্সবাজার সদর',
      total: 420,
      timeline: const [
        OrderStatusStep(label: 'পিকআপ হয়েছে', done: true, current: false),
        OrderStatusStep(label: 'ওয়াশ হচ্ছে', done: true, current: false),
        OrderStatusStep(label: 'ইস্ত্রি', done: true, current: false),
        OrderStatusStep(label: 'ডেলিভারির পথে', done: true, current: false),
        OrderStatusStep(label: 'ডেলিভারি', done: true, current: true),
      ],
    ),
    MockOrder(
      id: '#DB123388',
      date: '২৮ মে, ২০২৪',
      service: 'Wash',
      pieces: 8,
      area: 'কলাতলী, কক্সবাজার সদর',
      total: 240,
      timeline: const [
        OrderStatusStep(label: 'পিকআপ হয়েছে', done: true, current: false),
        OrderStatusStep(label: 'ওয়াশ হচ্ছে', done: true, current: false),
        OrderStatusStep(label: 'ইস্ত্রি', done: true, current: false),
        OrderStatusStep(label: 'ডেলিভারির পথে', done: true, current: false),
        OrderStatusStep(label: 'ডেলিভারি', done: true, current: true),
      ],
    ),
  ];

  static const chats = <ChatPreview>[
    ChatPreview(name: 'সাপোর্ট টিম', lastMessage: 'আপনার অর্ডার ওয়াশ হচ্ছে', time: '১০:৪২ AM', unread: 1, isRider: false),
    ChatPreview(name: 'করিম ভাই (রাইডার)', lastMessage: 'আমি ১০ মিনিটে পৌঁছাব', time: 'গতকাল', unread: 0, isRider: true),
  ];

  static const savedAddresses = [
    {'label': 'Home', 'labelBn': 'বাসা', 'line': 'বাসা ১২, রোড ৩, কলাতলী', 'area': "কক্সবাজার সদর"},
    {'label': 'Office', 'labelBn': 'অফিস', 'line': 'সুগন্ধা পয়েন্ট, দোকান ৫', 'area': "কক্সবাজার সদর"},
  ];

  static const userName = 'রায়হান ইসলাম';
  static const userPhone = '01712345678';
  static const userArea = 'কলাতলী, কক্সবাজার সদর';
}
