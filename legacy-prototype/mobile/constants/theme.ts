import { Dimensions } from 'react-native';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

export const Colors = {
  blue: '#0874f8',
  blueDark: '#071939',
  cyan: '#10c9b2',
  green: '#13c49a',
  red: '#f43f5e',
  ink: '#091632',
  muted: '#727b8e',
  line: '#e7ebf2',
  soft: '#f5f8fc',
  card: '#ffffff',
  white: '#ffffff',
  bg: '#eef3f8',
  orange: '#ef7b2d',
};

export const Gradients = {
  splash: ['#0874f8', '#07c8b6'],
  hero: ['#0874f8', '#12c5b1'],
  dashboardHead: ['#071939', '#0874f8'],
  banner: ['#0874f8', '#11c8aa'],
};

export const Shadows = {
  card: {
    shadowColor: '#091632',
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.09,
    shadowRadius: 15,
    elevation: 6,
  },
  button: {
    shadowColor: '#0874f8',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.2,
    shadowRadius: 10,
    elevation: 8,
  },
  greenButton: {
    shadowColor: '#13c49a',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.22,
    shadowRadius: 12,
    elevation: 8,
  },
};

export const Fonts = {
  regular: 'System',
  bold: 'System',
};

export const Spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 22,
  xxl: 28,
};

export const BorderRadius = {
  sm: 8,
  md: 10,
  lg: 14,
  xl: 22,
  pill: 999,
};

export const SCREEN_W = SCREEN_WIDTH;

// Bengali number converter
export const toBn = (value: number | string): string =>
  String(value).replace(/\d/g, (d) => '০১২৩৪৫৬৭৮৯'[parseInt(d)]);

export const money = (value: number): string => `৳${toBn(value)}`;

// Service labels
export const serviceLabels: Record<string, string> = {
  wash: 'ওয়াশ',
  dry: 'ড্রাই ক্লিন',
};

// Delivery constants
export const FREE_DELIVERY_MINIMUM = 300;
export const DELIVERY_CHARGE = 30;
export const DELIVERY_TIME_TEXT = 'Pickup After 3-7 Day Complete';

// Workflow steps
export const workflowSteps = [
  { key: 'pending', title: 'অর্ডার পেন্ডিং', note: 'অ্যাডমিন approval দিলে অর্ডার confirmed হবে' },
  { key: 'confirmed', title: 'অর্ডার কনফার্মড', note: 'আপনার অর্ডার গ্রহণ করা হয়েছে' },
  { key: 'collecting', title: 'কাপড় সংগ্রহ করা হচ্ছে', note: 'ডেলিভারিম্যান আপনার ঠিকানায় যাচ্ছে' },
  { key: 'collected', title: 'কাপড় সংগ্রহ করা হয়েছে', note: 'ডেলিভারিম্যান কাপড় গ্রহণ করেছেন' },
  { key: 'washing', title: 'ধোয়া হচ্ছে', note: 'আপনার কাপড় যত্নসহকারে প্রসেস করা হচ্ছে।' },
  { key: 'packaging', title: 'প্যাকেজিং', note: 'কাপড় প্যাকেজিং করা হচ্ছে' },
  { key: 'ready', title: 'ডেলিভারির জন্য প্রস্তুত', note: 'রাইডার অফিস থেকে প্যাকেজ গ্রহণ করবে' },
  { key: 'delivered', title: 'ডেলিভারি সম্পন্ন', note: 'অর্ডার সফলভাবে সম্পন্ন হয়েছে' },
];

// Price map (from the original prototype)
export const priceMap: Record<string, Record<string, number>> = {
  'শার্ট': { wash: 40, dry: 60, combo: 50, iron: 8 },
  'প্যান্ট': { wash: 40, dry: 60, combo: 50, iron: 8 },
  'টি-শার্ট': { wash: 40, dry: 60, combo: 50, iron: 8 },
  'পাঞ্জাবি': { wash: 50, dry: 70, combo: 60, iron: 10 },
  'জুব্বা': { wash: 60, dry: 80, combo: 70, iron: 12 },
  'পায়জামা': { wash: 40, dry: 60, combo: 50, iron: 8 },
  'কোট': { wash: 200, dry: 200, combo: 210, iron: 20 },
  'কটি': { wash: 120, dry: 120, combo: 130, iron: 15 },
  'সুইটার': { wash: 100, dry: 200, combo: 110, iron: 20 },
  'জ্যাকেট': { wash: 100, dry: 200, combo: 110, iron: 20 },
  'শাল': { wash: 100, dry: 200, combo: 110, iron: 20 },
  'শেরওয়ানি': { wash: 250, dry: 250, combo: 260, iron: 25 },
  'স্যুট': { wash: 250, dry: 350, combo: 270, iron: 25 },
  'টাই': { wash: 40, dry: 40, combo: 45, iron: 8 },
  'বোরকা': { wash: 80, dry: 120, combo: 95, iron: 15 },
  'শাড়ি': { wash: 150, dry: 400, combo: 180, iron: 30 },
  'সালোয়ার, কামিজ, ওড়না': { wash: 120, dry: 180, combo: 140, iron: 25 },
  'ব্লাউজ': { wash: 40, dry: 60, combo: 50, iron: 8 },
  'লেহেঙ্গা / গাউন': { wash: 300, dry: 800, combo: 350, iron: 40 },
  'হিজাব': { wash: 40, dry: 60, combo: 50, iron: 8 },
  'বেডশিট / চাদর': { wash: 60, dry: 60, combo: 70, iron: 15 },
  'বালিশ কভার': { wash: 30, dry: 30, combo: 35, iron: 8 },
  'টাওয়েল': { wash: 80, dry: 80, combo: 85, iron: 8 },
  'পর্দা': { wash: 150, dry: 250, combo: 180, iron: 20 },
  'কম্বল': { wash: 300, dry: 800, combo: 350, iron: 30 },
  'কমফোর্টার': { wash: 200, dry: 650, combo: 250, iron: 30 },
  'নকশী কাঁথা': { wash: 60, dry: 80, combo: 70, iron: 10 },
  'জায়নামাজ': { wash: 0, dry: 0, combo: 0, iron: 0 },
  'বেবি ফ্রক': { wash: 30, dry: 50, combo: 40, iron: 5 },
  'বেবি রম্পার': { wash: 30, dry: 50, combo: 40, iron: 5 },
  'বাচ্চার সেট': { wash: 50, dry: 80, combo: 65, iron: 10 },
  'বেবি প্যান্ট': { wash: 25, dry: 40, combo: 30, iron: 5 },
  'বেবি গেঞ্জি': { wash: 25, dry: 40, combo: 30, iron: 5 },
  'কাঁথা': { wash: 30, dry: 50, combo: 40, iron: 5 },
};

