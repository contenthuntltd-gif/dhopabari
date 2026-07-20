/// Dhopa Bari office/shop hours — 1:00 PM to 9:00 PM, every day. Mirrors
/// `backend/src/utils/businessHours.js` (and the seeded
/// `Setting["business_hours"]` row) so the same rule is enforced/shown
/// consistently client- and server-side.
class BusinessHours {
  static const openHour = 13; // 24h clock
  static const closeHour = 21;
  static const label = '১:০০ PM - ৯:০০ PM';
  static const labelWithDays = '১:০০ PM - ৯:০০ PM (প্রতিদিন)';

  static const offHoursMessage =
      'আপনার অর্ডার গ্রহণ করা হয়েছে। অফিস খোলার সময় (১:০০ PM - ৯:০০ PM) আমাদের টিম এটি নিশ্চিত করবে।';

  static bool get isOpenNow {
    final hour = DateTime.now().hour;
    return hour >= openHour && hour < closeHour;
  }
}

enum DeliveryType { free, express }

class DeliveryOption {
  final DeliveryType type;
  final String label;
  final int charge;
  final String eta;
  const DeliveryOption({required this.type, required this.label, required this.charge, required this.eta});
}

/// The two delivery options a customer can pick during checkout — Free is
/// always the default.
class DeliveryOptions {
  static const free = DeliveryOption(type: DeliveryType.free, label: 'ফ্রি ডেলিভারি', charge: 0, eta: '৩-৫ দিন');
  static const express = DeliveryOption(type: DeliveryType.express, label: 'এক্সপ্রেস ডেলিভারি', charge: 50, eta: '২ দিনের মধ্যে');

  static const all = [free, express];
}
