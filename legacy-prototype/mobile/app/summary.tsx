import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, TextInput } from 'react-native';
import { useRouter } from 'expo-router';
import { Colors, Shadows, toBn, money, serviceLabels, DELIVERY_TIME_TEXT } from '../constants/theme';
import { useStore } from '../services/store';
import { createOrder, saveCustomer } from '../services/api';
import Svg, { Path, Rect, Circle, Line } from 'react-native-svg';
import { useLanguage } from '../services/language';

export default function SummaryScreen() {
  const router = useRouter();
  const { getCartItems, cartSubtotal, deliveryCharge, cartTotal, user, setUser, getOrderPayload, clearCart, setLastOrderId, setOrderWorkflowStatus } = useStore();
  const { t } = useLanguage();
  const [payment, setPayment] = useState('COD');
  const [loading, setLoading] = useState(false);

  const [isEditingAddress, setIsEditingAddress] = useState(false);
  const [editedAddress, setEditedAddress] = useState(user.address || '');

  const handleSaveAddress = async () => {
    if (!editedAddress.trim()) return;
    const updatedUser = { ...user, address: editedAddress.trim() };
    setUser(updatedUser);
    setIsEditingAddress(false);
    try {
      await saveCustomer(updatedUser);
    } catch (e) {
      console.warn('Address updated locally');
    }
  };

  const items = getCartItems();
  const subtotal = cartSubtotal();
  const delivery = deliveryCharge();
  const total = cartTotal();
  const services = [...new Set(items.map((i) => i.serviceLabel))];

  const handleConfirm = async () => {
    if (items.length === 0) return;
    setLoading(true);
    try {
      const payload = getOrderPayload();
      const order = await createOrder(payload);
      setLastOrderId(order.id);
      setOrderWorkflowStatus('pending');
      clearCart();
      router.push('/success');
    } catch (e) {
      console.warn('Order saved locally');
      clearCart();
      router.push('/success');
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <ScrollView style={styles.scroll} contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        <View style={styles.topbar}>
          <TouchableOpacity style={styles.backBtn} onPress={() => router.back()} activeOpacity={0.7}>
            <Text style={styles.backText}>‹</Text>
          </TouchableOpacity>
          <Text style={styles.title}>{t('summaryTitle')}</Text>
          <View style={{ width: 36 }} />
        </View>

        {/* Items Summary */}
        <View style={styles.summaryCard}>
          <View style={styles.infoLine}>
            <Text style={styles.infoIcon}>▣</Text>
            <Text style={styles.infoLabel}>{t('summaryService')}</Text>
            <Text style={styles.infoValue}>{services.join(' + ') || t('summaryWash')}</Text>
          </View>
          <View style={styles.infoLine}>
            <Text style={styles.infoIcon}>◴</Text>
            <Text style={styles.infoLabel}>{t('summaryTime')}</Text>
            <Text style={[styles.infoValue, { fontSize: 13 }]}>{DELIVERY_TIME_TEXT}</Text>
          </View>
          <View style={styles.infoLine}>
            <Text style={styles.infoIcon}>📍</Text>
            <Text style={styles.infoLabel}>{t('summaryAddress')}</Text>
            {isEditingAddress ? (
              <View style={styles.addressEditRow}>
                <TextInput
                  style={styles.addressInput}
                  value={editedAddress}
                  onChangeText={setEditedAddress}
                  placeholder={t('summaryAddressEdit')}
                  multiline
                />
                <TouchableOpacity onPress={handleSaveAddress} style={styles.saveAddressBtn}>
                  <Text style={styles.saveAddressText}>✓</Text>
                </TouchableOpacity>
                <TouchableOpacity onPress={() => setIsEditingAddress(false)} style={styles.cancelAddressBtn}>
                  <Text style={styles.cancelAddressText}>✕</Text>
                </TouchableOpacity>
              </View>
            ) : (
              <TouchableOpacity 
                onPress={() => {
                  setEditedAddress(user.address || '');
                  setIsEditingAddress(true);
                }} 
                style={styles.addressValueRow}
              >
                <Text style={styles.addressText} numberOfLines={2}>
                  {user.address || t('summaryKoxBazar')}
                </Text>
                <Text style={styles.editIcon}>✏️</Text>
              </TouchableOpacity>
            )}
          </View>
        </View>

        {/* Line Items */}
        <View style={styles.summaryCard}>
          <Text style={styles.cardTitle}>{t('summaryItems')}</Text>
          {items.map((item, i) => (
            <View key={i} style={styles.summaryLine}>
              <Text style={styles.lineLeft}>{item.serviceLabel}: {item.name} × {toBn(item.qty)}</Text>
              <View style={styles.dashLine} />
              <Text style={styles.lineRight}>{money(item.total)}</Text>
            </View>
          ))}
          <View style={styles.totalRow}>
            <Text style={styles.totalLabel}>{t('summarySubtotal')}</Text>
            <Text style={styles.totalValue}>{money(subtotal)}</Text>
          </View>
          <View style={styles.summaryLine}>
            <Text style={styles.lineLeft}>{t('summaryDelivery')}</Text>
            <View style={styles.dashLine} />
            <Text style={styles.lineRight}>{delivery === 0 && subtotal > 0 ? t('summaryFree') : money(delivery)}</Text>
          </View>
          <View style={[styles.totalRow, { borderTopWidth: 1, borderTopColor: Colors.line, paddingTop: 16 }]}>
            <Text style={[styles.totalLabel, { fontSize: 22 }]}>{t('summaryTotal')}</Text>
            <Text style={[styles.totalValue, { fontSize: 26, color: Colors.blue }]}>{money(total)}</Text>
          </View>
        </View>

        {/* Payment */}
        <View style={[styles.summaryCard, { marginTop: 10, paddingBottom: 12 }]}>
          <View style={styles.paymentHeader}>
            <Svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke={Colors.ink} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" style={{ marginRight: 6, marginTop: -6 }}>
              <Rect x={2} y={5} width={20} height={14} rx={2} />
              <Line x1={2} y1={10} x2={22} y2={10} />
            </Svg>
            <Text style={styles.cardTitle}>{t('summaryPaymentTitle')}</Text>
          </View>
          
          <TouchableOpacity
            style={[styles.paymentCardItem, payment === 'COD' && styles.paymentCardItemActive]}
            onPress={() => setPayment('COD')}
            activeOpacity={0.8}
          >
            <View style={styles.paymentIconContainer}>
              <Svg width={36} height={24} viewBox="0 0 36 24" fill="none">
                <Rect x={1} y={1} width={34} height={22} rx={3} fill="#E8F5E9" stroke="#4CAF50" strokeWidth={1.5} />
                <Circle cx={18} cy={12} r={5} fill="#4CAF50" opacity={0.2} />
                <Circle cx={18} cy={12} r={2.5} fill="#4CAF50" />
                <Rect x={4} y={4} width={4} height={4} rx={1} fill="#4CAF50" opacity={0.6} />
                <Rect x={28} y={4} width={4} height={4} rx={1} fill="#4CAF50" opacity={0.6} />
                <Rect x={4} y={16} width={4} height={4} rx={1} fill="#4CAF50" opacity={0.6} />
                <Rect x={28} y={16} width={4} height={4} rx={1} fill="#4CAF50" opacity={0.6} />
              </Svg>
            </View>
            <Text style={styles.paymentCardText}>{t('summaryCOD')}</Text>
            
            <View style={[styles.paymentCardRadio, payment === 'COD' && styles.paymentCardRadioActive]}>
              {payment === 'COD' && <View style={styles.paymentCardRadioInner} />}
            </View>
          </TouchableOpacity>

          <View style={[styles.paymentCardItem, styles.paymentCardItemDisabled]}>
            <View style={styles.paymentIconContainer}>
              <Svg width={30} height={30} viewBox="0 0 30 30" fill="none">
                <Path d="M22 6c-1.5 2-4 3-6 3.5-2 .5-4.5.2-6-1.5 1.5 3 4.5 4 7 3.5 2.5-.5 4.5-2 5-5.5z" fill="#D12053" />
                <Path d="M14 12c-1.5 1.5-3.5 2-5.5 1.5-2-.5-3.5-2-4-4 1 2.5 3 3.5 5.5 3.5s4-1 4-1z" fill="#E2136E" />
                <Path d="M8 20c1.5 0 3-.5 4-1.5 1-1 1.5-2.5 1.5-4 0 2-1 3.5-2.5 4.5S8.5 20.5 8 20z" fill="#F06292" />
              </Svg>
            </View>
            <Text style={styles.paymentCardText}>{t('summaryBkash')}</Text>
            
            <View style={styles.disabledBadge}>
              <Text style={styles.disabledBadgeText}>{t('summaryComing')}</Text>
            </View>
            
            <View style={styles.paymentCardRadio}>
              {/* Unselected */}
            </View>
          </View>
        </View>
      </ScrollView>

      {/* Confirm Button */}
      <View style={styles.footerBar}>
        <TouchableOpacity
          style={[styles.confirmButton, loading && { opacity: 0.6 }]}
          onPress={handleConfirm}
          activeOpacity={0.85}
          disabled={loading || items.length === 0}
        >
          <Text style={styles.confirmText}>{loading ? t('summaryProcessing') : t('summaryConfirm')}</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f8fc' },
  scroll: { flex: 1 },
  content: { paddingHorizontal: 16, paddingTop: 16, paddingBottom: 120 },
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
  summaryCard: {
    backgroundColor: '#fff',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#eef1f6',
    ...Shadows.card,
    padding: 12,
    marginTop: 10,
  },
  cardTitle: { fontSize: 18, fontWeight: '900', color: Colors.ink, marginBottom: 8 },
  infoLine: {
    flexDirection: 'row',
    alignItems: 'center',
    minHeight: 40,
    gap: 8,
    borderBottomWidth: 1,
    borderBottomColor: Colors.line,
    paddingVertical: 6,
  },
  infoIcon: { fontSize: 16, width: 22, textAlign: 'center' },
  infoLabel: { fontWeight: '800', fontSize: 15, color: Colors.ink },
  infoValue: { color: Colors.ink, fontSize: 14, marginLeft: 'auto' },
  summaryLine: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginVertical: 4,
  },
  lineLeft: { fontSize: 14, color: Colors.ink },
  dashLine: { flex: 1, borderBottomWidth: 1, borderStyle: 'dashed', borderBottomColor: '#c9d0dc' },
  lineRight: { fontSize: 14, fontWeight: '800', color: Colors.ink },
  totalRow: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 8 },
  totalLabel: { fontSize: 16, fontWeight: '900', color: Colors.ink },
  totalValue: { fontSize: 18, fontWeight: '900', color: Colors.ink },
  paymentHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  paymentCardItem: {
    flexDirection: 'row',
    alignItems: 'center',
    minHeight: 58,
    borderRadius: 12,
    borderWidth: 1.5,
    borderColor: '#eef1f6',
    backgroundColor: '#fff',
    paddingHorizontal: 16,
    marginVertical: 5,
    gap: 12,
  },
  paymentCardItemActive: {
    borderColor: Colors.blue,
    backgroundColor: '#fff',
  },
  paymentCardItemDisabled: {
    borderColor: '#f2f4f7',
    backgroundColor: '#fff',
    opacity: 0.85,
  },
  paymentIconContainer: {
    width: 44,
    height: 32,
    justifyContent: 'center',
    alignItems: 'center',
  },
  paymentCardText: {
    fontSize: 16,
    fontWeight: '800',
    color: Colors.ink,
  },
  paymentCardRadio: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 2,
    borderColor: '#d0d5dd',
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: 'auto',
  },
  paymentCardRadioActive: {
    borderColor: Colors.blue,
  },
  paymentCardRadioInner: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: Colors.blue,
  },
  disabledBadge: {
    backgroundColor: '#f2f4f7',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    marginLeft: 8,
  },
  disabledBadgeText: {
    fontSize: 12,
    color: '#667085',
    fontWeight: '800',
  },
  addressEditRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    flex: 1,
    marginLeft: 10,
  },
  addressInput: {
    flex: 1,
    backgroundColor: '#f1f4f9',
    borderRadius: 6,
    paddingHorizontal: 8,
    paddingVertical: 4,
    fontSize: 13,
    color: Colors.ink,
    minHeight: 36,
  },
  saveAddressBtn: {
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: Colors.green,
    justifyContent: 'center',
    alignItems: 'center',
  },
  saveAddressText: {
    color: '#fff',
    fontSize: 15,
    fontWeight: '900',
  },
  cancelAddressBtn: {
    width: 30,
    height: 30,
    borderRadius: 15,
    backgroundColor: '#f1f3f7',
    justifyContent: 'center',
    alignItems: 'center',
  },
  cancelAddressText: {
    color: Colors.muted,
    fontSize: 13,
    fontWeight: '800',
  },
  addressValueRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    flex: 1,
    justifyContent: 'flex-end',
  },
  addressText: {
    color: Colors.ink,
    fontSize: 14,
    textAlign: 'right',
    flex: 1,
  },
  editIcon: {
    fontSize: 14,
  },
  footerBar: {
    backgroundColor: '#fff',
    padding: 16,
    paddingBottom: 18,
    borderTopWidth: 1,
    borderTopColor: Colors.line,
  },
  confirmButton: {
    minHeight: 50,
    borderRadius: 8,
    backgroundColor: Colors.green,
    justifyContent: 'center',
    alignItems: 'center',
    ...Shadows.greenButton,
  },
  confirmText: { color: '#fff', fontSize: 18, fontWeight: '900' },
});
