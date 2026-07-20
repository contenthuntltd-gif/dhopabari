import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView } from 'react-native';
import { useRouter } from 'expo-router';
import { Colors, Shadows, money } from '../constants/theme';
import { useLanguage } from '../services/language';
import { useStore } from '../services/store';

export default function PriceListScreen() {
  const router = useRouter();
  const { t, lang } = useLanguage();
  const { priceMap } = useStore();

  const items = Object.entries(priceMap).map(([name, prices]) => ({
    name,
    wash: prices.wash,
    dry: prices.dry,
  }));

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
      <View style={styles.topbar}>
        <TouchableOpacity style={styles.backBtn} onPress={() => router.back()} activeOpacity={0.7}>
          <Text style={styles.backText}>‹</Text>
        </TouchableOpacity>
        <Text style={styles.title}>{t('priceTitle')}</Text>
        <View style={{ width: 36 }} />
      </View>

      <View style={styles.note}>
        <Text style={styles.noteText}>
          Wash / Dry Clean price item ও কাপড়ের condition অনুযায়ী final হবে।
        </Text>
      </View>

      {/* Price Table */}
      <View style={styles.table}>
        {/* Header */}
        <View style={[styles.tableRow, styles.tableHeader]}>
          <Text style={[styles.cellLeft, styles.headerText]}>{t('priceItem')}</Text>
          <Text style={[styles.cellRight, styles.headerText]}>{t('priceWash')} / {t('priceDry')}</Text>
        </View>

        {items.map((item, i) => (
          <View key={item.name} style={[styles.tableRow, i % 2 === 0 && styles.tableRowAlt]}>
            <Text style={styles.cellLeft}>{item.name}</Text>
            <Text style={styles.cellRight}>
              {item.wash === 0 && item.dry === 0 ? t('summaryFree') : `${money(item.wash)} / ${money(item.dry)}`}
            </Text>
          </View>
        ))}
      </View>

      <TouchableOpacity style={styles.primaryButton} onPress={() => router.push('/order')} activeOpacity={0.85}>
        <Text style={styles.primaryText}>{lang === 'bn' ? 'এই প্রাইস দিয়ে অর্ডার করুন' : 'Order at these prices'}</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { paddingHorizontal: 22, paddingTop: 16, paddingBottom: 40 },
  topbar: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', minHeight: 44, marginBottom: 8 },
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
  title: { fontSize: 24, fontWeight: '900', color: Colors.ink },
  note: {
    backgroundColor: '#eef7ff',
    borderWidth: 1,
    borderColor: '#d8eaff',
    borderRadius: 10,
    padding: 14,
    marginTop: 16,
  },
  noteText: { color: Colors.blueDark, fontWeight: '800', lineHeight: 22, fontSize: 14 },
  table: {
    borderWidth: 1,
    borderColor: '#d6dde8',
    borderRadius: 10,
    overflow: 'hidden',
    backgroundColor: '#fff',
    ...Shadows.card,
    marginTop: 16,
  },
  tableRow: {
    flexDirection: 'row',
    minHeight: 42,
    borderBottomWidth: 1,
    borderBottomColor: '#e7ebf2',
  },
  tableRowAlt: { backgroundColor: '#f8fafc' },
  tableHeader: { backgroundColor: Colors.blueDark },
  cellLeft: {
    flex: 1.2,
    paddingVertical: 9,
    paddingHorizontal: 10,
    fontSize: 14,
    color: Colors.ink,
    lineHeight: 20,
    borderRightWidth: 1,
    borderRightColor: '#e7ebf2',
  },
  cellRight: {
    flex: 1,
    paddingVertical: 9,
    paddingHorizontal: 10,
    fontSize: 14,
    fontWeight: '800',
    color: Colors.ink,
    textAlign: 'center',
  },
  headerText: { color: '#fff', fontWeight: '900', fontSize: 13 },
  primaryButton: {
    minHeight: 56,
    borderRadius: 8,
    backgroundColor: Colors.blue,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 24,
    ...Shadows.button,
  },
  primaryText: { color: '#fff', fontSize: 18, fontWeight: '900' },
});
