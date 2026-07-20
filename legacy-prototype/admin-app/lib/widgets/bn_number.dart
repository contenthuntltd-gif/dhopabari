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
