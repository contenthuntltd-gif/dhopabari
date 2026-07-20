library;

/// Local mock data for the Admin Panel UI preview — no backend calls.
/// Mirrors the shape of the real API (see backend/prisma/schema.prisma)
/// so swapping this for real network calls later is a drop-in
/// replacement, not a rewrite.

class AdminOrder {
  final String id;
  final String customerName;
  final String customerPhone;
  String? riderName;
  final String service;
  final String category;
  final String itemsSummary;
  final int pieces;
  final int total;
  String status;
  final String date;
  final String address;
  final String paymentMethod;
  AdminOrder({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.riderName,
    required this.service,
    required this.category,
    required this.itemsSummary,
    required this.pieces,
    required this.total,
    required this.status,
    required this.date,
    required this.address,
    required this.paymentMethod,
  });
}

class AdminCustomer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String area;
  final int totalOrders;
  final int totalSpent;
  final List<String> addresses;
  bool blocked;
  final String joined;
  AdminCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.area,
    required this.totalOrders,
    required this.totalSpent,
    required this.addresses,
    this.blocked = false,
    required this.joined,
  });
}

class AdminRider {
  final String id;
  final String name;
  final String phone;
  String area;
  bool online;
  bool active;
  final double rating;
  final int completedOrders;
  final String? currentDeliveryId;
  final int walletBalance;
  final int totalEarnings;
  AdminRider({
    required this.id,
    required this.name,
    required this.phone,
    required this.area,
    required this.online,
    this.active = true,
    required this.rating,
    required this.completedOrders,
    this.currentDeliveryId,
    required this.walletBalance,
    required this.totalEarnings,
  });
}

class WithdrawalRequest {
  final String id;
  final String riderId;
  final String riderName;
  final int amount;
  String status; // Pending, Approved, Rejected
  final String date;
  WithdrawalRequest({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.amount,
    required this.status,
    required this.date,
  });
}

class CatalogCategory {
  final String id;
  String name;
  String nameBn;
  bool enabled;
  CatalogCategory({required this.id, required this.name, required this.nameBn, this.enabled = true});
}

class CatalogService {
  final String id;
  String name;
  String nameBn;
  bool enabled;
  CatalogService({required this.id, required this.name, required this.nameBn, this.enabled = true});
}

class CatalogItem {
  final String id;
  String name;
  String nameBn;
  String categoryId;
  int washPrice;
  int dryPrice;
  bool enabled;
  CatalogItem({
    required this.id,
    required this.name,
    required this.nameBn,
    required this.categoryId,
    required this.washPrice,
    required this.dryPrice,
    this.enabled = true,
  });
}

class AdminMockData {
  static const orderStatuses = ['Pending', 'Accepted', 'Picked Up', 'Processing', 'Ready for Delivery', 'Delivered', 'Cancelled'];
  static const orderStatusesBn = {
    'Pending': 'পেন্ডিং',
    'Accepted': 'গৃহীত',
    'Picked Up': 'পিকআপ হয়েছে',
    'Processing': 'প্রসেসিং',
    'Ready for Delivery': 'ডেলিভারির জন্য প্রস্তুত',
    'Delivered': 'ডেলিভারি হয়েছে',
    'Cancelled': 'বাতিল',
  };

