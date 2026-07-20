import React, { useState, useEffect } from 'react';
import {
  View, Text, TouchableOpacity, StyleSheet, ScrollView, ActivityIndicator
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors, Shadows, toBn, money } from '../constants/theme';
import { getRiderOrders } from '../services/api';
import { useLanguage } from '../services/language';

/* ─── helpers ──────────────────────────────────────────── */
const TODAY = new Date().toDateString();

function isToday(iso: string) {
  if (!iso) return false;
  return new Date(iso).toDateString() === TODAY;
}

function isDelivered(status: string) {
  return status.includes('সম্পন্ন') || status.toLowerCase().includes('delivered');
}
function isCancelled(status: string) {
  return status.includes('বাতিল') || status.toLowerCase().includes('cancelled');
}
function isPending(status: string) {
  return !isDelivered(status) && !isCancelled(status);
}

/* For COD: only Cash‑on‑Delivery orders that the rider has completed
   contain money the rider is currently holding.
   Orders marked "delivered" = money already collected by rider (COD).
   Assumes payment field = 'COD' | 'bKash' etc.
*/
function isCOD(order: any) {
  const p = (order.payment || '').toLowerCase();
  return !p || p === 'cod' || p.includes('cod') || p.includes('cash');
}

/* Avatar gradient colours cycled by rider position */
const GRAD_PALETTES: [string, string][] = [
  ['#1a2a6c', '#2563eb'],
  ['#134e4a', '#0d9488'],
  ['#7c3aed', '#a855f7'],
  ['#b45309', '#f59e0b'],
];

function gradForIndex(i: number): [string, string] {
  return GRAD_PALETTES[i % GRAD_PALETTES.length];
}

const STATUS_COLOR: Record<string, { bg: string; text: string; border: string }> = {
  delivered: { bg: '#e8f5e9', text: '#2e7d32', border: '#c8e6c9' },
  cancelled:  { bg: '#ffebee', text: '#c62828', border: '#ffcdd2' },
  default:    { bg: '#fff3e0', text: '#e65100', border: '#ffe0b2' },
};

function statusStyle(status: string) {
  if (isDelivered(status)) return STATUS_COLOR.delivered;
  if (isCancelled(status)) return STATUS_COLOR.cancelled;
  return STATUS_COLOR.default;
}

