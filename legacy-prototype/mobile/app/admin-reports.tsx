import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { Colors, Shadows, toBn, money } from '../constants/theme';
import { getOrders } from '../services/api';
import { useLanguage } from '../services/language';

export default function AdminReportsScreen() {
  const router = useRouter();
  const { lang } = useLanguage();
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    try {
      const ords = await getOrders();
      setOrders(ords);
    } catch (e) {
      console.warn('Failed to load orders for reports');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const totalSales = orders
    .filter((o) => !o.status.includes('বাতিল') && !o.status.includes('cancelled'))
    .reduce((sum, o) => sum + (o.total || 0), 0);

  const avgOrderVal = orders.length ? Math.round(totalSales / orders.length) : 0;
  const codCount = orders.filter((o) => o.payment === 'COD').length;
  const onlineCount = orders.filter((o) => o.payment !== 'COD').length;

  return (
    <View style={styles.root}>
      <ScrollView style={styles.container} contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        {/* Header */}
        <View style={styles.topbar}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backBtn} activeOpacity={0.7}>
            <Text style={styles.backText}>‹</Text>
          </TouchableOpacity>
          <Text style={styles.title}>{lang === 'bn' ? 'ব্যবসায়িক এনালাইটিক্স' : 'Business Reports'}</Text>
          <View style={{ width: 36 }} />
        </View>

        {loading ? (
          <ActivityIndicator style={{ marginTop: 40 }} size="large" color={Colors.blue} />
        ) : (
          <View style={{ gap: 16 }}>
            {/* Financial Summary card */}
            <Text style={styles.reportSubtitle}>{lang === 'bn' ? 'আর্থিক সারসংক্ষেপ' : 'Financial Summary'}</Text>
            <View style={styles.reportStatCard}>
              <View style={styles.reportStatRow}>
                <Text style={styles.reportStatLabel}>{lang === 'bn' ? 'সর্বমোট বিক্রি' : 'Total Revenue'}</Text>
                <Text style={[styles.reportStatVal, { color: Colors.green, fontSize: 16 }]}>{money(totalSales)}</Text>
              </View>
              <View style={[styles.reportStatRow, { borderTopWidth: 1, borderTopColor: '#edf2f7', paddingTop: 8, marginTop: 4 }]}>
                <Text style={styles.reportStatLabel}>{lang === 'bn' ? 'গড় অর্ডার মূল্য' : 'Avg Order Value'}</Text>
                <Text style={styles.reportStatVal}>{money(avgOrderVal)}</Text>
              </View>
              <View style={[styles.reportStatRow, { borderTopWidth: 1, borderTopColor: '#edf2f7', paddingTop: 8, marginTop: 4 }]}>
                <Text style={styles.reportStatLabel}>{lang === 'bn' ? 'মোট সফল অর্ডার' : 'Total Orders'}</Text>
                <Text style={styles.reportStatVal}>
                  {toBn(orders.filter((o) => !o.status.includes('বাতিল') && !o.status.includes('cancelled')).length)}
                </Text>
              </View>
            </View>

            {/* Payment method distribution */}
            <Text style={styles.reportSubtitle}>{lang === 'bn' ? 'পেমেন্ট মেথড ডিস্ট্রিবিউশন' : 'Payment Type'}</Text>
            <View style={styles.reportStatCard}>
              <View style={styles.reportStatRow}>
                <Text style={styles.reportStatLabel}>💵 Cash on Delivery (COD)</Text>
                <Text style={styles.reportStatVal}>
                  {toBn(codCount)} {lang === 'bn' ? 'অর্ডার' : 'Orders'}
                </Text>
              </View>
              <View style={[styles.reportStatRow, { borderTopWidth: 1, borderTopColor: '#edf2f7', paddingTop: 8, marginTop: 4 }]}>
                <Text style={styles.reportStatLabel}>📱 bKash / Nagad</Text>
                <Text style={styles.reportStatVal}>
                  {toBn(onlineCount)} {lang === 'bn' ? 'অর্ডার' : 'Orders'}
                </Text>
              </View>
            </View>

            {/* Service Areas Summary */}
            <Text style={styles.reportSubtitle}>{lang === 'bn' ? 'অর্ডারের অবস্থান এনালাইটিক্স' : 'Top Service Areas'}</Text>
            <View style={styles.reportStatCard}>
              {['কলাতলী', 'সুগন্ধা', 'লাবণী', 'ঝাউতলা'].map((areaName, idx) => {
                const areaOrders = orders.filter(
                  (o) => o.address?.includes(areaName) || o.customerName === areaName
                ).length;
                return (
                  <View
                    key={areaName}
                    style={[
                      styles.reportStatRow,
                      idx > 0 && { borderTopWidth: 1, borderTopColor: '#edf2f7', paddingTop: 8, marginTop: 4 },
                    ]}
                  >
                    <Text style={styles.reportStatLabel}>📍 {areaName}</Text>
                    <Text style={styles.reportStatVal}>
                      {toBn(areaOrders)} {lang === 'bn' ? 'অর্ডার' : 'Orders'}
                    </Text>
                  </View>
                );
              })}
            </View>
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#f7f9fc' },
  container: { flex: 1 },
  content: { paddingHorizontal: 20, paddingTop: 16, paddingBottom: 40 },
  topbar: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', minHeight: 44, marginBottom: 20 },
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
  title: { fontSize: 22, fontWeight: '900', color: Colors.ink },

  reportSubtitle: { fontSize: 15, fontWeight: '900', color: Colors.ink, marginTop: 8, marginBottom: 6 },
  reportStatCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 14,
    borderWidth: 1,
    borderColor: '#eef1f6',
    ...Shadows.card as any,
  },
  reportStatRow: { flexDirection: 'row', justifyContent: 'space-between', paddingVertical: 6 },
  reportStatLabel: { fontSize: 13, color: '#475569', fontWeight: '800' },
  reportStatVal: { fontSize: 14, color: Colors.blue, fontWeight: '900' },
});