  static final orders = <AdminOrder>[
    AdminOrder(id: '#DB123456', customerName: 'রায়হান ইসলাম', customerPhone: '01712345678', riderName: 'করিম ভাই', service: 'Wash', category: 'Men', itemsSummary: 'শার্ট x৩, প্যান্ট x২', pieces: 12, total: 330, status: 'Processing', date: '১২ জুন, ১০:০০ AM', address: 'বাসা ১২, রোড ৩, কলাতলী', paymentMethod: 'নগদ (COD)'),
    AdminOrder(id: '#DB123455', customerName: 'সুমি আক্তার', customerPhone: '01812345678', riderName: 'মামুন ভাই', service: 'Dry Clean', category: 'Women', itemsSummary: 'শাড়ি x১', pieces: 1, total: 150, status: 'Ready for Delivery', date: '১২ জুন, ৯:৩০ AM', address: 'সুগন্ধা পয়েন্ট, দোকান ৫', paymentMethod: 'bKash'),
    AdminOrder(id: '#DB123454', customerName: 'তানভীর হাসান', customerPhone: '01912345678', service: 'Wash', category: 'Home', itemsSummary: 'বেডশিট x২, বালিশ কভার x৪', pieces: 6, total: 200, status: 'Pending', date: '১২ জুন, ৯:০০ AM', address: 'লাবণী পয়েন্ট', paymentMethod: 'নগদ (COD)'),
    AdminOrder(id: '#DB123453', customerName: 'নাফিসা রহমান', customerPhone: '01612345678', riderName: 'শাহিন ভাই', service: 'Wash', category: 'Kids', itemsSummary: 'শার্ট x২', pieces: 2, total: 40, status: 'Accepted', date: '১১ জুন, ৬:০০ PM', address: 'কলাতলী বিচ রোড', paymentMethod: 'Nagad'),
    AdminOrder(id: '#DB123452', customerName: 'রায়হান ইসলাম', customerPhone: '01712345678', riderName: 'করিম ভাই', service: 'Dry Clean', category: 'Men', itemsSummary: 'কোট x১, স্যুট x১', pieces: 2, total: 600, status: 'Delivered', date: '৫ জুন, ১০:০০ AM', address: 'বাসা ১২, রোড ৩, কলাতলী', paymentMethod: 'bKash'),
    AdminOrder(id: '#DB123451', customerName: 'ইমরান খান', customerPhone: '01512345678', service: 'Wash', category: 'Men', itemsSummary: 'প্যান্ট x৪', pieces: 4, total: 120, status: 'Picked Up', date: '১২ জুন, ৮:০০ AM', address: 'সমিতি পাড়া', paymentMethod: 'নগদ (COD)'),
    AdminOrder(id: '#DB123450', customerName: 'তানভীর হাসান', customerPhone: '01912345678', service: 'Wash', category: 'Home', itemsSummary: 'পর্দা x২', pieces: 2, total: 200, status: 'Cancelled', date: '৪ জুন, ১১:০০ AM', address: 'লাবণী পয়েন্ট', paymentMethod: 'নগদ (COD)'),
  ];

  static final customers = <AdminCustomer>[
    AdminCustomer(id: 'cus_1', name: 'রায়হান ইসলাম', phone: '01712345678', email: 'rayhan@example.com', area: 'কলাতলী, কক্সবাজার সদর', totalOrders: 12, totalSpent: 4200, addresses: ['বাসা ১২, রোড ৩, কলাতলী', 'অফিস, সুগন্ধা'], joined: 'জানুয়ারি ২০২৪'),
    AdminCustomer(id: 'cus_2', name: 'সুমি আক্তার', phone: '01812345678', email: 'sumi@example.com', area: 'সুগন্ধা, কক্সবাজার', totalOrders: 8, totalSpent: 2600, addresses: ['সুগন্ধা পয়েন্ট, দোকান ৫'], joined: 'ফেব্রুয়ারি ২০২৪'),
    AdminCustomer(id: 'cus_3', name: 'তানভীর হাসান', phone: '01912345678', email: 'tanvir@example.com', area: 'লাবণী, কক্সবাজার', totalOrders: 5, totalSpent: 1400, addresses: ['লাবণী পয়েন্ট'], joined: 'মার্চ ২০২৪'),
    AdminCustomer(id: 'cus_4', name: 'নাফিসা রহমান', phone: '01612345678', email: 'nafisa@example.com', area: 'কলাতলী বিচ রোড', totalOrders: 3, totalSpent: 620, blocked: true, addresses: ['কলাতলী বিচ রোড'], joined: 'এপ্রিল ২০২৪'),
    AdminCustomer(id: 'cus_5', name: 'ইমরান খান', phone: '01512345678', email: 'imran@example.com', area: 'সমিতি পাড়া', totalOrders: 1, totalSpent: 120, addresses: ['সমিতি পাড়া'], joined: 'জুন ২০২৪'),
  ];

  static final riders = <AdminRider>[
    AdminRider(id: 'rider_karim', name: 'করিম ভাই', phone: '01911111111', area: "কক্সবাজার সদর", online: true, rating: 4.8, completedOrders: 142, currentDeliveryId: '#DB123456', walletBalance: 2400, totalEarnings: 38600),
    AdminRider(id: 'rider_mamun', name: 'মামুন ভাই', phone: '01922222222', area: "কলাতলী", online: true, rating: 4.6, completedOrders: 98, currentDeliveryId: '#DB123455', walletBalance: 1600, totalEarnings: 24200),
    AdminRider(id: 'rider_shahin', name: 'শাহিন ভাই', phone: '01933333333', area: "সুগন্ধা", online: false, rating: 4.9, completedOrders: 210, walletBalance: 3200, totalEarnings: 52800),
    AdminRider(id: 'rider_rasel', name: 'রাসেল ভাই', phone: '01944444444', area: "লাবণী", online: false, active: false, rating: 4.2, completedOrders: 34, walletBalance: 0, totalEarnings: 8100),
  ];