// Items organized by category (for the order screen)
export const itemsByCategory: Record<string, { name: string; icon: string }[]> = {
  male: [
    { name: 'শার্ট', icon: '👔' },
    { name: 'প্যান্ট', icon: '👖' },
    { name: 'টি-শার্ট', icon: '👕' },
    { name: 'পাঞ্জাবি', icon: '🥻' },
    { name: 'জুব্বা', icon: '🧥' },
    { name: 'পায়জামা', icon: '👖' },
    { name: 'কোট', icon: '🧥' },
    { name: 'কটি', icon: '🦺' },
    { name: 'সুইটার', icon: '🧶' },
    { name: 'জ্যাকেট', icon: '🧥' },
    { name: 'শাল', icon: '🧣' },
    { name: 'শেরওয়ানি', icon: '👘' },
    { name: 'স্যুট', icon: '🤵' },
    { name: 'টাই', icon: '👔' },
  ],
  female: [
    { name: 'বোরকা', icon: '🧕' },
    { name: 'শাড়ি', icon: '👘' },
    { name: 'সালোয়ার, কামিজ, ওড়না', icon: '👗' },
    { name: 'ব্লাউজ', icon: '👚' },
    { name: 'লেহেঙ্গা / গাউন', icon: '👗' },
    { name: 'হিজাব', icon: '🧕' },
  ],
  kids: [
    { name: 'বেবি ফ্রক', icon: '👗' },
    { name: 'বেবি রম্পার', icon: '👶' },
    { name: 'বাচ্চার সেট', icon: '👕' },
    { name: 'বেবি প্যান্ট', icon: '👖' },
    { name: 'বেবি গেঞ্জি', icon: '👕' },
    { name: 'কাঁথা', icon: '🧵' },
  ],
  home: [
    { name: 'বেডশিট / চাদর', icon: '🛏️' },
    { name: 'বালিশ কভার', icon: '🛌' },
    { name: 'টাওয়েল', icon: '🧻' },
    { name: 'পর্দা', icon: '🪟' },
    { name: 'কম্বল', icon: '🛏️' },
    { name: 'কমফোর্টার', icon: '🛏️' },
    { name: 'নকশী কাঁথা', icon: '🧵' },
    { name: 'জায়নামাজ', icon: '🕌' },
  ],
};

// Area options
export const areaOptions = [
  'বাস টার্মিনাল', 'কক্সবাজার সিটি কলেজ', 'আলীর জাহাঁল',
  'রুমালিয়ারছড়া - উত্তর', 'রুমালিয়ারছড়া - দক্ষিণ', 'পিটিআই স্কুল (PTI) এলাকা',
  'রাস্তার মাথা', 'তারাবনিয়া ছড়া', 'খালুর দোকান', 'টেকপাড়া',
  'পেশকার পাড়া', 'বার্মিজ মার্কেট', 'বাজারঘাটা', 'ব্রাহ্ম মন্দির',
  'পেট্রোল পাম্প', 'পানবাজার রোড', 'ঘুনগাছ তলা', 'ঝাউতলা',
  'হলিডে মোড়', 'নুনিয়ারছড়া', 'সুগন্ধা পয়েন্ট', 'লাবণী পয়েন্ট', 'কলাতলী',
];

// Riders
export const ridersData: Record<string, { id: string; avatar: string; name: string; phone: string; displayPhone: string }> = {
  rider_karim: { id: 'rider_karim', avatar: 'ক', name: 'করিম ভাই', phone: '01912345678', displayPhone: '০১৯XXXXXXXX' },
  rider_mamun: { id: 'rider_mamun', avatar: 'ম', name: 'মামুন ভাই', phone: '01612345678', displayPhone: '০১৬XXXXXXXX' },
  rider_shahin: { id: 'rider_shahin', avatar: 'শ', name: 'শাহিন ভাই', phone: '01512345678', displayPhone: '০১৫XXXXXXXX' },
};
