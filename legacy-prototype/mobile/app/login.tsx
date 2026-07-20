import React, { useEffect, useRef, useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, KeyboardAvoidingView, Platform, ScrollView, Alert, Linking, ActivityIndicator, Modal, Animated, Easing } from 'react-native';
import { useRouter } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import Svg, { Path, Circle, Rect, Line } from 'react-native-svg';
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

function EyeIcon({ open }: { open: boolean }) {
  return (
    <Svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="#a2abb8" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round">
      {open ? (
        <>
          <Path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7-11-7-11-7z" />
          <Circle cx={12} cy={12} r={3} />
        </>
      ) : (
        <>
          <Path d="M17.94 17.94A10.94 10.94 0 0112 19c-7 0-11-7-11-7a18.5 18.5 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 7 11 7a18.5 18.5 0 01-2.16 3.19" />
          <Path d="M14.12 14.12A3 3 0 019.88 9.88" />
          <Line x1={1} y1={1} x2={23} y2={23} />
        </>
      )}
    </Svg>
  );
}

function GoogleIcon() {
  return (
    <Svg width={20} height={20} viewBox="0 0 48 48">
      <Path fill="#FFC107" d="M43.6 20.5H42V20H24v8h11.3c-1.6 4.7-6.1 8-11.3 8-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.9 1.2 8 3.1l5.7-5.7C34.6 6 29.6 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.7-.4-3.5z" />
      <Path fill="#FF3D00" d="M6.3 14.7l6.6 4.8C14.5 15.9 18.9 13 24 13c3.1 0 5.9 1.2 8 3.1l5.7-5.7C34.6 6 29.6 4 24 4 16.3 4 9.7 8.3 6.3 14.7z" />
      <Path fill="#4CAF50" d="M24 44c5.5 0 10.4-1.9 14.2-5.1l-6.6-5.4C29.6 35.4 26.9 36.3 24 36.3c-5.2 0-9.6-3.3-11.3-7.9l-6.5 5C9.6 39.6 16.3 44 24 44z" />
      <Path fill="#1976D2" d="M43.6 20.5H42V20H24v8h11.3c-.8 2.3-2.2 4.2-4.1 5.5l6.6 5.4C41.6 35.6 44 30.2 44 24c0-1.3-.1-2.7-.4-3.5z" />
    </Svg>
  );
}

function FloatingBubbles() {
  const anim1 = useRef(new Animated.Value(0)).current;
  const anim2 = useRef(new Animated.Value(0)).current;
  const anim3 = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    const loop = (val: Animated.Value, duration: number, delay: number) =>
      Animated.loop(
        Animated.sequence([
          Animated.timing(val, { toValue: 1, duration, delay, easing: Easing.inOut(Easing.sin), useNativeDriver: true }),
          Animated.timing(val, { toValue: 0, duration, easing: Easing.inOut(Easing.sin), useNativeDriver: true }),
        ])
      ).start();
    loop(anim1, 2800, 0);
    loop(anim2, 3400, 300);
    loop(anim3, 3000, 600);
  }, []);

  const float = (val: Animated.Value, range: number) => ({
    transform: [{ translateY: val.interpolate({ inputRange: [0, 1], outputRange: [0, -range] }) }],
  });

  return (
    <>
      <Animated.View style={[styles.bubble, { width: 14, height: 14, top: 18, left: 30 }, float(anim1, 10)]} />
      <Animated.View style={[styles.bubble, { width: 9, height: 9, top: 46, left: 60 }, float(anim2, 8)]} />
      <Animated.View style={[styles.bubble, { width: 11, height: 11, top: 24, right: 40 }, float(anim3, 12)]} />
      <Animated.View style={[styles.bubble, { width: 7, height: 7, top: 60, right: 70 }, float(anim1, 6)]} />
    </>
  );
}

