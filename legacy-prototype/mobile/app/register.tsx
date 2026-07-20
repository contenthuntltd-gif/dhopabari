import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, KeyboardAvoidingView, Platform, ScrollView, Alert, ActivityIndicator } from 'react-native';
import { useRouter } from 'expo-router';
import { Colors } from '../constants/theme';
import { useStore } from '../services/store';
import { useLanguage } from '../services/language';
import * as apiService from '../services/api';
import Logo from '../components/logo';

const normalizePhone = (str: string): string => {
  const map: Record<string, string> = {
    '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4',
    '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9'
  };
  let normalized = str.replace(/[০-৯]/g, d => map[d] || d);
  normalized = normalized.replace(/\D/g, '');
  if (normalized.startsWith('880')) normalized = normalized.substring(3);
  if (normalized.startsWith('0')) normalized = normalized.substring(1);
  return normalized;
};

export default function RegisterScreen() {
  const router = useRouter();
  const { setUser } = useStore();
  const { lang } = useLanguage();
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const handleRegister = async () => {
    const cleanPhone = normalizePhone(phone.trim());
    if (cleanPhone.length < 10) {
      Alert.alert('', lang === 'bn' ? 'সঠিক মোবাইল নম্বর দিন (১০ ডিজিট)।' : 'Please enter a valid 10-digit mobile number.');
      return;
    }
    if (password.length < 4) {
      Alert.alert('', lang === 'bn' ? 'পাসওয়ার্ড অন্তত ৪ অক্ষরের হতে হবে।' : 'Password must be at least 4 characters.');
      return;
    }
    if (password !== confirmPassword) {
      Alert.alert('', lang === 'bn' ? 'পাসওয়ার্ড মিলছে না।' : 'Passwords do not match.');
      return;
    }

    setLoading(true);
    setErrorMsg('');
    try {
      const res = await apiService.registerCustomer({ phone: cleanPhone, password: password.trim() });
      if (res.ok && res.user) {
        setUser({
          phone: res.user.phone || cleanPhone,
          name: res.user.name || '',
          area: res.user.area || '',
          address: res.user.address || '',
          avatar: '👨',
        });
        router.push('/details');
      } else {
        setErrorMsg(res.error || (lang === 'bn' ? 'একাউন্ট তৈরি করা যায়নি' : 'Could not create account'));
      }
    } catch (e) {
      setErrorMsg(lang === 'bn' ? 'সার্ভার সংযোগে ব্যর্থতা' : 'Failed to connect to server');
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView style={styles.container} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        <View style={styles.hero}>
          <TouchableOpacity onPress={() => router.back()} style={styles.backBtn} activeOpacity={0.7}>
            <Text style={styles.backText}>‹</Text>
          </TouchableOpacity>
          <Logo width={54} height={54} />
          <Text style={styles.brand}>ধোপা বাড়ি</Text>
          <Text style={styles.brandSub}>PREMIUM LAUNDRY SERVICE</Text>
        </View>

        <View style={styles.form}>
          <Text style={styles.title}>{lang === 'bn' ? 'একাউন্ট তৈরি করুন' : 'Create an account'}</Text>
          <Text style={styles.subtitle}>{lang === 'bn' ? 'নতুন একাউন্ট খুলে অর্ডার শুরু করুন' : 'Sign up to start ordering'}</Text>

          {errorMsg ? (
            <View style={styles.errorBox}>
              <Text style={styles.errorText}>⚠️ {errorMsg}</Text>
            </View>
          ) : null}

          <View style={styles.field}>
            <Text style={styles.countryCode}>+880 ⌄</Text>
            <View style={styles.divider} />
            <TextInput
              style={styles.input}
              value={phone}
              onChangeText={setPhone}
              placeholder={lang === 'bn' ? 'মোবাইল নাম্বার দিন' : 'Enter mobile number'}
              placeholderTextColor="#a2abb8"
              keyboardType="phone-pad"
            />
          </View>

          <View style={styles.field}>
            <TextInput
              style={styles.input}
              value={password}
              onChangeText={setPassword}
              placeholder={lang === 'bn' ? 'পাসওয়ার্ড দিন' : 'Create a password'}
              placeholderTextColor="#a2abb8"
              secureTextEntry
            />
          </View>

          <View style={styles.field}>
            <TextInput
              style={styles.input}
              value={confirmPassword}
              onChangeText={setConfirmPassword}
              placeholder={lang === 'bn' ? 'পাসওয়ার্ড আবার দিন' : 'Confirm password'}
              placeholderTextColor="#a2abb8"
              secureTextEntry
            />
          </View>

          <TouchableOpacity style={styles.primaryButton} onPress={handleRegister} activeOpacity={0.85} disabled={loading}>
            {loading ? <ActivityIndicator color="#fff" /> : (
              <Text style={styles.primaryText}>{lang === 'bn' ? 'একাউন্ট তৈরি করুন' : 'Create account'}  →</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity onPress={() => router.replace('/login')} style={{ marginTop: 18 }}>
            <Text style={styles.loginLinkText}>
              {lang === 'bn' ? 'ইতিমধ্যে একাউন্ট আছে? ' : 'Already have an account? '}
              <Text style={{ color: Colors.blue, fontWeight: '900' }}>{lang === 'bn' ? 'লগইন করুন' : 'Log in'}</Text>
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  scrollContent: { flexGrow: 1, paddingBottom: 30 },
  hero: {
    backgroundColor: '#EAF1FF', paddingTop: 40, paddingBottom: 22, alignItems: 'center',
    borderBottomLeftRadius: 32, borderBottomRightRadius: 32,
  },
  backBtn: {
    position: 'absolute', top: 16, left: 16, width: 36, height: 36, borderRadius: 18,
    backgroundColor: '#fff', justifyContent: 'center', alignItems: 'center',
  },
  backText: { fontSize: 22, fontWeight: '900', color: Colors.ink, lineHeight: 24, textAlign: 'center' },
  brand: { fontSize: 22, fontWeight: '900', color: Colors.blue, letterSpacing: 0.3, marginTop: 8 },
  brandSub: { fontSize: 9.5, fontWeight: '800', color: Colors.blue, letterSpacing: 2, marginTop: 2 },
  form: { paddingHorizontal: 24, paddingTop: 22, alignItems: 'center' },
  title: { fontSize: 22, fontWeight: '900', color: Colors.ink },
  subtitle: { fontSize: 13.5, color: Colors.muted, marginTop: 4, textAlign: 'center', fontWeight: '600' },
  errorBox: { width: '100%', padding: 12, backgroundColor: '#fef2f2', borderWidth: 1, borderColor: '#fee2e2', borderRadius: 8, marginTop: 16 },
  errorText: { color: '#dc2626', fontSize: 13, fontWeight: '600', textAlign: 'center' },
  field: {
    flexDirection: 'row', alignItems: 'center', borderWidth: 1.2, borderColor: '#e2e7ee',
    borderRadius: 12, minHeight: 56, paddingHorizontal: 16, gap: 10, marginTop: 16, width: '100%', backgroundColor: '#fff',
  },
  countryCode: { fontWeight: '800', fontSize: 15, color: Colors.ink },
  divider: { width: 1.2, height: 22, backgroundColor: '#dce2eb' },
  input: { flex: 1, fontSize: 15.5, color: Colors.ink, fontWeight: '700' },
  primaryButton: {
    minHeight: 52, borderRadius: 12, backgroundColor: Colors.blue, width: '100%', marginTop: 22,
    justifyContent: 'center', alignItems: 'center', shadowColor: Colors.blue, shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.2, shadowRadius: 10, elevation: 6,
  },
  primaryText: { color: '#fff', fontSize: 16.5, fontWeight: '900' },
  loginLinkText: { fontSize: 13, color: Colors.muted, fontWeight: '700', textAlign: 'center' },
});