/* ─── screen ────────────────────────────────────────────── */
export default function AdminRiderProfile() {
  const router   = useRouter();
  const { lang } = useLanguage();

  const params = useLocalSearchParams<{
    riderId: string;
    name: string;
    phone: string;
    avatar: string;
    gradIndex: string;
  }>();

  const [loading, setLoading]     = useState(true);
  const [orderList, setOrderList] = useState<any[]>([]);

  useEffect(() => {
    if (!params.riderId) return;
    getRiderOrders(params.riderId)
      .then(data =>
        setOrderList(
          (data as any[]).sort((a, b) => (a.id > b.id ? -1 : 1))
        )
      )
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [params.riderId]);

  /* ── derived stats ── */
  const completedOrders  = orderList.filter(o => isDelivered(o.status));
  const pendingOrders    = orderList.filter(o => isPending(o.status));
  const cancelledOrders  = orderList.filter(o => isCancelled(o.status));

  // COD cash rider currently holds = delivered COD orders
  const codHeld = completedOrders
    .filter(o => isCOD(o))
    .reduce((s, o) => s + (o.total || 0), 0);

  // Today
  const todayCompleted  = completedOrders.filter(o => isToday(o.updatedAt || o.createdAt));
  const todayCOD        = todayCompleted.filter(o => isCOD(o)).reduce((s, o) => s + (o.total || 0), 0);

  const gradIndex = Number(params.gradIndex || 0);
  const [g1, g2]  = gradForIndex(gradIndex);

  return (
    <View style={styles.root}>
      <ScrollView showsVerticalScrollIndicator={false}>

        {/* ── Gradient header ── */}
        <LinearGradient colors={[g1, g2]} style={styles.header}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backBtn} activeOpacity={0.7}>
            <Text style={styles.backText}>‹</Text>
          </TouchableOpacity>

          {/* Avatar */}
          <View style={styles.avatarCircle}>
            <Text style={styles.avatarText}>{params.avatar || '?'}</Text>
          </View>
          <Text style={styles.riderName}>{params.name || 'Rider'}</Text>
          <Text style={styles.riderPhone}>📞 {params.phone}</Text>

          {/* Stats row */}
          <View style={styles.statRow}>
            <View style={styles.statBox}>
              <Text style={styles.statVal}>{toBn(completedOrders.length)}</Text>
              <Text style={styles.statLbl}>{lang === 'bn' ? 'সম্পন্ন' : 'Completed'}</Text>
            </View>
            <View style={styles.statDiv} />
            <View style={styles.statBox}>
              <Text style={[styles.statVal, { color: '#fbbf24' }]}>{toBn(pendingOrders.length)}</Text>
              <Text style={styles.statLbl}>{lang === 'bn' ? 'চলমান' : 'Pending'}</Text>
            </View>
            <View style={styles.statDiv} />
            <View style={styles.statBox}>
              <Text style={[styles.statVal, { color: '#f87171' }]}>{toBn(cancelledOrders.length)}</Text>
              <Text style={styles.statLbl}>{lang === 'bn' ? 'বাতিল' : 'Cancelled'}</Text>
            </View>
          </View>

          {/* Open rider live dashboard button */}
          <TouchableOpacity
            style={styles.riderDashBtn}
            activeOpacity={0.8}
            onPress={() => router.push({ pathname: '/rider-dashboard', params: { riderId: params.riderId } })}
          >
            <Text style={styles.riderDashBtnText}>
              🚴 {lang === 'bn' ? 'রাইডার ড্যাশবোর্ড খুলুন' : 'Open Rider Dashboard'}
            </Text>
          </TouchableOpacity>
        </LinearGradient>

        {/* ── Cash / money summary cards ── */}
        <View style={styles.moneySection}>

          {/* Today card */}
          <View style={[styles.moneyCard, { borderLeftColor: Colors.green }]}>
            <View style={styles.moneyCardTop}>
              <Text style={styles.moneyCardIcon}>📅</Text>
              <Text style={styles.moneyCardTitle}>
                {lang === 'bn' ? 'আজকের হিসাব' : "Today's Summary"}
              </Text>
            </View>
            <View style={styles.moneyRow}>
              <Text style={styles.moneyLabel}>{lang === 'bn' ? 'আজ সম্পন্ন' : 'Completed Today'}</Text>
              <Text style={styles.moneyVal}>{toBn(todayCompleted.length)} {lang === 'bn' ? 'টি' : 'orders'}</Text>
            </View>
            <View style={styles.moneyRow}>
              <Text style={styles.moneyLabel}>{lang === 'bn' ? 'আজ COD আদায়' : 'COD Collected Today'}</Text>
              <Text style={[styles.moneyVal, { color: Colors.green, fontSize: 17 }]}>{money(todayCOD)}</Text>
            </View>
          </View>

          {/* COD balance card */}
          <View style={[styles.moneyCard, { borderLeftColor: Colors.orange }]}>
            <View style={styles.moneyCardTop}>
              <Text style={styles.moneyCardIcon}>💵</Text>
              <Text style={styles.moneyCardTitle}>
                {lang === 'bn' ? 'রাইডারের কাছে টাকা (COD)' : 'Cash at Rider (COD)'}
              </Text>
            </View>
            <View style={styles.moneyRow}>
              <Text style={styles.moneyLabel}>{lang === 'bn' ? 'মোট COD সম্পন্ন' : 'Total COD Delivered'}</Text>
              <Text style={styles.moneyVal}>{toBn(completedOrders.filter(o => isCOD(o)).length)} {lang === 'bn' ? 'টি' : 'orders'}</Text>
            </View>
            <View style={styles.moneyRow}>
              <Text style={styles.moneyLabel}>{lang === 'bn' ? 'মোট নগদ রাইডারের কাছে' : 'Total Cash Held by Rider'}</Text>
              <Text style={[styles.moneyVal, { color: Colors.orange, fontSize: 17 }]}>{money(codHeld)}</Text>
            </View>
            <View style={styles.officeNote}>
              <Text style={styles.officeNoteText}>
                🏢 {lang === 'bn'
                  ? 'bKash/অনলাইন পেমেন্ট সরাসরি অফিসে জমা হয়'
                  : 'bKash/online payments go directly to office'}
              </Text>
            </View>
          </View>

          {/* Pending COD card */}
          {pendingOrders.length > 0 && (
            <View style={[styles.moneyCard, { borderLeftColor: '#f59e0b' }]}>
              <View style={styles.moneyCardTop}>
                <Text style={styles.moneyCardIcon}>⏳</Text>
                <Text style={styles.moneyCardTitle}>
                  {lang === 'bn' ? 'চলমান অর্ডার বাকি টাকা' : 'Pending COD Outstanding'}
                </Text>
              </View>
              <View style={styles.moneyRow}>
                <Text style={styles.moneyLabel}>{lang === 'bn' ? 'চলমান অর্ডার' : 'Active orders'}</Text>
                <Text style={styles.moneyVal}>{toBn(pendingOrders.length)} {lang === 'bn' ? 'টি' : 'orders'}</Text>
              </View>
              <View style={styles.moneyRow}>
                <Text style={styles.moneyLabel}>{lang === 'bn' ? 'মোট বাকি COD' : 'Total pending COD'}</Text>
                <Text style={[styles.moneyVal, { color: '#d97706', fontSize: 17 }]}>
                  {money(pendingOrders.filter(o => isCOD(o)).reduce((s, o) => s + (o.total || 0), 0))}
                </Text>
              </View>
            </View>
          )}
        </View>

        {/* ── Order History ── */}
        <View style={styles.historySection}>
          <Text style={styles.sectionTitle}>
            📋 {lang === 'bn' ? 'সব অর্ডার' : 'All Orders'}
            {'  '}
            <Text style={{ fontSize: 13, color: Colors.muted, fontWeight: '700' }}>
              ({toBn(orderList.length)} {lang === 'bn' ? 'টি' : 'total'})
            </Text>
          </Text>

          {loading ? (
            <ActivityIndicator size="large" color={Colors.blue} style={{ marginTop: 40 }} />
          ) : orderList.length === 0 ? (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyIcon}>📭</Text>
              <Text style={styles.emptyTitle}>
                {lang === 'bn' ? 'কোনো অর্ডার নেই' : 'No orders yet'}
              </Text>
              <Text style={styles.emptySub}>
                {lang === 'bn' ? 'এই রাইডারের এখনো কোনো অর্ডার নেই।' : 'No orders assigned to this rider yet.'}
              </Text>
            </View>
          ) : (
            orderList.map((order, idx) => {
              const ss        = statusStyle(order.status);
              const delivered = isDelivered(order.status);
              const cancelled = isCancelled(order.status);
              const cod       = isCOD(order);

              return (
                <View key={order.id} style={[styles.orderCard, delivered && styles.orderCardDelivered]}>
                  {/* Top row */}
                  <View style={styles.orderTop}>
                    <View style={styles.serialBadge}>
                      <Text style={styles.serialText}>{toBn(idx + 1)}</Text>
                    </View>
                    <View style={{ flex: 1, marginLeft: 10 }}>
                      <Text style={styles.orderId}>#{order.id}</Text>
                      <Text style={styles.orderCustomer}>👤 {order.customerName}</Text>
                      <Text style={styles.orderDate}>
                        {order.createdAt
                          ? new Date(order.createdAt).toLocaleDateString(
                              lang === 'bn' ? 'bn-BD' : 'en-GB',
                              { day: '2-digit', month: 'short', year: 'numeric' }
                            )
                          : '—'}
                        {isToday(order.updatedAt || order.createdAt) && (
                          <Text style={{ color: Colors.green, fontWeight: '900' }}>  ● {lang === 'bn' ? 'আজকের' : 'Today'}</Text>
                        )}
                      </Text>
                    </View>
                    <View>
                      <View style={[styles.statusBadge, { backgroundColor: ss.bg, borderColor: ss.border }]}>
                        <Text style={[styles.statusText, { color: ss.text }]}>{order.status}</Text>
                      </View>
                      {cod ? (
                        <View style={styles.codPill}>
                          <Text style={styles.codPillText}>💵 COD</Text>
                        </View>
                      ) : (
                        <View style={[styles.codPill, { backgroundColor: '#e8f5e9', borderColor: '#c8e6c9' }]}>
                          <Text style={[styles.codPillText, { color: '#2e7d32' }]}>🏢 {lang === 'bn' ? 'অনলাইন' : 'Online'}</Text>
                        </View>
                      )}
                    </View>
                  </View>

                  {/* Items */}
                  {Array.isArray(order.items) && order.items.length > 0 && (
                    <View style={styles.itemsBlock}>
                      {order.items.map((it: any, j: number) => (
                        <View key={j} style={styles.itemRow}>
                          <Text style={styles.itemName}>• {it.name}</Text>
                          <Text style={styles.itemQty}>×{toBn(it.qty)}</Text>
                          <Text style={styles.itemTotal}>{money(it.total || 0)}</Text>
                        </View>
                      ))}
                    </View>
                  )}

                  {/* Footer */}
                  <View style={styles.orderFooter}>
                    <Text style={styles.orderService}>🧺 {order.service}</Text>
                    <Text style={[
                      styles.orderTotal,
                      cancelled && { color: '#9e9e9e', textDecorationLine: 'line-through' }
                    ]}>
                      {money(order.total || 0)}
                    </Text>
                  </View>

                  {/* Address */}
                  {order.address ? (
                    <Text style={styles.orderAddr}>📍 {order.address}</Text>
                  ) : null}

                  {/* Delivered banner */}
                  {delivered && (
                    <View style={styles.delivBanner}>
                      <Text style={styles.delivBannerText}>
                        ✅ {lang === 'bn' ? 'ডেলিভারি সম্পন্ন' : 'Delivery completed'}
                        {cod ? (lang === 'bn' ? ` — ${money(order.total || 0)} রাইডারের কাছে` : ` — ${money(order.total || 0)} held by rider`) : ''}
                      </Text>
                    </View>
                  )}
                </View>
              );
            })
          )}
        </View>
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
    paddingBottom: 28,
    paddingHorizontal: 20,
    alignItems: 'center',
    borderBottomLeftRadius: 28,
    borderBottomRightRadius: 28,
    ...Shadows.button as any,
  },
  backBtn: {
    position: 'absolute',
    top: 16,
    left: 18,
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#fff',
    borderWidth: 1.5,
    borderColor: 'rgba(255,255,255,0.4)',
    justifyContent: 'center',
    alignItems: 'center',
    elevation: 3,
  },
  backText: { fontSize: 22, fontWeight: '900', color: '#334155', lineHeight: 24, textAlign: 'center' },

  avatarCircle: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: 'rgba(255,255,255,0.25)',
    borderWidth: 3,
    borderColor: 'rgba(255,255,255,0.55)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 10,
  },
  avatarText: { fontSize: 32, fontWeight: '900', color: '#fff' },
  riderName:  { fontSize: 22, fontWeight: '900', color: '#fff', textAlign: 'center' },
  riderPhone: { fontSize: 14, color: 'rgba(255,255,255,0.85)', marginTop: 4, fontWeight: '700' },

  // Stats
  statRow: {
    flexDirection: 'row',
    marginTop: 18,
    backgroundColor: 'rgba(255,255,255,0.15)',
    borderRadius: 16,
    padding: 14,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.2)',
  },
  statBox: { flex: 1, alignItems: 'center' },
  statVal:  { fontSize: 22, fontWeight: '900', color: '#fff' },
  statLbl:  { fontSize: 11, color: 'rgba(255,255,255,0.8)', marginTop: 3, fontWeight: '700' },
  statDiv:  { width: 1, backgroundColor: 'rgba(255,255,255,0.3)', marginHorizontal: 4 },

  riderDashBtn: {
    marginTop: 16,
    backgroundColor: 'rgba(255,255,255,0.2)',
    borderRadius: 12,
    paddingVertical: 12,
    paddingHorizontal: 20,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.4)',
  },
  riderDashBtnText: { fontSize: 14, fontWeight: '900', color: '#fff' },

  // Money cards
  moneySection: { paddingHorizontal: 16, paddingTop: 18, gap: 12 },
  moneyCard: {
    backgroundColor: '#fff',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    borderLeftWidth: 4,
    padding: 14,
    ...Shadows.card as any,
  },
  moneyCardTop: { flexDirection: 'row', alignItems: 'center', marginBottom: 10 },
  moneyCardIcon: { fontSize: 20, marginRight: 8 },
  moneyCardTitle: { fontSize: 14, fontWeight: '900', color: Colors.ink, flex: 1 },
  moneyRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 5, borderTopWidth: 1, borderTopColor: '#f1f5f9' },
  moneyLabel: { fontSize: 13, color: Colors.muted, fontWeight: '700' },
  moneyVal:   { fontSize: 15, fontWeight: '900', color: Colors.ink },
  officeNote: { marginTop: 10, backgroundColor: '#f0f9ff', borderRadius: 8, padding: 8, borderWidth: 1, borderColor: '#bae6fd' },
  officeNoteText: { fontSize: 12, color: '#0369a1', fontWeight: '800', textAlign: 'center' },

  // Order history
  historySection: { paddingHorizontal: 16, paddingTop: 20, paddingBottom: 40 },
  sectionTitle: { fontSize: 17, fontWeight: '900', color: Colors.ink, marginBottom: 12 },

  emptyCard: { paddingVertical: 50, alignItems: 'center', backgroundColor: '#fff', borderRadius: 16, borderWidth: 1, borderColor: '#e2e8f0' },
  emptyIcon:  { fontSize: 48, marginBottom: 8 },
  emptyTitle: { fontSize: 16, fontWeight: '900', color: Colors.ink },
  emptySub:   { fontSize: 13, color: Colors.muted, marginTop: 6, textAlign: 'center', paddingHorizontal: 24 },

  orderCard: {
    backgroundColor: '#fff',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    padding: 14,
    marginBottom: 12,
    ...Shadows.card as any,
  },
  orderCardDelivered: { borderLeftWidth: 4, borderLeftColor: Colors.green },

  orderTop: { flexDirection: 'row', alignItems: 'flex-start', marginBottom: 10 },
  serialBadge: {
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: Colors.blue,
    justifyContent: 'center',
    alignItems: 'center',
    flexShrink: 0,
    marginTop: 2,
  },
  serialText:    { fontSize: 13, fontWeight: '900', color: '#fff' },
  orderId:       { fontSize: 15, fontWeight: '900', color: Colors.ink },
  orderCustomer: { fontSize: 13, color: Colors.muted, fontWeight: '700', marginTop: 2 },
  orderDate:     { fontSize: 12, color: Colors.muted, marginTop: 2, fontWeight: '600' },

  statusBadge: { borderRadius: 8, paddingHorizontal: 7, paddingVertical: 3, borderWidth: 1, alignSelf: 'flex-start', marginBottom: 4 },
  statusText:  { fontSize: 11, fontWeight: '900' },
  codPill:     { borderRadius: 8, paddingHorizontal: 7, paddingVertical: 3, borderWidth: 1, alignSelf: 'flex-start', backgroundColor: '#fff8e1', borderColor: '#ffe082' },
  codPillText: { fontSize: 10, fontWeight: '900', color: '#b45309' },

  itemsBlock: { borderTopWidth: 1, borderTopColor: '#f1f5f9', paddingTop: 8, gap: 4 },
  itemRow:    { flexDirection: 'row', alignItems: 'center' },
  itemName:   { flex: 1, fontSize: 13, color: '#475569', fontWeight: '700' },
  itemQty:    { fontSize: 13, color: Colors.muted, fontWeight: '700', marginRight: 10 },
  itemTotal:  { fontSize: 13, color: Colors.blue, fontWeight: '900' },

  orderFooter:  { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 10, borderTopWidth: 1, borderTopColor: '#f1f5f9', paddingTop: 8 },
  orderService: { fontSize: 13, color: Colors.muted, fontWeight: '700' },
  orderTotal:   { fontSize: 18, fontWeight: '900', color: Colors.blue },
  orderAddr:    { fontSize: 12, color: Colors.muted, marginTop: 6, fontWeight: '600' },

  delivBanner:     { marginTop: 8, backgroundColor: '#e8f5e9', borderRadius: 8, padding: 8, alignItems: 'center' },
  delivBannerText: { fontSize: 12, color: '#2e7d32', fontWeight: '800', textAlign: 'center' },
});
