import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, TextInput, Linking } from 'react-native';
import { useRouter } from 'expo-router';
import { Colors, Shadows, ridersData, areaOptions } from '../../constants/theme';
import { useStore } from '../../services/store';
import { useLanguage } from '../../services/language';
import { saveCustomer } from '../../services/api';

export default function ProfileScreen() {
  const router = useRouter();
  const { user, setUser } = useStore();
  const { lang, setLang, t } = useLanguage();

  // State modals
  const [showEditProfile, setShowEditProfile] = useState(false);
  const [showEditAddress, setShowEditAddress] = useState(false);
  const [showReviews, setShowReviews] = useState(false);
  const [showAbout, setShowAbout] = useState(false);

  // Profile Edit fields
  const [name, setName] = useState(user.name || '');
  const [avatar, setAvatar] = useState(user.avatar || '👨');

  // Address Edit fields
  const [area, setArea] = useState(user.area || '');
  const [address, setAddress] = useState(user.address || '');
  const [showAreaDropdown, setShowAreaDropdown] = useState(false);

  // Review states
  const [selectedRider, setSelectedRider] = useState('rider_karim');
  const [reviewRating, setReviewRating] = useState(5);
  const [reviewComment, setReviewComment] = useState('');
  const [reviews, setReviews] = useState([
    { riderName: 'করিম ভাই', customerName: 'মুনতাসির', rating: 5, comment: 'অসাধারণ সার্ভিস! খুব দ্রুত কাপড় নিয়ে গিয়েছে এবং সময়মতো দিয়ে গিয়েছে।' },
    { riderName: 'শাহিন ভাই', customerName: 'ফারহান', rating: 5, comment: 'খুবই ভদ্র রাইডার। অনেক দ্রুত এবং যত্ন সহকারে ডেলিভারি দিয়েছেন।' },
    { riderName: 'মামুন ভাই', customerName: 'আরিফ', rating: 4, comment: 'ব্যবহার অনেক ভালো ছিল, কক্সবাজার শহরের ভেতরে সবচেয়ে নির্ভরযোগ্য লন্ড্রি।' },
  ]);

  // Emojis for custom avatars
  const avatarsList = ['👨', '👩', '🧑', '👦', '👧', '🧔', '👵', '👴', '🧢', '🧺', '👕', '👔', '🧼', '✨', '👑'];

  // Cox's Bazar Area List
  const coxAreas = areaOptions;

  const handleSaveProfile = async () => {
    if (!name.trim()) return;
    const updated = { ...user, name: name.trim(), avatar };
    setUser(updated);
    setShowEditProfile(false);
    try {
      await saveCustomer(updated);
    } catch (e) {}
  };

  const handleSaveAddress = async () => {
    if (!area) return;
    const updated = { ...user, area, address: address.trim() };
    setUser(updated);
    setShowEditAddress(false);
    try {
      await saveCustomer(updated);
    } catch (e) {}
  };

  const handleAddReview = () => {
    if (!reviewComment.trim()) return;
    const riderObj = ridersData[selectedRider] || ridersData.rider_karim;
    const newRev = {
      riderName: riderObj.name,
      customerName: user.name || (lang === 'bn' ? 'গ্রাহক' : 'Customer'),
      rating: reviewRating,
      comment: reviewComment.trim(),
    };
    setReviews([newRev, ...reviews]);
    setReviewComment('');
  };

  const openWhatsApp = () => {
    const WHATSAPP_NUMBER = '8801973615217';
    const msg = lang === 'bn'
      ? 'আসসালামু আলাইকুম, আমি ধোপা বাড়ি অ্যাপ থেকে কাস্টমার সাপোর্ট ও হেল্প সেন্টারে যোগাযোগ করতে চাই।'
      : 'Hi, I would like to contact the customer support & help center of Dopa Bari.';
    const url = `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(msg)}`;
    Linking.openURL(url);
  };

  const isAdmin = user.phone === '8801973615217' || user.phone === '01973615217' || user.phone === '০১৯৭৩৬১৫২১৭' || user.name?.toLowerCase().includes('admin');

  const menuItems = [
    { 
      icon: '📍', 
      label: t('profileAddress'), 
      value: `${user.area || (lang === 'bn' ? 'এলাকা' : 'Area')} ›`,
      onPress: () => {
        setArea(user.area || '');
        setAddress(user.address || '');
        setShowEditAddress(true);
      }
    },
    { 
      icon: '▣', 
      label: t('profileOrders'), 
      value: '›', 
      onPress: () => router.push('/(tabs)/orders') 
    },
    { 
      icon: '★', 
      label: lang === 'bn' ? 'রেটিং ও রিভিউ' : 'Ratings & Reviews', 
      value: '›', 
      onPress: () => setShowReviews(true) 
    },
    { 
      icon: '☎', 
      label: t('profileContact'), 
      value: '›', 
      onPress: openWhatsApp 
    },
    { 
      icon: 'i', 
      label: t('profileAbout'), 
      value: '›', 
      onPress: () => setShowAbout(true) 
    },
    ...(isAdmin ? [{ 
      icon: '🛠️', 
      label: lang === 'bn' ? 'অ্যাডমিন প্যানেল' : 'Admin Panel', 
      value: '›', 
      onPress: () => router.push('/admin-dashboard') 
    }] : []),
    { 
      icon: '◎', 
      label: 'LANG_SWITCH', 
      value: '' 
    },
  ];

  return (
    <View style={styles.root}>
      <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity 
            style={styles.avatar}
            onPress={() => {
              setName(user.name || '');
              setAvatar(user.avatar || '👨');
              setShowEditProfile(true);
            }}
            activeOpacity={0.8}
          >
            <Text style={styles.avatarText}>{user.avatar || '👨'}</Text>
            <View style={styles.editDot}>
              <Text style={styles.editIcon}>✎</Text>
            </View>
          </TouchableOpacity>
          <Text style={styles.name}>{user.name || t('profileCustomer')}</Text>
          <Text style={styles.phone}>{user.phone}</Text>
          <Text style={styles.addressText}>
            📍 {user.area ? `${user.area}, ` : ''}{user.address || t('profileCoxBazar')}
          </Text>
        </View>

        {/* Menu */}
        <View style={styles.menuContainer}>
          <View style={styles.menuCard}>
            {menuItems.map((item, i) => {
              if (item.label === 'LANG_SWITCH') {
                return (
                  <View key={i} style={[styles.menuRow, i < menuItems.length - 1 && styles.menuRowBorder]}>
                    <View style={styles.menuIcon}>
                      <Text style={styles.menuIconText}>🌐</Text>
                    </View>
                    <Text style={styles.menuLabel}>{t('profileLanguage')}</Text>
                    <View style={styles.langToggleRow}>
                      <TouchableOpacity 
                        style={[styles.langChip, lang === 'bn' && styles.langChipActive]} 
                        onPress={() => setLang('bn')}
                      >
                        <Text style={[styles.langChipText, lang === 'bn' && styles.langChipTextActive]}>বাংলা</Text>
                      </TouchableOpacity>
                      <TouchableOpacity 
                        style={[styles.langChip, lang === 'en' && styles.langChipActive]} 
                        onPress={() => setLang('en')}
                      >
                        <Text style={[styles.langChipText, lang === 'en' && styles.langChipTextActive]}>English</Text>
                      </TouchableOpacity>
                    </View>
                  </View>
                );
              }
              return (
                <TouchableOpacity
                  key={i}
                  style={[styles.menuRow, i < menuItems.length - 1 && styles.menuRowBorder]}
                  onPress={item.onPress}
                  activeOpacity={0.7}
                >
                  <View style={styles.menuIcon}>
                    <Text style={styles.menuIconText}>{item.icon}</Text>
                  </View>
                  <Text style={styles.menuLabel}>{item.label}</Text>
                  <Text style={styles.menuValue}>{item.value}</Text>
                </TouchableOpacity>
              );
            })}
          </View>

          {/* Logout */}
          <TouchableOpacity
            style={styles.logoutRow}
            onPress={() => {
              setUser({ phone: '', name: '', area: '', address: '', avatar: '👨' });
              router.replace('/');
            }}
            activeOpacity={0.7}
          >
            <Text style={styles.logoutIcon}>↪</Text>
            <Text style={styles.logoutText}>{t('profileLogout')}</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>

      {/* ── 1. Edit Profile Overlay ── */}
      {showEditProfile && (
        <View style={styles.overlay}>
          <View style={styles.dialog}>
            <View style={styles.dialogHeader}>
              <Text style={styles.dialogTitle}>
                {lang === 'bn' ? 'প্রোফাইল এডিট' : 'Edit Profile'}
              </Text>
              <TouchableOpacity onPress={() => setShowEditProfile(false)}>
                <Text style={styles.dialogClose}>✕</Text>
              </TouchableOpacity>
            </View>

            <Text style={styles.formLabel}>{lang === 'bn' ? 'পূর্ণ নাম' : 'Full Name'}</Text>
            <TextInput
              style={styles.input}
              value={name}
              onChangeText={setName}
              placeholder={lang === 'bn' ? 'আপনার নাম লিখুন' : 'Enter your name'}
              placeholderTextColor="#a2abb8"
            />

            <Text style={styles.formLabel}>{lang === 'bn' ? 'প্রোফাইল ছবি (ইমোজি)' : 'Profile Photo (Emoji)'}</Text>
            <View style={styles.avatarGrid}>
              {avatarsList.map((av) => (
                <TouchableOpacity
                  key={av}
                  style={[styles.avatarChip, avatar === av && styles.avatarChipActive]}
                  onPress={() => setAvatar(av)}
                  activeOpacity={0.8}
                >
                  <Text style={styles.avatarChipText}>{av}</Text>
                </TouchableOpacity>
              ))}
            </View>

            <View style={styles.dialogBtns}>
              <TouchableOpacity style={styles.dialogBtnCancel} onPress={() => setShowEditProfile(false)}>
                <Text style={styles.dialogBtnCancelText}>{lang === 'bn' ? 'বাতিল' : 'Cancel'}</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.dialogBtnSave} onPress={handleSaveProfile}>
                <Text style={styles.dialogBtnSaveText}>{lang === 'bn' ? 'সংরক্ষণ' : 'Save'}</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      )}

      {/* ── 2. Edit Address Overlay ── */}
      {showEditAddress && (
        <View style={styles.overlay}>
          <View style={styles.dialog}>
            <View style={styles.dialogHeader}>
              <Text style={styles.dialogTitle}>
                {lang === 'bn' ? 'ঠিকানা আপডেট' : 'Update Address'}
              </Text>
              <TouchableOpacity onPress={() => setShowEditAddress(false)}>
                <Text style={styles.dialogClose}>✕</Text>
              </TouchableOpacity>
            </View>

            <Text style={styles.formLabel}>{lang === 'bn' ? 'এলাকা নির্বাচন করুন' : 'Select Area'}</Text>
            <TouchableOpacity 
              style={styles.areaSelectBtn} 
              onPress={() => setShowAreaDropdown(!showAreaDropdown)}
              activeOpacity={0.9}
            >
              <Text style={area ? styles.areaSelectText : styles.areaSelectTextEmpty}>
                {area || (lang === 'bn' ? 'এলাকা বেছে নিন' : 'Select area')}
              </Text>
              <Text style={{ color: Colors.muted }}>⌄</Text>
            </TouchableOpacity>

            {showAreaDropdown && (
              <ScrollView style={styles.areaDropdownList} nestedScrollEnabled={true}>
                {coxAreas.map((item) => (
                  <TouchableOpacity
                    key={item}
                    style={[styles.areaDropdownItem, area === item && styles.areaDropdownItemActive]}
                    onPress={() => {
                      setArea(item);
                      setShowAreaDropdown(false);
                    }}
                  >
                    <Text style={styles.areaDropdownText}>{item}</Text>
                  </TouchableOpacity>
                ))}
              </ScrollView>
            )}

            <Text style={styles.formLabel}>{lang === 'bn' ? 'বিস্তারিত ঠিকানা' : 'Detailed Address'}</Text>
            <TextInput
              style={[styles.input, { height: 80, textAlignVertical: 'top' }]}
              value={address}
              onChangeText={setAddress}
              placeholder={lang === 'bn' ? 'বাসা নম্বর, রোড, এলাকা লিখুন' : 'Enter house, road, area details'}
              placeholderTextColor="#a2abb8"
              multiline={true}
            />

            <View style={styles.dialogBtns}>
              <TouchableOpacity style={styles.dialogBtnCancel} onPress={() => setShowEditAddress(false)}>
                <Text style={styles.dialogBtnCancelText}>{lang === 'bn' ? 'বাতিল' : 'Cancel'}</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.dialogBtnSave} onPress={handleSaveAddress}>
                <Text style={styles.dialogBtnSaveText}>{lang === 'bn' ? 'সংরক্ষণ' : 'Save'}</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      )}

      {/* ── 3. Ratings & Reviews Overlay ── */}
      {showReviews && (
        <View style={styles.overlay}>
          <View style={styles.dialog}>
            <View style={styles.dialogHeader}>
              <Text style={styles.dialogTitle}>
                {lang === 'bn' ? 'রাইডার রিভিউ ও রেটিং' : 'Rider Ratings & Reviews'}
              </Text>
              <TouchableOpacity onPress={() => setShowReviews(false)}>
                <Text style={styles.dialogClose}>✕</Text>
              </TouchableOpacity>
            </View>

            {/* Rider select */}
            <Text style={styles.formLabel}>{lang === 'bn' ? 'রাইডার নির্বাচন করুন' : 'Select Delivery Rider'}</Text>
            <View style={styles.riderSelectorRow}>
              {Object.keys(ridersData).map((key) => {
                const r = ridersData[key];
                return (
                  <TouchableOpacity
                    key={key}
                    style={[styles.riderChip, selectedRider === key && styles.riderChipActive]}
                    onPress={() => setSelectedRider(key)}
                  >
                    <Text style={[styles.riderChipText, selectedRider === key && styles.riderChipTextActive]}>
                      {r.name}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>

            {/* Stars */}
            <View style={styles.starRow}>
              {[1, 2, 3, 4, 5].map((star) => (
                <TouchableOpacity
                  key={star}
                  style={styles.starBtn}
                  onPress={() => setReviewRating(star)}
                >
                  <Text style={[styles.starIcon, reviewRating >= star && styles.starIconActive]}>★</Text>
                </TouchableOpacity>
              ))}
            </View>

            {/* Comment */}
            <TextInput
              style={styles.input}
              value={reviewComment}
              onChangeText={setReviewComment}
              placeholder={lang === 'bn' ? 'রাইডারের জন্য আপনার মন্তব্য লিখুন...' : 'Write your comment for the rider...'}
              placeholderTextColor="#a2abb8"
            />
            <TouchableOpacity style={styles.reviewSubmitBtn} onPress={handleAddReview}>
              <Text style={styles.reviewSubmitText}>
                {lang === 'bn' ? 'রিভিউ সাবমিট করুন' : 'Submit Review'}
              </Text>
            </TouchableOpacity>

            {/* Reviews list */}
            <Text style={[styles.formLabel, { borderTopWidth: 1, borderTopColor: '#edf0f7', paddingTop: 12 }]}>
              {lang === 'bn' ? 'সাম্প্রতিক রিভিউসমূহ' : 'Recent Reviews'}
            </Text>
            <ScrollView style={styles.reviewsScroll} showsVerticalScrollIndicator={false}>
              {reviews.map((rev, index) => (
                <View key={index} style={styles.reviewCard}>
                  <View style={styles.reviewCardTop}>
                    <Text style={styles.reviewRider}>🏍️ {rev.riderName}</Text>
                    <Text style={{ color: '#fdb022', fontWeight: '950', fontSize: 13 }}>
                      {'★'.repeat(rev.rating)}{'☆'.repeat(5 - rev.rating)}
                    </Text>
                  </View>
                  <Text style={styles.reviewCustomer}>{rev.customerName}</Text>
                  <Text style={styles.reviewComment}>{rev.comment}</Text>
                </View>
              ))}
            </ScrollView>
          </View>
        </View>
      )}

      {/* ── 4. About Us Overlay ── */}
      {showAbout && (
        <View style={styles.overlay}>
          <View style={styles.dialog}>
            <View style={styles.dialogHeader}>
              <Text style={styles.dialogTitle}>
                {lang === 'bn' ? 'আমাদের সম্পর্কে' : 'About Us'}
              </Text>
              <TouchableOpacity onPress={() => setShowAbout(false)}>
                <Text style={styles.dialogClose}>✕</Text>
              </TouchableOpacity>
            </View>

            <ScrollView style={styles.aboutScroll} showsVerticalScrollIndicator={false}>
              <View style={styles.aboutBadge}>
                <Text style={styles.aboutBadgeText}>Cox's Bazar Laundry Partner</Text>
              </View>
              <Text style={styles.aboutTitle}>
                {lang === 'bn' 
                  ? 'কক্সবাজার শহরের সবচেয়ে বিশ্বস্ত লন্ড্রি প্রতিষ্ঠান' 
                  : "Cox's Bazar's Most Trusted Laundry Institution"}
              </Text>
              
              <Text style={styles.aboutPara}>
                {lang === 'bn' ? (
                  `ধোপা বাড়ি (Dopa Bari) কক্সবাজার শহরের সর্ববৃহৎ ও আধুনিক প্রযুক্তিসম্পন্ন এক্সপ্রেস লন্ড্রি সার্ভিস। আমরা কক্সবাজার পৌরসভা ও পর্যটন জোনের সর্বত্র অত্যন্ত নিষ্ঠা ও সুনামের সাথে গ্রাহকদের সেবা দিয়ে আসছি। 

আমাদের বিশেষত্ব:
• সম্পূর্ণ আধুনিক মেশিনে স্বাস্থ্যকর উপায়ে কাপড় ধৌতকরণ
• প্রিমিয়াম ড্রাই ক্লিনিং সেবা ও নিপুণ ইস্ত্রি (Iron)
• শহরের যেকোনো এলাকা থেকে ফ্রি পিকআপ ও দ্রুততম সময়ে ডেলিভারি
• কাপড় সুরক্ষায় শতভাগ দায়িত্বশীল ও বিশ্বস্ত টিম

আপনার দৈনন্দিন ব্যস্ততা থেকে মুক্তি দিতে ধোপা বাড়ি সর্বদা পাশে আছে। আমরা শুধু কাপড় পরিষ্কার করি না, আমরা আপনার ব্যক্তিত্ব ও সতেজতা বজায় রাখি!`
                ) : (
                  `Dopa Bari is Cox's Bazar's premier and most reliable express laundry service. We serve across the Cox's Bazar municipal areas and tourism zones with great care and reputation.

Our Highlights:
• Hygienic and clean washing in modern automatic machines
• Premium dry cleaning & crisp, expert steam pressing
• Free pick-up & fast doorstep delivery citywide
• Highly responsible & trusted service guarantee

Let us handle the laundry while you enjoy Cox's Bazar. We do not just clean fabrics; we maintain your confidence and elegance!`
                )}
              </Text>
            </ScrollView>

            <TouchableOpacity 
              style={[styles.dialogBtnCancel, { borderColor: Colors.blue, marginTop: 12 }]} 
              onPress={() => setShowAbout(false)}
            >
              <Text style={[styles.dialogBtnCancelText, { color: Colors.blue }]}>
                {lang === 'bn' ? 'বন্ধ করুন' : 'Close'}
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, position: 'relative' },
  container: { flex: 1, backgroundColor: '#f7f9fc' },
  header: {
    backgroundColor: Colors.blue,
    paddingTop: 16,
    paddingBottom: 18,
    paddingHorizontal: 22,
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
    alignItems: 'center',
    ...Shadows.button as any,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    borderWidth: 3,
    borderColor: '#fff',
    backgroundColor: '#fff',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
    position: 'relative',
  },
  avatarText: { fontSize: 48 },
  editDot: {
    position: 'absolute',
    right: -4,
    bottom: -4,
    width: 30,
    height: 30,
    backgroundColor: '#fff',
    borderRadius: 15,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1.5,
    borderColor: Colors.blue,
  },
  editIcon: { color: Colors.blue, fontSize: 13, fontWeight: '900' },
  name: { fontSize: 20, fontWeight: '900', color: '#fff' },
  phone: { color: 'rgba(255,255,255,0.86)', fontSize: 13, marginTop: 2, fontWeight: '700' },
  addressText: { color: 'rgba(255,255,255,0.92)', fontSize: 12, marginTop: 5, fontWeight: '700' },
  
  langToggleRow: {
    flexDirection: 'row',
    gap: 6,
    alignItems: 'center',
  },
  langChip: {
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 12,
    backgroundColor: '#f1f3f7',
    borderWidth: 1,
    borderColor: '#e2e6ee',
  },
  langChipActive: {
    backgroundColor: Colors.blue,
    borderColor: Colors.blue,
  },
  langChipText: {
    fontSize: 13,
    fontWeight: '700',
    color: '#5d6676',
  },
  langChipTextActive: {
    color: '#fff',
  },
  menuContainer: { paddingHorizontal: 16, paddingTop: 14, paddingBottom: 60 },
  menuCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#eef1f6',
    ...Shadows.card as any,
    overflow: 'hidden',
  },
  menuRow: {
    flexDirection: 'row',
    alignItems: 'center',
    minHeight: 52,
    paddingHorizontal: 14,
    gap: 10,
  },
  menuRowBorder: { borderBottomWidth: 1, borderBottomColor: Colors.line },
  menuIcon: {
    width: 32,
    height: 32,
    borderRadius: 8,
    backgroundColor: '#edf4ff',
    justifyContent: 'center',
    alignItems: 'center',
  },
  menuIconText: { color: Colors.blue, fontSize: 15 },
  menuLabel: { flex: 1, fontSize: 15, fontWeight: '800', color: Colors.ink },
  menuValue: { color: Colors.muted, fontSize: 13, fontWeight: '700' },
  logoutRow: {
    flexDirection: 'row',
    alignItems: 'center',
    minHeight: 52,
    paddingHorizontal: 14,
    gap: 10,
    backgroundColor: '#fff',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#eef1f6',
    ...Shadows.card as any,
    marginTop: 12,
  },
  logoutIcon: { fontSize: 17, color: '#d92d20' },
  logoutText: { fontSize: 15, fontWeight: '800', color: '#d92d20' },

  // Overlay Styling
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0,0,0,0.56)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000,
    padding: 16,
  },
  dialog: {
    backgroundColor: '#fff',
    borderRadius: 20,
    padding: 20,
    width: '100%',
    maxWidth: 380,
    maxHeight: '85%',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.2,
    shadowRadius: 24,
    elevation: 10,
  },
  dialogHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 14,
  },
  dialogTitle: {
    fontSize: 18,
    fontWeight: '900',
    color: Colors.ink,
  },
  dialogClose: {
    fontSize: 20,
    color: Colors.muted,
    paddingHorizontal: 8,
  },
  formLabel: {
    fontSize: 13,
    fontWeight: '800',
    color: Colors.muted,
    marginBottom: 6,
    marginTop: 8,
  },
  input: {
    borderWidth: 1.5,
    borderColor: '#e8edf6',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 15,
    color: Colors.ink,
    backgroundColor: '#f8fafc',
    marginBottom: 12,
  },
  avatarGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginVertical: 10,
    justifyContent: 'center',
  },
  avatarChip: {
    width: 44,
    height: 44,
    borderRadius: 22,
    borderWidth: 1.5,
    borderColor: '#e8edf6',
    backgroundColor: '#f8fafc',
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarChipActive: {
    borderColor: Colors.blue,
    backgroundColor: '#eaf4ff',
  },
  avatarChipText: {
    fontSize: 22,
  },
  dialogBtns: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 14,
  },
  dialogBtnCancel: {
    flex: 1,
    borderWidth: 1.5,
    borderColor: '#dde3ec',
    borderRadius: 10,
    paddingVertical: 12,
    alignItems: 'center',
  },
  dialogBtnCancelText: {
    fontWeight: '800',
    color: '#5d6676',
    fontSize: 14,
  },
  dialogBtnSave: {
    flex: 1,
    backgroundColor: Colors.blue,
    borderRadius: 10,
    paddingVertical: 12,
    alignItems: 'center',
  },
  dialogBtnSaveText: {
    fontWeight: '900',
    color: '#fff',
    fontSize: 14,
  },
  areaSelectBtn: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderWidth: 1.5,
    borderColor: '#e8edf6',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    backgroundColor: '#f8fafc',
    marginBottom: 10,
  },
  areaSelectText: {
    fontSize: 15,
    color: Colors.ink,
    fontWeight: '700',
  },
  areaSelectTextEmpty: {
    fontSize: 15,
    color: Colors.muted,
  },
  areaDropdownList: {
    maxHeight: 180,
    borderWidth: 1.5,
    borderColor: '#e8edf6',
    borderRadius: 10,
    backgroundColor: '#fff',
    marginBottom: 12,
  },
  areaDropdownItem: {
    padding: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f4f9',
  },
  areaDropdownItemActive: {
    backgroundColor: '#eaf4ff',
  },
  areaDropdownText: {
    fontSize: 14,
    color: Colors.ink,
    fontWeight: '750',
  },
  riderSelectorRow: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 12,
  },
  riderChip: {
    flex: 1,
    paddingVertical: 8,
    borderRadius: 10,
    borderWidth: 1.5,
    borderColor: '#e8edf6',
    alignItems: 'center',
    backgroundColor: '#f8fafc',
  },
  riderChipActive: {
    borderColor: Colors.blue,
    backgroundColor: '#eaf4ff',
  },
  riderChipText: {
    fontSize: 12,
    fontWeight: '805',
    color: '#5d6676',
  },
  riderChipTextActive: {
    color: Colors.blue,
  },
  starRow: {
    flexDirection: 'row',
    gap: 8,
    justifyContent: 'center',
    marginVertical: 10,
  },
  starBtn: {
    padding: 4,
  },
  starIcon: {
    fontSize: 26,
    color: '#d0d5dd',
  },
  starIconActive: {
    color: '#fdb022',
  },
  reviewSubmitBtn: {
    backgroundColor: Colors.blue,
    borderRadius: 8,
    paddingVertical: 10,
    alignItems: 'center',
    marginTop: 4,
    marginBottom: 14,
  },
  reviewSubmitText: {
    color: '#fff',
    fontWeight: '800',
    fontSize: 13,
  },
  reviewsScroll: {
    flex: 1,
    marginTop: 10,
  },
  reviewCard: {
    padding: 12,
    backgroundColor: '#f8fafc',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#f0f3f8',
    marginBottom: 8,
  },
  reviewCardTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  reviewRider: {
    fontSize: 12,
    fontWeight: '800',
    color: Colors.blue,
    backgroundColor: '#eaf4ff',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  reviewCustomer: {
    fontSize: 12,
    fontWeight: '700',
    color: Colors.ink,
  },
  reviewComment: {
    fontSize: 12,
    color: '#475467',
    marginTop: 4,
    lineHeight: 18,
  },
  aboutScroll: {
    flex: 1,
  },
  aboutBadge: {
    backgroundColor: '#eaf4ff',
    alignSelf: 'center',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 8,
    marginBottom: 10,
  },
  aboutBadgeText: {
    color: Colors.blue,
    fontWeight: '900',
    fontSize: 12,
  },
  aboutTitle: {
    fontSize: 16,
    fontWeight: '900',
    color: Colors.ink,
    textAlign: 'center',
    marginBottom: 14,
  },
  aboutPara: {
    fontSize: 13,
    color: '#344054',
    lineHeight: 22,
    marginBottom: 14,
    textAlign: 'justify',
  },
});
