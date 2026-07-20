import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, ActivityIndicator } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useRouter } from 'expo-router';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Colors, Gradients, Shadows, toBn, money, ridersData } from '../constants/theme';
import { getOrders, updateOrderStatus, getCustomers } from '../services/api';
import { useLanguage } from '../services/language';

export default function AdminDashboard() {
  const router = useRouter();
  const { lang } = useLanguage();

  const [orders, setOrders] = useState<any[]>([]);
  const [customers, setCustomers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  // Active status tab: 0: All, 1: Pending/Confirmed, 2: Processing, 3: Completed, 4: Cancelled
  const [activeTab, setActiveTab] = useState(0);

  // Overlays
  const [showRiderAssign, setShowRiderAssign] = useState<string | null>(null); // holds orderId

  const loadData = async () => {
    try {
      const ords = await getOrders();
      setOrders(ords.sort((a: any, b: any) => b.id - a.id));
      const custs = await getCustomers();
      setCustomers(custs);
    } catch (e) {
      console.warn('Failed to load admin data');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const [authChecked, setAuthChecked] = useState(false);

  useEffect(() => {
    const checkAuth = async () => {
      const session = await AsyncStorage.getItem('admin_session');
      if (session !== 'true') {
        router.replace('/admin-login');
      } else {
        setAuthChecked(true);
        loadData();
      }
    };
    checkAuth();
  }, []);

  if (!authChecked) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#fff' }}>
        <ActivityIndicator size="large" color={Colors.blue} />
      </View>
    );
  }

  const handleRefresh = () => {
    setRefreshing(true);
    loadData();
  };

  const handleAssignRider = async (riderId: string) => {
    if (!showRiderAssign) return;
    try {
      await updateOrderStatus(showRiderAssign, 'অর্ডার কনফার্মড', riderId);
      setShowRiderAssign(null);
      loadData();
    } catch (e) {
      console.error('Rider assignment failed');
    }
  };

  const handleAdvanceStatus = async (orderId: string, currentStatus: string) => {
    const statusWorkflow = [
      'অর্ডার পেন্ডিং',
      'অর্ডার কনফার্মড',
      'কাপড় সংগ্রহ করা হচ্ছে',
      'কাপড় সংগ্রহ করা হয়েছে',
      'ধোয়া হচ্ছে',
      'প্যাকেজিং',
      'ডেলিভারির জন্য প্রস্তুত',
      'ডেলিভারি সম্পন্ন'
    ];

    const idx = statusWorkflow.indexOf(currentStatus);
    if (idx === -1 || idx === statusWorkflow.length - 1) return;
    const nextStatus = statusWorkflow[idx + 1];

    try {
      await updateOrderStatus(orderId, nextStatus);
      loadData();
    } catch (e) {
      console.error('Status advancement failed');
    }
  };

  const handleCancelOrder = async (orderId: string) => {
    try {
      await updateOrderStatus(orderId, 'বাতিল');
      loadData();
    } catch (e) {
      console.error('Order cancellation failed');
    }
  };

  // Metric computations
  const totalSales = orders
    .filter((o) => !o.status.includes('বাতিল') && !o.status.includes('cancelled'))
    .reduce((sum, o) => sum + (o.total || 0), 0);

  const activeOrders = orders.filter((o) => {
    const s = o.status.toLowerCase();
    return !s.includes('সম্পন্ন') && !s.includes('delivered') &&
           !s.includes('বাতিল') && !s.includes('cancelled');
  }).length;

  const pendingPickups = orders.filter(
    (o) => o.status.includes('পেন্ডিং') || o.status.includes('pending')
  ).length;

  // Filter orders by tab
  const getFilteredOrders = () => {
    if (activeTab === 0) return orders;
    return orders.filter((o) => {
      const s = o.status.toLowerCase();
      if (activeTab === 1) {
        return o.status.includes('পেন্ডিং') || o.status.includes('pending') || o.status.includes('কনফার্মড') || o.status.includes('confirmed');
      }
      if (activeTab === 2) {
        return (o.status.includes('সংগ্রহ') || o.status.includes('ধোয়া') || o.status.includes('প্যাকেজিং') || o.status.includes('প্রস্তুত')) &&
               !s.includes('পেন্ডিং') && !s.includes('pending') && !s.includes('সম্পন্ন') && !s.includes('delivered');
      }
      if (activeTab === 3) {
        return s.includes('সম্পন্ন') || s.includes('delivered');
      }
      if (activeTab === 4) {
        return s.includes('বাতিল') || s.includes('cancelled');
      }
      return true;
    });
  };

  const filtered = getFilteredOrders();

  // Next status button label helper
  const getNextStatusLabel = (status: string) => {
    const mapping: Record<string, string> = {
      'অর্ডার পেন্ডিং': lang === 'bn' ? 'কনফার্ম ও রাইডার দিন' : 'Confirm & Assign',
      'অর্ডার কনফার্মড': lang === 'bn' ? 'সংগ্রহ শুরু করুন' : 'Start Collecting',
      'কাপড় সংগ্রহ করা হচ্ছে': lang === 'bn' ? 'সংগ্রহ সম্পন্ন করুন' : 'Mark Collected',
      'কাপড় সংগ্রহ করা হয়েছে': lang === 'bn' ? 'ধোয়ার কাজ শুরু' : 'Start Washing',
      'ধোয়া হচ্ছে': lang === 'bn' ? 'প্যাকেজিং শুরু করুন' : 'Start Packaging',
      'প্যাকেজিং': lang === 'bn' ? 'প্রস্তুত করুন' : 'Mark Ready for Delivery',
      'ডেলিভারির জন্য প্রস্তুত': lang === 'bn' ? 'ডেলিভারি সম্পন্ন' : 'Mark Delivered',
    };
    return mapping[status] || null;
  };

  return (
    <View style={styles.root}>
      <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
        {/* Dashboard Header */}
        <LinearGradient colors={Gradients.dashboardHead as any} style={styles.header}>
          <View style={styles.topbar}>
            <TouchableOpacity onPress={() => router.back()} style={styles.backBtn} activeOpacity={0.7}>
              <Text style={styles.backText}>‹</Text>
            </TouchableOpacity>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
              <View style={styles.adminBadge}>
                <Text style={styles.adminBadgeText}>{lang === 'bn' ? 'অ্যাডমিন' : 'Admin'}</Text>
              </View>
              <TouchableOpacity
                onPress={async () => {
                  await AsyncStorage.removeItem('admin_session');
                  router.replace('/');
                }}
                style={styles.logoutBtn}
                activeOpacity={0.7}
              >
                <Text style={styles.logoutBtnText}>🚪</Text>
              </TouchableOpacity>
            </View>
          </View>
          <Text style={styles.headerTitle}>{lang === 'bn' ? 'ধোপা বাড়ি ড্যাশবোর্ড' : 'Dopa Bari Console'}</Text>
          <Text style={styles.headerSubtitle}>
            {lang === 'bn' ? 'আজকের বিক্রি, লাইভ অর্ডার ও পিকআপ কন্ট্রোল' : 'Today\'s sales, active orders & logistics control'}
          </Text>

          {/* Metric Dashboard */}
          <View style={styles.metricGrid}>
            <View style={styles.metricCard}>
              <Text style={styles.metricLabel}>{lang === 'bn' ? 'আজকের বিক্রি' : 'Today\'s Revenue'}</Text>
              <Text style={styles.metricValue}>{money(totalSales)}</Text>
            </View>
            <View style={styles.metricCard}>
              <Text style={styles.metricLabel}>{lang === 'bn' ? 'চলমান অর্ডার' : 'Active Orders'}</Text>
              <Text style={styles.metricValue}>{toBn(activeOrders)}</Text>
            </View>
            <View style={styles.metricCard}>
              <Text style={styles.metricLabel}>{lang === 'bn' ? 'পেন্ডিং পিকআপ' : 'Pending Pickups'}</Text>
              <Text style={styles.metricValue}>{toBn(pendingPickups)}</Text>
            </View>
            <View style={styles.metricCard}>
              <Text style={styles.metricLabel}>{lang === 'bn' ? 'মোট কাস্টমার' : 'Total Customers'}</Text>
              <Text style={styles.metricValue}>{toBn(customers.length)}</Text>
            </View>
          </View>
        </LinearGradient>

        <View style={styles.body}>
          {/* Quick Actions Management Row */}
          <View style={styles.quickActionsRow}>
            <TouchableOpacity style={styles.actionPill} onPress={() => router.push('/admin-pricing')}>
              <Text style={styles.actionPillText}>🏷️ {lang === 'bn' ? 'আইটেমের নাম' : 'Item Name'}</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionPill} onPress={() => router.push('/admin-customers')}>
              <Text style={styles.actionPillText}>👥 {lang === 'bn' ? 'কাস্টমারস' : 'Customers'}</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionPill} onPress={() => router.push('/admin-riders')}>
              <Text style={styles.actionPillText}>🏍️ {lang === 'bn' ? 'রাইডারস' : 'Riders'}</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.actionPill} onPress={() => router.push('/admin-reports')}>
              <Text style={styles.actionPillText}>📊 {lang === 'bn' ? 'রিপোর্ট' : 'Reports'}</Text>
            </TouchableOpacity>
          </View>

          {/* Header Row */}
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>📦 {lang === 'bn' ? 'অর্ডার কিউ / তালিকা' : 'Live Order Queue'}</Text>
            <TouchableOpacity style={styles.refreshBtn} onPress={handleRefresh} disabled={refreshing}>
              {refreshing ? (
                <ActivityIndicator size="small" color={Colors.blue} />
              ) : (
                <Text style={styles.refreshBtnText}>🔄 {lang === 'bn' ? 'রিফ্রেশ' : 'Refresh'}</Text>
              )}
            </TouchableOpacity>
          </View>

          {/* Queue Tab Buttons */}
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.tabsScroll}>
            {[
              lang === 'bn' ? 'সব অর্ডার' : 'All',
              lang === 'bn' ? 'পেন্ডিং/কনফার্ম' : 'New/Pending',
              lang === 'bn' ? 'প্রসেসিং' : 'Processing',
              lang === 'bn' ? 'সম্পন্ন' : 'Completed',
              lang === 'bn' ? 'বাতিল' : 'Cancelled'
            ].map((tabLabel, idx) => (
              <TouchableOpacity
                key={idx}
                style={[styles.queueTab, activeTab === idx && styles.queueTabActive]}
                onPress={() => setActiveTab(idx)}
              >
                <Text style={[styles.queueTabText, activeTab === idx && styles.queueTabTextActive]}>
                  {tabLabel}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>

          {/* Order List */}
          {loading ? (
            <ActivityIndicator style={{ marginTop: 40 }} size="large" color={Colors.blue} />
          ) : filtered.length === 0 ? (
            <View style={styles.emptyQueueCard}>
              <Text style={styles.emptyQueueIcon}>📭</Text>
              <Text style={styles.emptyQueueTitle}>
                {lang === 'bn' ? 'কোনো অর্ডার পাওয়া যায়নি' : 'No orders in queue'}
              </Text>
              <Text style={styles.emptyQueueSub}>
                {lang === 'bn' ? 'এই ফিল্টারে বর্তমানে কোনো তালিকা নেই।' : 'Currently no items match this category.'}
              </Text>
            </View>
          ) : (
            filtered.map((order) => {
              const nextStatusLabel = getNextStatusLabel(order.status);
              const isOrderPending = order.status.includes('পেন্ডিং') || order.status.includes('pending');
              const isOrderCancelled = order.status.includes('বাতিল') || order.status.includes('cancelled');
              const isOrderDelivered = order.status.includes('সম্পন্ন') || order.status.includes('delivered');

              // Find assigned rider name
              const riderObj = ridersData[order.riderId];

              return (
                <View key={order.id} style={styles.queueCard}>
                  <View style={styles.queueCardTop}>
                    <View style={{ flex: 1 }}>
                      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                        <Text style={styles.orderId}>#{order.id}</Text>
                        <Text style={styles.orderDate}>
                          {order.createdAt ? new Date(order.createdAt).toLocaleTimeString(lang === 'bn' ? 'bn-BD' : 'en-US', { hour: '2-digit', minute: '2-digit' }) : ''}
                        </Text>
                      </View>
                      <Text style={styles.orderInfo}>
                        👤 {order.customerName} • 📞 {order.phone}
                      </Text>
                      <Text style={styles.orderInfo}>
                        📍 {order.address}
                      </Text>
                      <Text style={styles.orderService}>
                        🧺 {order.service} ({toBn(order.items?.length || 0)} {lang === 'bn' ? 'আইটেম' : 'Items'})
                      </Text>
                      {riderObj && (
                        <Text style={styles.riderAssigned}>
                          🏍️ {lang === 'bn' ? 'নিযুক্ত রাইডার: ' : 'Rider: '} <Text style={{ fontWeight: '800' }}>{riderObj.name}</Text>
                        </Text>
                      )}
                    </View>

                    {/* Status badge */}
                    <View style={[styles.statusBadge, isOrderCancelled && styles.statusBadgeRed, isOrderDelivered && styles.statusBadgeGreen]}>
                      <Text style={[styles.statusBadgeText, isOrderCancelled && styles.statusBadgeTextRed, isOrderDelivered && styles.statusBadgeTextGreen]}>
                        {order.status}
                      </Text>
                    </View>
                  </View>

                  <View style={styles.orderRow}>
                    <Text style={styles.paymentMethod}>
                      💳 {lang === 'bn' ? 'পেমেন্ট: ' : 'Pay: '}<Text style={{ fontWeight: '900' }}>{order.payment}</Text>
                    </Text>
                    <Text style={styles.price}>{money(order.total || 0)}</Text>
                  </View>

                  {/* Actions Row */}
                  <View style={styles.actionRow}>
                    <TouchableOpacity 
                      style={[styles.chatBtn, (isOrderCancelled || isOrderDelivered) && { flex: 1 }]} 
                      onPress={() => router.push({
                        pathname: '/chat',
                        params: { orderId: order.id, riderId: order.riderId || 'rider_karim' }
                      })}
                      activeOpacity={0.8}
                    >
                      <Text style={styles.chatBtnText}>💬 {lang === 'bn' ? 'চ্যাট' : 'Chat'}</Text>
                    </TouchableOpacity>

                    {!isOrderCancelled && !isOrderDelivered && (
                      <>
                        <TouchableOpacity 
                          style={styles.cancelBtn} 
                          onPress={() => handleCancelOrder(order.id)}
                          activeOpacity={0.8}
                        >
                          <Text style={styles.cancelBtnText}>{lang === 'bn' ? 'বাতিল' : 'Cancel'}</Text>
                        </TouchableOpacity>

                        {isOrderPending ? (
                          <TouchableOpacity 
                            style={styles.solidBtn} 
                            onPress={() => setShowRiderAssign(order.id)}
                            activeOpacity={0.8}
                          >
                            <Text style={styles.solidBtnText}>{lang === 'bn' ? 'রাইডার' : 'Assign Rider'}</Text>
                          </TouchableOpacity>
                        ) : (
                          nextStatusLabel && (
                            <TouchableOpacity 
                              style={styles.advanceBtn} 
                              onPress={() => handleAdvanceStatus(order.id, order.status)}
                              activeOpacity={0.8}
                            >
                              <Text style={styles.advanceBtnText}>⚡ {nextStatusLabel}</Text>
                            </TouchableOpacity>
                          )
                        )}
                      </>
                    )}
                  </View>
                </View>
              );
            })
          )}
        </View>
      </ScrollView>

      {/* ── 1. Rider Assignment Overlay ── */}
      {showRiderAssign && (
        <View style={styles.overlay}>
          <View style={styles.dialog}>
            <View style={styles.dialogHeader}>
              <Text style={styles.dialogTitle}>
                {lang === 'bn' ? 'রাইডার নিযুক্ত করুন' : 'Assign Delivery Rider'}
              </Text>
              <TouchableOpacity onPress={() => setShowRiderAssign(null)}>
                <Text style={styles.dialogClose}>✕</Text>
              </TouchableOpacity>
            </View>

            <Text style={styles.dialogSubtitle}>
              {lang === 'bn' ? `অর্ডার #${showRiderAssign}-এর জন্য রাইডার বেছে নিন:` : `Choose logistics rider for order #${showRiderAssign}:`}
            </Text>

            <View style={{ gap: 10, marginVertical: 14 }}>
              {Object.keys(ridersData).map((key) => {
                const rider = ridersData[key];
                return (
                  <TouchableOpacity
                    key={key}
                    style={styles.riderListCard}
                    onPress={() => handleAssignRider(key)}
                    activeOpacity={0.8}
                  >
                    <View style={styles.riderAvatar}>
                      <Text style={styles.riderAvatarText}>{rider.avatar}</Text>
                    </View>
                    <View style={{ flex: 1 }}>
                      <Text style={styles.riderName}>{rider.name}</Text>
                      <Text style={styles.riderPhone}>📞 {rider.phone}</Text>
                    </View>
                    <Text style={styles.assignArrow}>›</Text>
                  </TouchableOpacity>
                );
              })}
            </View>
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
    paddingHorizontal: 22,
    paddingTop: 16,
    paddingBottom: 24,
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
    ...Shadows.button as any,
  },
  topbar: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
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
  adminBadge: { backgroundColor: '#fff', borderRadius: 999, paddingHorizontal: 12, paddingVertical: 6 },
  adminBadgeText: { color: Colors.blue, fontWeight: '900', fontSize: 13 },
  headerTitle: { fontSize: 26, fontWeight: '900', color: '#fff', marginTop: 14 },
  headerSubtitle: { color: 'rgba(255,255,255,0.82)', fontSize: 13, marginTop: 4, lineHeight: 18 },
  metricGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginTop: 18 },
  metricCard: {
    width: '48%',
    minHeight: 74,
    borderRadius: 12,
    backgroundColor: 'rgba(255,255,255,0.13)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.18)',
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  metricLabel: { color: 'rgba(255,255,255,0.85)', fontSize: 12, fontWeight: '700' },
  metricValue: { color: '#fff', fontSize: 22, fontWeight: '900', marginTop: 4 },
  
  body: { paddingHorizontal: 16, paddingBottom: 40 },
  quickActionsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 14,
    justifyContent: 'center',
  },
  actionPill: {
    backgroundColor: '#fff',
    borderWidth: 1.5,
    borderColor: '#e2e8f0',
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 20,
    minWidth: '22%',
    alignItems: 'center',
    ...Shadows.card as any,
  },
  actionPillText: {
    fontSize: 12,
    fontWeight: '800',
    color: '#334155',
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 22,
    marginBottom: 10,
  },
  sectionTitle: { fontSize: 17, fontWeight: '900', color: Colors.ink },
  refreshBtn: {
    paddingVertical: 6,
    paddingHorizontal: 12,
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#e2e8f0',
    borderRadius: 8,
  },
  refreshBtnText: {
    fontSize: 12,
    fontWeight: '800',
    color: Colors.blue,
  },
  tabsScroll: {
    flexDirection: 'row',
    marginBottom: 12,
  },
  queueTab: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 14,
    backgroundColor: '#eaf2fd',
    marginRight: 8,
    borderWidth: 1.5,
    borderColor: 'transparent',
  },
  queueTabActive: {
    backgroundColor: Colors.blue,
    borderColor: Colors.blue,
  },
  queueTabText: {
    fontSize: 13,
    fontWeight: '800',
    color: '#475569',
  },
  queueTabTextActive: {
    color: '#fff',
  },
  emptyQueueCard: {
    paddingVertical: 50,
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    marginTop: 10,
  },
  emptyQueueIcon: {
    fontSize: 48,
    marginBottom: 8,
  },
  emptyQueueTitle: {
    fontSize: 16,
    fontWeight: '900',
    color: Colors.ink,
  },
  emptyQueueSub: {
    fontSize: 12,
    color: Colors.muted,
    marginTop: 4,
  },

  // Queue cards
  queueCard: {
    backgroundColor: '#fff',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    ...Shadows.card as any,
    padding: 16,
    marginBottom: 12,
  },
  queueCardTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    borderBottomWidth: 1.5,
    borderBottomColor: '#f1f5f9',
    paddingBottom: 12,
  },
  orderId: { fontSize: 18, fontWeight: '900', color: Colors.ink },
  orderDate: { fontSize: 11, color: Colors.muted },
  orderInfo: { fontSize: 13, color: '#475569', marginTop: 4, fontWeight: '700' },
  orderService: { fontSize: 12, color: Colors.muted, marginTop: 4, fontWeight: '700' },
  riderAssigned: { fontSize: 12, color: Colors.blue, marginTop: 5, fontWeight: '800' },
  statusBadge: {
    backgroundColor: '#fff3e0',
    borderRadius: 8,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderWidth: 1,
    borderColor: '#ffe0b2',
  },
  statusBadgeGreen: {
    backgroundColor: '#e8f5e9',
    borderColor: '#c8e6c9',
  },
  statusBadgeRed: {
    backgroundColor: '#ffebee',
    borderColor: '#ffcdd2',
  },
  statusBadgeText: { fontSize: 11, color: '#e65100', fontWeight: '900' },
  statusBadgeTextGreen: { color: '#2e7d32' },
  statusBadgeTextRed: { color: '#c62828' },
  
  orderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
  },
  paymentMethod: {
    fontSize: 13,
    color: '#64748b',
    fontWeight: '700',
  },
  price: { fontSize: 22, fontWeight: '900', color: Colors.blue },
  actionRow: { flexDirection: 'row', gap: 10, borderTopWidth: 1, borderTopColor: '#f1f5f9', paddingTop: 12 },
  cancelBtn: {
    flex: 0.35,
    minHeight: 40,
    borderRadius: 10,
    borderWidth: 1.5,
    borderColor: '#fca5a5',
    backgroundColor: '#fff5f5',
    justifyContent: 'center',
    alignItems: 'center',
  },
  cancelBtnText: { color: '#dc2626', fontWeight: '900', fontSize: 13 },
  solidBtn: {
    flex: 1,
    minHeight: 40,
    borderRadius: 10,
    backgroundColor: Colors.blue,
    justifyContent: 'center',
    alignItems: 'center',
    ...Shadows.button as any,
  },
  solidBtnText: { color: '#fff', fontWeight: '900', fontSize: 13 },
  advanceBtn: {
    flex: 1,
    minHeight: 40,
    borderRadius: 10,
    backgroundColor: '#10b981',
    justifyContent: 'center',
    alignItems: 'center',
    ...Shadows.greenButton as any,
  },
  advanceBtnText: { color: '#fff', fontWeight: '900', fontSize: 13 },

  // Overlay Dialogs
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
  dialogTitle: { fontSize: 18, fontWeight: '900', color: Colors.ink },
  dialogClose: { fontSize: 20, color: Colors.muted, paddingHorizontal: 8 },
  dialogSubtitle: { fontSize: 14, color: Colors.muted, marginBottom: 8, fontWeight: '700' },
  emptyText: { textAlign: 'center', color: Colors.muted, paddingVertical: 20, fontSize: 14 },
  
  // Rider assignments List
  riderListCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderRadius: 12,
    borderWidth: 1.5,
    borderColor: '#e2e8f0',
    backgroundColor: '#f8fafc',
  },
  riderAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#e2e8f0',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  riderAvatarText: { fontSize: 16, fontWeight: '900', color: Colors.ink },
  riderName: { fontSize: 15, fontWeight: '900', color: Colors.ink },
  riderPhone: { fontSize: 12, color: Colors.muted, marginTop: 2 },
  assignArrow: { fontSize: 22, color: Colors.muted, marginLeft: 8 },

  // Chat action buttons
  chatBtn: {
    flex: 0.3,
    minHeight: 40,
    borderRadius: 10,
    backgroundColor: '#eef5ff',
    borderWidth: 1.5,
    borderColor: '#cce1ff',
    justifyContent: 'center',
    alignItems: 'center',
  },
  chatBtnText: { color: '#0874f8', fontWeight: '900', fontSize: 13 },
  logoutBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(255,255,255,0.2)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  logoutBtnText: {
    fontSize: 16,
    lineHeight: 18,
  },
});
