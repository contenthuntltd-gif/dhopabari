// Bilingual translations for Dhopa Bari app
// Lang: 'bn' = Bengali | 'en' = English

export type Lang = 'bn' | 'en';

const translations = {
  // ── App Brand ───────────────────────────────────────────────────────────────
  appName: { bn: 'ধোপা বাড়ি', en: 'Dhopa Bari' },
  poweredBy: { bn: 'Powered by Dhopa Bari', en: 'Powered by Dhopa Bari' },

  // ── Splash ──────────────────────────────────────────────────────────────────
  splashTagline: { bn: 'কাপড়ের যত্নে আপনার বিশ্বস্ত পার্টনার।', en: 'Your trusted partner in clothing care.' },
  splashStart: { bn: 'শুরু করুন →', en: 'Get Started →' },

  // ── Login ───────────────────────────────────────────────────────────────────
  loginTitle: { bn: 'আপনার নম্বর দিন', en: 'Enter Your Number' },
  loginSubtitle: { bn: 'আমরা আপনাকে একটি OTP কোড পাঠাব', en: 'We will send you an OTP code' },
  loginPhonePlaceholder: { bn: '১৭XXXXXXXXX', en: '17XXXXXXXXX' },
  loginButton: { bn: 'ওটিপি পাঠান →', en: 'Send OTP →' },
  loginTerms: { bn: 'লগইন করে আপনি আমাদের শর্তাবলী মেনে নিচ্ছেন', en: 'By logging in, you agree to our Terms & Conditions' },
  loginTermsLink: { bn: 'শর্তাবলী', en: 'Terms & Conditions' },


  // ── OTP ─────────────────────────────────────────────────────────────────────
  otpTitle: { bn: 'কোড যাচাই করুন', en: 'Verify Code' },
  otpSubtitle: { bn: 'আপনার মোবাইলে পাঠানো কোড দিন', en: 'Enter the code sent to your mobile' },
  otpButton: { bn: 'যাচাই করুন ✓', en: 'Verify ✓' },
  otpResend: { bn: 'কোড পাননি? আবার পাঠান', en: "Didn't get code? Resend" },

  // ── Details ─────────────────────────────────────────────────────────────────
  detailsTitle: { bn: 'আপনার তথ্য দিন', en: 'Your Details' },
  detailsStep: { bn: 'ধাপ ১ / ১', en: 'Step 1 / 1' },
  detailsNamePlaceholder: { bn: 'আপনার নাম লিখুন', en: 'Enter your name' },
  detailsAreaPlaceholder: { bn: 'আপনার এলাকা বেছে নিন', en: 'Select your area' },
  detailsAddressPlaceholder: { bn: 'বিস্তারিত ঠিকানা লিখুন', en: 'Enter full address' },
  detailsButton: { bn: 'সেভ করুন ✓', en: 'Save ✓' },
  detailsSkip: { bn: 'পরে দিব', en: 'Skip' },

  // ── Welcome ──────────────────────────────────────────────────────────────────
  welcomeTitle: { bn: 'স্বাগতম!', en: 'Welcome!' },
  welcomeSubtitle: { bn: 'আপনার অ্যাকাউন্ট প্রস্তুত', en: 'Your account is ready' },
  welcomeButton: { bn: 'শুরু করি →', en: "Let's Start →" },

  // ── Home ────────────────────────────────────────────────────────────────────
  homeGreeting: { bn: 'আসসালামু আলাইকুম', en: 'Hello' },
  homeCustomer: { bn: 'গ্রাহক', en: 'Customer' },
  homeHeroTitle: { bn: 'আজই কাপড় পিকআপ বুক করুন', en: 'Book Laundry Pickup Today' },
  homeHeroSubtitle: { bn: 'সময় বেছে দিন, আমরা বাসা থেকে সংগ্রহ করে পরিষ্কার কাপড় পৌঁছে দেব।', en: 'Choose a time and we will collect your clothes and return them clean.' },
  homeOrderBtn: { bn: 'অর্ডার দিন →', en: 'Order Now →' },
  homeServices: { bn: 'সার্ভিস বেছে নিন', en: 'Choose Service' },
  homePriceList: { bn: 'প্রাইস লিস্ট', en: 'Price List' },
  homeWash: { bn: 'ওয়াশ', en: 'Wash' },
  homeDryClean: { bn: 'ড্রাই ক্লিন', en: 'Dry Clean' },
  homeWashPrice: { bn: '৳৪০/পিস থেকে', en: '৳40/pc from' },
  homeDryPrice: { bn: '৳৬০/পিস থেকে', en: '৳60/pc from' },
  homeCurrentOrder: { bn: 'চলমান অর্ডার', en: 'Current Order' },
  homeDetails: { bn: 'বিস্তারিত →', en: 'Details →' },
  homePiece: { bn: 'পিস', en: 'pcs' },

  // ── Orders Screen ────────────────────────────────────────────────────────────
  ordersTitle: { bn: 'আমার অর্ডার', en: 'My Orders' },
  ordersTabOngoing: { bn: 'চলমান', en: 'Ongoing' },
  ordersTabCompleted: { bn: 'সম্পন্ন', en: 'Completed' },
  ordersTabCancelled: { bn: 'বাতিল', en: 'Cancelled' },
  ordersPiece: { bn: 'পিস', en: 'pcs' },
  ordersToday: { bn: 'আজ', en: 'Today' },
  ordersPending: { bn: 'পেন্ডিং', en: 'Pending' },
  ordersEmpty: { bn: 'এখনো কোনো অর্ডার নেই', en: 'No orders yet' },
  ordersEmptySub: { bn: 'প্রথম অর্ডার দিলে এখানে দেখাবে।', en: 'Your first order will appear here.' },
  ordersCancelBtn: { bn: 'বাতিল করুন', en: 'Cancel Order' },
  ordersCancelTitle: { bn: 'অর্ডার বাতিল করবেন?', en: 'Cancel this order?' },
  ordersCancelMsg: { bn: 'এই অর্ডারটি বাতিল করলে পূর্বাবস্থায় ফেরানো যাবে না।', en: 'This action cannot be undone once the order is cancelled.' },
  ordersCancelConfirm: { bn: 'হ্যাঁ, বাতিল করুন', en: 'Yes, Cancel' },
  ordersCancelNo: { bn: 'না, থাকুক', en: 'No, Keep it' },
  ordersCancelSuccess: { bn: 'অর্ডার বাতিল হয়েছে', en: 'Order Cancelled' },
  ordersCancelFail: { bn: 'বাতিল করা যায়নি। পরে আবার চেষ্টা করুন।', en: 'Could not cancel. Please try again later.' },
  ordersCancelNotAllowed: { bn: 'এই অর্ডার এখন আর বাতিল করা যাবে না।', en: 'This order can no longer be cancelled.' },


  // ── New Order Screen ─────────────────────────────────────────────────────────
  orderScreenTitle: { bn: 'নতুন অর্ডার', en: 'New Order' },
  orderWash: { bn: 'ওয়াশ', en: 'Wash' },
  orderDry: { bn: 'ড্রাই ক্লিন', en: 'Dry Clean' },
  orderCatMale: { bn: 'পুরুষ', en: 'Men' },
  orderCatFemale: { bn: 'মহিলা', en: 'Women' },
  orderCatKids: { bn: 'শিশু', en: 'Kids' },
  orderCatHome: { bn: 'ঘরের কাপড়', en: 'Home' },
  orderCartEmpty: { bn: 'কার্টে এখনো কোনো item নেই', en: 'No items in cart yet' },
  orderSeeAll: { bn: 'সব দেখুন 📑', en: 'See All 📑' },
  orderNext: { bn: 'পরবর্তী →', en: 'Next →' },
  orderPiece: { bn: 'পিস', en: 'pcs' },
  orderPerPiece: { bn: '/পিস', en: '/pc' },
  orderCartTitle: { bn: 'কার্ট এর তালিকা', en: 'Cart Items' },
  orderTotal: { bn: 'মোট হিসাব:', en: 'Total:' },
  orderNextStep: { bn: 'পরবর্তী ধাপে যান →', en: 'Go to Next Step →' },
  orderCartEmpty2: { bn: 'কার্ট খালি আছে', en: 'Cart is empty' },

  // ── Summary Screen ────────────────────────────────────────────────────────────
  summaryTitle: { bn: 'অর্ডার সামারি', en: 'Order Summary' },
  summaryService: { bn: 'সার্ভিস', en: 'Service' },
  summaryWash: { bn: 'ওয়াশ', en: 'Wash' },
  summaryTime: { bn: 'সময়', en: 'Timeline' },
  summaryAddress: { bn: 'ঠিকানা', en: 'Address' },
  summaryAddressEdit: { bn: 'ঠিকানা লিখুন', en: 'Enter address' },
  summaryItems: { bn: 'আইটেম', en: 'Items' },
  summarySubtotal: { bn: 'সাবটোটাল', en: 'Subtotal' },
  summaryDelivery: { bn: 'ডেলিভারি চার্জ', en: 'Delivery Charge' },
  summaryFree: { bn: 'ফ্রি', en: 'Free' },
  summaryTotal: { bn: 'মোট', en: 'Total' },
  summaryPaymentTitle: { bn: 'পেমেন্ট পদ্ধতি', en: 'Payment Method' },
  summaryCOD: { bn: 'ক্যাশ অন ডেলিভারি', en: 'Cash on Delivery' },
  summaryBkash: { bn: 'বিকাশ / নগদ', en: 'bKash / Nagad' },
  summaryComing: { bn: 'শীঘ্রই আসছে', en: 'Coming Soon' },
  summaryConfirm: { bn: 'অর্ডার কনফার্ম করুন', en: 'Confirm Order' },
  summaryProcessing: { bn: 'প্রসেস হচ্ছে...', en: 'Processing...' },
  summaryKoxBazar: { bn: 'কক্সবাজার', en: 'Cox\'s Bazar' },

  // ── Success Screen ────────────────────────────────────────────────────────────
  successTitle: { bn: 'অর্ডার সফল!', en: 'Order Placed!' },
  successSubtitle: { bn: 'আপনার অর্ডার সফলভাবে গ্রহণ করা হয়েছে।\nআমরা দ্রুত যোগাযোগ করব।', en: 'Your order has been placed successfully.\nWe will contact you shortly.' },
  successTrack: { bn: 'অর্ডার ট্র্যাক করুন', en: 'Track Order' },
  successHome: { bn: 'হোমে ফিরুন', en: 'Go Home' },

  // ── Tracking Screen ───────────────────────────────────────────────────────────
  trackingTitle: { bn: 'অর্ডার ট্র্যাকিং', en: 'Order Tracking' },
  trackingDeliveryMan: { bn: 'ডেলিভারিম্যান', en: 'Delivery Man' },
  trackingETA: { bn: 'আনুমানিক ডেলিভারি: Pickup After 3-7 Day Complete', en: 'Estimated Delivery: Pickup After 3-7 Day Complete' },

  // ── Messages Screen ────────────────────────────────────────────────────────────
  messagesTitle: { bn: 'যোগাযোগ ও চ্যাট', en: 'Chat & Messages' },
  messagesSubtitle: { bn: 'ডেলিভারিম্যানের সাথে কথা বলুন', en: 'Talk to your delivery man' },
  messagesStatus: { bn: 'অর্ডার স্ট্যাটাস:', en: 'Order Status:' },
  messagesUpdate: { bn: '🔄 আপডেট করুন', en: '🔄 Refresh' },
  messagesDefaultMsg: { bn: 'আসসালামু আলাইকুম, কীভাবে সাহায্য করতে পারি?', en: 'Hello, how can I help you?' },
  messagesTapToChat: { bn: 'চ্যাট শুরু করতে ট্যাপ করুন', en: 'Tap to start chat' },
  messagesSupportChat: { bn: 'সহায়তা চ্যাট', en: 'Support Chat' },

  // ── Chat Screen ────────────────────────────────────────────────────────────────
  chatOnline: { bn: 'অনলাইন', en: 'Online' },
  chatPlaceholder: { bn: 'মেসেজ লিখুন...', en: 'Type a message...' },
  chatSend: { bn: 'পাঠান', en: 'Send' },
  chatEmptyTitle: { bn: 'চ্যাট শুরু করুন', en: 'Start a Chat' },
  chatEmptySub: { bn: 'ডেলিভারিম্যানের সাথে কথা বলতে মেসেজ লিখুন।', en: 'Send a message to talk to your delivery man.' },
  chatTyping: { bn: 'টাইপ করছেন...', en: 'typing...' },
  chatCallFail: { bn: 'কল করা সম্ভব নয়', en: 'Unable to call' },
  chatRiderNumber: { bn: 'রাইডারের নম্বর:', en: "Rider's number:" },
  chatSendFail: { bn: 'মেসেজ পাঠানো যায়নি। আবার চেষ্টা করুন।', en: 'Failed to send. Please try again.' },
  chatError: { bn: 'ভুল', en: 'Error' },

  // ── Chat Auto Responses ───────────────────────────────────────────────────────
  chatRespPending: { bn: 'আসসালামু আলাইকুম ভাই। আপনার অর্ডারটি এখনো পেন্ডিং আছে। অ্যাডমিন কনফার্ম করলেই আমি আপনার ঠিকানায় রওয়ানা হব।', en: 'Hello! Your order is still pending. I will head to your address once the admin confirms it.' },
  chatRespCollect: { bn: 'জি ভাই, আমি এখন আপনার ঠিকানার দিকেই আসছি। আর ১০-১৫ মিনিটের মধ্যে পৌঁছে যাব ইনশাআল্লাহ।', en: "Yes! I'm on my way to your address. Should arrive in 10-15 minutes, God willing." },
  chatRespWash: { bn: 'ভাই আপনার কাপড়গুলো এখন ওয়াশ করা হচ্ছে। ধোয়া শেষ হলে আমি ডেলিভারির জন্য প্রস্তুত করব।', en: 'Your clothes are currently being washed. Once done, I will prepare them for delivery.' },
  chatRespReady: { bn: 'ভাইয়া, কাপড় রেডি হয়েছে। আমি অফিস থেকে ডেলিভারি নিয়ে আপনার বাসায় আসছি।', en: 'Your clothes are ready! I am picking them up from the office and heading to your home now.' },
  chatRespDone: { bn: 'জি ভাইয়া, ডেলিভারি তো সম্পন্ন হয়েছে। কোনো সমস্যা থাকলে জানাবেন।', en: 'Yes, delivery has been completed. Please let me know if there are any issues.' },
  chatRespLocCollect: { bn: 'আমি আপনার নির্ধারিত এলাকার কাছাকাছি আছি ভাই। কিছুক্ষণের মধ্যে এসে নক দিচ্ছি।', en: "I'm near your area. I'll knock on your door shortly." },
  chatRespLocDefault: { bn: 'আমি এখন ধোপা বাড়ি অফিসে আছি ভাই। আপনার কাপড় প্রসেস করা হচ্ছে।', en: "I'm currently at the Dhopa Bari office. Your clothes are being processed." },
  chatRespDefaultPending: { bn: 'আসসালামু আলাইকুম, আমি ধোপা বাড়ি রাইডার বলছি। আপনার অর্ডারটি কনফার্ম হওয়ার পর আমি আপনার কাপড় সংগ্রহ করতে আসব।', en: 'Hello, this is your Dhopa Bari rider. I will come to collect your clothes after the order is confirmed.' },
  chatRespDefaultCollect: { bn: 'জি ভাই, আমি আপনার ঠিকানায় কাপড় সংগ্রহ করতে আসছি। অনুগ্রহ করে কাপড় গুছিয়ে রেডি রাখুন।', en: "Yes, I'm coming to your address to collect the clothes. Please have them ready." },
  chatRespDefaultWash: { bn: 'জি ভাই, আপনার কাপড় এখন ওয়াশিং ডিপার্টমেন্টে আছে। কাজ শেষ হলে আপনার সাথে যোগাযোগ করব।', en: "Yes, your clothes are in the washing department now. I'll contact you once done." },
  chatRespDefaultDone: { bn: 'ধন্যবাদ ভাই, ধোপা বাড়ির সাথে থাকার জন্য। আপনার দিনটি শুভ হোক!', en: 'Thank you for using Dhopa Bari. Have a wonderful day!' },
  chatRespDefault: { bn: 'আসসালামু আলাইকুম ভাই, কীভাবে সাহায্য করতে পারি বলুন?', en: 'Hello! How can I help you?' },

  // ── Profile Screen ────────────────────────────────────────────────────────────
  profileAddress: { bn: 'আমার ঠিকানা', en: 'My Address' },
  profileArea: { bn: 'এলাকা', en: 'Area' },
  profileOrders: { bn: 'অর্ডার হিস্ট্রি', en: 'Order History' },
  profileRating: { bn: 'রেটিং ও রিভিউ', en: 'Ratings & Reviews' },
  profileContact: { bn: 'যোগাযোগ / সাহায্য', en: 'Contact / Help' },
  profileAbout: { bn: 'আমাদের সম্পর্কে', en: 'About Us' },
  profileLanguage: { bn: 'ভাষা / Language', en: 'ভাষা / Language' },
  profileLogout: { bn: 'লগআউট', en: 'Logout' },
  profileCustomer: { bn: 'গ্রাহক', en: 'Customer' },
  profileCoxBazar: { bn: 'কক্সবাজার', en: "Cox's Bazar" },

  // ── Price List Screen ──────────────────────────────────────────────────────────
  priceTitle: { bn: 'মূল্য তালিকা', en: 'Price List' },
  priceItem: { bn: 'আইটেম', en: 'Item' },
  priceWash: { bn: 'ওয়াশ', en: 'Wash' },
  priceDry: { bn: 'ড্রাই', en: 'Dry' },
  priceIron: { bn: 'আয়রন', en: 'Iron' },

  // ── Workflow Steps ────────────────────────────────────────────────────────────
  workflowPending: { bn: 'অর্ডার পেন্ডিং', en: 'Order Pending' },
  workflowConfirmed: { bn: 'অর্ডার কনফার্মড', en: 'Order Confirmed' },
  workflowCollecting: { bn: 'কাপড় সংগ্রহ করা হচ্ছে', en: 'Collecting Clothes' },
  workflowCollected: { bn: 'কাপড় সংগ্রহ করা হয়েছে', en: 'Clothes Collected' },
  workflowWashing: { bn: 'ধোয়া হচ্ছে', en: 'Washing' },
  workflowPackaging: { bn: 'প্যাকেজিং', en: 'Packaging' },
  workflowReady: { bn: 'ডেলিভারির জন্য প্রস্তুত', en: 'Ready for Delivery' },
  workflowDelivered: { bn: 'ডেলিভারি সম্পন্ন', en: 'Delivered' },

  // ── Tab Navigation ────────────────────────────────────────────────────────────
  tabHome: { bn: 'হোম', en: 'Home' },
  tabOrders: { bn: 'অর্ডার', en: 'Orders' },
  tabMessages: { bn: 'চ্যাট', en: 'Chat' },
  tabProfile: { bn: 'প্রোফাইল', en: 'Profile' },
} as const;

export type TranslationKey = keyof typeof translations;

export function t(key: TranslationKey, lang: Lang): string {
  return translations[key]?.[lang] ?? translations[key]?.bn ?? key;
}

export default translations;