  static final withdrawals = <WithdrawalRequest>[
    WithdrawalRequest(id: 'w1', riderId: 'rider_karim', riderName: 'করিম ভাই', amount: 2000, status: 'Pending', date: '১২ জুন, ২০২৪'),
    WithdrawalRequest(id: 'w2', riderId: 'rider_shahin', riderName: 'শাহিন ভাই', amount: 3000, status: 'Pending', date: '১১ জুন, ২০২৪'),
    WithdrawalRequest(id: 'w3', riderId: 'rider_mamun', riderName: 'মামুন ভাই', amount: 1500, status: 'Approved', date: '৮ জুন, ২০২৪'),
    WithdrawalRequest(id: 'w4', riderId: 'rider_rasel', riderName: 'রাসেল ভাই', amount: 500, status: 'Rejected', date: '৫ জুন, ২০২৪'),
  ];

  static final categories = <CatalogCategory>[
    CatalogCategory(id: 'men', name: 'Men', nameBn: 'পুরুষ'),
    CatalogCategory(id: 'women', name: 'Women', nameBn: 'মহিলা'),
    CatalogCategory(id: 'kids', name: 'Kids', nameBn: 'শিশু'),
    CatalogCategory(id: 'home', name: 'Home', nameBn: 'ঘরের কাপড়'),
  ];

  static final services = <CatalogService>[
    CatalogService(id: 'wash', name: 'Wash', nameBn: 'ওয়াশ'),
    CatalogService(id: 'dry', name: 'Dry Clean', nameBn: 'ড্রাই ক্লিন'),
  ];

  static final items = <CatalogItem>[
    CatalogItem(id: 'shirt', name: 'Shirt', nameBn: 'শার্ট', categoryId: 'men', washPrice: 30, dryPrice: 60),
    CatalogItem(id: 'pant', name: 'Pant', nameBn: 'প্যান্ট', categoryId: 'men', washPrice: 30, dryPrice: 60),
    CatalogItem(id: 'tshirt', name: 'T-shirt', nameBn: 'টি-শার্ট', categoryId: 'men', washPrice: 20, dryPrice: 50),
    CatalogItem(id: 'panjabi', name: 'Panjabi', nameBn: 'পাঞ্জাবি', categoryId: 'men', washPrice: 50, dryPrice: 80),
    CatalogItem(id: 'jeans', name: 'Jeans', nameBn: 'জিন্স', categoryId: 'men', washPrice: 40, dryPrice: 70),
    CatalogItem(id: 'saree', name: 'Saree', nameBn: 'শাড়ি', categoryId: 'women', washPrice: 80, dryPrice: 150),
    CatalogItem(id: 'salwar', name: 'Salwar Kameez', nameBn: 'সালোয়ার কামিজ', categoryId: 'women', washPrice: 60, dryPrice: 100),
    CatalogItem(id: 'kids_shirt', name: 'Kids Shirt', nameBn: 'বাচ্চাদের শার্ট', categoryId: 'kids', washPrice: 20, dryPrice: 40),
    CatalogItem(id: 'bedsheet', name: 'Bedsheet', nameBn: 'বেডশিট', categoryId: 'home', washPrice: 40, dryPrice: 70),
    CatalogItem(id: 'pillow', name: 'Pillow Cover', nameBn: 'বালিশ কভার', categoryId: 'home', washPrice: 20, dryPrice: 30),
    CatalogItem(id: 'curtain', name: 'Curtain', nameBn: 'পর্দা', categoryId: 'home', washPrice: 100, dryPrice: 180),
    CatalogItem(id: 'blanket', name: 'Blanket', nameBn: 'কম্বল', categoryId: 'home', washPrice: 150, dryPrice: 300),
    CatalogItem(id: 'carpet', name: 'Carpet', nameBn: 'কার্পেট', categoryId: 'home', washPrice: 250, dryPrice: 400),
  ];

  // ── Dashboard stats ──
  static const todayOrders = 24;
  static const pendingOrders = 4;
  static const acceptedOrders = 3;
  static const pickedUpOrders = 5;
  static const processingOrders = 6;
  static const readyForDeliveryOrders = 3;
  static const deliveredOrders = 2;
  static const cancelledOrders = 1;
  static const todayRevenue = 6840;
  static const monthlyRevenue = 182400;
  static const totalCustomers = 5;
  static const activeRiders = 3;
  static const onlineRiders = 2;
  static const offlineRiders = 2;

  static const revenueSeries = [12000, 15400, 9800, 21000, 18600, 24200, 26400]; // last 7 days
  static const revenueSeriesLabels = ['শনি', 'রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র'];
}
