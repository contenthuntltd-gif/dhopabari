import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  View, Text, TouchableOpacity, StyleSheet, ScrollView,
  ActivityIndicator, RefreshControl, Linking, Animated, Alert
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useRouter, useLocalSearchParams } from 'expo-router';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Colors, Shadows, toBn, money, ridersData } from '../constants/theme';
import { getOrders, updateOrderStatus, getRiders } from '../services/api';
import { useLanguage } from '../services/language';

/* ─── helpers ───────────────────────────────────────────── */
const TODAY = new Date().toDateString();

function isDelivered(s: string) {
  return s.includes('সম্পন্ন') || s.toLowerCase().includes('delivered');
}
function isCancelled(s: string) {
  return s.includes('বাতিল') || s.toLowerCase().includes('cancelled');
}
function isActive(s: string) {
  return !isDelivered(s) && !isCancelled(s);
}
function isCOD(order: any) {
  const p = (order.payment || '').toLowerCase();
  return !p || p === 'cod' || p.includes('cod') || p.includes('cash');
}
function isToday(iso: string) {
  if (!iso) return false;
  return new Date(iso).toDateString() === TODAY;
}

// Status badge style
const STATUS_COLOR: Record<string, { bg: string; text: string; border: string }> = {
  delivered: { bg: '#e8f5e9', text: '#2e7d32', border: '#c8e6c9' },
  cancelled:  { bg: '#ffebee', text: '#c62828', border: '#ffcdd2' },
  default:    { bg: '#fff3e0', text: '#e65100', border: '#ffe0b2' },
};
function statusStyle(s: string) {
  if (isDelivered(s)) return STATUS_COLOR.delivered;
  if (isCancelled(s)) return STATUS_COLOR.cancelled;
  return STATUS_COLOR.default;
}

// Workflow step list (for advancing status)
const STATUS_WORKFLOW = [
  'অর্ডার পেন্ডিং',
  'অর্ডার কনফার্মড',
  'কাপড় সংগ্রহ করা হচ্ছে',
  'কাপড় সংগ্রহ করা হয়েছে',
  'ধোয়া হচ্ছে',
  'প্যাকেজিং',
  'ডেলিভারির জন্য প্রস্তুত',
  'ডেলিভারি সম্পন্ন',
];

