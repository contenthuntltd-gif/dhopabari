const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// Converts an integer/number string to Bengali numerals, matching the
/// approved design's typography (৳৩৩০, ১২ পিস, etc.).
String toBn(num n) {
  return n.toString().split('').map((c) {
    final d = int.tryParse(c);
    return d != null ? _bnDigits[d] : c;
  }).join();
}

String money(num n) => '৳${toBn(n)}';

const _bnMonths = [
  'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
  'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
];

/// "জুলাই ২০২৬" from an ISO timestamp — the customer "joined" label.
String bnMonthYear(String? iso) {
  final d = DateTime.tryParse(iso ?? '')?.toLocal();
  if (d == null) return '—';
  return '${_bnMonths[d.month - 1]} ${toBn(d.year)}';
}

/// "২১ জুলাই" — a compact day + month label from a DateTime.
String bnDate(DateTime d) => '${toBn(d.day)} ${_bnMonths[d.month - 1]}';

/// "১২ জুন, ১০:০০ AM" from an ISO timestamp — the order date label.
String bnDateTime(String? iso) {
  final d = DateTime.tryParse(iso ?? '')?.toLocal();
  if (d == null) return '—';
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = toBn(d.minute).padLeft(2, '০');
  final period = d.hour < 12 ? 'AM' : 'PM';
  return '${toBn(d.day)} ${_bnMonths[d.month - 1]}, ${toBn(hour12)}:$minute $period';
}
