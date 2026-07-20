import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Real (not decorative) app-wide language switch. Default is Bangla;
/// flipping it to English updates every screen that reads
/// [AppLanguage.isEnglish] or calls [AppLanguage.tr] — today that's the
/// Login screen, the bottom navigation, Home and Profile. Extending
/// coverage to the remaining screens is a straightforward follow-up: wrap
/// the screen's `build()` in a `ValueListenableBuilder<bool>` on
/// [isEnglish] and swap `Text('বাংলা...')` for `Text(AppLanguage.tr('বাংলা...'))`.
class AppLanguage {
  AppLanguage._();
  static const _prefsKey = 'app_language_en';
  static final ValueNotifier<bool> isEnglish = ValueNotifier<bool>(false);

  /// Restores the saved language choice on app start. Call once before
  /// `runApp`.
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    isEnglish.value = prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> setEnglish(bool value) async {
    isEnglish.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  static Future<void> toggle() => setEnglish(!isEnglish.value);

  /// Translates a Bangla source string to English when English is active.
  /// Falls back to the original string for anything not yet in the
  /// dictionary, so it's always safe to wrap any label with this.
  static String tr(String bn) => isEnglish.value ? (_dict[bn] ?? bn) : bn;

  /// Bottom-sheet language picker — used by both the Login screen's chip
  /// and Profile's "ভাষা / Language" menu tile so there's one consistent
  /// place users learn to change language from.
  static Future<void> showPicker(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ValueListenableBuilder<bool>(
        valueListenable: isEnglish,
        builder: (context, current, _) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(tr('ভাষা নির্বাচন করুন'), style: AppText.h1),
              const SizedBox(height: 14),
              _langOption(context, '🇧🇩', 'বাংলা', selected: !current, onTap: () => setEnglish(false)),
              const SizedBox(height: 10),
              _langOption(context, '🇬🇧', 'English', selected: current, onTap: () => setEnglish(true)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _langOption(BuildContext context, String flag, String label, {required bool selected, required VoidCallback onTap}) {
    return Material(
      color: selected ? AppColors.blueSoft : Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          onTap();
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: selected ? AppColors.blue : AppColors.line)),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: selected ? AppColors.blue : AppColors.ink))),
              if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.blue, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Bangla → English lookup for chrome shared across many screens
  /// (bottom nav, common headers/section titles, Profile & Home labels).
  static const Map<String, String> _dict = {
    // Login screen
    '+৮৮০': '+880',
    'মোবাইল নাম্বার': 'Mobile number',
    'অথবা': 'or',
    'আপনার নম্বরে একটি যাচাই কোড (OTP) পাঠানো হবে': 'A verification code (OTP) will be sent to your number',
    'কোড পাঠানো যায়নি। আবার চেষ্টা করুন।': 'Could not send code. Please try again.',
    'লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।': 'Login failed. Please try again.',

    // Bottom nav
    'হোম': 'Home',
    'আমার অর্ডার': 'My Orders',
    'নতুন অর্ডার': 'New Order',
    'চ্যাট': 'Chat',
    'প্রোফাইল': 'Profile',

    // Home screen
    'স্বাগতম, ': 'Welcome, ',
    'নোটিফিকেশন, ৩ টি নতুন': 'Notifications, 3 new',
    'সম্পন্ন অর্ডার': 'Completed Orders',
    'সাপোর্ট (WhatsApp)': 'Support (WhatsApp)',
    'অর্ডার করুন': 'Order Now',
    'এই মুহূর্তে কোনো চলমান অর্ডার নেই': 'No running order right now',
    'সার্ভিস বাছাই করে অর্ডার করুন': 'Choose a service to order',
    'মাত্র ২ ধাপে আপনার কাপড় আমাদের কাছে পৌঁছে দিন': 'Get your clothes to us in just 2 steps',
    'ওয়াশ': 'Wash',
    'ড্রাই ক্লিন': 'Dry Clean',
    'চলমান অর্ডার': 'Running Order',
    'সবগুলো দেখুন →': 'View all →',
    'সাম্প্রতিক অর্ডার': 'Recent Orders',
    'কুইক অ্যাকশন': 'Quick Actions',
    'ট্র্যাক অর্ডার': 'Track Order',
    'চ্যাট সাপোর্ট': 'Chat Support',
    'অর্ডার ইতিহাস': 'Order History',
    'অফার': 'Offers',
    'এখনই অর্ডার করুন': 'Order Now',
    'ফ্রি পিকআপ': 'Free Pickup',
    'ফ্রি ডেলিভারি': 'Free Delivery',
    'প্রতিটি অর্ডারে সম্পূর্ণ ফ্রি — কোনো শর্ত ছাড়াই': 'Completely free on every order — no conditions',
    'ধোপা বাড়ি': 'Dhopa Bari',
    // NOTE: our tagline ("কাপড়ের যত্নে আপনার বিশ্বস্ত পার্টনার") is
    // intentionally left untranslated — brand voice stays Bangla in every
    // language mode.
    'নতুন অর্ডার করুন →': 'Place a new order →',
    'মেনু': 'Menu',
    'লগআউট': 'Logout',
    'নোটিফিকেশন': 'Notifications',
    'চলমান অফার': 'Active Offers',

    // Profile screen
    'একাউন্ট': 'Account',
    'অ্যাকাউন্ট': 'Account',
    'ব্যক্তিগত তথ্য': 'Personal Information',
    'সংরক্ষিত ঠিকানা': 'Saved Addresses',
    'পাসওয়ার্ড পরিবর্তন করুন': 'Change Password',
    'রিসিট ও মেমো': 'Receipts & Memos',
    'রেটিং ও রিভিউ': 'Ratings & Reviews',
    'অফার ও রিওয়ার্ড': 'Offers & Rewards',
    'কুপন ও অফার': 'Coupons & Offers',
    'রেফার করে আয় করুন': 'Refer & Earn',
    'সাপোর্ট': 'Support',
    'সাপোর্ট সেন্টার': 'Support Center',
    'লাইভ চ্যাট': 'Live Chat',
    'সাধারণ': 'General',
    'ভাষা': 'Language',
    'নিরাপত্তা': 'Security',
    'সম্পর্কে': 'About',
    'প্রাইভেসি পলিসি': 'Privacy Policy',
    'শর্তাবলী': 'Terms & Conditions',
    'ঝুঁকিপূর্ণ এলাকা': 'Danger Zone',
    'অ্যাকাউন্ট মুছে ফেলুন': 'Delete Account',
    'মোট অর্ডার': 'Total Orders',
    'সম্পন্ন': 'Completed',
    'চলমান': 'Running',
    'বাতিল': 'Cancelled',
    'মোট খরচ': 'Total Spending',
    'রিওয়ার্ড পয়েন্ট': 'Reward Points',
    'গোল্ড মেম্বার': 'Gold Member',
    'প্রোফাইল সম্পাদনা': 'Edit Profile',
    'প্রোফাইল ৯০% সম্পন্ন': '90% profile complete',
    'ব্যবসায়িক তথ্য': 'Business Info',
    'অফিস সময়': 'Office Hours',
    'এক্সপ্রেস ডেলিভারি': 'Express Delivery',
    'বাংলা': 'বাংলা',

    // Register (Create Account) screen
    'ফিরে যান': 'Back',
    'একাউন্ট তৈরি করুন': 'Create Account',
    'নতুন একাউন্ট খুলে অর্ডার শুরু করুন': 'Open a new account to start ordering',
    'পূর্ণ নাম দিন': 'Enter full name',
    'মোবাইল নাম্বার দিন': 'Enter mobile number',
    'পাসওয়ার্ড দিন': 'Enter password',
    'পাসওয়ার্ড লুকান': 'Hide password',
    'পাসওয়ার্ড দেখান': 'Show password',
    'পাসওয়ার্ড আবার দিন': 'Re-enter password',
    'ঠিকানার তথ্য': 'Address Info',
    'এলাকা নির্বাচন করুন': 'Select area',
    'বাসা/বিল্ডিং/ফ্ল্যাট/রোড (যেমন: বাসা ১২, রোড ৩)': 'House/Building/Flat/Road (e.g. House 12, Road 3)',
    'হোয়াটসঅ্যাপ নাম্বার (ঐচ্ছিক)': 'WhatsApp number (optional)',
    'ইতিমধ্যে একাউন্ট আছে? ': 'Already have an account? ',
    'লগইন করুন': 'Log in',
    'এলাকা খুঁজুন...': 'Search area...',
    'কোনো এলাকা পাওয়া যায়নি': 'No area found',
    'দুর্বল': 'Weak',
    'মোটামুটি': 'Fair',
    'শক্তিশালী': 'Strong',
    'সঠিক মোবাইল নম্বর দিন (১০-১১ ডিজিট)': 'Enter a valid mobile number (10-11 digits)',
    'পাসওয়ার্ড অন্তত ৬ অক্ষরের হতে হবে': 'Password must be at least 6 characters',
    'পাসওয়ার্ড মিলছে না': 'Passwords do not match',
    'বাসা/বিল্ডিং/রোড এর ঠিকানা দিন': 'Enter house/building/road address',
    'সঠিক হোয়াটসঅ্যাপ নাম্বার দিন': 'Enter a valid WhatsApp number',
    'সার্ভারের সাথে সংযোগ করা যায়নি। আবার চেষ্টা করুন।': 'Could not connect to the server. Please try again.',

    // Orders screen
    'অর্ডার নম্বর বা সার্ভিস খুঁজুন': 'Search order number or service',
    'সব': 'All',
    'কোনো অর্ডার পাওয়া যায়নি': 'No orders found',
    'এখনো কোনো অর্ডার নেই': 'No orders yet',
    'ভিন্ন ফিল্টার বা সার্চ শব্দ ব্যবহার করে দেখুন।': 'Try a different filter or search term.',
    'আপনার প্রথম অর্ডার দিন এবং প্রিমিয়াম লন্ড্রি সেবা উপভোগ করুন।': 'Place your first order and enjoy premium laundry service.',
  };
}