/* ─── main screen ───────────────────────────────────────── */
export default function RiderDashboard() {
  const router   = useRouter();
  const { lang } = useLanguage();
  const params   = useLocalSearchParams<{ riderId?: string }>();

  const [authChecked, setAuthChecked] = useState(false);
  const [activeRiderId, setActiveRiderId] = useState<string>('');
  const [riderInfo, setRiderInfo] = useState<any>(null);

  useEffect(() => {
    const checkAuth = async () => {
      const storedRiderId = await AsyncStorage.getItem('rider_session_id');
      const activeId = params.riderId || storedRiderId;
      if (!activeId) {
        router.replace('/rider-login');
        return;
      }
      setActiveRiderId(activeId);
      setAuthChecked(true);
    };
    checkAuth();
  }, [params.riderId]);

  const riderId = activeRiderId;
  const staticRider = ridersData[riderId] || ridersData['rider_karim'];
  const rider = riderInfo || {
    name: staticRider.name,
    phone: staticRider.phone,
    displayPhone: staticRider.displayPhone || staticRider.phone,
    avatar: staticRider.avatar
  };

  const [orders, setOrders]       = useState<any[]>([]);
  const [loading, setLoading]     = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [tab, setTab]             = useState<'active' | 'done'>('active');
  const [advancingId, setAdvancingId] = useState<string | null>(null);

  // Animated badge pulse
  const pulse = useRef(new Animated.Value(1)).current;
  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(pulse, { toValue: 1.12, duration: 700, useNativeDriver: true }),
        Animated.timing(pulse, { toValue: 1, duration: 700, useNativeDriver: true }),
      ])
    ).start();
  }, []);

  const loadData = useCallback(async () => {
    if (!riderId) return;
    try {
      const [all, rds] = await Promise.all([getOrders(), getRiders()]);
      // Filter only this rider's orders
      const mine = (all as any[]).filter(o => o.riderId === riderId);
      setOrders(mine.sort((a, b) => (a.id > b.id ? -1 : 1)));

      const found = rds.find((r: any) => r.id === riderId);
      if (found) {
        setRiderInfo({
          name: found.name,
          phone: found.phone,
          displayPhone: found.phone,
          avatar: found.avatar || found.name.charAt(0)
        });
      }
    } catch {
      // silent
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [riderId]);

  useEffect(() => {
    if (authChecked) {
      loadData();
    }
  }, [authChecked, loadData]);

  const onRefresh = () => { setRefreshing(true); loadData(); };

  /* Advance order to next workflow step */
  const handleAdvance = async (order: any) => {
    const idx = STATUS_WORKFLOW.indexOf(order.status);
    if (idx < 0 || idx >= STATUS_WORKFLOW.length - 1) return;
    const next = STATUS_WORKFLOW[idx + 1];

    setAdvancingId(order.id);
    try {
      await updateOrderStatus(order.id, next, riderId);
      await loadData();
    } catch {
      Alert.alert('Error', 'Status update failed. Try again.');
    } finally {
      setAdvancingId(null);
    }
  };

  /* Call customer */
  const callCustomer = (phone: string) => {
    const clean = phone.replace(/[^\d]/g, '');
    Linking.openURL(`tel:${clean}`).catch(() => {});
  };

  /* WhatsApp to customer */
  const whatsappCustomer = (phone: string) => {
    if (!phone) return;
    let clean = phone.replace(/[^\d]/g, '');
    if (clean.startsWith('0') && clean.length === 11) {
      clean = '88' + clean;
    } else if (clean.startsWith('1') && clean.length === 10) {
      clean = '880' + clean;
    }
    const msg = encodeURIComponent(
      lang === 'bn'
        ? 'আসসালামু আলাইকুম, আমি ধোপা বাড়ি রাইডার বলছি। আপনার অর্ডারের বিষয়ে যোগাযোগ করছি।'
        : 'Hello, I am the Dhopa Bari delivery rider contacting you regarding your order.'
    );
    Linking.openURL(`https://wa.me/${clean}?text=${msg}`).catch(() => {});
  };

  /* ── derived stats ── */
  const activeOrders    = orders.filter(o => isActive(o.status));
  const completedOrders = orders.filter(o => isDelivered(o.status));
  const todayDone       = completedOrders.filter(o => isToday(o.updatedAt || o.createdAt));
  const todayCOD        = todayDone.filter(isCOD).reduce((s, o) => s + (o.total || 0), 0);
  const totalCOD        = completedOrders.filter(isCOD).reduce((s, o) => s + (o.total || 0), 0);

  const displayOrders = tab === 'active' ? activeOrders : completedOrders;

  if (!authChecked) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#fff' }}>
        <ActivityIndicator size="large" color={Colors.blue} />
      </View>
    );
  }

  return (
    <View style={styles.root}>
      <ScrollView
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} colors={[Colors.blue]} />}
      >
        {/* ── Gradient Header ── */}
        <LinearGradient colors={['#071939', '#0874f8', '#1d9bf0']} style={styles.header}>
          {/* Header Row */}
          <View style={styles.headerRow}>
            <TouchableOpacity onPress={() => router.back()} style={styles.backBtn} activeOpacity={0.7}>
              <Text style={styles.backText}>‹</Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={async () => {
                await AsyncStorage.removeItem('rider_session_id');
                await AsyncStorage.removeItem('rider_session_name');
                router.replace('/');
              }}
              style={styles.logoutBtn}
              activeOpacity={0.7}
            >
              <Text style={styles.logoutBtnText}>🚪</Text>
            </TouchableOpacity>
          </View>

          {/* Rider identity */}
          <View style={styles.headerCenter}>
            <Animated.View style={[styles.avatarCircle, { transform: [{ scale: pulse }] }]}>
              <Text style={styles.avatarText}>{rider.avatar}</Text>
            </Animated.View>
            <Text style={styles.riderName}>{rider.name}</Text>
            <Text style={styles.riderPhone}>📞 {rider.displayPhone}</Text>

            {/* Online badge */}
            <View style={styles.onlineBadge}>
              <View style={styles.onlineDot} />
              <Text style={styles.onlineBadgeText}>Online • রাইডার প্যানেল</Text>
            </View>
          </View>

          {/* Stats strip */}
          <View style={styles.statsStrip}>
            <View style={styles.statBox}>
              <Text style={styles.statVal}>{toBn(activeOrders.length)}</Text>
              <Text style={styles.statLbl}>{lang === 'bn' ? 'চলমান' : 'Active'}</Text>
            </View>
            <View style={styles.statDiv} />
            <View style={styles.statBox}>
              <Text style={styles.statVal}>{toBn(completedOrders.length)}</Text>
              <Text style={styles.statLbl}>{lang === 'bn' ? 'সম্পন্ন' : 'Completed'}</Text>
            </View>
            <View style={styles.statDiv} />
            <View style={styles.statBox}>
              <Text style={[styles.statVal, { color: '#fbbf24' }]}>{toBn(todayDone.length)}</Text>
              <Text style={styles.statLbl}>{lang === 'bn' ? 'আজ' : 'Today'}</Text>
            </View>
            <View style={styles.statDiv} />
            <View style={styles.statBox}>
              <Text style={[styles.statVal, { fontSize: 14 }]}>{money(todayCOD)}</Text>
              <Text style={styles.statLbl}>{lang === 'bn' ? 'আজ COD' : 'Today COD'}</Text>
            </View>
          </View>
        </LinearGradient>

        {/* ── COD Summary Card ── */}
        <View style={styles.codCard}>
          <View style={styles.codCardLeft}>
            <Text style={styles.codCardIcon}>💵</Text>
            <View>
              <Text style={styles.codCardTitle}>{lang === 'bn' ? 'COD হাতে আছে' : 'COD Cash in Hand'}</Text>
              <Text style={styles.codCardSub}>
                {lang === 'bn' ? 'অফিসে জমা দিতে হবে' : 'Submit to office'}
              </Text>
            </View>
          </View>
          <Text style={styles.codCardAmount}>{money(totalCOD)}</Text>
        </View>

        {/* ── Tab bar ── */}
        <View style={styles.tabBar}>
          <TouchableOpacity
            style={[styles.tabBtn, tab === 'active' && styles.tabBtnActive]}
            onPress={() => setTab('active')}
            activeOpacity={0.8}
          >
            <Text style={[styles.tabBtnText, tab === 'active' && styles.tabBtnTextActive]}>
              🚴 {lang === 'bn' ? 'চলমান' : 'Active'} ({toBn(activeOrders.length)})
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.tabBtn, tab === 'done' && styles.tabBtnActive]}
            onPress={() => setTab('done')}
            activeOpacity={0.8}
          >
            <Text style={[styles.tabBtnText, tab === 'done' && styles.tabBtnTextActive]}>
              ✅ {lang === 'bn' ? 'সম্পন্ন' : 'Done'} ({toBn(completedOrders.length)})
            </Text>
          </TouchableOpacity>
        </View>

        {/* ── Order List ── */}
        <View style={styles.orderList}>
          {loading ? (
            <ActivityIndicator size="large" color={Colors.blue} style={{ marginTop: 40 }} />
          ) : displayOrders.length === 0 ? (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyIcon}>{tab === 'active' ? '🎉' : '📭'}</Text>
              <Text style={styles.emptyTitle}>
                {tab === 'active'
                  ? (lang === 'bn' ? 'কোনো চলমান অর্ডার নেই!' : 'No active orders!')
                  : (lang === 'bn' ? 'এখনো কোনো অর্ডার সম্পন্ন হয়নি' : 'No completed orders yet')}
              </Text>
              <Text style={styles.emptySub}>
                {tab === 'active'
                  ? (lang === 'bn' ? 'নতুন অর্ডার পেলে এখানে দেখাবে।' : 'New orders will appear here.')
                  : (lang === 'bn' ? 'সম্পন্ন অর্ডার এখানে দেখাবে।' : 'Completed orders will appear here.')}
              </Text>
            </View>
          ) : (
            displayOrders.map((order, idx) => {
              const ss          = statusStyle(order.status);
              const delivered   = isDelivered(order.status);
              const cod         = isCOD(order);
              const workflowIdx = STATUS_WORKFLOW.indexOf(order.status);
              const canAdvance  = !delivered && !isCancelled(order.status) && workflowIdx < STATUS_WORKFLOW.length - 1;
              const nextStatus  = canAdvance ? STATUS_WORKFLOW[workflowIdx + 1] : null;
              const isUpdating  = advancingId === order.id;

              return (
                <View key={order.id} style={[
                  styles.orderCard,
                  delivered && styles.orderCardDone,
                  isToday(order.updatedAt || order.createdAt) && !delivered && styles.orderCardToday,
                ]}>
                  {/* Top */}
                  <View style={styles.orderTop}>
                    <View style={styles.serialBadge}>
                      <Text style={styles.serialText}>{toBn(idx + 1)}</Text>
                    </View>
                    <View style={{ flex: 1, marginLeft: 10 }}>
                      <Text style={styles.orderId}>#{order.id}</Text>
                      <Text style={styles.customerName}>👤 {order.customerName}</Text>
                      {order.address ? (
                        <Text style={styles.orderAddr} numberOfLines={1}>📍 {order.address}</Text>
                      ) : null}
                    </View>
                    <View style={{ alignItems: 'flex-end', gap: 4 }}>
                      <View style={[styles.statusBadge, { backgroundColor: ss.bg, borderColor: ss.border }]}>
                        <Text style={[styles.statusText, { color: ss.text }]}>{order.status}</Text>
                      </View>
                      <View style={[styles.payBadge, cod
                        ? { backgroundColor: '#fff8e1', borderColor: '#ffe082' }
                        : { backgroundColor: '#e8f5e9', borderColor: '#c8e6c9' }
                      ]}>
                        <Text style={[styles.payBadgeText, { color: cod ? '#b45309' : '#2e7d32' }]}>
                          {cod ? '💵 COD' : '🏢 Online'}
                        </Text>
                      </View>
                    </View>
                  </View>

                  {/* Items summary */}
                  {Array.isArray(order.items) && order.items.length > 0 && (
                    <View style={styles.itemsRow}>
                      <Text style={styles.itemsText}>
                        🧺 {order.items.map((it: any) => `${it.name} ×${it.qty}`).join(', ')}
                      </Text>
                    </View>
                  )}

                  {/* Total */}
                  <View style={styles.totalRow}>
                    <Text style={styles.totalLabel}>
                      {order.service} • {new Date(order.createdAt || '').toLocaleDateString(lang === 'bn' ? 'bn-BD' : 'en-GB', { day: '2-digit', month: 'short' })}
                    </Text>
                    <Text style={styles.totalAmount}>{money(order.total || 0)}</Text>
                  </View>

                  {/* Action buttons */}
                  {!delivered && !isCancelled(order.status) && (
                    <View style={styles.actionRow}>
                      {/* Call */}
                      <TouchableOpacity
                        style={styles.callBtn}
                        onPress={() => callCustomer(order.phone)}
                        activeOpacity={0.75}
                      >
                        <Text style={styles.callBtnText}>📞 {lang === 'bn' ? 'কল' : 'Call'}</Text>
                      </TouchableOpacity>

                      {/* WhatsApp */}
                      <TouchableOpacity
                        style={styles.waBtn}
                        onPress={() => whatsappCustomer(order.phone)}
                        activeOpacity={0.75}
                      >
                        <Text style={styles.waBtnText}>💬 WhatsApp</Text>
                      </TouchableOpacity>

                      {/* Chat */}
                      <TouchableOpacity
                        style={styles.chatBtn}
                        onPress={() => router.push({ pathname: '/chat', params: { orderId: order.id, role: 'rider' } })}
                        activeOpacity={0.75}
                      >
                        <Text style={styles.chatBtnText}>🗨️</Text>
                      </TouchableOpacity>
                    </View>
                  )}

                  {/* Advance status button */}
                  {canAdvance && (
                    <TouchableOpacity
                      style={[styles.advanceBtn, isUpdating && { opacity: 0.6 }]}
                      onPress={() => handleAdvance(order)}
                      disabled={isUpdating}
                      activeOpacity={0.8}
                    >
                      {isUpdating ? (
                        <ActivityIndicator size="small" color="#fff" />
                      ) : (
                        <Text style={styles.advanceBtnText}>
                          ▶ {nextStatus}
                        </Text>
                      )}
                    </TouchableOpacity>
                  )}

                  {/* Delivered banner */}
                  {delivered && (
                    <View style={styles.delivBanner}>
                      <Text style={styles.delivBannerText}>
                        ✅ {lang === 'bn' ? 'ডেলিভারি সম্পন্ন' : 'Delivered'}
                        {cod ? `  •  COD ${money(order.total || 0)}` : ''}
                      </Text>
                    </View>
                  )}
                </View>
              );
            })
          )}
        </View>

        {/* Bottom spacer */}
        <View style={{ height: 40 }} />
      </ScrollView>
    </View>
  );
}

