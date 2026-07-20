import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, TextInput, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { Colors, Shadows, toBn, money, ridersData, priceMap } from '../constants/theme';
import { getCustomers, createOrder, saveCustomer } from '../services/api';
import { useLanguage } from '../services/language';
import { useStore } from '../services/store';

export default function AdminCustomersScreen() {
  const router = useRouter();
  const { lang, t } = useLanguage();
  const { priceMap: livePriceMap, priceList } = useStore();

  const [customers, setCustomers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Order creation states
  const [selectedCustForOrder, setSelectedCustForOrder] = useState<any | null>(null);
  const [adminOrderCart, setAdminOrderCart] = useState<Record<string, number>>({});
  const [adminOrderService, setAdminOrderService] = useState<'wash' | 'dry'>('wash');
  const [adminOrderRider, setAdminOrderRider] = useState('rider_karim');

  const loadData = async () => {
    try {
      const custs = await getCustomers();
      setCustomers(custs);
    } catch (e) {
      console.warn('Failed to load customers');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const computeAdminSubtotal = () => {
    let sub = 0;
    Object.entries(adminOrderCart).forEach(([name, qty]) => {
      const prices = priceMap[name] || {};
      const rate = adminOrderService === 'wash' ? (prices.wash || 0) : (prices.dry || 0);
      sub += qty * rate;
    });
    return sub;
  };

  const getAdminOrderItems = () => {
    const itemsList: any[] = [];
    Object.entries(adminOrderCart).forEach(([name, qty]) => {
      if (qty > 0) {
        const prices = priceMap[name] || {};
        const price = adminOrderService === 'wash' ? (prices.wash || 0) : (prices.dry || 0);
        itemsList.push({
          name,
          service: adminOrderService,
          serviceLabel: adminOrderService === 'wash' ? 'ওয়াশ' : 'ড্রাই ক্লিন',
          qty,
          price,
          total: qty * price,
        });
      }
    });
    return itemsList;
  };

  const handleAdminSubmitOrder = async () => {
    if (!selectedCustForOrder) return;
    const items = getAdminOrderItems();
    if (items.length === 0) {
      alert(lang === 'bn' ? 'দয়া করে কমপক্ষে ১টি আইটেম সিলেক্ট করুন' : 'Please select at least 1 item');
      return;
    }
    const subtotal = computeAdminSubtotal();
    const delivery = subtotal >= 300 ? 0 : 30;
    const total = subtotal + delivery;

    const payload = {
      customerName: selectedCustForOrder.name || 'গ্রাহক',
      phone: selectedCustForOrder.phone,
      address: selectedCustForOrder.address || 'কক্সবাজার',
      service: adminOrderService === 'wash' ? 'ওয়াশ' : 'ড্রাই ক্লিন',
      items,
      subtotal,
      delivery,
      discount: 0,
      total,
      deliveryTime: 'Pickup After 3-7 Day Complete',
      status: 'অর্ডার কনফার্মড',
      riderId: adminOrderRider,
      payment: 'COD',
    };

    try {
      await createOrder(payload);
      setSelectedCustForOrder(null);
      setAdminOrderCart({});
      loadData();
      alert(lang === 'bn' ? 'অর্ডার সফলভাবে তৈরি হয়েছে!' : 'Order created successfully!');
    } catch (e) {
      alert('Failed to create order');
    }
  };

  // Customer Account Creation States
  const [showAddCustModal, setShowAddCustModal] = useState(false);
  const [custName, setCustName] = useState('');
  const [custPhone, setCustPhone] = useState('');
  const [custArea, setCustArea] = useState('');
  const [custAddress, setCustAddress] = useState('');
  const [custSubmitting, setCustSubmitting] = useState(false);
  const [custError, setCustError] = useState('');

  const handleAddCustomer = async () => {
    if (!custName.trim() || !custPhone.trim()) {
      setCustError(lang === 'bn' ? 'নাম এবং মোবাইল নম্বর আবশ্যক' : 'Name and phone are required');
      return;
    }
    setCustError('');
    setCustSubmitting(true);
    try {
      const payload = {
        name: custName.trim(),
        phone: custPhone.trim(),
        area: custArea.trim(),
        address: custAddress.trim()
      };
      await saveCustomer(payload);
      setCustName('');
      setCustPhone('');
      setCustArea('');
      setCustAddress('');
      setShowAddCustModal(false);
      
      setLoading(true);
      await loadData();
      alert(lang === 'bn' ? 'কাস্টমার অ্যাকাউন্ট সফলভাবে খোলা হয়েছে!' : 'Customer account created successfully!');
    } catch (e) {
      setCustError(lang === 'bn' ? 'গ্রাহক যোগ করতে ব্যর্থ হয়েছে' : 'Failed to save customer account');
    } finally {
      setCustSubmitting(false);
    }
  };

  return (
    <View style={styles.root}>
      <ScrollView style={styles.container} contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        {/* Header */}
        <View style={styles.topbar}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backBtn} activeOpacity={0.7}>
            <Text style={styles.backText}>‹</Text>
          </TouchableOpacity>
          <Text style={styles.title}>{lang === 'bn' ? 'কাস্টমারস তালিকা' : 'Customers Directory'}</Text>
          <View style={{ flexDirection: 'row', gap: 8 }}>
            <TouchableOpacity onPress={() => { loadData(); }} style={styles.refreshBtn} activeOpacity={0.75}>
              <Text style={styles.refreshIcon}>↻</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={() => setShowAddCustModal(true)} style={styles.addBtn} activeOpacity={0.75}>
              <Text style={styles.addBtnText}>+ {lang === 'bn' ? 'নতুন' : 'Add'}</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Total count */}
        {customers.length > 0 && (
          <View style={styles.totalBadge}>
            <Text style={styles.totalBadgeText}>
              {lang === 'bn'
                ? `মোট ${toBn(customers.length)} জন গ্রাহক নিবন্ধিত`
                : `${customers.length} registered customers`}
            </Text>
          </View>
        )}

        {/* Customer List */}
        <View style={{ gap: 10 }}>
          {customers.length === 0 ? (
            <View style={styles.emptyCard}>
              <Text style={styles.emptyIcon}>👥</Text>
              <Text style={styles.emptyText}>{lang === 'bn' ? 'কোনো কাস্টমার পাওয়া যায়নি।' : 'No customers found.'}</Text>
            </View>
          ) : (
            customers.map((c, i) => (
              <TouchableOpacity
                key={i}
                style={styles.customerRowCard}
                activeOpacity={0.82}
                onPress={() =>
                  router.push({
                    pathname: '/admin-customer-profile',
                    params: {
                      phone: c.phone,
                      name: c.name || 'গ্রাহক',
                      address: c.address || '',
                      orders: String(c.orders || 0),
                    },
                  })
                }
              >
                {/* Serial number circle */}
                <View style={styles.serialCircle}>
                  <Text style={styles.serialText}>{toBn(i + 1)}</Text>
                </View>

                {/* Info */}
                <View style={{ flex: 1, marginLeft: 12 }}>
                  <Text style={styles.customerNameText}>{c.name || 'গ্রাহক'}</Text>
                  <Text style={styles.customerDetailText}>📞 {c.phone}</Text>
                  {c.address ? (
                    <Text style={styles.customerDetailText} numberOfLines={1}>📍 {c.address}</Text>
                  ) : null}
                </View>

                {/* Order count badge + quick order btn */}
                <View style={styles.orderBadgeCol}>
                  <View style={styles.orderCountBadge}>
                    <Text style={styles.orderCountNum}>{toBn(c.orders || 0)}</Text>
                    <Text style={styles.orderCountLabel}>{lang === 'bn' ? 'অর্ডার' : 'Orders'}</Text>
                  </View>
                  <TouchableOpacity
                    style={styles.quickOrderBtn}
                    activeOpacity={0.7}
                    onPress={(e: any) => {
                      e.stopPropagation();
                      setSelectedCustForOrder(c);
                      setAdminOrderCart({});
                    }}
                  >
                    <Text style={styles.quickOrderBtnText}>+ {lang === 'bn' ? 'অর্ডার' : 'Order'}</Text>
                  </TouchableOpacity>
                </View>

                <Text style={styles.arrowText}>›</Text>
              </TouchableOpacity>
            ))
          )}
        </View>
      </ScrollView>

      {/* Admin New Order Form Overlay */}
      {selectedCustForOrder && (() => {
        const subtotal = computeAdminSubtotal();
        const delivery = subtotal >= 300 ? 0 : 30;
        const total = subtotal + delivery;

        return (
          <View style={styles.overlay}>
            <View style={[styles.dialog, { maxHeight: '90%' }]}>
              <View style={styles.dialogHeader}>
                <Text style={styles.dialogTitle}>
                  {lang === 'bn' ? 'নতুন অর্ডার তৈরি' : 'Create New Order'}
                </Text>
                <TouchableOpacity onPress={() => setSelectedCustForOrder(null)}>
                  <Text style={styles.dialogClose}>✕</Text>
                </TouchableOpacity>
              </View>

              <Text style={styles.dialogSubtitle}>
                {lang === 'bn'
                  ? `কাস্টমার: ${selectedCustForOrder.name || 'গ্রাহক'} (${selectedCustForOrder.phone})`
                  : `Customer: ${selectedCustForOrder.name || 'Customer'} (${selectedCustForOrder.phone})`}
              </Text>

              {/* Service Tabs */}
              <View style={styles.adminServiceSelector}>
                <TouchableOpacity
                  style={[styles.serviceTab, adminOrderService === 'wash' && styles.serviceTabActive]}
                  onPress={() => setAdminOrderService('wash')}
                >
                  <Text style={[styles.serviceTabText, adminOrderService === 'wash' && styles.serviceTabActiveText]}>
                    {lang === 'bn' ? 'ওয়াশ' : 'Wash'}
                  </Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.serviceTab, adminOrderService === 'dry' && styles.serviceTabActive]}
                  onPress={() => setAdminOrderService('dry')}
                >
                  <Text style={[styles.serviceTabText, adminOrderService === 'dry' && styles.serviceTabActiveText]}>
                    {lang === 'bn' ? 'ড্রাই ক্লিন' : 'Dry Clean'}
                  </Text>
                </TouchableOpacity>
              </View>

              {/* Items List */}
              <Text style={styles.adminSectionTitle}>{lang === 'bn' ? 'আইটেম এবং পরিমাণ' : 'Items & Quantities'}</Text>
              <ScrollView style={{ maxHeight: 220 }} showsVerticalScrollIndicator={false}>
                {Object.entries(priceMap).map(([itemName, prices]) => {
                  const qty = adminOrderCart[itemName] || 0;
                  const rate = adminOrderService === 'wash' ? (prices.wash || 0) : (prices.dry || 0);
                  if (rate === 0) return null;

                  return (
                    <View key={itemName} style={styles.adminCartRow}>
                      <Text style={styles.adminCartRowName}>{itemName}</Text>
                      <Text style={styles.adminCartRowPrice}>{money(rate)}</Text>
                      <View style={styles.adminCartRowCounter}>
                        <TouchableOpacity
                          style={styles.adminCartRowCounterBtn}
                          onPress={() => {
                            setAdminOrderCart(prev => ({
                              ...prev,
                              [itemName]: Math.max((prev[itemName] || 0) - 1, 0)
                            }));
                          }}
                        >
                          <Text style={styles.counterText}>−</Text>
                        </TouchableOpacity>
                        <Text style={styles.counterQty}>{toBn(qty)}</Text>
                        <TouchableOpacity
                          style={styles.adminCartRowCounterBtn}
                          onPress={() => {
                            setAdminOrderCart(prev => ({
                              ...prev,
                              [itemName]: (prev[itemName] || 0) + 1
                            }));
                          }}
                        >
                          <Text style={styles.counterText}>+</Text>
                        </TouchableOpacity>
                      </View>
                    </View>
                  );
                })}
              </ScrollView>

              {/* Rider Selection */}
              <Text style={styles.adminSectionTitle}>{lang === 'bn' ? 'রাইডার সিলেক্ট করুন' : 'Assign Logistics Rider'}</Text>
              <View style={styles.adminRiderSelector}>
                {Object.keys(ridersData).map((rKey) => {
                  const r = ridersData[rKey];
                  return (
                    <TouchableOpacity
                      key={rKey}
                      style={[styles.riderChip, adminOrderRider === rKey && styles.riderChipActive]}
                      onPress={() => setAdminOrderRider(rKey)}
                    >
                      <Text style={[styles.riderChipText, adminOrderRider === rKey && styles.riderChipActiveText]}>
                        {r.name}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </View>

              {/* Pricing Box */}
              <View style={styles.adminSummaryBox}>
                <View style={styles.adminSummaryRow}>
                  <Text style={styles.adminSummaryLabel}>{lang === 'bn' ? 'সাবটোটাল:' : 'Subtotal:'}</Text>
                  <Text style={styles.adminSummaryVal}>{money(subtotal)}</Text>
                </View>
                <View style={styles.adminSummaryRow}>
                  <Text style={styles.adminSummaryLabel}>{lang === 'bn' ? 'ডেলিভারি চার্জ:' : 'Delivery:'}</Text>
                  <Text style={styles.adminSummaryVal}>{delivery === 0 ? (lang === 'bn' ? 'ফ্রি' : 'Free') : money(delivery)}</Text>
                </View>
                <View style={[styles.adminSummaryRow, { borderTopWidth: 1, borderTopColor: '#e2e8f0', paddingTop: 8, marginTop: 8 }]}>
                  <Text style={[styles.adminSummaryLabel, { fontWeight: '900', fontSize: 16 }]}>{lang === 'bn' ? 'সর্বমোট:' : 'Total:'}</Text>
                  <Text style={[styles.adminSummaryVal, { fontWeight: '900', color: Colors.blue, fontSize: 18 }]}>{money(total)}</Text>
                </View>
              </View>

              {/* Form Actions */}
              <View style={styles.adminFormActions}>
                <TouchableOpacity
                  style={styles.adminFormCancel}
                  onPress={() => setSelectedCustForOrder(null)}
                >
                  <Text style={styles.adminFormCancelText}>{lang === 'bn' ? 'ফিরে যান' : 'Go Back'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.adminFormSubmit}
                  onPress={handleAdminSubmitOrder}
                >
                  <Text style={styles.adminFormSubmitText}>{lang === 'bn' ? 'অর্ডার প্লেস করুন' : 'Place Order'}</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        );
      })()}

      {/* Create Customer Account — in-frame overlay */}
      {showAddCustModal && (
        <View style={styles.overlay}>
          <TouchableOpacity style={styles.overlayBackdrop} activeOpacity={1} onPress={() => setShowAddCustModal(false)} />
          <View style={styles.sheet}>
            <View style={styles.sheetHandle} />
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>{lang === 'bn' ? 'নতুন কাস্টমার অ্যাকাউন্ট' : 'Create Customer Account'}</Text>
              <TouchableOpacity onPress={() => setShowAddCustModal(false)} style={styles.closeBtn}>
                <Text style={styles.closeBtnText}>✕</Text>
              </TouchableOpacity>
            </View>

            {custError ? (
              <View style={styles.errorBanner}>
                <Text style={styles.errorText}>⚠️ {custError}</Text>
              </View>
            ) : null}

            <ScrollView showsVerticalScrollIndicator={false} keyboardShouldPersistTaps="handled">
              <Text style={styles.inputLabel}>{lang === 'bn' ? 'কাস্টমারের নাম' : 'Customer Name'}</Text>
              <TextInput
                style={styles.modalInput}
                value={custName}
                onChangeText={setCustName}
                placeholder={lang === 'bn' ? 'যেমন: রহিম উদ্দিন' : 'e.g. Rahim Uddin'}
                placeholderTextColor="#94a3b8"
              />

              <Text style={styles.inputLabel}>{lang === 'bn' ? 'মোবাইল নম্বর' : 'Phone Number'}</Text>
              <TextInput
                style={styles.modalInput}
                value={custPhone}
                onChangeText={setCustPhone}
                placeholder={lang === 'bn' ? 'যেমন: ০১৭XXXXXXXX' : 'e.g. 017XXXXXXXX'}
                placeholderTextColor="#94a3b8"
                keyboardType="phone-pad"
              />

              <Text style={styles.inputLabel}>{lang === 'bn' ? 'এলাকা' : 'Area'}</Text>
              <TextInput
                style={styles.modalInput}
                value={custArea}
                onChangeText={setCustArea}
                placeholder={lang === 'bn' ? 'যেমন: কলাতলী' : 'e.g. Kolatoli'}
                placeholderTextColor="#94a3b8"
              />

              <Text style={styles.inputLabel}>{lang === 'bn' ? 'পূর্ণ ঠিকানা' : 'Full Address'}</Text>
              <TextInput
                style={styles.modalInput}
                value={custAddress}
                onChangeText={setCustAddress}
                placeholder={lang === 'bn' ? 'যেমন: বাসা ১২, রোড ৩, কলাতলী' : 'e.g. House 12, Road 3, Kolatoli'}
                placeholderTextColor="#94a3b8"
              />
            </ScrollView>

            <TouchableOpacity
              style={styles.submitBtn}
              onPress={handleAddCustomer}
              disabled={custSubmitting}
              activeOpacity={0.8}
            >
              {custSubmitting ? (
                <ActivityIndicator color="#fff" />
              ) : (
                <Text style={styles.submitBtnText}>{lang === 'bn' ? 'অ্যাকাউন্ট তৈরি করুন' : 'Create Account'}</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>
      )}
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
  emptyText: { textAlign: 'center', color: Colors.muted, paddingVertical: 16, fontSize: 15, fontWeight: '700' },

  // Total badge
  totalBadge: {
    backgroundColor: '#eef5ff',
    borderRadius: 10,
    paddingVertical: 10,
    paddingHorizontal: 14,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#cce1ff',
  },
  totalBadgeText: { fontSize: 13, fontWeight: '800', color: Colors.blue },

  // Empty card
  emptyCard: {
    paddingVertical: 50,
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#e2e8f0',
  },
  emptyIcon: { fontSize: 48, marginBottom: 8 },

  customerRowCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 14,
    backgroundColor: '#fff',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#eef1f6',
    gap: 0,
    ...Shadows.card as any,
  },

  // Serial number
  serialCircle: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: Colors.blue,
    justifyContent: 'center',
    alignItems: 'center',
    flexShrink: 0,
  },
  serialText: { fontSize: 14, fontWeight: '900', color: '#fff' },

  customerNameText: { fontSize: 15, fontWeight: '900', color: Colors.ink },
  customerDetailText: { fontSize: 12, color: Colors.muted, marginTop: 3, fontWeight: '700' },

  // Order count + quick btn
  orderBadgeCol: { alignItems: 'center', gap: 6, marginLeft: 8 },
  orderCountBadge: {
    backgroundColor: '#eef5ff',
    borderRadius: 10,
    paddingHorizontal: 8,
    paddingVertical: 4,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#cce1ff',
    minWidth: 52,
  },
  orderCountNum: { fontSize: 16, fontWeight: '900', color: Colors.blue },
  orderCountLabel: { fontSize: 9, color: Colors.blue, fontWeight: '700' },

  quickOrderBtn: {
    backgroundColor: Colors.green,
    borderRadius: 8,
    paddingHorizontal: 8,
    paddingVertical: 5,
    alignItems: 'center',
  },
  quickOrderBtnText: { fontSize: 11, fontWeight: '900', color: '#fff' },

  arrowText: { fontSize: 22, color: Colors.muted, marginLeft: 6, fontWeight: '900' },
  adminOrderCreateBtn: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    backgroundColor: Colors.blue,
    justifyContent: 'center',
    alignItems: 'center',
  },
  adminOrderCreateBtnText: {
    color: '#fff',
    fontSize: 13,
    fontWeight: '900',
  },

  // Modal styling
  overlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(9, 22, 50, 0.46)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
    zIndex: 999,
  },
  dialog: {
    width: '100%',
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 16,
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
  adminSectionTitle: {
    fontSize: 14,
    fontWeight: '900',
    color: '#091632',
    marginTop: 10,
    marginBottom: 6,
  },
  adminCartRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#edf2f7',
  },
  adminCartRowName: {
    flex: 1.2,
    fontSize: 15,
    fontWeight: '800',
    color: '#091632',
  },
  adminCartRowPrice: {
    flex: 0.6,
    fontSize: 14,
    fontWeight: '700',
    color: '#64748b',
    textAlign: 'right',
    paddingRight: 10,
  },
  adminCartRowCounter: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  adminCartRowCounterBtn: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: '#edf2f7',
    justifyContent: 'center',
    alignItems: 'center',
  },
  counterText: {
    fontSize: 16,
    fontWeight: '800',
    color: '#4a5568',
  },
  counterQty: {
    fontSize: 16,
    fontWeight: '900',
    color: '#091632',
    minWidth: 20,
    textAlign: 'center',
  },
  adminServiceSelector: {
    flexDirection: 'row',
    gap: 10,
    marginVertical: 12,
  },
  serviceTab: {
    flex: 1,
    height: 38,
    borderRadius: 8,
    backgroundColor: '#edf2f7',
    justifyContent: 'center',
    alignItems: 'center',
  },
  serviceTabActive: {
    backgroundColor: Colors.blue,
  },
  serviceTabText: {
    fontSize: 14,
    fontWeight: '800',
    color: '#4a5568',
  },
  serviceTabActiveText: {
    color: '#fff',
  },
  adminRiderSelector: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 12,
  },
  riderChip: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 15,
    backgroundColor: '#edf2f7',
  },
  riderChipActive: {
    backgroundColor: '#edf5ff',
    borderWidth: 1,
    borderColor: '#cce1ff',
  },
  riderChipText: {
    fontSize: 12,
    fontWeight: '800',
    color: '#4a5568',
  },
  riderChipActiveText: {
    color: Colors.blue,
  },
  adminSummaryBox: {
    backgroundColor: '#f8fafc',
    borderRadius: 10,
    padding: 12,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    marginVertical: 10,
  },
  adminSummaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginVertical: 2,
  },
  adminSummaryLabel: {
    fontSize: 13,
    color: '#64748b',
    fontWeight: '700',
  },
  adminSummaryVal: {
    fontSize: 13,
    color: '#091632',
    fontWeight: '800',
  },
  adminFormActions: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 10,
  },
  adminFormCancel: {
    flex: 1,
    height: 44,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#cbd5e1',
    justifyContent: 'center',
    alignItems: 'center',
  },
  adminFormCancelText: {
    fontSize: 15,
    fontWeight: '800',
    color: '#475569',
  },
  adminFormSubmit: {
    flex: 1.5,
    height: 44,
    borderRadius: 8,
    backgroundColor: Colors.green,
    justifyContent: 'center',
    alignItems: 'center',
  },
  adminFormSubmitText: {
    fontSize: 15,
    fontWeight: '900',
    color: '#fff',
  },
  addBtn: {
    backgroundColor: Colors.blue,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  addBtnText: { color: '#fff', fontSize: 13, fontWeight: '900' },
  refreshBtn: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: '#eef5ff',
    borderWidth: 1,
    borderColor: '#cce1ff',
    justifyContent: 'center',
    alignItems: 'center',
  },
  refreshIcon: { fontSize: 17, color: Colors.blue, fontWeight: '900' },

  // In-frame overlay styles (replaces Modal)
  overlay: {
    position: 'absolute',
    top: 0, left: 0, right: 0, bottom: 0,
    zIndex: 999,
  },
  overlayBackdrop: {
    position: 'absolute',
    top: 0, left: 0, right: 0, bottom: 0,
    backgroundColor: 'rgba(9, 22, 50, 0.55)',
  },
  sheet: {
    position: 'absolute',
    left: 0, right: 0, bottom: 0,
    backgroundColor: '#fff',
    borderTopLeftRadius: 22,
    borderTopRightRadius: 22,
    paddingHorizontal: 20,
    paddingTop: 8,
    paddingBottom: 24,
    maxHeight: '85%',
  },
  sheetHandle: {
    width: 38,
    height: 4,
    borderRadius: 2,
    backgroundColor: '#dde2ea',
    alignSelf: 'center',
    marginBottom: 14,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 14,
  },
  modalTitle: {
    fontSize: 16,
    fontWeight: '900',
    color: Colors.ink,
  },
  closeBtn: {
    width: 26,
    height: 26,
    borderRadius: 13,
    backgroundColor: '#f1f5f9',
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeBtnText: {
    fontSize: 11,
    fontWeight: '900',
    color: '#64748b',
  },
  errorBanner: {
    backgroundColor: '#fef2f2',
    borderWidth: 1,
    borderColor: '#fee2e2',
    padding: 8,
    borderRadius: 8,
    marginBottom: 10,
  },
  errorText: {
    color: '#dc2626',
    fontSize: 12,
    fontWeight: '600',
    textAlign: 'center',
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: '800',
    color: '#475569',
    marginBottom: 4,
    marginTop: 8,
  },
  modalInput: {
    borderWidth: 1,
    borderColor: '#cbd5e1',
    borderRadius: 8,
    paddingHorizontal: 12,
    height: 42,
    fontSize: 14,
    fontWeight: '700',
    color: Colors.ink,
    backgroundColor: '#f8fafc',
    marginBottom: 2,
  },
  submitBtn: {
    backgroundColor: Colors.blue,
    borderRadius: 10,
    height: 46,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 14,
  },
  submitBtnText: {
    color: '#fff',
    fontSize: 15,
    fontWeight: '900',
  },
});
