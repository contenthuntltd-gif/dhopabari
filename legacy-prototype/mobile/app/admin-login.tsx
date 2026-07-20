import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, KeyboardAvoidingView, Platform, ScrollView, Alert, ActivityIndicator } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useRouter } from 'expo-router';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Colors } from '../constants/theme';
import { useLanguage } from '../services/language';
import * as apiService from '../services/api';
import Logo from '../components/logo';

export default function AdminLoginScreen() {
  const router = useRouter();
  const { lang } = useLanguage();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const handleLogin = async () => {
    if (!username.trim() || !password.trim()) {
      const msg = lang === 'bn' ? 'সবগুলো তথ্য পূরণ করুন' : 'Please fill all fields';
      setErrorMsg(msg);
      return;
    }
    
    setLoading(true);
    setErrorMsg('');
    try {
      const res = await apiService.adminLogin({
        username: username.trim(),
        password: password.trim()
      });
      if (res.ok) {
        await AsyncStorage.setItem('admin_session', 'true');
        router.replace('/admin-dashboard');
      } else {
        setErrorMsg(res.error || (lang === 'bn' ? 'ভুল ইউজারনেম অথবা পাসওয়ার্ড' : 'Invalid credentials'));
      }
    } catch (e: any) {
      // Local fallback for offline / prototype robustness
      if (username.trim() === 'ADMIN' && password.trim() === 'admin2026') {
        await AsyncStorage.setItem('admin_session', 'true');
        router.replace('/admin-dashboard');
      } else {
        setErrorMsg(lang === 'bn' ? 'সার্ভার সংযোগে ব্যর্থতা বা ভুল পাসওয়ার্ড' : 'Failed to connect or invalid credentials');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView style={styles.container} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        
        {/* Curved Top Hero */}
        <View style={styles.heroContainer}>
          <LinearGradient colors={['#1e293b', '#0f172a']} style={styles.hero}>
            
            {/* Topbar back button */}
            <View style={styles.headerBar}>
              <TouchableOpacity onPress={() => router.back()} style={styles.backBtn} activeOpacity={0.7}>
                <Text style={styles.backText}>‹</Text>
              </TouchableOpacity>
              <Text style={styles.headerTitle}>{lang === 'bn' ? 'এডমিন পোর্টাল' : 'Admin Portal'}</Text>
              <View style={{ width: 36 }} />
            </View>
            <View style={styles.logoRow}>
              <Logo width={46} height={46} />
              <Text style={styles.logoText}>ধোপা বাড়ি</Text>
            </View>
            <Text style={styles.brandSub}>PREMIUM LAUNDRY SERVICE</Text>
          </LinearGradient>
          <View style={styles.heroCurve} />
        </View>

        {/* Form Body */}
        <View style={styles.form}>
          <Text style={styles.title}>{lang === 'bn' ? 'এডমিন লগইন' : 'Admin Sign In'}</Text>
          <Text style={styles.subtitle}>{lang === 'bn' ? 'এডমিন হিসেবে ড্যাশবোর্ড এক্সেস করুন' : 'Access the control panel'}</Text>

          {errorMsg ? (
            <View style={styles.errorContainer}>
              <Text style={styles.errorText}>⚠️ {errorMsg}</Text>
            </View>
          ) : null}

          {/* Username input */}
          <View style={styles.field}>
            <Text style={styles.fieldIcon}>👤</Text>
            <View style={styles.divider} />
            <TextInput
              style={styles.input}
              value={username}
              onChangeText={setUsername}
              placeholder={lang === 'bn' ? 'ইউজারনেম দিন (ADMIN)' : 'Username (ADMIN)'}
              placeholderTextColor="#a2abb8"
              autoCapitalize="none"
            />
          </View>

          {/* Password input */}
          <View style={styles.field}>
            <Text style={styles.fieldIcon}>🔒</Text>
            <View style={styles.divider} />
            <TextInput
              style={styles.input}
              value={password}
              onChangeText={setPassword}
              placeholder={lang === 'bn' ? 'পাসওয়ার্ড দিন (admin2026)' : 'Password (admin2026)'}
              placeholderTextColor="#a2abb8"
              secureTextEntry
              autoCapitalize="none"
            />
          </View>

          <TouchableOpacity style={styles.primaryButton} onPress={handleLogin} activeOpacity={0.85} disabled={loading}>
            {loading ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.primaryText}>{lang === 'bn' ? 'লগইন করুন →' : 'Log In →'}</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity onPress={() => router.push('/login')} style={{ marginTop: 20 }}>
            <Text style={styles.customerLinkText}>
              {lang === 'bn' ? 'কাস্টমার হিসেবে লগইন করতে চান? ' : 'Want to log in as a customer? '}
              <Text style={{ color: '#0874f8', fontWeight: '900' }}>{lang === 'bn' ? 'এখানে যান' : 'Go here'}</Text>
            </Text>
          </TouchableOpacity>
        </View>

      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  scrollContent: { flexGrow: 1, paddingBottom: 40 },
  heroContainer: {
    height: 230,
    position: 'relative',
    backgroundColor: '#fff',
  },
  hero: {
    height: 200,
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: 30,
  },
  headerBar: {
    position: 'absolute',
    top: 20,
    left: 16,
    right: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    zIndex: 10,
  },
  backBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(255,255,255,0.2)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  backText: { fontSize: 24, fontWeight: '900', color: '#fff', lineHeight: 26, textAlign: 'center' },
  headerTitle: { fontSize: 16, color: 'rgba(255,255,255,0.8)', fontWeight: '700' },
  heroCurve: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 40,
    backgroundColor: '#0f172a',
    borderBottomLeftRadius: 180,
    borderBottomRightRadius: 180,
  },
  logoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginTop: 20,
  },
  logoText: { fontSize: 32, fontWeight: '900', color: '#fff', letterSpacing: 0.5 },
  brandSub: { fontSize: 9.5, fontWeight: '800', color: 'rgba(255,255,255,0.85)', letterSpacing: 2, marginTop: 4 },
  customerLinkText: { fontSize: 12.5, color: '#727b8e', fontWeight: '700', textAlign: 'center' },
  form: {
    paddingHorizontal: 28,
    paddingTop: 16,
    alignItems: 'center',
  },
  title: { fontSize: 24, fontWeight: '900', color: '#091632', textAlign: 'center' },
  subtitle: { fontSize: 14, color: '#727b8e', marginTop: 6, fontWeight: '500', marginBottom: 20 },
  errorContainer: {
    width: '100%',
    padding: 12,
    backgroundColor: '#fef2f2',
    borderWidth: 1,
    borderColor: '#fee2e2',
    borderRadius: 8,
    marginBottom: 16,
  },
  errorText: { color: '#dc2626', fontSize: 13, fontWeight: '600', textAlign: 'center' },
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1.2,
    borderColor: '#e2e7ee',
    borderRadius: 12,
    minHeight: 56,
    paddingHorizontal: 16,
    gap: 12,
    marginBottom: 16,
    width: '100%',
    backgroundColor: '#fff',
  },
  fieldIcon: { fontSize: 18 },
  divider: { width: 1.2, height: 22, backgroundColor: '#dce2eb' },
  input: {
    flex: 1,
    fontSize: 16,
    color: '#091632',
    fontWeight: '700',
  },
  primaryButton: {
    minHeight: 52,
    borderRadius: 10,
    backgroundColor: '#0f172a',
    width: '100%',
    marginTop: 10,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 6,
    elevation: 4,
  },
  primaryText: { color: '#fff', fontSize: 17, fontWeight: '900' },
});
