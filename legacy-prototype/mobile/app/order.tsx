import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Modal } from 'react-native';
import { useRouter } from 'expo-router';
import Svg, { Path, Rect, Circle, Line } from 'react-native-svg';
import { Colors, Shadows, toBn, money, serviceLabels } from '../constants/theme';
import { useStore } from '../services/store';
import { useLanguage } from '../services/language';

// Clothing Item Custom SVG Icons matching line drawing style in Screenshot 5
function ItemIcon({ name, color = '#0874f8' }: { name: string; color?: string }) {
  if (name === 'শার্ট' || name === 'টাই') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Path d="M20.38 3.46L16 6.14V3a1 1 0 0 0-1-1H9a1 1 0 0 0-1 1v3.14L3.62 3.46a1 1 0 0 0-1.38.92v6.62a1 1 0 0 0 .55.89L8 14.2V21a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1v-6.8l5.21-2.31a1 1 0 0 0 .55-.89V4.38a1 1 0 0 0-1.38-.92z" />
        <Path d="M12 2v4m0 0a2 2 0 0 1-2-2m2 2a2 2 0 0 0 2-2" />
        <Circle cx={12} cy={10} r={0.7} fill={color} />
        <Circle cx={12} cy={14} r={0.7} fill={color} />
        <Circle cx={12} cy={18} r={0.7} fill={color} />
      </Svg>
    );
  }
  if (name === 'প্যান্ট' || name === 'পায়জামা' || name === 'বেবি প্যান্ট') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Path d="M5 2h14v2.5L16.5 22h-3.5l-1-7-1 7H5.5L5 4.5V2z" />
        <Path d="M5 5.5h14" />
        <Line x1={12} y1={2} x2={12} y2={5.5} />
      </Svg>
    );
  }
  if (name === 'লুঙ্গি' || name === 'শাল') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Rect x={6} y={3} width={12} height={18} rx={1} />
        <Path d="M6 7h12M6 11h12M6 15h12M6 19h12" />
        <Line x1={10} y1={3} x2={10} y2={21} />
        <Line x1={14} y1={3} x2={14} y2={21} />
      </Svg>
    );
  }
  if (name === 'টি-শার্ট' || name === 'বেবি গেঞ্জি') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Path d="M18 2h-3.5a2.5 2.5 0 0 0-5 0H6a2 2 0 0 0-2 2v5a2 2 0 0 0 .6 1.4l3.4 3.4v6.2a2 2 0 0 0 2 2h4a2 2 0 0 0 2-2v-6.2l3.4-3.4a2 2 0 0 0 .6-1.4V4a2 2 0 0 0-2-2z" />
      </Svg>
    );
  }
  if (name === 'পাঞ্জাবি' || name === 'জুব্বা' || name === 'শেরওয়ানি') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Path d="M6 3h12l1 4h-3v14H8V7H5l1-4z" />
        <Path d="M12 3v6" />
        <Circle cx={12} cy={5} r={0.5} fill={color} />
        <Circle cx={12} cy={7} r={0.5} fill={color} />
      </Svg>
    );
  }
  if (name === 'কোট' || name === 'স্যুট' || name === 'জ্যাকেট') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Path d="M4 4h16v18H4V4z" />
        <Path d="M4 4l8 8 8-8" />
        <Path d="M8 12h8" />
        <Circle cx={12} cy={15} r={1} fill={color} />
      </Svg>
    );
  }
  if (name === 'কটি' || name === 'সুইটার') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Path d="M6 3h12v4l-1.5 14H7.5L6 7V3z" />
        <Path d="M6 3l6 5 6-5" />
        <Circle cx={12} cy={11} r={0.7} fill={color} />
        <Circle cx={12} cy={14} r={0.7} fill={color} />
      </Svg>
    );
  }
  if (name === 'বোরকা' || name === 'হিজাব') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Path d="M12 2C9 3.5 7 6 7 9v13h10V9c0-3-2-5.5-5-7z" />
        <Path d="M12 2v20" />
      </Svg>
    );
  }
  if (name === 'শাড়ি' || name === 'সালোয়ার, কামিজ, ওড়না' || name === 'লেহেঙ্গা / গাউন') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Path d="M4 6c3 0 6 2 9 2s6-2 7-2M4 11c4 0 7 3 11 3s5-3 5-3M4 16c4 0 6 3 10 3s6-3 6-3" />
        <Path d="M4 4v16h16V4H4z" />
      </Svg>
    );
  }
  if (name === 'ব্লাউজ' || name === 'বেবি ফ্রক') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Path d="M7 4h10l2 4v4h-3v10H8V12H5V8l2-4z" />
        <Path d="M7 4a5 5 0 0 0 10 0" />
      </Svg>
    );
  }
  if (name === 'बेडशीट / চাদর' || name === 'বেডশিট / চাদর' || name === 'পর্দা' || name === 'জায়নামাজ') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Rect x={3} y={6} width={18} height={12} rx={2} />
        <Path d="M3 10h18M3 14h18" />
      </Svg>
    );
  }
  if (name === 'বালিশ কভার' || name === 'তেওয়েল' || name === 'টাওয়েল') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Rect x={4} y={6} width={16} height={12} rx={1} />
        <Rect x={7} y={9} width={10} height={6} rx={0.5} />
      </Svg>
    );
  }
  if (name === 'কম্বল' || name === 'কমফোর্টার' || name === 'নকশী কাঁথা' || name === 'কাঁথা') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Rect x={3} y={4} width={18} height={16} rx={2} />
        <Line x1={9} y1={4} x2={9} y2={20} />
        <Line x1={15} y1={4} x2={15} y2={20} />
        <Line x1={3} y1={9} x2={21} y2={9} />
        <Line x1={3} y1={15} x2={21} y2={15} />
      </Svg>
    );
  }
  if (name === 'বেবি রম্পার' || name === 'বাচ্চার সেট') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Path d="M6 3h12v11a3 3 0 0 1-3 3h-6a3 3 0 0 1-3-3V3z" />
        <Path d="M9 17v4m6-4v4" />
      </Svg>
    );
  }
  if (name === 'আন্ডারওয়্যার') {
    return (
      <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
        <Path d="M3 4h18v7c0 3.8-3.2 7-7 7h-4c-3.8 0-7-3.2-7-7V4z" />
        <Path d="M3 7.5h18" />
        <Line x1={9} y1={7.5} x2={12} y2={18} />
        <Line x1={15} y1={7.5} x2={12} y2={18} />
      </Svg>
    );
  }

  // Fallback clothes hanger outline icon
  return (
    <Svg width={46} height={46} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
      <Path d="M12 2a3 3 0 0 1 3 3c0 1.3-.8 2.4-2 2.8V9.2l8.8 4.4A2 2 0 0 1 23 15.4V17a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2v-1.6c0-.8.5-1.5 1.2-1.8l8.8-4.4V7.8a3 3 0 0 1-2-2.8 3 3 0 0 1 3-3z" />
    </Svg>
  );
}

