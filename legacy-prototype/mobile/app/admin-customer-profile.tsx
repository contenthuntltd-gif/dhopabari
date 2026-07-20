import React, { useState, useEffect } from 'react';
import {
  View, Text, TouchableOpacity, StyleSheet, ScrollView, ActivityIndicator
} from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { Colors, Shadows, toBn, money } from '../constants/theme';
import { getCustomerOrders } from '../services/api';
import { useLanguage } from '../services/language';

const STATUS_COLOR: Record<string, { bg: string; text: string; border: string }> = {
  delivered: { bg: '#e8f5e9', text: '#2e7d32', border: '#c8e6c9' },
  cancelled:  { bg: '#ffebee', text: '#c62828', border: '#ffcdd2' },
  default:    { bg: '#fff3e0', text: '#e65100', border: '#ffe0b2' },
};

function statusStyle(status: string) {
  if (status.includes('সম্পন্ন') || status.includes('delivered')) return STATUS_COLOR.delivered;
  if (status.includes('বাতিল') || status.includes('cancelled'))  return STATUS_COLOR.cancelled;
  return STATUS_COLOR.default;
}

export default function AdminCustomerProfile() {
  const router   = useRouter();
  const { lang } = useLanguage();

  // params passed via router.push
  const params = useLocalSearchParams<{
    phone: string;
    name: string;
    address: string;
    orders: string;
  }>();

  const [loading, setLoading] = useState(true);
  const [orderList, setOrderList] = useState<any[]>([]);

  useEffect(() => {
    if (!params.phone) return;
    getCustomerOrders(params.phone)
      .then(data => setOrderList((data as any[]).sort((a, b) => b.id > a.id ? 1 : -1)))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [params.phone]);

  const totalSpent = orderList
    .filter(o => !o.status.includes('বাতিল') && !o.status.includes('cancelled'))
    .reduce((s, o) => s + (o.total || 0), 0);

  return (
    <View style={styles.root}>
      <ScrollView showsVerticalScrollIndicator={false}>
        {/* ── Header gradient ── */}
        <LinearGradient colors={['#1a2a6c', '#2563eb', '#1d9bf0']} style={styles.header}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backBtn} activeOpacity={0.7}>
            <Text style={styles.backText}>‹</Text>
          </TouchableOpacity>

          {/* Avatar */}
          <View style={styles.avatarCircle}>
            <Text style={styles.avatarInitial}>
              {(params.name || 'গ্রাহক').charAt(0).toUpperCase()}
            </Text>
          </View>
          <Text style={styles.custName}>{params.name || lang === 'bn' ? 'গ্রাহক' : 'Customer'}</Text>
          <Text style={styles.custPhone}>📞 {params.phone}</Text>
          {params.address ? (
            <Text style={styles.custAddress}>📍 {params.address}</Text>
          ) : null}

          {/* Quick stats */}
          <View style={styles.statRow}>
            <View style={styles.statBox}>
              <Text style={styles.statValue}>{toBn(Number(params.orders) || orderList.length)}</Text>
              <Text style={styles.statLabel}>{lang === 'bn' ? 'মোট অর্ডার' : 'Total Orders'}</Text>
            </View>
            <View style={styles.statDivider} />
            <View style={styles.statBox}>
              <Text style={styles.statValue}>{money(totalSpent)}</Text>
              <Text style={styles.statLabel}>{lang === 'bn' ? 'মোট খরচ' : 'Total Spent'}</Text>
            </View>
            <View style={styles.statDivider} />
            <View style={styles.statBox}>
              <Text style={styles.statValue}>
                {toBn(orderList.filter(o => o.status.includes('সম্পন্ন') || o.status.includes('delivered')).length)}
              </Text>
              <Text style={styles.statLabel}>{lang === 'bn' ? 'সম্পন্ন' : 'Completed'}</Text>
            </View>
          </View>
        </LinearGradient>

        {/* ── Order History ── */}
        <View style={styles.body}>
          <Text style={styles.sectionTitle}>
            📋 {lang === 'bn' ? 'অর্ডার ইতিহাস' : 'Order History'}
          </Text>

          {loading ? (
            <ActivityIndicator size="large" color={Colors.blue} style={{ marginTop: 40 }} />
          ) : orderList.length === 0 ? (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyIcon}>📭</Text>
              <Text style={styles.emptyTitle}>{lang === 'bn' ? 'কোনো অর্ডার নেই' : 'No orders yet'}</Text>
              <Text style={styles.emptySubtitle}>
                {lang === 'bn' ? 'এই কাস্টমারের এখনো কোনো অর্ডার নেই।' : 'This customer has not placed any orders.'}
              </Text>
            </View>
          ) : (
            orderList.map((order, idx) => {
              const ss = statusStyle(order.status);
              const isDelivered = order.status.includes('সম্পন্ন') || order.status.includes('delivered');
              const isCancelled = order.status.includes('বাতিল') || order.status.includes('cancelled');
              return (
                <View key={order.id} style={styles.orderCard}>
                  {/* Top row */}
                  <View style={styles.orderCardTop}>
                    <View style={styles.serialBadge}>
                      <Text style={styles.serialText}>{toBn(idx + 1)}</Text>
                    </View>
                    <View style={{ flex: 1, marginLeft: 10 }}>
                      <Text style={styles.orderId}>#{order.id}</Text>
                      <Text style={styles.orderDate}>
                        {order.createdAt
                          ? new Date(order.createdAt).toLocaleDateString(
                              lang === 'bn' ? 'bn-BD' : 'en-GB',
                              { day: '2-digit', month: 'short', year: 'numeric' }
                            )
                          : '—'}
                      </Text>
                    </View>
                    <View style={[styles.statusBadge, { backgroundColor: ss.bg, borderColor: ss.border }]}>
                      <Text style={[styles.statusText, { color: ss.text }]}>{order.status}</Text>
                    </View>
                  </View>

                  {/* Items */}
                  {Array.isArray(order.items) && order.items.length > 0 && (
                    <View style={styles.itemsList}>
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
                      isCancelled && { color: '#9e9e9e', textDecorationLine: 'line-through' }
                    ]}>
                      {money(order.total || 0)}
                    </Text>
                  </View>

                  {isDelivered && (
                    <View style={styles.deliveredBanner}>
                      <Text style={styles.deliveredBannerText}>
                        ✅ {lang === 'bn' ? 'ডেলিভারি সম্পন্ন হয়েছে — ধন্যবাদ!' : 'Delivery completed — Thank you!'}
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
    borderColor: 'rgba(255,255,255,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 10,
  },
  avatarInitial: { fontSize: 32, fontWeight: '900', color: '#fff' },
  custName:    { fontSize: 22, fontWeight: '900', color: '#fff', textAlign: 'center' },
  custPhone:   { fontSize: 14, color: 'rgba(255,255,255,0.85)', marginTop: 4, fontWeight: '700' },
  custAddress: { fontSize: 13, color: 'rgba(255,255,255,0.75)', marginTop: 3, textAlign: 'center', fontWeight: '600' },

  statRow: {
    flexDirection: 'row',
    marginTop: 18,
    backgroundColor: 'rgba(255,255,255,0.15)',
    borderRadius: 16,
    padding: 14,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.2)',
    gap: 0,
  },
  statBox: { flex: 1, alignItems: 'center' },
  statValue: { fontSize: 20, fontWeight: '900', color: '#fff' },
  statLabel: { fontSize: 11, color: 'rgba(255,255,255,0.8)', marginTop: 2, fontWeight: '700', textAlign: 'center' },
  statDivider: { width: 1, backgroundColor: 'rgba(255,255,255,0.3)', marginHorizontal: 6 },

  // Body
  body: { paddingHorizontal: 16, paddingTop: 20, paddingBottom: 40 },
  sectionTitle: { fontSize: 17, fontWeight: '900', color: Colors.ink, marginBottom: 12 },

  // Empty state
  emptyCard: { paddingVertical: 50, alignItems: 'center', backgroundColor: '#fff', borderRadius: 16, borderWidth: 1, borderColor: '#e2e8f0' },
  emptyIcon: { fontSize: 48, marginBottom: 8 },
  emptyTitle: { fontSize: 16, fontWeight: '900', color: Colors.ink },
  emptySubtitle: { fontSize: 13, color: Colors.muted, marginTop: 6, textAlign: 'center', paddingHorizontal: 24 },

  // Order card
  orderCard: {
    backgroundColor: '#fff',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    padding: 14,
    marginBottom: 12,
    ...Shadows.card as any,
  },
  orderCardTop: { flexDirection: 'row', alignItems: 'flex-start', marginBottom: 10 },
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
  serialText: { fontSize: 13, fontWeight: '900', color: '#fff' },
  orderId: { fontSize: 16, fontWeight: '900', color: Colors.ink },
  orderDate: { fontSize: 12, color: Colors.muted, marginTop: 2, fontWeight: '600' },
  statusBadge: { borderRadius: 8, paddingHorizontal: 8, paddingVertical: 4, borderWidth: 1, alignSelf: 'flex-start' },
  statusText: { fontSize: 11, fontWeight: '900' },

  itemsList: { borderTopWidth: 1, borderTopColor: '#f1f5f9', paddingTop: 8, gap: 4 },
  itemRow: { flexDirection: 'row', alignItems: 'center' },
  itemName: { flex: 1, fontSize: 13, color: '#475569', fontWeight: '700' },
  itemQty: { fontSize: 13, color: Colors.muted, fontWeight: '700', marginRight: 10 },
  itemTotal: { fontSize: 13, color: Colors.blue, fontWeight: '900' },

  orderFooter: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 10, borderTopWidth: 1, borderTopColor: '#f1f5f9', paddingTop: 8 },
  orderService: { fontSize: 13, color: Colors.muted, fontWeight: '700' },
  orderTotal: { fontSize: 18, fontWeight: '900', color: Colors.blue },

  deliveredBanner: {
    marginTop: 8,
    backgroundColor: '#e8f5e9',
    borderRadius: 8,
    padding: 8,
    alignItems: 'center',
  },
  deliveredBannerText: { fontSize: 13, color: '#2e7d32', fontWeight: '800' },
});
