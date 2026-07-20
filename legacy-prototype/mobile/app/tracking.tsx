import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Linking } from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { Colors, Shadows, workflowSteps, ridersData } from '../constants/theme';
import { useStore } from '../services/store';
import Svg, { Path, Circle } from 'react-native-svg';
import { useLanguage } from '../services/language';
import { getOrders } from '../services/api';

export default function TrackingScreen() {
  const router = useRouter();
  const params = useLocalSearchParams();
  const { lastOrderId, orderWorkflowStatus, activeRiderId, setOrderWorkflowStatus, setActiveRiderId } = useStore();
  const { t, lang } = useLanguage();

  const activeOrderId = (params.orderId as string) || lastOrderId;

  const [status, setStatus] = useState(orderWorkflowStatus);
  const [riderId, setRiderId] = useState(activeRiderId);

  useEffect(() => {
    const fetchStatus = async () => {
      try {
        const ordersList = await getOrders();
        const activeOrder = ordersList.find(
          (o: any) => String(o.id).toLowerCase() === String(activeOrderId).toLowerCase()
        );
        if (activeOrder) {
          setStatus(activeOrder.status);
          setRiderId(activeOrder.riderId || 'rider_karim');
          // Sync to global store
          setOrderWorkflowStatus(activeOrder.status);
          if (activeOrder.riderId) setActiveRiderId(activeOrder.riderId);
        }
      } catch (e) {
        console.warn('Failed to fetch live order tracking details');
      }
    };

    fetchStatus();
    const interval = setInterval(fetchStatus, 3000); // poll every 3 seconds

    return () => clearInterval(interval);
  }, [activeOrderId]);

  const statusMap: Record<string, string> = {
    'pending': 'pending',
    'অর্ডার পেন্ডিং': 'pending',
    'confirmed': 'confirmed',
    'অর্ডার কনফার্মড': 'confirmed',
    'collecting': 'collecting',
    'কাপড় সংগ্রহ করা হচ্ছে': 'collecting',
    'collected': 'collected',
    'কাপড় সংগ্রহ করা হয়েছে': 'collected',
    'washing': 'washing',
    'ধোয়া হচ্ছে': 'washing',
    'packaging': 'packaging',
    'প্যাকেজিং': 'packaging',
    'ready': 'ready',
    'ডেলিভারির জন্য প্রস্তুত': 'ready',
    'delivered': 'delivered',
    'ডেলিভারি সম্পন্ন': 'delivered',
  };

  const currentKey = statusMap[status] || 'pending';
  const activeIndex = Math.max(workflowSteps.findIndex((s) => s.key === currentKey), 0);
  const rider = ridersData[riderId] || ridersData.rider_karim;

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
      {/* Header */}
      <View style={styles.topbar}>
        <TouchableOpacity style={styles.backBtn} onPress={() => router.back()} activeOpacity={0.7}>
          <Text style={styles.backText}>‹</Text>
        </TouchableOpacity>
        <Text style={styles.title}>{t('trackingTitle')}</Text>
        <View style={styles.orderBadge}>
          <Text style={styles.orderBadgeText}>#{activeOrderId}</Text>
        </View>
      </View>

      {/* Tracking Steps */}
      <View style={styles.trackingList}>
        {workflowSteps.map((step, index) => {
          const done = index < activeIndex;
          const current = index === activeIndex;
          const isLast = index === workflowSteps.length - 1;

          return (
            <View key={step.key} style={styles.trackItem}>
              {/* Line */}
              {!isLast && (
                <View style={[styles.trackLine, done && styles.trackLineDone]} />
              )}
              {/* Dot */}
              <View style={[
                styles.trackDot,
                done && styles.trackDotDone,
                current && styles.trackDotCurrent,
              ]}>
                {done ? (
                  <Text style={styles.trackDotCheck}>✓</Text>
                ) : (
                  <View style={[styles.trackDotInner, current && styles.trackDotInnerCurrent]} />
                )}
              </View>
              {/* Content */}
              <View style={styles.trackContent}>
                <Text style={[
                  styles.trackTitle,
                  done && styles.trackTitleDone,
                  current && styles.trackTitleCurrent,
                ]}>
                  {step.title}
                </Text>
                <Text style={styles.trackNote}>{step.note}</Text>
              </View>
            </View>
          );
        })}
      </View>

      {/* Rider Card */}
      <View style={styles.riderCard}>
        <View style={styles.riderAvatar}>
          <Text style={styles.riderAvatarText}>{rider.avatar}</Text>
        </View>
        <View style={styles.riderInfo}>
          <Text style={styles.riderName}>{rider.name}</Text>
          <Text style={styles.riderPhone}>{t('trackingDeliveryMan')} • {rider.displayPhone}</Text>
        </View>
        <TouchableOpacity
          style={[styles.circleAction, { backgroundColor: Colors.green }]}
          onPress={() => Linking.openURL(`tel:${rider.phone}`)}
          activeOpacity={0.8}
        >
          <Svg width={18} height={18} viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
            <Path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z" />
          </Svg>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.circleAction, { backgroundColor: Colors.blue }]}
          onPress={() => router.push({
            pathname: '/chat',
            params: { orderId: activeOrderId, riderId: rider.id }
          })}
          activeOpacity={0.8}
        >
          <Svg width={18} height={18} viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
            <Path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
            <Circle cx={8} cy={10} r={1.5} fill="#fff" />
            <Circle cx={12} cy={10} r={1.5} fill="#fff" />
            <Circle cx={16} cy={10} r={1.5} fill="#fff" />
          </Svg>
        </TouchableOpacity>
      </View>

      {/* ETA or Thank You Note */}
      <View style={[styles.eta, currentKey === 'delivered' && { backgroundColor: '#eafaf1', borderColor: '#c3ecd0' }]}>
        <Text style={styles.etaIcon}>{currentKey === 'delivered' ? '🎉' : '◴'}</Text>
        <Text style={[styles.etaText, currentKey === 'delivered' && { color: '#15803d' }]}>
          {currentKey === 'delivered'
            ? (lang === 'bn'
                ? 'ধোপা বাড়ি বেছে নেওয়ার জন্য ধন্যবাদ! আপনার পরবর্তী অর্ডারে আবার দেখা হবে। 💙'
                : 'Thank you for choosing Dopa Bari! Hope to serve you again on your next order. 💙')
            : (lang === 'bn'
                ? 'আনুমানিক ডেলিভারি সময়: সংগ্রহের পর ৩-৭ দিন'
                : 'Estimated Delivery: 3-7 Days after collection')
          }
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { paddingHorizontal: 16, paddingTop: 16, paddingBottom: 16 },
  topbar: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', minHeight: 44, marginBottom: 8 },
  
  // Premium Back Button Style
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
  
  title: { fontSize: 20, fontWeight: '900', color: Colors.ink },
  orderBadge: { backgroundColor: '#eaf3ff', borderRadius: 10, paddingHorizontal: 10, paddingVertical: 6 },
  orderBadgeText: { color: Colors.blue, fontWeight: '900', fontSize: 13 },
  
  // Compact list layout
  trackingList: { marginTop: 12, paddingLeft: 42 },
  trackItem: { minHeight: 52, paddingLeft: 22, marginBottom: 4, position: 'relative' },
  trackLine: {
    position: 'absolute',
    left: -22,
    top: 24,
    bottom: -10,
    width: 2,
    backgroundColor: '#e2e8f0',
  },
  trackLineDone: { backgroundColor: Colors.green },
  trackDot: {
    position: 'absolute',
    left: -32,
    top: 4,
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 2,
    borderColor: '#c8d0db',
    backgroundColor: '#fff',
    justifyContent: 'center',
    alignItems: 'center',
  },
  trackDotDone: { backgroundColor: Colors.green, borderColor: Colors.green },
  trackDotCurrent: {
    backgroundColor: Colors.blue,
    borderColor: Colors.blue,
  },
  trackDotInner: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: '#cbd5e1',
  },
  trackDotInnerCurrent: {
    backgroundColor: '#fff',
  },
  trackDotCheck: { color: '#fff', fontSize: 12, fontWeight: '900' },
  trackContent: { paddingTop: 2 },
  trackTitle: { fontSize: 14, fontWeight: '900', color: '#64748b' },
  trackTitleDone: { color: Colors.ink },
  trackTitleCurrent: { color: Colors.blue },
  trackNote: { fontSize: 11, color: Colors.muted, marginTop: 1, lineHeight: 15 },
  
  // Compact Rider Card
  riderCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#eef1f6',
    ...Shadows.card as any,
    backgroundColor: '#fff',
    marginTop: 16,
  },
  riderAvatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: Colors.blue,
    justifyContent: 'center',
    alignItems: 'center',
  },
  riderAvatarText: { color: '#fff', fontWeight: '900', fontSize: 20 },
  riderInfo: { flex: 1 },
  riderName: { fontSize: 15, fontWeight: '900', color: Colors.ink },
  riderPhone: { fontSize: 12, color: Colors.muted, marginTop: 2 },
  circleAction: {
    width: 38,
    height: 38,
    borderRadius: 19,
    justifyContent: 'center',
    alignItems: 'center',
  },
  
  // Compact ETA
  eta: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: '#eef7ff',
    borderWidth: 1,
    borderColor: '#d9ebff',
    borderRadius: 10,
    minHeight: 44,
    paddingHorizontal: 12,
    marginTop: 10,
  },
  etaIcon: { fontSize: 18 },
  etaText: { fontSize: 13, fontWeight: '800', color: Colors.ink, flex: 1 },
});
