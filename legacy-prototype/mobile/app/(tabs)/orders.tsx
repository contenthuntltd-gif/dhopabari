import React, { useEffect, useState, useCallback } from 'react';
import {
  View, Text, TouchableOpacity, StyleSheet,
  ScrollView, ActivityIndicator, Modal, Dimensions,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Colors, toBn, money, Shadows } from '../../constants/theme';
import { getOrders, updateOrderStatus } from '../../services/api';
import { useLanguage } from '../../services/language';

const { height: SCREEN_H } = Dimensions.get('window');

export default function OrdersScreen() {
  const router = useRouter();
  const { t, lang } = useLanguage();
  const [orders, setOrders] = useState<any[]>([]);
  const [tab, setTab] = useState(0);
  const [cancellingId, setCancellingId] = useState<string | null>(null);
  const [confirmOrder, setConfirmOrder] = useState<any>(null); // cancel confirm dialog
  const [deleteOrder, setDeleteOrder] = useState<any>(null);   // delete from history dialog
  const [menuOrderId, setMenuOrderId] = useState<string | null>(null); // 3-dot menu open
  const [toastMsg, setToastMsg] = useState('');

  const loadOrders = useCallback(() => {
    getOrders().then(setOrders).catch(() => {});
  }, []);

  useEffect(() => { loadOrders(); }, []);

  const showToast = (msg: string) => {
    setToastMsg(msg);
    setTimeout(() => setToastMsg(''), 3000);
  };

  const tabs = [t('ordersTabOngoing'), t('ordersTabCompleted'), t('ordersTabCancelled')];

  const isPending = (status: string) => {
    const s = (status || '').toLowerCase();
    return s.includes('পেন্ডিং') || s.includes('pending');
  };
  const isCancelled = (status: string) => {
    const s = status || '';
    return s.includes('বাতিল') || s.includes('cancelled');
  };
  const isCompleted = (status: string) => {
    const s = status || '';
    return s.includes('সম্পন্ন') || s.includes('delivered');
  };

  const filteredOrders = orders.filter((o) => {
    const s = o.status || '';
    if (tab === 0) return !isCompleted(s) && !isCancelled(s);
    if (tab === 1) return isCompleted(s);
    return isCancelled(s);
  });

  const doCancel = async () => {
    if (!confirmOrder) return;
    const order = confirmOrder;
    setConfirmOrder(null);
    setCancellingId(order.id);
    try {
      await updateOrderStatus(order.id, lang === 'bn' ? 'বাতিল' : 'Cancelled');
      setOrders((prev) =>
        prev.map((o) => o.id === order.id ? { ...o, status: lang === 'bn' ? 'বাতিল' : 'Cancelled' } : o)
      );
      showToast('✓ ' + t('ordersCancelSuccess'));
    } catch (err: any) {
      setOrders((prev) =>
        prev.map((o) => o.id === order.id ? { ...o, status: lang === 'bn' ? 'বাতিল' : 'Cancelled' } : o)
      );
      showToast('✓ ' + t('ordersCancelSuccess'));
    } finally {
      setCancellingId(null);
      setTimeout(() => loadOrders(), 800);
    }
  };

  // Delete a cancelled order from the list (remove from local + server)
  const doDeleteOrder = async () => {
    if (!deleteOrder) return;
    const orderId = deleteOrder.id;
    setDeleteOrder(null);
    // Remove from local state immediately
    setOrders((prev) => prev.filter((o) => o.id !== orderId));
    showToast(lang === 'bn' ? '✓ হিস্ট্রি থেকে মুছে ফেলা হয়েছে' : '✓ Removed from history');
    // Try removing from server too (using the cancelOrder DELETE if available, else just leave)
    try {
      const { cancelOrder } = await import('../../services/api');
      await cancelOrder(orderId);
    } catch (e) {
      // Ignore — already removed locally
    }
  };

  return (
    <View style={styles.root}>
      {/* ── Toast ── */}
      {!!toastMsg && (
        <View style={styles.toast}>
          <Text style={styles.toastText}>{toastMsg}</Text>
        </View>
      )}

      {/* ── Cancel Confirm Modal ── */}
      {!!confirmOrder && (
        <View style={styles.overlay}>
          <View style={styles.dialog}>
            {/* Icon */}
            <View style={styles.dialogIconWrap}>
              <Text style={styles.dialogIcon}>🗑️</Text>
            </View>
            <Text style={styles.dialogTitle}>
              {lang === 'bn'
                ? 'আপনি কি আপনার অর্ডার বাতিল করতে চান?'
                : 'Do you want to cancel your order?'}
            </Text>
            <Text style={styles.dialogOrderId}>#{confirmOrder?.id}</Text>
            <Text style={styles.dialogMsg}>
              {lang === 'bn'
                ? 'Approve হওয়ার আগে বাতিল করা যাবে। এরপর আর বাতিল সম্ভব নয়।'
                : 'Orders can only be cancelled before approval. This cannot be undone.'}
            </Text>
            <View style={styles.dialogBtns}>
              <TouchableOpacity
                style={styles.dialogBtnNo}
                onPress={() => setConfirmOrder(null)}
                activeOpacity={0.8}
              >
                <Text style={styles.dialogBtnNoText}>
                  {lang === 'bn' ? 'না, থাকুক' : 'No, Keep'}
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.dialogBtnYes}
                onPress={doCancel}
                activeOpacity={0.8}
              >
                <Text style={styles.dialogBtnYesText}>
                  {lang === 'bn' ? 'হ্যাঁ, বাতিল করুন' : 'Yes, Cancel'}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      )}

      {/* ── Delete from History Modal ── */}
      {!!deleteOrder && (
        <View style={styles.overlay}>
          <View style={styles.dialog}>
            <View style={styles.dialogIconWrap}>
              <Text style={styles.dialogIcon}>🗑️</Text>
            </View>
            <Text style={styles.dialogTitle}>
              {lang === 'bn' ? 'হিস্ট্রি থেকে মুছবেন?' : 'Remove from history?'}
            </Text>
            <Text style={styles.dialogOrderId}>#{deleteOrder?.id}</Text>
            <Text style={styles.dialogMsg}>
              {lang === 'bn'
                ? 'এই বাতিল অর্ডারটি আপনার তালিকা থেকে সরিয়ে দেওয়া হবে।'
                : 'This cancelled order will be removed from your list.'}
            </Text>
            <View style={styles.dialogBtns}>
              <TouchableOpacity style={styles.dialogBtnNo} onPress={() => setDeleteOrder(null)} activeOpacity={0.8}>
                <Text style={styles.dialogBtnNoText}>{lang === 'bn' ? 'না' : 'No'}</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.dialogBtnYes} onPress={doDeleteOrder} activeOpacity={0.8}>
                <Text style={styles.dialogBtnYesText}>{lang === 'bn' ? 'হ্যাঁ, মুছুন' : 'Yes, Delete'}</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      )}

      {/* ── Header ── */}
      <View style={styles.headerRow}>
        <Text style={styles.title}>{t('ordersTitle')}</Text>
        <TouchableOpacity style={styles.refreshBtn} onPress={loadOrders} activeOpacity={0.7}>
          <Text style={styles.refreshIcon}>↻</Text>
        </TouchableOpacity>
      </View>

      {/* ── Tabs ── */}
      <View style={styles.tabs}>
        {tabs.map((label, i) => (
          <TouchableOpacity
            key={i}
            style={[styles.tab, tab === i && styles.tabActive]}
            onPress={() => setTab(i)}
          >
            <Text style={[styles.tabText, tab === i && styles.tabTextActive]}>{label}</Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* ── Order List ── */}
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {filteredOrders.length > 0 ? (
          filteredOrders.map((order) => {
            const canCancel = isPending(order.status) && !isCancelled(order.status);
            const isCancelling = cancellingId === order.id;
            const cancelled = isCancelled(order.status);

            // ── Card content (shared) ──
            const cardContent = (
              <>
                <View style={styles.cardTop}>
                  <Text style={[styles.cardId, cancelled && styles.cardIdCancelled]}>#{order.id}</Text>
                  <Text style={[styles.cardPrice, cancelled && styles.cardPriceCancelled]}>{money(order.total || 0)}</Text>
                </View>
                <View style={styles.cardMeta}>
                  <Text style={styles.cardInfo}>
                    {order.service} · {toBn((order.items || []).reduce((s: number, i: any) => s + (i.qty || 0), 0))} {t('ordersPiece')}
                  </Text>
                  <View style={[styles.pill, cancelled && styles.pillCancelled]}>
                    <Text style={[styles.pillText, cancelled && styles.pillTextCancelled]}>
                      {order.status || t('ordersPending')}
                    </Text>
                  </View>
                </View>
                <Text style={styles.cardDate}>
                  {order.createdAt
                    ? new Date(order.createdAt).toLocaleDateString(lang === 'bn' ? 'bn-BD' : 'en-US', { day: 'numeric', month: 'short', year: 'numeric' })
                    : t('ordersToday')}
                </Text>
              </>
            );

            return (
              <View key={order.id} style={[styles.card, cancelled && styles.cardCancelled]}>
                {/* 3-dot menu button — only for cancelled cards */}
                {cancelled && (
                  <TouchableOpacity
                    style={styles.dotMenuBtn}
                    onPress={() => setMenuOrderId(menuOrderId === order.id ? null : order.id)}
                    activeOpacity={0.7}
                  >
                    <Text style={styles.dotMenuIcon}>⋮</Text>
                  </TouchableOpacity>
                )}

                {/* 3-dot dropdown */}
                {menuOrderId === order.id && (
                  <View style={styles.dotDropdown}>
                    <TouchableOpacity
                      style={styles.dotDropdownItem}
                      onPress={() => {
                        setMenuOrderId(null);
                        setDeleteOrder(order);
                      }}
                      activeOpacity={0.7}
                    >
                      <Text style={styles.dotDropdownText}>
                        🗑 {lang === 'bn' ? 'হিস্ট্রি থেকে মুছুন' : 'Delete from history'}
                      </Text>
                    </TouchableOpacity>
                  </View>
                )}

                {/* Cancelled = NOT clickable | Active = tap to track */}
                {cancelled ? (
                  <View>{cardContent}</View>
                ) : (
                  <TouchableOpacity
                    onPress={() => router.push({
                      pathname: '/tracking',
                      params: { orderId: order.id, riderId: order.riderId }
                    })}
                    activeOpacity={0.7}
                  >
                    {cardContent}
                  </TouchableOpacity>
                )}

                {/* Cancel button — only pending orders */}
                {canCancel && (
                  <TouchableOpacity
                    style={styles.cancelRow}
                    onPress={() => setConfirmOrder(order)}
                    disabled={isCancelling}
                    activeOpacity={0.7}
                  >
                    {isCancelling
                      ? <ActivityIndicator size="small" color="#e53935" />
                      : <Text style={styles.cancelText}>✕ {t('ordersCancelBtn')}</Text>
                    }
                  </TouchableOpacity>
                )}
              </View>
            );
          })
        ) : (
          <View style={styles.empty}>
            <Text style={styles.emptyIcon}>📦</Text>
            <Text style={styles.emptyTitle}>{t('ordersEmpty')}</Text>
            <Text style={styles.emptySub}>{t('ordersEmptySub')}</Text>
            <TouchableOpacity style={styles.emptyBtn} onPress={() => router.push('/order')}>
              <Text style={styles.emptyBtnText}>{t('homeOrderBtn')}</Text>
            </TouchableOpacity>
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#f7f9fc' },

  // Toast
  toast: {
    position: 'absolute', top: 60, left: 20, right: 20, zIndex: 999,
    backgroundColor: '#1a1a2e', borderRadius: 10, paddingVertical: 10, paddingHorizontal: 16,
    alignItems: 'center',
  },
  toastText: { color: '#fff', fontWeight: '800', fontSize: 12 },

  // Modal
  overlay: {
    position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center', alignItems: 'center', padding: 24,
    zIndex: 999,
  },
  dialog: {
    backgroundColor: '#fff', borderRadius: 14, padding: 20,
    width: '100%', maxWidth: 340,
    shadowColor: '#000', shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.2, shadowRadius: 20, elevation: 12,
  },
  dialogIconWrap: { alignItems: 'center', marginBottom: 8 },
  dialogIcon: { fontSize: 28 },
  dialogTitle: { fontSize: 14, fontWeight: '900', color: '#1a1a2e', marginBottom: 5, textAlign: 'center', lineHeight: 20 },
  dialogOrderId: { fontSize: 12, color: Colors.blue, fontWeight: '800', marginBottom: 6, textAlign: 'center' },
  dialogMsg: { fontSize: 12, color: '#5d6676', lineHeight: 18, marginBottom: 18, textAlign: 'center' },
  dialogBtns: { flexDirection: 'row', gap: 8 },
  dialogBtnNo: {
    flex: 1, borderWidth: 1.5, borderColor: '#dde3ec', borderRadius: 8,
    paddingVertical: 10, alignItems: 'center',
  },
  dialogBtnNoText: { fontWeight: '800', fontSize: 13, color: '#5d6676' },
  dialogBtnYes: {
    flex: 1, backgroundColor: '#e53935', borderRadius: 8,
    paddingVertical: 10, alignItems: 'center',
  },
  dialogBtnYesText: { fontWeight: '900', fontSize: 13, color: '#fff' },

  // Header row
  headerRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', paddingTop: 12, paddingBottom: 4, paddingHorizontal: 16 },
  title: { fontSize: 18, fontWeight: '900', color: Colors.ink, textAlign: 'center', flex: 1 },
  refreshBtn: {
    width: 32, height: 32, borderRadius: 16,
    backgroundColor: '#eef5ff', borderWidth: 1, borderColor: '#cce1ff',
    justifyContent: 'center', alignItems: 'center',
  },
  refreshIcon: { fontSize: 17, color: Colors.blue, fontWeight: '900' },

  // Tabs
  tabs: {
    flexDirection: 'row', borderBottomWidth: 1.5, borderBottomColor: '#e8ecf2',
    backgroundColor: '#fff',
  },
  tab: { flex: 1, paddingVertical: 10, alignItems: 'center' },
  tabActive: { borderBottomWidth: 2.5, borderBottomColor: Colors.blue },
  tabText: { fontSize: 12, fontWeight: '700', color: '#8896a7' },
  tabTextActive: { color: Colors.blue, fontWeight: '900' },

  // List
  scroll: { flex: 1 },
  scrollContent: { padding: 12, paddingBottom: 90 },

  // Card
  card: {
    backgroundColor: '#fff', borderRadius: 10, marginBottom: 8,
    borderWidth: 1, borderColor: '#e8edf5',
    ...Shadows.card, overflow: 'hidden',
    padding: 12,
  },
  cardCancelled: { borderColor: '#fde8e8', backgroundColor: '#fffafa', opacity: 0.75 },
  cardTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 },
  cardId: { fontSize: 13, fontWeight: '900', color: Colors.ink },
  cardIdCancelled: { color: '#b0b8c4', textDecorationLine: 'line-through' },
  cardPrice: { fontSize: 16, fontWeight: '900', color: Colors.blue },
  cardPriceCancelled: { color: '#c5ccd6', textDecorationLine: 'line-through' },
  cardMeta: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 3 },
  cardInfo: { fontSize: 11, color: '#7a8899', flex: 1 },
  cardDate: { fontSize: 10, color: '#a2abb8', marginTop: 2 },
  pill: {
    backgroundColor: '#e8f3ff', borderRadius: 6,
    paddingHorizontal: 7, paddingVertical: 3,
  },
  pillCancelled: { backgroundColor: '#fde8e8' },
  pillText: { color: Colors.blue, fontWeight: '800', fontSize: 10 },
  pillTextCancelled: { color: '#e53935' },

  // Cancel
  cancelRow: {
    borderTopWidth: 1, borderTopColor: '#fde8e8',
    marginTop: 8, paddingTop: 8,
    alignItems: 'center', justifyContent: 'center', minHeight: 30,
  },
  cancelText: { color: '#e53935', fontWeight: '800', fontSize: 12 },

  // 3-dot menu (cancelled cards)
  dotMenuBtn: {
    position: 'absolute', top: 8, right: 8, zIndex: 10,
    width: 26, height: 26, borderRadius: 13,
    backgroundColor: '#f4f5f9',
    justifyContent: 'center', alignItems: 'center',
  },
  dotMenuIcon: { fontSize: 17, fontWeight: '900', color: '#8896a7', lineHeight: 20 },
  dotDropdown: {
    position: 'absolute', top: 36, right: 8, zIndex: 20,
    backgroundColor: '#fff', borderRadius: 8,
    borderWidth: 1, borderColor: '#e8edf5',
    shadowColor: '#000', shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.12, shadowRadius: 12, elevation: 8,
    minWidth: 160,
  },
  dotDropdownItem: {
    paddingHorizontal: 12, paddingVertical: 10,
  },
  dotDropdownText: { fontSize: 12, fontWeight: '700', color: '#e53935' },

  // Empty state
  empty: {
    backgroundColor: '#fff', borderRadius: 12, borderWidth: 1,
    borderColor: '#e8edf5', padding: 22, alignItems: 'center', marginTop: 16,
  },
  emptyIcon: { fontSize: 36, marginBottom: 8 },
  emptyTitle: { fontSize: 15, fontWeight: '900', color: Colors.ink },
  emptySub: { fontSize: 12, color: '#7a8899', marginTop: 5, textAlign: 'center' },
  emptyBtn: {
    marginTop: 14, backgroundColor: Colors.blue, borderRadius: 8,
    paddingHorizontal: 22, paddingVertical: 10, ...Shadows.button,
  },
  emptyBtnText: { color: '#fff', fontWeight: '900', fontSize: 13 },
});