/* ─── styles ─────────────────────────────────────────────── */
const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#f4f7fb' },

  // Header
  header: {
    paddingTop: 16,
    paddingBottom: 0,
    borderBottomLeftRadius: 28,
    borderBottomRightRadius: 28,
    ...Shadows.button as any,
    marginBottom: 0,
  },
  backBtn: {
    position: 'absolute',
    top: 16,
    left: 18,
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(255,255,255,0.2)',
    borderWidth: 1.5,
    borderColor: 'rgba(255,255,255,0.35)',
    justifyContent: 'center',
    alignItems: 'center',
    elevation: 3,
    zIndex: 10,
  },
  backText: { fontSize: 22, fontWeight: '900', color: '#fff', lineHeight: 24, textAlign: 'center' },

  headerCenter: { alignItems: 'center', paddingHorizontal: 20, paddingBottom: 16 },

  avatarCircle: {
    width: 70,
    height: 70,
    borderRadius: 35,
    backgroundColor: 'rgba(255,255,255,0.2)',
    borderWidth: 3,
    borderColor: 'rgba(255,255,255,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 10,
  },
  avatarText:  { fontSize: 30, fontWeight: '900', color: '#fff' },
  riderName:   { fontSize: 22, fontWeight: '900', color: '#fff' },
  riderPhone:  { fontSize: 13, color: 'rgba(255,255,255,0.82)', marginTop: 4, fontWeight: '700' },

  onlineBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.18)',
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 5,
    marginTop: 10,
    gap: 6,
  },
  onlineDot:       { width: 8, height: 8, borderRadius: 4, backgroundColor: '#4ade80' },
  onlineBadgeText: { fontSize: 12, fontWeight: '800', color: '#fff' },

  statsStrip: {
    flexDirection: 'row',
    backgroundColor: 'rgba(0,0,0,0.25)',
    paddingVertical: 14,
    paddingHorizontal: 10,
    borderBottomLeftRadius: 28,
    borderBottomRightRadius: 28,
    marginTop: 16,
  },
  statBox:  { flex: 1, alignItems: 'center' },
  statVal:  { fontSize: 19, fontWeight: '900', color: '#fff' },
  statLbl:  { fontSize: 10, color: 'rgba(255,255,255,0.75)', marginTop: 3, fontWeight: '700' },
  statDiv:  { width: 1, backgroundColor: 'rgba(255,255,255,0.2)', alignSelf: 'stretch' },

  // COD card
  codCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 16,
    marginHorizontal: 16,
    marginTop: 16,
    borderWidth: 1,
    borderColor: '#ffe082',
    borderLeftWidth: 5,
    borderLeftColor: '#f59e0b',
    ...Shadows.card as any,
  },
  codCardLeft:   { flexDirection: 'row', alignItems: 'center', gap: 12 },
  codCardIcon:   { fontSize: 28 },
  codCardTitle:  { fontSize: 14, fontWeight: '900', color: Colors.ink },
  codCardSub:    { fontSize: 12, color: Colors.muted, fontWeight: '700', marginTop: 2 },
  codCardAmount: { fontSize: 22, fontWeight: '900', color: '#b45309' },

  // Tab bar
  tabBar: {
    flexDirection: 'row',
    marginHorizontal: 16,
    marginTop: 14,
    backgroundColor: '#e8eef8',
    borderRadius: 12,
    padding: 4,
    gap: 4,
  },
  tabBtn: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 9,
    alignItems: 'center',
  },
  tabBtnActive:     { backgroundColor: '#fff', ...Shadows.card as any },
  tabBtnText:       { fontSize: 13, fontWeight: '800', color: Colors.muted },
  tabBtnTextActive: { color: Colors.blue },

  // Order list
  orderList: { paddingHorizontal: 16, paddingTop: 14, gap: 12 },

  emptyCard: { paddingVertical: 50, alignItems: 'center', backgroundColor: '#fff', borderRadius: 16, borderWidth: 1, borderColor: '#e2e8f0', marginTop: 8 },
  emptyIcon:  { fontSize: 48, marginBottom: 8 },
  emptyTitle: { fontSize: 17, fontWeight: '900', color: Colors.ink },
  emptySub:   { fontSize: 13, color: Colors.muted, marginTop: 6, textAlign: 'center', paddingHorizontal: 24 },

  // Order card
  orderCard: {
    backgroundColor: '#fff',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    padding: 14,
    gap: 10,
    ...Shadows.card as any,
  },
  orderCardDone:  { borderLeftWidth: 4, borderLeftColor: Colors.green },
  orderCardToday: { borderLeftWidth: 4, borderLeftColor: Colors.blue },

  orderTop:    { flexDirection: 'row', alignItems: 'flex-start' },
  serialBadge: { width: 30, height: 30, borderRadius: 15, backgroundColor: Colors.blue, justifyContent: 'center', alignItems: 'center', flexShrink: 0, marginTop: 2 },
  serialText:  { fontSize: 13, fontWeight: '900', color: '#fff' },

  orderId:      { fontSize: 15, fontWeight: '900', color: Colors.ink },
  customerName: { fontSize: 13, color: Colors.muted, fontWeight: '700', marginTop: 1 },
  orderAddr:    { fontSize: 12, color: Colors.muted, fontWeight: '600', marginTop: 2 },

  statusBadge: { borderRadius: 8, paddingHorizontal: 7, paddingVertical: 3, borderWidth: 1 },
  statusText:  { fontSize: 11, fontWeight: '900' },
  payBadge:    { borderRadius: 8, paddingHorizontal: 7, paddingVertical: 3, borderWidth: 1 },
  payBadgeText:{ fontSize: 10, fontWeight: '900' },

  itemsRow:   { backgroundColor: '#f8fafc', borderRadius: 8, padding: 8 },
  itemsText:  { fontSize: 12, color: '#475569', fontWeight: '700', lineHeight: 18 },

  totalRow:   { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', borderTopWidth: 1, borderTopColor: '#f1f5f9', paddingTop: 8 },
  totalLabel: { fontSize: 12, color: Colors.muted, fontWeight: '700' },
  totalAmount:{ fontSize: 18, fontWeight: '900', color: Colors.blue },

  // Action buttons
  actionRow: { flexDirection: 'row', gap: 8 },
  callBtn:   { flex: 1, backgroundColor: '#eef5ff', borderRadius: 10, paddingVertical: 10, alignItems: 'center', borderWidth: 1, borderColor: '#cce1ff' },
  callBtnText: { fontSize: 12, fontWeight: '900', color: Colors.blue },
  waBtn:     { flex: 1.3, backgroundColor: '#e8f5e9', borderRadius: 10, paddingVertical: 10, alignItems: 'center', borderWidth: 1, borderColor: '#c8e6c9' },
  waBtnText: { fontSize: 12, fontWeight: '900', color: '#2e7d32' },
  chatBtn:   { width: 42, backgroundColor: '#f3e8ff', borderRadius: 10, paddingVertical: 10, alignItems: 'center', borderWidth: 1, borderColor: '#e9d5ff' },
  chatBtnText: { fontSize: 16 },

  // Advance status button
  advanceBtn: {
    backgroundColor: Colors.blue,
    borderRadius: 10,
    paddingVertical: 12,
    alignItems: 'center',
    ...Shadows.button as any,
  },
  advanceBtnText: { fontSize: 14, fontWeight: '900', color: '#fff' },

  // Delivered banner
  delivBanner:     { backgroundColor: '#e8f5e9', borderRadius: 8, padding: 10, alignItems: 'center' },
  delivBannerText: { fontSize: 12, color: '#2e7d32', fontWeight: '800', textAlign: 'center' },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    width: '100%',
    paddingHorizontal: 4,
    marginBottom: 10,
  },
  logoutBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(255,255,255,0.15)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  logoutBtnText: {
    fontSize: 16,
    lineHeight: 18,
  },
});