export default function OrderScreen() {
  const router = useRouter();
  const { selectedService, setSelectedService, cart, updateCartItem, getCartItems, cartSubtotal, cartCount, priceMap, itemsByCategory } = useStore();
  const { t } = useLanguage();
  const [category, setCategory] = useState('male');
  const [showCartModal, setShowCartModal] = useState(false);

  const categories = [
    { key: 'male', label: t('orderCatMale') },
    { key: 'female', label: t('orderCatFemale') },
    { key: 'kids', label: t('orderCatKids') },
    { key: 'home', label: t('orderCatHome') },
  ];

  const items = category === 'male'
    ? (itemsByCategory.male || [])
    : category === 'female'
    ? (itemsByCategory.female || [])
    : (itemsByCategory[category] || []);

  const getQty = (name: string) => {
    const key = `${selectedService}::${name}`;
    return cart[key]?.qty || 0;
  };

  const getPriceLabel = (name: string) => {
    const prices = priceMap[name] || {};
    const rate = selectedService === 'wash' ? (prices.wash || 0) : (prices.dry || 0);
    return `৳${toBn(rate)}${t('orderPerPiece')}`;
  };

  const cartItems = getCartItems();
  const count = cartCount();
  const subtotal = cartSubtotal();

  return (
    <View style={styles.container}>
      <ScrollView style={styles.scroll} contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        {/* Header */}
        <View style={styles.topbar}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backBtn} activeOpacity={0.7}>
            <Text style={styles.backText}>‹</Text>
          </TouchableOpacity>
          <Text style={styles.title}>{t('orderScreenTitle')}</Text>
          <View style={{ width: 36 }} />
        </View>

        {/* Service Tabs */}
        <View style={styles.serviceTabs}>
          {['wash', 'dry'].map((s) => (
            <TouchableOpacity
              key={s}
              style={[styles.serviceChip, selectedService === s && styles.serviceChipActive]}
              onPress={() => setSelectedService(s)}
            >
              <Text style={[styles.serviceChipText, selectedService === s && styles.serviceChipTextActive]}>
                {serviceLabels[s]}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Category switcher tabs */}
        <View style={styles.categoryTabs}>
          {categories.map((c) => (
            <TouchableOpacity
              key={c.key}
              style={[styles.categoryChip, category === c.key && styles.categoryChipActive]}
              onPress={() => setCategory(c.key)}
              activeOpacity={0.8}
            >
              <Text style={[styles.categoryChipText, category === c.key && styles.categoryChipTextActive]}>
                {c.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Item Cards with clean vector clothing drawings */}
        {items.map((item) => {
          const qty = getQty(item.name);
          return (
            <View key={item.name} style={styles.itemCard}>
              <View style={styles.itemIcon}>
                <ItemIcon name={item.name} />
              </View>
              <View style={styles.itemInfo}>
                <Text style={styles.itemName}>{item.name}</Text>
                <Text style={styles.itemPrice}>{getPriceLabel(item.name)}</Text>
              </View>
              <View style={styles.counter}>
                <TouchableOpacity
                  style={styles.roundBtn}
                  onPress={() => updateCartItem(item.name, selectedService, -1)}
                  disabled={qty === 0}
                  activeOpacity={0.6}
                >
                  <Text style={[styles.roundBtnText, qty === 0 && { color: '#bdc3c7' }]}>−</Text>
                </TouchableOpacity>
                <Text style={styles.qtyText}>{toBn(qty)}</Text>
                <TouchableOpacity
                  style={[styles.roundBtn, styles.roundBtnPlus]}
                  onPress={() => updateCartItem(item.name, selectedService, 1)}
                  activeOpacity={0.7}
                >
                  <Text style={[styles.roundBtnText, { color: '#fff' }]}>+</Text>
                </TouchableOpacity>
              </View>
            </View>
          );
        })}
      </ScrollView>

      {/* Footer */}
      <View style={styles.footer}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.cartPreview}>
          {cartItems.length > 0 ? (
            cartItems.map((item, i) => (
              <View key={i} style={[styles.cartPill, item.service === 'dry' && styles.cartPillDry]}>
                <Text style={styles.cartPillText}>
                  {serviceLabels[item.service] || item.service}: {item.name} × {toBn(item.qty)}
                </Text>
              </View>
            ))
          ) : (
            <Text style={styles.cartEmpty}>{t('orderCartEmpty')}</Text>
          )}
        </ScrollView>

        <View style={styles.footerBottom}>
          <View>
            <Text style={styles.cartCount}>{toBn(count)} {t('orderPiece')}</Text>
            <Text style={styles.cartTotal}>{money(subtotal)}</Text>
          </View>
          {count > 0 && (
            <TouchableOpacity onPress={() => setShowCartModal(true)} style={styles.seeAllBtn} activeOpacity={0.7}>
              <Text style={styles.seeAllText}>{t('orderSeeAll')}</Text>
            </TouchableOpacity>
          )}
          <TouchableOpacity
            style={styles.nextButton}
            onPress={() => { if (count > 0) router.push('/summary'); }}
            activeOpacity={0.85}
          >
            <Text style={styles.nextButtonText}>{t('orderNext')}</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Cart Customize Modal */}
      {showCartModal && (
        <TouchableOpacity 
          style={styles.modalOverlay} 
          activeOpacity={1} 
          onPress={() => setShowCartModal(false)}
        >
          <TouchableOpacity 
            style={styles.modalContent} 
            activeOpacity={1}
          >
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>{t('orderCartTitle')}</Text>
              <TouchableOpacity onPress={() => setShowCartModal(false)} style={styles.modalCloseBtn}>
                <Text style={styles.modalCloseText}>✕</Text>
              </TouchableOpacity>
            </View>

            <ScrollView style={styles.modalList} showsVerticalScrollIndicator={false}>
              {cartItems.length > 0 ? (
                cartItems.map((item, i) => (
                  <View key={i} style={styles.modalItem}>
                    <View style={styles.modalItemInfo}>
                      <Text style={styles.modalItemName}>{item.name}</Text>
                      <Text style={styles.modalItemService}>
                        {serviceLabels[item.service] || item.service} • {money(item.price)}{t('orderPerPiece')}
                      </Text>
                    </View>
                    <View style={styles.modalCounter}>
                      <TouchableOpacity
                        style={styles.modalRoundBtn}
                        onPress={() => updateCartItem(item.name, item.service, -1)}
                      >
                        <Text style={styles.modalRoundBtnText}>−</Text>
                      </TouchableOpacity>
                      <Text style={styles.modalQtyText}>{toBn(item.qty)}</Text>
                      <TouchableOpacity
                        style={[styles.modalRoundBtn, styles.modalRoundBtnPlus]}
                        onPress={() => updateCartItem(item.name, item.service, 1)}
                      >
                        <Text style={[styles.modalRoundBtnText, { color: '#fff' }]}>+</Text>
                      </TouchableOpacity>
                    </View>
                  </View>
                ))
              ) : (
                <View style={styles.modalEmpty}>
                  <Text style={styles.modalEmptyText}>{t('orderCartEmpty2')}</Text>
                </View>
              )}
            </ScrollView>

            <View style={styles.modalFooter}>
              <View style={styles.modalTotalRow}>
                <Text style={styles.modalTotalLabel}>{t('orderTotal')}</Text>
                <Text style={styles.modalTotalVal}>{money(subtotal)} ({toBn(count)} {t('orderPiece')})</Text>
              </View>
              <TouchableOpacity
                style={styles.modalConfirmBtn}
                onPress={() => {
                  setShowCartModal(false);
                  if (count > 0) router.push('/summary');
                }}
              >
                <Text style={styles.modalConfirmText}>{t('orderNextStep')}</Text>
              </TouchableOpacity>
            </View>
          </TouchableOpacity>
        </TouchableOpacity>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f8fc' },
  scroll: { flex: 1 },
  content: { paddingHorizontal: 22, paddingTop: 16, paddingBottom: 240 },
  topbar: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', minHeight: 44 },
  backBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#fff',
    borderWidth: 1.5,
    borderColor: '#e2e8f0',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 2,
  },
  backText: {
    fontSize: 22,
    fontWeight: '900',
    color: '#334155',
    lineHeight: 24,
    textAlign: 'center',
  },
  title: { fontSize: 26, fontWeight: '900', color: '#091632' },
  serviceTabs: { flexDirection: 'row', gap: 8, marginTop: 14, marginBottom: 8 },
  serviceChip: {
    flex: 1,
    minHeight: 42,
    borderRadius: 12,
    backgroundColor: '#eef2f6',
    justifyContent: 'center',
    alignItems: 'center',
  },
  serviceChipActive: { backgroundColor: '#0874f8', ...Shadows.button },
  serviceChipText: { fontWeight: '900', fontSize: 14, color: '#5d6676' },
  serviceChipTextActive: { color: '#fff' },
  categoryTabs: { flexDirection: 'row', gap: 6, marginTop: 12, marginBottom: 16 },
  categoryChip: {
    flex: 1,
    minHeight: 38,
    borderRadius: 18,
    backgroundColor: '#eef2f6',
    justifyContent: 'center',
    alignItems: 'center',
  },
  categoryChipActive: { backgroundColor: '#0874f8', ...Shadows.button },
  categoryChipText: { fontWeight: '800', fontSize: 13, color: '#5d6676' },
  categoryChipTextActive: { color: '#fff' },
  itemCard: {
    flexDirection: 'row',
    alignItems: 'center',
    minHeight: 90,
    borderRadius: 12,
    padding: 12,
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#eef3fa',
    marginBottom: 10,
    gap: 10,
    ...Shadows.card,
  },
  itemIcon: {
    width: 52,
    height: 52,
    borderRadius: 10,
    backgroundColor: '#f1f7fe',
    justifyContent: 'center',
    alignItems: 'center',
  },
  itemInfo: { flex: 1, gap: 2 },
  itemName: { fontSize: 17, fontWeight: '900', color: '#091632' },
  itemPrice: { fontSize: 13, color: '#727b8e', fontWeight: '600' },
  counter: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  roundBtn: {
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: '#eef0f4',
    justifyContent: 'center',
    alignItems: 'center',
  },
  roundBtnPlus: { backgroundColor: '#0874f8' },
  roundBtnText: { fontSize: 18, fontWeight: '800', color: '#667085', lineHeight: 20 },
  qtyText: { fontSize: 18, fontWeight: '900', width: 20, textAlign: 'center', color: '#091632' },
  footer: {
    backgroundColor: 'rgba(255,255,255,0.98)',
    borderTopLeftRadius: 22,
    borderTopRightRadius: 22,
    shadowColor: '#091632',
    shadowOffset: { width: 0, height: -14 },
    shadowOpacity: 0.11,
    shadowRadius: 16,
    elevation: 20,
    paddingHorizontal: 18,
    paddingTop: 10,
    paddingBottom: 16,
  },
  cartPreview: { maxHeight: 36, marginBottom: 8 },
  cartPill: {
    backgroundColor: '#edf5ff',
    borderWidth: 1,
    borderColor: '#dceaff',
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 7,
    marginRight: 8,
  },
  cartPillDry: { backgroundColor: '#f1f3f7', borderColor: '#e2e6ee' },
  cartPillText: { fontSize: 12, fontWeight: '900', color: Colors.blueDark },
  cartEmpty: { color: Colors.muted, fontSize: 14, paddingVertical: 8 },
  footerBottom: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  cartCount: { fontSize: 18, fontWeight: '900', color: Colors.ink },
  cartTotal: { fontSize: 28, fontWeight: '900', color: Colors.blue },
  nextButton: {
    minHeight: 50,
    borderRadius: 8,
    backgroundColor: Colors.blue,
    paddingHorizontal: 28,
    justifyContent: 'center',
    alignItems: 'center',
    ...Shadows.button,
  },
  nextButtonText: { color: '#fff', fontSize: 18, fontWeight: '900' },
  seeAllBtn: {
    backgroundColor: '#eef4ff',
    borderWidth: 1.2,
    borderColor: '#cfe2ff',
    borderRadius: 20,
    paddingHorizontal: 14,
    paddingVertical: 8,
    justifyContent: 'center',
    alignItems: 'center',
    marginHorizontal: 8,
  },
  seeAllText: {
    color: Colors.blue,
    fontWeight: '800',
    fontSize: 14,
  },
  modalOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(9, 22, 50, 0.46)',
    justifyContent: 'flex-end',
    zIndex: 999,
  },
  modalContent: {
    backgroundColor: '#fff',
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    maxHeight: '75%',
    paddingHorizontal: 22,
    paddingTop: 22,
    paddingBottom: 34,
    shadowColor: '#091632',
    shadowOffset: { width: 0, height: -10 },
    shadowOpacity: 0.15,
    shadowRadius: 18,
    elevation: 24,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  modalTitle: {
    fontSize: 22,
    fontWeight: '900',
    color: Colors.ink,
  },
  modalCloseBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#f1f3f7',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalCloseText: {
    fontSize: 16,
    color: Colors.muted,
    fontWeight: '800',
  },
  modalList: {
    marginVertical: 10,
  },
  modalItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f3f7',
  },
  modalItemInfo: {
    flex: 1,
    gap: 4,
  },
  modalItemName: {
    fontSize: 18,
    fontWeight: '800',
    color: Colors.ink,
  },
  modalItemService: {
    fontSize: 13,
    color: Colors.muted,
  },
  modalCounter: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  modalRoundBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#eef0f4',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalRoundBtnPlus: {
    backgroundColor: Colors.blue,
  },
  modalRoundBtnText: {
    fontSize: 20,
    fontWeight: '800',
    color: '#667085',
    lineHeight: 22,
  },
  modalQtyText: {
    fontSize: 18,
    fontWeight: '900',
    width: 24,
    textAlign: 'center',
    color: Colors.ink,
  },
  modalEmpty: {
    paddingVertical: 40,
    alignItems: 'center',
  },
  modalEmptyText: {
    color: Colors.muted,
    fontSize: 16,
    fontWeight: '700',
  },
  modalFooter: {
    marginTop: 18,
    gap: 14,
  },
  modalTotalRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  modalTotalLabel: {
    fontSize: 16,
    fontWeight: '800',
    color: Colors.muted,
  },
  modalTotalVal: {
    fontSize: 20,
    fontWeight: '900',
    color: Colors.blue,
  },
  modalConfirmBtn: {
    height: 54,
    borderRadius: 8,
    backgroundColor: Colors.blue,
    justifyContent: 'center',
    alignItems: 'center',
    ...Shadows.button,
  },
  modalConfirmText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '900',
  },
});
