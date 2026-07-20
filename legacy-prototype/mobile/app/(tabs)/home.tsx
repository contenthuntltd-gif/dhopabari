import React, { useEffect, useState, useRef } from 'react';
import {
  View, Text, TouchableOpacity, StyleSheet, Modal, ScrollView,
  Animated, Linking,
} from 'react-native';
import FontAwesome from '@expo/vector-icons/FontAwesome';
import { LinearGradient } from 'expo-linear-gradient';

const WHATSAPP_NUMBER = '8801973615217';
import { useRouter } from 'expo-router';
import { Colors, Gradients, toBn, money, Shadows, FREE_DELIVERY_MINIMUM } from '../../constants/theme';
import { useStore } from '../../services/store';
import { getOrders } from '../../services/api';
import { useLanguage } from '../../services/language';

export default function HomeScreen() {
  const router = useRouter();
  const { user, orderWorkflowStatus } = useStore();
  const { t, lang } = useLanguage();
  const [recentOrder, setRecentOrder] = useState<any>(null);
  const [allOrders, setAllOrders] = useState<any[]>([]);
  const [showNotif, setShowNotif] = useState(false);
  const pulseAnim = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    getOrders().then((orders: any[]) => {
      setAllOrders(orders);
      if (orders.length) setRecentOrder(orders[0]);
    }).catch(() => {});
  }, []);

  // Pulse animation for free delivery banner
  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, { toValue: 1.03, duration: 900, useNativeDriver: true }),
        Animated.timing(pulseAnim, { toValue: 1, duration: 900, useNativeDriver: true }),
      ])
    ).start();
  }, []);

  const statusLabel = () => {
    const labels: Record<string, string> = {
      pending: t('workflowPending'),
      confirmed: t('workflowConfirmed'),
      collecting: t('workflowCollecting'),
      washing: t('workflowWashing'),
      packaging: t('workflowPackaging'),
      ready: t('workflowReady'),
      delivered: t('workflowDelivered'),
    };
    return labels[orderWorkflowStatus] || t('workflowPending');
  };

  // Ongoing orders (not delivered/cancelled) — shown in notification panel
  const ongoingOrders = allOrders.filter((o) => {
    const s = (o.status || '').toLowerCase();
    return !s.includes('সম্পন্ন') && !s.includes('delivered') &&
           !s.includes('বাতিল') && !s.includes('cancelled');
  });
  const notifCount = ongoingOrders.length;

  const openWhatsApp = () => {
    const msg = lang === 'bn'
      ? 'আসসালামু আলাইকুম, আমি ধোপা বাড়ি অ্যাপ থেকে যোগাযোগ করছি।'
      : 'Hi, I am contacting from Dopa Bari app.';
    const url = `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(msg)}`;
    Linking.openURL(url);
  };

  return (
    <View style={styles.root}>
      {/* ── Notification Overlay Panel ── */}
      {showNotif && (
        <View style={styles.notifOverlay}>
          <View style={styles.notifPanel}>
            <View style={styles.notifHeader}>
              <Text style={styles.notifTitle}>
                {lang === 'bn' ? '🔔 অর্ডার আপডেট' : '🔔 Order Updates'}
              </Text>
              <TouchableOpacity onPress={() => setShowNotif(false)}>
                <Text style={styles.notifClose}>✕</Text>
              </TouchableOpacity>
            </View>

            <ScrollView showsVerticalScrollIndicator={false}>
              {ongoingOrders.length === 0 ? (
                <View style={styles.notifEmpty}>
                  <Text style={styles.notifEmptyIcon}>📭</Text>
                  <Text style={styles.notifEmptyText}>
                    {lang === 'bn' ? 'কোনো চলমান অর্ডার নেই' : 'No active orders'}
                  </Text>
                </View>
              ) : (
                ongoingOrders.map((order) => (
                  <TouchableOpacity
                    key={order.id}
                    style={styles.notifItem}
                    onPress={() => {
                      setShowNotif(false);
                      router.push({
                        pathname: '/tracking',
                        params: { orderId: order.id, riderId: order.riderId }
                      });
                    }}
                    activeOpacity={0.8}
                  >
                    <View style={styles.notifDot} />
                    <View style={{ flex: 1 }}>
                      <View style={styles.notifItemTop}>
                        <Text style={styles.notifOrderId}>#{order.id}</Text>
                        <Text style={styles.notifMoney}>{money(order.total || 0)}</Text>
                      </View>
                      <Text style={styles.notifStatus}>
                        {lang === 'bn' ? 'স্ট্যাটাস: ' : 'Status: '}
                        <Text style={styles.notifStatusVal}>{order.status || t('ordersPending')}</Text>
                      </Text>
                      <Text style={styles.notifDate}>
                        {order.createdAt ? new Date(order.createdAt).toLocaleDateString(
                          lang === 'bn' ? 'bn-BD' : 'en-US',
                          { day: 'numeric', month: 'short' }
                        ) : ''}
                      </Text>
                    </View>
                    <Text style={styles.notifArrow}>›</Text>
                  </TouchableOpacity>
                ))
              )}
            </ScrollView>
          </View>
        </View>
      )}

      {/* ── Top bar ── */}
      <View style={styles.topbar}>
        <Text style={styles.brand}>{t('appName')}</Text>
        <View style={styles.topRight}>
          <TouchableOpacity onPress={() => router.push('/price-list')}>
            <Text style={styles.priceLink}>📋</Text>
          </TouchableOpacity>
          {/* Notification Bell */}
          <TouchableOpacity style={styles.bellWrap} onPress={() => setShowNotif(true)}>
            <Text style={styles.bell}>🔔</Text>
            {notifCount > 0 && (
              <View style={styles.badge}>
                <Text style={styles.badgeText}>{notifCount}</Text>
              </View>
            )}
          </TouchableOpacity>
        </View>
      </View>

      {/* ── Greeting ── */}
      <View style={styles.greetRow}>
        <Text style={styles.greeting}>{t('homeGreeting')}, {user.name || t('homeCustomer')} 👋</Text>
        <Text style={styles.dateText}>
          {new Date().toLocaleDateString(lang === 'bn' ? 'bn-BD' : 'en-US', { weekday: 'short', day: 'numeric', month: 'short' })}
        </Text>
      </View>

      {/* ── FREE DELIVERY Banner ── */}
      <Animated.View style={[styles.freeBannerWrap, { transform: [{ scale: pulseAnim }] }]}>
        <LinearGradient
          colors={['#ff7043', '#ff9800']}
          start={{ x: 0, y: 0 }} end={{ x: 1, y: 0 }}
          style={styles.freeBanner}
        >
          <Text style={styles.freeBannerEmoji}>🚚</Text>
          <View style={{ flex: 1 }}>
            <Text style={styles.freeBannerTitle}>
              {lang === 'bn' ? 'ফ্রি ডেলিভারি!' : 'FREE DELIVERY!'}
            </Text>
            <Text style={styles.freeBannerSub}>
              {lang === 'bn'
                ? `৳${FREE_DELIVERY_MINIMUM} বা তার বেশি অর্ডারে ডেলিভারি একদম বিনামূল্যে`
                : `On orders of ৳${FREE_DELIVERY_MINIMUM} or more — completely free!`}
            </Text>
          </View>
          <View style={styles.freeBannerBadge}>
            <Text style={styles.freeBannerBadgeText}>FREE</Text>
          </View>
        </LinearGradient>
      </Animated.View>

      {/* ── Hero Card ── */}
      <LinearGradient colors={['#025bf3', '#0ea5e9']} style={styles.heroCard} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }}>
        <View style={styles.heroLeft}>
          {/* Cover Badges */}
          <View style={styles.heroBadgesRow}>
            <View style={styles.heroLocationBadge}>
              <Text style={styles.heroLocationText}>📍 {lang === 'bn' ? 'শুধুমাত্র কক্সবাজার সদর' : 'Only Cox\'s Bazar Sadar'}</Text>
            </View>
            <View style={styles.heroFreeBadge}>
              <Text style={styles.heroFreeText}>🚚 {lang === 'bn' ? 'ফ্রি ডেলিভারি' : 'Free Delivery'}</Text>
            </View>
          </View>

          <Text style={styles.heroTitle}>
            {t('splashTagline')}
          </Text>
          
          <Text style={styles.heroSub}>
            {lang === 'bn' 
              ? 'কক্সবাজার সদরের প্রিমিয়াম লন্ড্রি ও ড্রাইক্লিনিং সেবা' 
              : 'Premium laundry & dry cleaning service in Cox\'s Bazar Sadar'}
          </Text>

          <TouchableOpacity style={styles.heroBtnPremium} onPress={() => router.push('/order')} activeOpacity={0.85}>
            <Text style={styles.heroBtnTextPremium}>{t('homeOrderBtn')}</Text>
          </TouchableOpacity>
        </View>
      </LinearGradient>

      {/* ── Service cards ── */}
      <View style={styles.sectionRow}>
        <Text style={styles.sectionTitle}>{t('homeServices')}</Text>
      </View>
      <View style={styles.serviceRow}>
        <TouchableOpacity style={styles.svcCard} onPress={() => router.push('/order')} activeOpacity={0.7}>
          <Text style={styles.svcIcon}>🧺</Text>
          <Text style={styles.svcTitle}>{t('homeWash')}</Text>
          <Text style={styles.svcPrice}>{t('homeWashPrice')}</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.svcCard} onPress={() => router.push('/order')} activeOpacity={0.7}>
          <Text style={styles.svcIcon}>👔</Text>
          <Text style={styles.svcTitle}>{t('homeDryClean')}</Text>
          <Text style={styles.svcPrice}>{t('homeDryPrice')}</Text>
        </TouchableOpacity>
      </View>

      {/* ── Order Track Button ── */}
      <TouchableOpacity
        style={styles.trackBtn}
        onPress={() => router.push('/(tabs)/orders')}
        activeOpacity={0.8}
      >
        <View style={styles.trackLeft}>
          <Text style={styles.trackIcon}>📦</Text>
          <View>
            <Text style={styles.trackTitle}>
              {lang === 'bn' ? 'অর্ডার ট্র্যাক করুন' : 'Track Orders'}
            </Text>
            <Text style={styles.trackSub}>
              {lang === 'bn' ? 'আপনার সব অর্ডারের আপডেট দেখুন' : 'See all your order updates'}
            </Text>
          </View>
        </View>
        <Text style={styles.trackArrow}>›</Text>
      </TouchableOpacity>

      {/* ── WhatsApp Support FAB ── */}
      <TouchableOpacity
        style={styles.whatsappFab}
        onPress={openWhatsApp}
        activeOpacity={0.85}
      >
        <FontAwesome name="whatsapp" size={34} color="#fff" />
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1, backgroundColor: '#f7f9fc',
    paddingHorizontal: 16, paddingTop: 16,
  },

  // Top bar
  topbar: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 },
  brand: { color: Colors.blue, fontWeight: '900', fontSize: 24 },
  topRight: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  priceLink: { fontSize: 20 },

  // Bell / Notification
  bellWrap: { position: 'relative', padding: 4 },
  bell: { fontSize: 22 },
  badge: {
    position: 'absolute', top: 0, right: 0,
    backgroundColor: '#e53935', borderRadius: 9, minWidth: 18, height: 18,
    justifyContent: 'center', alignItems: 'center', paddingHorizontal: 3,
    borderWidth: 1.5, borderColor: '#f7f9fc',
  },
  badgeText: { color: '#fff', fontSize: 10, fontWeight: '900' },

  // Greeting
  greetRow: { marginBottom: 10 },
  greeting: { fontSize: 19, fontWeight: '900', color: Colors.ink, lineHeight: 26 },
  dateText: { fontSize: 12, color: Colors.muted, marginTop: 1 },

  // Free Delivery Banner
  freeBannerWrap: { marginBottom: 10, borderRadius: 14, overflow: 'hidden', ...Shadows.button as any },
  freeBanner: {
    flexDirection: 'row', alignItems: 'center',
    paddingHorizontal: 14, paddingVertical: 11, gap: 10,
  },
  freeBannerEmoji: { fontSize: 26 },
  freeBannerTitle: { fontSize: 15, fontWeight: '900', color: '#fff', lineHeight: 20 },
  freeBannerSub: { fontSize: 11, color: 'rgba(255,255,255,0.9)', lineHeight: 16, marginTop: 1 },
  freeBannerBadge: {
    backgroundColor: '#fff', borderRadius: 8,
    paddingHorizontal: 8, paddingVertical: 4,
  },
  freeBannerBadgeText: { color: '#ff7043', fontWeight: '900', fontSize: 12 },

  // Hero
  heroCard: {
    borderRadius: 16,
    padding: 18,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 14,
    shadowColor: '#025bf3',
    shadowOffset: { width: 0, height: 12 },
    shadowOpacity: 0.18,
    shadowRadius: 18,
    elevation: 8,
  },
  heroLeft: { flex: 1 },
  heroBadgesRow: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 10,
    flexWrap: 'wrap',
  },
  heroLocationBadge: {
    backgroundColor: '#fff',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 20,
  },
  heroLocationText: {
    fontSize: 10,
    color: '#ef4444',
    fontWeight: '900',
  },
  heroFreeBadge: {
    backgroundColor: '#f59e0b',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 20,
  },
  heroFreeText: {
    fontSize: 10,
    color: '#fff',
    fontWeight: '900',
  },
  heroTitle: {
    fontSize: 22,
    fontWeight: '900',
    color: '#fff',
    lineHeight: 28,
    textShadowColor: 'rgba(0, 0, 0, 0.2)',
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 4,
    marginBottom: 6,
  },
  heroSub: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.9)',
    fontWeight: '700',
    lineHeight: 18,
    marginBottom: 14,
  },
  heroBtnPremium: {
    alignSelf: 'flex-start',
    backgroundColor: '#fff',
    borderRadius: 30,
    paddingHorizontal: 16,
    paddingVertical: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },
  heroBtnTextPremium: {
    color: '#025bf3',
    fontWeight: '900',
    fontSize: 13,
  },

  // Services
  sectionRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 },
  sectionTitle: { fontSize: 15, fontWeight: '900', color: Colors.ink },
  serviceRow: { flexDirection: 'row', gap: 10, marginBottom: 12 },
  svcCard: {
    flex: 1, backgroundColor: '#fff', borderRadius: 12, padding: 12,
    borderWidth: 1, borderColor: '#edf0f7', ...Shadows.card as any,
  },
  svcIcon: { fontSize: 24, marginBottom: 5 },
  svcTitle: { fontSize: 14, fontWeight: '900', color: Colors.ink },
  svcPrice: { fontSize: 11, color: Colors.muted, marginTop: 2 },

  // Track Order Button
  trackBtn: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    backgroundColor: '#fff', borderRadius: 12, padding: 14,
    borderWidth: 1, borderColor: '#edf0f7', ...Shadows.card as any,
  },
  trackLeft: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  trackIcon: { fontSize: 28 },
  trackTitle: { fontSize: 15, fontWeight: '900', color: Colors.ink, lineHeight: 20 },
  trackSub: { fontSize: 11, color: Colors.muted, marginTop: 1 },
  trackArrow: { fontSize: 26, color: Colors.blue, fontWeight: '900' },

  // WhatsApp Floating Button
  whatsappFab: {
    position: 'absolute',
    bottom: 24,
    right: 20,
    width: 60,
    height: 60,
    borderRadius: 30,
    backgroundColor: '#25D366',
    justifyContent: 'center',
    alignItems: 'center',
    ...Shadows.button as any,
    elevation: 5,
  },

  // Notification Modal Overlay
  notifOverlay: {
    position: 'absolute',
    top: -16, // Offsets styles.root's paddingTop: 16
    left: -16, // Offsets styles.root's paddingHorizontal: 16
    right: -16, // Offsets styles.root's paddingHorizontal: 16
    bottom: 0,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end', // slides up from bottom
    zIndex: 999,
  },
  notifPanel: {
    backgroundColor: '#fff',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    maxHeight: '75%',
    paddingBottom: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -8 },
    shadowOpacity: 0.15,
    shadowRadius: 16,
    elevation: 20,
  },
  notifHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 18,
    borderBottomWidth: 1.5,
    borderBottomColor: '#edf0f7',
  },
  notifTitle: {
    fontSize: 18,
    fontWeight: '900',
    color: Colors.ink,
  },
  notifClose: {
    fontSize: 20,
    color: Colors.muted,
    paddingHorizontal: 8,
  },
  notifEmpty: {
    paddingVertical: 50,
    alignItems: 'center',
    justifyContent: 'center',
  },
  notifEmptyIcon: {
    fontSize: 48,
    marginBottom: 10,
  },
  notifEmptyText: {
    fontSize: 14,
    color: Colors.muted,
    fontWeight: '700',
  },
  notifItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f4f9',
  },
  notifDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: Colors.blue,
    marginRight: 12,
  },
  notifItemTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  notifOrderId: {
    fontSize: 14,
    fontWeight: '900',
    color: Colors.ink,
  },
  notifMoney: {
    fontSize: 14,
    fontWeight: '900',
    color: Colors.blue,
  },
  notifStatus: {
    fontSize: 12,
    color: Colors.muted,
  },
  notifStatusVal: {
    color: Colors.blue,
    fontWeight: '850',
  },
  notifDate: {
    fontSize: 11,
    color: Colors.muted,
    marginTop: 4,
  },
  notifArrow: {
    fontSize: 22,
    color: Colors.muted,
    marginLeft: 8,
  },
});
