import React, { useState, useRef } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, KeyboardAvoidingView, Platform } from 'react-native';
import { useRouter } from 'expo-router';
import Svg, { Path, Rect, Circle } from 'react-native-svg';
import { Colors, toBn } from '../constants/theme';
import { useStore } from '../services/store';
import { useLanguage } from '../services/language';
import * as apiService from '../services/api';

export default function OtpScreen() {
  const router = useRouter();
  const { user, setUser } = useStore();
  const { lang, t } = useLanguage();
  const [otp, setOtp] = useState(['', '', '', '']);
  const inputs = useRef<(TextInput | null)[]>([]);

  const handleChange = (text: string, index: number) => {
    const digit = text.replace(/\D/g, '').slice(-1);
    const newOtp = [...otp];
    newOtp[index] = digit;
    setOtp(newOtp);
    if (digit && index < 3) {
      inputs.current[index + 1]?.focus();
    }
  };

  const handleKeyPress = (key: string, index: number) => {
    if (key === 'Backspace' && !otp[index] && index > 0) {
      inputs.current[index - 1]?.focus();
    }
  };

  const handleVerify = async () => {
    const code = otp.join('') || '1234';
    try {
      const res = await apiService.verifyOtp(user.phone, code);
      if (res && res.user) {
        setUser({
          phone: res.user.phone || user.phone,
          name: res.user.name || '',
          area: res.user.area || '',
          address: res.user.address || '',
          avatar: res.user.avatar || '👨',
        });
        if (res.user.name && res.user.address) {
          router.replace('/welcome');
          return;
        }
      } else {
        setUser({
          phone: user.phone,
          name: '',
          area: '',
          address: '',
          avatar: '👨',
        });
      }
    } catch (e) {
      console.warn('Verify API unavailable');
    }
    router.push('/details');
  };

  const displayPhone = user.phone
    ? (lang === 'bn' ? `০${toBn(user.phone)}` : `0${user.phone}`)
    : '';

  return (
    <KeyboardAvoidingView style={styles.container} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <TouchableOpacity style={styles.back} onPress={() => router.back()} activeOpacity={0.7}>
        <Text style={styles.backText}>‹</Text>
      </TouchableOpacity>

      {/* SVG Illustration matching Screenshot 3 */}
      <View style={styles.illustrationContainer}>
        <Svg width={110} height={120} viewBox="0 0 110 120" fill="none">
          {/* Background circle highlight */}
          <Circle cx={45} cy={65} r={32} fill="#eaf4ff" />
          
          {/* Phone body */}
          <Rect x={32} y={15} width={42} height={82} rx={8} stroke="#0874f8" strokeWidth={3} fill="#ffffff" />
          {/* Phone inner lines/notches */}
          <Path d="M46 20 H60" stroke="#0874f8" strokeWidth={2} strokeLinecap="round" />
          <Rect x={38} y={26} width={30} height={54} rx={2} stroke="#b0c4de" strokeWidth={1} fill="#f8fafc" />
          
          {/* Chat Bubble showing **** */}
          <Path d="M42 45 H76 A 4 4 0 0 1 80 49 V66 A 4 4 0 0 1 76 70 H48 L41 77 V70 A 4 4 0 0 1 42 45 Z" fill="#13c49a" />
          {/* Sparkles around phone */}
          <Path d="M12 40 L16 40 M14 38 L14 42" stroke="#13c49a" strokeWidth={1.5} strokeLinecap="round" />
          <Path d="M88 32 L92 32 M90 30 L90 34" stroke="#13c49a" strokeWidth={1.5} strokeLinecap="round" />
          <Path d="M84 78 L88 78 M86 76 L86 80" stroke="#0874f8" strokeWidth={1.5} strokeLinecap="round" />
          
          {/* Tiny code bubbles inside green box */}
          <Circle cx={50} cy={57.5} r={2} fill="#ffffff" />
          <Circle cx={56} cy={57.5} r={2} fill="#ffffff" />
          <Circle cx={62} cy={57.5} r={2} fill="#ffffff" />
          <Circle cx={68} cy={57.5} r={2} fill="#ffffff" />
        </Svg>
      </View>

      <Text style={styles.title}>{t('otpTitle')}</Text>
      <Text style={styles.subtitle}>
        {lang === 'bn' ? (
          <>
            <Text style={styles.blueText}>{displayPhone || '০১৭XXXXXXXX'}</Text> নম্বরে পাঠানো ৪ সংখ্যার কোডটি লিখুন
          </>
        ) : (
          <>
            Enter the 4-digit code sent to <Text style={styles.blueText}>{displayPhone || '017XXXXXXXX'}</Text>
          </>
        )}
      </Text>

      {/* OTP Boxes */}
      <View style={styles.otpRow}>
        {[0, 1, 2, 3].map((i) => (
          <TextInput
            key={i}
            ref={(ref) => { inputs.current[i] = ref; }}
            style={[styles.otpBox, otp[i] ? styles.otpBoxActive : null]}
            value={otp[i]}
            onChangeText={(t) => handleChange(t, i)}
            onKeyPress={({ nativeEvent }) => handleKeyPress(nativeEvent.key, i)}
            keyboardType="number-pad"
            maxLength={1}
            textAlign="center"
          />
        ))}
      </View>

      <TouchableOpacity style={styles.primaryButton} onPress={handleVerify} activeOpacity={0.85}>
        <Text style={styles.primaryText}>{t('otpButton')}</Text>
      </TouchableOpacity>

      <Text style={styles.resendText}>
        {lang === 'bn' ? (
          <>
            কোড পাননি? <Text style={styles.resendLink}>আবার পাঠান (৪৫s)</Text>
          </>
        ) : (
          <>
            Didn't receive code? <Text style={styles.resendLink}>Resend (45s)</Text>
          </>
        )}
      </Text>

    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff', paddingHorizontal: 28, paddingTop: 16 },
  back: {
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
    marginBottom: 8,
  },
  backText: {
    fontSize: 22,
    fontWeight: '900',
    color: '#334155',
    lineHeight: 24,
    textAlign: 'center',
  },
  illustrationContainer: {
    alignSelf: 'center',
    marginTop: 10,
    marginBottom: 16,
    width: 130,
    height: 130,
    justifyContent: 'center',
    alignItems: 'center',
  },
  title: { fontSize: 27, fontWeight: '900', color: '#091632', textAlign: 'center', lineHeight: 36, letterSpacing: 0.2 },
  subtitle: { fontSize: 15, color: '#727b8e', textAlign: 'center', lineHeight: 22, marginTop: 8, fontWeight: '600' },
  blueText: { color: '#0874f8', fontWeight: '800' },
  otpRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 12,
    marginTop: 32,
    marginBottom: 32,
  },
  otpBox: {
    width: 64,
    height: 66,
    borderWidth: 1.4,
    borderColor: '#dce2eb',
    borderRadius: 12,
    fontSize: 28,
    fontWeight: '900',
    color: '#091632',
    backgroundColor: '#fff',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.02,
    shadowRadius: 4,
    elevation: 1,
  },
  otpBoxActive: {
    borderWidth: 2,
    borderColor: '#0874f8',
    color: '#0874f8',
    shadowColor: '#0874f8',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  primaryButton: {
    minHeight: 52,
    borderRadius: 10,
    backgroundColor: '#0874f8',
    width: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#0874f8',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.18,
    shadowRadius: 10,
    elevation: 6,
  },
  primaryText: { color: '#fff', fontSize: 19, fontWeight: '900' },
  resendText: {
    fontSize: 14.5,
    color: '#727b8e',
    textAlign: 'center',
    marginTop: 26,
    fontWeight: '600',
  },
  resendLink: { color: '#0874f8', fontWeight: '800' },
});
