import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, ActivityIndicator, TextInput } from 'react-native';
import { useRouter } from 'expo-router';
import { Colors, Shadows, toBn } from '../constants/theme';
import { getOrders, getRiders, createRider } from '../services/api';
import { useLanguage } from '../services/language';

const GRAD_COLORS = ['#2563eb', '#0d9488', '#7c3aed', '#b45309'];

export default function AdminRidersScreen() {
  const router = useRouter();
  const { lang } = useLanguage();
  const [riders, setRiders] = useState<any[]>([]);
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Modal States
  const [showAddModal, setShowAddModal] = useState(false);
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const loadData = async () => {
    try {
      const [ords, rds] = await Promise.all([getOrders(), getRiders()]);
      setOrders(ords);
      setRiders(rds);
    } catch (e) {
      console.warn('Failed to load dynamic data for riders dashboard');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleAddRider = async () => {
    if (!name.trim() || !phone.trim() || !username.trim() || !password.trim()) {
      setErrorMsg(lang === 'bn' ? 'সবগুলো তথ্য পূরণ করুন' : 'Please fill in all fields');
      return;
    }
    setErrorMsg('');
    setSubmitting(true);
    try {
      const payload = {
        name: name.trim(),
        phone: phone.trim(),
        username: username.trim().toLowerCase(),
        password: password.trim()
      };
      await createRider(payload);
      
      // Clear inputs
      setName('');
      setPhone('');
      setUsername('');
      setPassword('');
      setShowAddModal(false);
      
      // Reload list
      setLoading(true);
      await loadData();
    } catch (e: any) {
      setErrorMsg(lang === 'bn' ? 'ইউজারনেম বা ফোন ইতিমধ্যেই ব্যবহৃত হচ্ছে' : 'Username or phone is already taken');
    } finally {
      setSubmitting(false);
    }
  };

  const TODAY = new Date().toDateString();

  return (
    <View style={styles.root}>
      <ScrollView style={styles.container} contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>

        {/* Header */}
        <View style={styles.topbar}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backBtn} activeOpacity={0.7}>
            <Text style={styles.backText}>‹</Text>
          </TouchableOpacity>
          <Text style={styles.title}>{lang === 'bn' ? 'রাইডারদের তালিকা' : 'Delivery Riders'}</Text>
          <View style={{ flexDirection: 'row', gap: 8 }}>
            <TouchableOpacity onPress={() => { setLoading(true); loadData(); }} style={styles.refreshBtn} activeOpacity={0.75}>
              <Text style={styles.refreshIcon}>↻</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={() => setShowAddModal(true)} style={styles.addBtn} activeOpacity={0.75}>
              <Text style={styles.addBtnText}>+ {lang === 'bn' ? 'নতুন' : 'Add'}</Text>
            </TouchableOpacity>
          </View>
        </View>

        {loading ? (
          <ActivityIndicator style={{ marginTop: 40 }} size="large" color={Colors.blue} />
        ) : (
          <View style={{ gap: 12 }}>
            {riders.map((r, index) => {
              const key = r.id;

              // Active (pending) task count
              const activeTasks = orders.filter(
                o => o.riderId === key &&
                  !o.status.includes('সম্পন্ন') &&
                  !o.status.toLowerCase().includes('delivered') &&
                  !o.status.includes('বাতিল') &&
                  !o.status.toLowerCase().includes('cancelled')
              );

              // Completed all-time
              const completedAll = orders.filter(
                o => o.riderId === key &&
                  (o.status.includes('সম্পন্ন') || o.status.toLowerCase().includes('delivered'))
              );

              // Today completed
              const completedToday = completedAll.filter(o =>
                new Date(o.updatedAt || o.createdAt).toDateString() === TODAY
              );

              // COD cash at rider
              const codHeld = completedAll
                .filter(o => {
                  const p = (o.payment || '').toLowerCase();
                  return !p || p === 'cod' || p.includes('cod') || p.includes('cash');
                })
                .reduce((s: number, o: any) => s + (o.total || 0), 0);

              const accentColor = GRAD_COLORS[index % GRAD_COLORS.length];
              const avatarInitial = r.avatar || (r.name ? r.name.charAt(0) : '🚴');

              return (
                <TouchableOpacity
                  key={key}
                  style={[styles.riderCard, { borderLeftColor: accentColor }]}
                  activeOpacity={0.82}
                  onPress={() =>
                    router.push({
                      pathname: '/admin-rider-profile',
                      params: {
                        riderId: key,
                        name: r.name,
                        phone: r.phone,
                        avatar: avatarInitial,
                        gradIndex: String(index),
                      },
                    })
                  }
                >
                  {/* Left: avatar + info */}
                  <View style={[styles.avatar, { backgroundColor: accentColor }]}>
                    <Text style={styles.avatarText}>{avatarInitial}</Text>
                  </View>

                  <View style={{ flex: 1, marginLeft: 12 }}>
                    <Text style={styles.riderName}>{r.name}</Text>
                    <Text style={styles.riderPhone}>📞 {r.phone}</Text>
                    <View style={styles.miniStatRow}>
                      <View style={styles.miniStat}>
                        <Text style={styles.miniStatVal}>{toBn(completedAll.length)}</Text>
                        <Text style={styles.miniStatLbl}>{lang === 'bn' ? 'সম্পন্ন' : 'Done'}</Text>
                      </View>
                      <View style={styles.miniStat}>
                        <Text style={[styles.miniStatVal, { color: '#f59e0b' }]}>{toBn(activeTasks.length)}</Text>
                        <Text style={styles.miniStatLbl}>{lang === 'bn' ? 'চলমান' : 'Active'}</Text>
                      </View>
                      <View style={styles.miniStat}>
                        <Text style={[styles.miniStatVal, { color: Colors.green, fontSize: 13 }]}>{toBn(completedToday.length)}</Text>
                        <Text style={styles.miniStatLbl}>{lang === 'bn' ? 'আজ' : 'Today'}</Text>
                      </View>
                    </View>
                  </View>

                  {/* Right: COD badge + arrow */}
                  <View style={styles.rightCol}>
                    <View style={styles.codBadge}>
                      <Text style={styles.codBadgeLabel}>💵 COD</Text>
                      <Text style={styles.codBadgeVal}>৳{toBn(Math.round(codHeld / 1000))}k</Text>
                    </View>
                    <Text style={styles.arrow}>›</Text>
                  </View>
                </TouchableOpacity>
              );
            })}
          </View>
        )}
      </ScrollView>

      {/* Add Rider Overlay — stays inside phone frame */}
      {showAddModal && (
        <View style={styles.overlay}>
          <TouchableOpacity style={styles.overlayBackdrop} activeOpacity={1} onPress={() => setShowAddModal(false)} />
          <View style={styles.sheet}>
            {/* Handle */}
            <View style={styles.sheetHandle} />
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>{lang === 'bn' ? 'নতুন রাইডার অ্যাকাউন্ট' : 'Create Rider Account'}</Text>
              <TouchableOpacity onPress={() => setShowAddModal(false)} style={styles.closeBtn}>
                <Text style={styles.closeBtnText}>✕</Text>
              </TouchableOpacity>
            </View>

            {errorMsg ? (
              <View style={styles.errorBanner}>
                <Text style={styles.errorText}>⚠️ {errorMsg}</Text>
              </View>
            ) : null}

            <ScrollView showsVerticalScrollIndicator={false} keyboardShouldPersistTaps="handled">
              <Text style={styles.inputLabel}>{lang === 'bn' ? 'রাইডারের নাম' : 'Rider Full Name'}</Text>
              <TextInput
                style={styles.modalInput}
                value={name}
                onChangeText={setName}
                placeholder={lang === 'bn' ? 'যেমন: জলিল হোসেন' : 'e.g. Jalil Hossain'}
                placeholderTextColor="#94a3b8"
              />

              <Text style={styles.inputLabel}>{lang === 'bn' ? 'মোবাইল নম্বর' : 'Phone Number'}</Text>
              <TextInput
                style={styles.modalInput}
                value={phone}
                onChangeText={setPhone}
                placeholder={lang === 'bn' ? 'যেমন: 018XXXXXXXX' : 'e.g. 018XXXXXXXX'}
                placeholderTextColor="#94a3b8"
                keyboardType="phone-pad"
              />

              <Text style={styles.inputLabel}>{lang === 'bn' ? 'ইউজারনেম (লগইন করার জন্য)' : 'Username (for Login)'}</Text>
              <TextInput
                style={styles.modalInput}
                value={username}
                onChangeText={setUsername}
                placeholder={lang === 'bn' ? 'যেমন: jalil' : 'e.g. jalil'}
                placeholderTextColor="#94a3b8"
                autoCapitalize="none"
              />

              <Text style={styles.inputLabel}>{lang === 'bn' ? 'পাসওয়ার্ড' : 'Password'}</Text>
              <TextInput
                style={styles.modalInput}
                value={password}
                onChangeText={setPassword}
                placeholder={lang === 'bn' ? 'পাসওয়ার্ড দিন' : 'Enter Password'}
                placeholderTextColor="#94a3b8"
                secureTextEntry
                autoCapitalize="none"
              />
            </ScrollView>

            <TouchableOpacity
              style={styles.submitBtn}
              onPress={handleAddRider}
              disabled={submitting}
              activeOpacity={0.8}
            >
              {submitting ? (
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
  root:      { flex: 1, backgroundColor: '#f4f7fb' },
  container: { flex: 1 },
  content:   { paddingHorizontal: 16, paddingTop: 16, paddingBottom: 40 },
  topbar:    { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', minHeight: 44, marginBottom: 20 },

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
  backText: { fontSize: 22, fontWeight: '900', color: '#334155', lineHeight: 24, textAlign: 'center' },
  title:    { fontSize: 22, fontWeight: '900', color: Colors.ink },
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

  // Rider card
  riderCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    borderLeftWidth: 5,
    padding: 14,
    ...Shadows.card as any,
  },

  // Avatar
  avatar:     { width: 48, height: 48, borderRadius: 24, justifyContent: 'center', alignItems: 'center', flexShrink: 0 },
  avatarText: { fontSize: 20, fontWeight: '900', color: '#fff' },

  riderName:  { fontSize: 15, fontWeight: '900', color: Colors.ink },
  riderPhone: { fontSize: 12, color: Colors.muted, marginTop: 2, fontWeight: '700' },

  // Mini stats
  miniStatRow: { flexDirection: 'row', gap: 10, marginTop: 8 },
  miniStat:    { alignItems: 'center' },
  miniStatVal: { fontSize: 15, fontWeight: '900', color: Colors.blue },
  miniStatLbl: { fontSize: 9, color: Colors.muted, fontWeight: '700', marginTop: 1 },

  // COD badge
  rightCol:     { alignItems: 'center', gap: 6, marginLeft: 8 },
  codBadge: {
    backgroundColor: '#fff8e1',
    borderRadius: 10,
    paddingHorizontal: 8,
    paddingVertical: 5,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#ffe082',
    minWidth: 56,
  },
  codBadgeLabel: { fontSize: 10, fontWeight: '800', color: '#b45309' },
  codBadgeVal:   { fontSize: 15, fontWeight: '900', color: '#b45309' },

  arrow: { fontSize: 22, color: Colors.muted, fontWeight: '900' },

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