export default function LoginScreen() {
  const router = useRouter();
  const { user, setUser } = useStore();
  const { lang, setLang } = useLanguage();
  const [phone, setPhone] = useState(user.phone || '');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [sheetOpen, setSheetOpen] = useState(false);

  const handleLogin = async () => {
    const rawPhone = phone.trim();
    if (!rawPhone) {
      Alert.alert('', lang === 'bn' ? 'অনুগ্রহ করে একটি মোবাইল নম্বর দিন।' : 'Please enter a mobile number.');
      return;
    }
    const cleanPhone = normalizePhone(rawPhone);
    if (cleanPhone.length < 10) {
      Alert.alert('', lang === 'bn' ? 'সঠিক মোবাইল নম্বর দিন (১০ ডিজিট)।' : 'Please enter a valid 10-digit mobile number.');
      return;
    }
    if (!password.trim()) {
      Alert.alert('', lang === 'bn' ? 'পাসওয়ার্ড দিন।' : 'Please enter your password.');
      return;
    }

    setLoading(true);
    setErrorMsg('');
    try {
      const res = await apiService.loginCustomer({ phone: cleanPhone, password: password.trim() });
      if (res.ok && res.user) {
        setUser({
          phone: res.user.phone || cleanPhone,
          name: res.user.name || '',
          area: res.user.area || '',
          address: res.user.address || '',
          avatar: res.user.avatar || '👨',
        });
        if (res.user.name && res.user.address) {
          router.replace('/welcome');
        } else {
          router.push('/details');
        }
      } else {
        setErrorMsg(res.error || (lang === 'bn' ? 'ভুল নম্বর অথবা পাসওয়ার্ড' : 'Invalid phone or password'));
      }
    } catch (e) {
      setErrorMsg(lang === 'bn' ? 'সার্ভার সংযোগে ব্যর্থতা' : 'Failed to connect to server');
    } finally {
      setLoading(false);
    }
  };

  const toggleLanguage = () => setLang(lang === 'bn' ? 'en' : 'bn');
  const openLink = (url: string) => Linking.openURL(url).catch(() => {});
  const handleGoogleLogin = () => {
    Alert.alert('', lang === 'bn' ? 'গুগল লগইন শীঘ্রই আসছে' : 'Google login is coming soon');
  };

  return (
    <KeyboardAvoidingView style={styles.container} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>

        {/* Hero header */}
        <View style={styles.hero}>
          <FloatingBubbles />

          <TouchableOpacity onPress={() => setSheetOpen(true)} style={styles.menuBtn} activeOpacity={0.7}>
            <Text style={styles.menuBtnText}>⋮</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={toggleLanguage} style={styles.langBtn} activeOpacity={0.7}>
            <Text style={styles.langText}>🌐 {lang === 'bn' ? 'বাংলা' : 'English'} ⌄</Text>
          </TouchableOpacity>

          <View style={styles.logoBadge}>
            <Logo width={72} height={72} />
          </View>
          <Text style={styles.brand}>ধোপা বাড়ি</Text>
          <Text style={styles.brandSub}>PREMIUM LAUNDRY SERVICE</Text>
          <Text style={styles.tagline}>{lang === 'bn' ? 'কাপড়ের যত্নে আপনার বিশ্বস্ত পার্টনার' : 'Your trusted partner in fabric care'}</Text>
        </View>

        {/* Form body */}
        <View style={styles.form}>
          <Text style={styles.title}>{lang === 'bn' ? 'স্বাগতম! 👋' : 'Welcome! 👋'}</Text>
          <Text style={styles.subtitle}>{lang === 'bn' ? 'লগইন করে আমাদের প্রিমিয়াম লন্ড্রি সেবা উপভোগ করুন।' : 'Log in to enjoy our premium laundry service.'}</Text>

          {errorMsg ? (
            <View style={styles.errorBox}>
              <Text style={styles.errorText}>⚠️ {errorMsg}</Text>
            </View>
          ) : null}

          {/* Phone field */}
          <View style={styles.field}>
            <Text style={styles.flagEmoji}>🇧🇩</Text>
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

          {/* Password field */}
          <View style={styles.field}>
            <Svg width={18} height={18} viewBox="0 0 24 24" fill="none" stroke="#727b8e" strokeWidth={1.8}>
              <Rect x={4} y={11} width={16} height={9} rx={2} />
              <Path d="M8 11V7a4 4 0 018 0v4" />
            </Svg>
            <View style={styles.divider} />
            <TextInput
              style={styles.input}
              value={password}
              onChangeText={setPassword}
              placeholder={lang === 'bn' ? 'পাসওয়ার্ড দিন' : 'Enter password'}
              placeholderTextColor="#a2abb8"
              secureTextEntry={!showPassword}
            />
            <TouchableOpacity onPress={() => setShowPassword(!showPassword)} hitSlop={8}>
              <EyeIcon open={showPassword} />
            </TouchableOpacity>
          </View>

          <TouchableOpacity onPress={() => router.push('/forgot-password')} style={styles.forgotWrap}>
            <Text style={styles.forgotText}>{lang === 'bn' ? 'পাসওয়ার্ড ভুলেছেন?' : 'Forgot password?'}</Text>
          </TouchableOpacity>

          <TouchableOpacity activeOpacity={0.85} onPress={handleLogin} disabled={loading} style={styles.primaryButtonWrap}>
            <LinearGradient colors={[Colors.blue, '#0A3FB0']} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.primaryButton}>
              {loading ? <ActivityIndicator color="#fff" /> : (
                <Text style={styles.primaryText}>{lang === 'bn' ? 'লগইন করুন' : 'Log In'}  →</Text>
              )}
            </LinearGradient>
          </TouchableOpacity>

          <View style={styles.dividerRow}>
            <View style={styles.hLine} />
            <Text style={styles.dividerText}>{lang === 'bn' ? 'অথবা' : 'or'}</Text>
            <View style={styles.hLine} />
          </View>

          <TouchableOpacity style={styles.googleButton} onPress={handleGoogleLogin} activeOpacity={0.85}>
            <GoogleIcon />
            <Text style={styles.googleText}>Continue with Google</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.outlineButton} onPress={() => router.push('/register')} activeOpacity={0.85}>
            <Text style={styles.outlineText}>{lang === 'bn' ? 'নতুন অ্যাকাউন্ট তৈরি করুন' : 'Create a new account'}</Text>
          </TouchableOpacity>

          <Text style={styles.connectTitle}>{lang === 'bn' ? 'আমাদের সাথে যুক্ত থাকুন' : 'Stay connected with us'}</Text>
          <View style={styles.socialRow}>
            <TouchableOpacity style={styles.socialCard} onPress={() => openLink('https://wa.me/8801700000000')} activeOpacity={0.8}>
              <Text style={styles.socialEmoji}>💬</Text>
              <View>
                <Text style={styles.socialTitle}>WhatsApp</Text>
                <Text style={styles.socialSub}>{lang === 'bn' ? 'আমাদের সাথে চ্যাট করুন' : 'Chat with us'}</Text>
              </View>
            </TouchableOpacity>
            <TouchableOpacity style={styles.socialCard} onPress={() => openLink('https://facebook.com')} activeOpacity={0.8}>
              <Text style={styles.socialEmoji}>📘</Text>
              <View>
                <Text style={styles.socialTitle}>Facebook</Text>
                <Text style={styles.socialSub}>{lang === 'bn' ? 'আমাদের পেজ ফলো করুন' : 'Follow our page'}</Text>
              </View>
            </TouchableOpacity>
          </View>

          <View style={styles.featuresBox}>
            {[
              { icon: '🚚', label: lang === 'bn' ? 'ফ্রি পিকআপ' : 'Free pickup' },
              { icon: '🧺', label: lang === 'bn' ? 'প্রিমিয়াম ওয়াশ' : 'Premium wash' },
              { icon: '🛡️', label: lang === 'bn' ? 'নিরাপদ সেবা' : 'Safe service' },
              { icon: '⏰', label: lang === 'bn' ? 'সময়মতো ডেলিভারি' : 'On-time delivery' },
            ].map((f, i) => (
              <View key={i} style={styles.featureItem}>
                <Text style={styles.featureIcon}>{f.icon}</Text>
                <Text style={styles.featureLabel}>{f.label}</Text>
              </View>
            ))}
          </View>

          <Text style={styles.footerText}>{lang === 'bn' ? 'আপনার কাপড়, আমাদের দায়িত্ব। 💙' : 'Your clothes, our responsibility. 💙'}</Text>
        </View>
      </ScrollView>

      {/* Bottom sheet: Admin / Rider login menu */}
      <Modal visible={sheetOpen} transparent animationType="slide" onRequestClose={() => setSheetOpen(false)}>
        <TouchableOpacity style={styles.sheetBackdrop} activeOpacity={1} onPress={() => setSheetOpen(false)}>
          <TouchableOpacity activeOpacity={1} style={styles.sheet} onPress={(e) => e.stopPropagation()}>
            <View style={styles.sheetHandle} />
            <Text style={styles.sheetTitle}>{lang === 'bn' ? 'লগইন করুন' : 'Log in'}</Text>
            <Text style={styles.sheetSubtitle}>{lang === 'bn' ? 'আপনার অ্যাকাউন্ট টাইপ নির্বাচন করুন' : 'Choose your account type'}</Text>

            <TouchableOpacity
              style={[styles.sheetOption, { backgroundColor: '#EAF1FF' }]}
              activeOpacity={0.85}
              onPress={() => { setSheetOpen(false); router.push('/admin-login'); }}
            >
              <View style={[styles.sheetIconBadge, { backgroundColor: Colors.blue }]}>
                <Text style={styles.sheetIconEmoji}>🛠️</Text>
              </View>
              <View style={{ flex: 1 }}>
                <Text style={[styles.sheetOptionTitle, { color: Colors.blue }]}>Admin Panel</Text>
                <Text style={styles.sheetOptionSub}>{lang === 'bn' ? 'অ্যাডমিন প্যানেলে লগইন করুন' : 'Log in to the admin panel'}</Text>
              </View>
              <Text style={[styles.sheetChevron, { color: Colors.blue }]}>›</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.sheetOption, { backgroundColor: '#E1F7F0' }]}
              activeOpacity={0.85}
              onPress={() => { setSheetOpen(false); router.push('/rider-login'); }}
            >
              <View style={[styles.sheetIconBadge, { backgroundColor: '#0d9488' }]}>
                <Text style={styles.sheetIconEmoji}>🏍️</Text>
              </View>
              <View style={{ flex: 1 }}>
                <Text style={[styles.sheetOptionTitle, { color: '#0d9488' }]}>Rider App</Text>
                <Text style={styles.sheetOptionSub}>{lang === 'bn' ? 'রাইডার অ্যাপে লগইন করুন' : 'Log in to the rider app'}</Text>
              </View>
              <Text style={[styles.sheetChevron, { color: '#0d9488' }]}>›</Text>
            </TouchableOpacity>

            <TouchableOpacity style={styles.sheetCancel} activeOpacity={0.85} onPress={() => setSheetOpen(false)}>
              <Text style={styles.sheetCancelText}>{lang === 'bn' ? 'বাতিল করুন' : 'Cancel'}</Text>
            </TouchableOpacity>
          </TouchableOpacity>
        </TouchableOpacity>
      </Modal>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  scrollContent: { flexGrow: 1, paddingBottom: 30 },
  hero: {
    backgroundColor: '#EAF1FF',
    paddingTop: 40,
    paddingBottom: 26,
    alignItems: 'center',
    borderBottomLeftRadius: 32,
    borderBottomRightRadius: 32,
    overflow: 'hidden',
    position: 'relative',
  },
  bubble: {
    position: 'absolute',
    borderRadius: 999,
    backgroundColor: 'rgba(18,89,232,0.14)',
    borderWidth: 1,
    borderColor: 'rgba(18,89,232,0.25)',
  },
  langBtn: {
    position: 'absolute',
    top: 16,
    right: 16,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 14,
    backgroundColor: '#fff',
  },
  langText: { fontSize: 12.5, fontWeight: '800', color: Colors.blue },
  menuBtn: {
    position: 'absolute', top: 16, left: 16, width: 34, height: 34, borderRadius: 17,
    backgroundColor: '#fff', justifyContent: 'center', alignItems: 'center', zIndex: 20,
  },
  menuBtnText: { fontSize: 22, fontWeight: '900', color: Colors.blue, lineHeight: 22 },
  logoBadge: { marginBottom: 6 },
  brand: { fontSize: 28, fontWeight: '900', color: Colors.blue, letterSpacing: 0.3 },
  brandSub: { fontSize: 10, fontWeight: '800', color: Colors.blue, letterSpacing: 2, marginTop: 2 },
  tagline: { fontSize: 12.5, color: Colors.ink, fontWeight: '700', textAlign: 'center', marginTop: 10 },
  form: { paddingHorizontal: 24, paddingTop: 22, alignItems: 'center' },
  title: { fontSize: 24, fontWeight: '900', color: Colors.ink },
  subtitle: { fontSize: 13.5, color: Colors.muted, marginTop: 4, textAlign: 'center', fontWeight: '600' },
  errorBox: { width: '100%', padding: 12, backgroundColor: '#fef2f2', borderWidth: 1, borderColor: '#fee2e2', borderRadius: 8, marginTop: 16 },
  errorText: { color: '#dc2626', fontSize: 13, fontWeight: '600', textAlign: 'center' },
  field: {
    flexDirection: 'row', alignItems: 'center', borderWidth: 1.2, borderColor: '#e2e7ee',
    borderRadius: 12, minHeight: 56, paddingHorizontal: 16, gap: 10, marginTop: 18, width: '100%', backgroundColor: '#fff',
  },
  flagEmoji: { fontSize: 16 },
  countryCode: { fontWeight: '800', fontSize: 15, color: Colors.ink },
  divider: { width: 1.2, height: 22, backgroundColor: '#dce2eb' },
  input: { flex: 1, fontSize: 15.5, color: Colors.ink, fontWeight: '700' },
  forgotWrap: { alignSelf: 'flex-end', marginTop: 10 },
  forgotText: { fontSize: 12.5, color: Colors.blue, fontWeight: '700' },
  primaryButtonWrap: {
    width: '100%', marginTop: 18, borderRadius: 12, shadowColor: Colors.blue, shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.25, shadowRadius: 12, elevation: 6,
  },
  primaryButton: { minHeight: 54, borderRadius: 12, justifyContent: 'center', alignItems: 'center' },
  primaryText: { color: '#fff', fontSize: 16.5, fontWeight: '900' },
  dividerRow: { flexDirection: 'row', alignItems: 'center', gap: 10, marginTop: 22, width: '100%' },
  hLine: { flex: 1, height: 1, backgroundColor: Colors.line },
  dividerText: { fontSize: 12.5, color: Colors.muted, fontWeight: '700' },
  googleButton: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 10,
    minHeight: 52, borderRadius: 12, borderWidth: 1.2, borderColor: '#e2e7ee', width: '100%',
    backgroundColor: '#fff', marginTop: 16,
  },
  googleText: { fontSize: 15, fontWeight: '800', color: Colors.ink },
  outlineButton: {
    minHeight: 50, borderRadius: 12, borderWidth: 1.5, borderColor: Colors.blue, width: '100%', marginTop: 14,
    justifyContent: 'center', alignItems: 'center',
  },
  outlineText: { color: Colors.blue, fontSize: 15, fontWeight: '900' },
  connectTitle: { fontSize: 13, color: Colors.muted, fontWeight: '700', marginTop: 26 },
  socialRow: { flexDirection: 'row', gap: 10, marginTop: 12, width: '100%' },
  socialCard: {
    flex: 1, flexDirection: 'row', alignItems: 'center', gap: 8, borderWidth: 1, borderColor: Colors.line,
    borderRadius: 12, padding: 12,
  },
  socialEmoji: { fontSize: 20 },
  socialTitle: { fontSize: 12.5, fontWeight: '800', color: Colors.ink },
  socialSub: { fontSize: 10, color: Colors.muted, fontWeight: '600' },
  featuresBox: {
    flexDirection: 'row', flexWrap: 'wrap', backgroundColor: 'rgba(234,241,255,0.6)', borderRadius: 16, padding: 14,
    marginTop: 20, width: '100%', justifyContent: 'space-between', gap: 10,
    borderWidth: 1, borderColor: 'rgba(18,89,232,0.1)',
  },
  featureItem: { width: '47%', flexDirection: 'row', alignItems: 'center', gap: 6 },
  featureIcon: { fontSize: 15 },
  featureLabel: { fontSize: 10.5, fontWeight: '700', color: Colors.ink, flexShrink: 1 },
  footerText: { fontSize: 12, color: Colors.muted, fontWeight: '700', marginTop: 18, textAlign: 'center' },

  sheetBackdrop: { flex: 1, backgroundColor: 'rgba(9,22,50,0.45)', justifyContent: 'flex-end' },
  sheet: {
    backgroundColor: '#fff', borderTopLeftRadius: 24, borderTopRightRadius: 24,
    paddingHorizontal: 22, paddingTop: 12, paddingBottom: 30, alignItems: 'center',
  },
  sheetHandle: { width: 40, height: 4, borderRadius: 2, backgroundColor: '#dce2eb', marginBottom: 16 },
  sheetTitle: { fontSize: 19, fontWeight: '900', color: Colors.ink },
  sheetSubtitle: { fontSize: 13, color: Colors.muted, fontWeight: '600', marginTop: 4, marginBottom: 18 },
  sheetOption: {
    flexDirection: 'row', alignItems: 'center', gap: 14, width: '100%', borderRadius: 16,
    padding: 14, marginBottom: 12,
  },
  sheetIconBadge: { width: 44, height: 44, borderRadius: 14, justifyContent: 'center', alignItems: 'center' },
  sheetIconEmoji: { fontSize: 20 },
  sheetOptionTitle: { fontSize: 15.5, fontWeight: '900' },
  sheetOptionSub: { fontSize: 11.5, color: Colors.muted, fontWeight: '600', marginTop: 2 },
  sheetChevron: { fontSize: 24, fontWeight: '900' },
  sheetCancel: {
    width: '100%', minHeight: 50, borderRadius: 12, borderWidth: 1.2, borderColor: '#e2e7ee',
    justifyContent: 'center', alignItems: 'center', marginTop: 6,
  },
  sheetCancelText: { fontSize: 15, fontWeight: '800', color: Colors.ink },
});
