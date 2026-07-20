import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { Colors } from '../constants/theme';
import Logo from '../components/logo';
import { useLanguage } from '../services/language';

export default function WelcomeScreen() {
  const router = useRouter();
  const { lang, t } = useLanguage();

  return (
    <View style={styles.container}>
      <View style={styles.content}>
        <Logo width={120} height={120} style={{ marginBottom: 26 }} />
        <Text style={styles.title}>{lang === 'bn' ? 'স্বাগতম ধোপা বাড়িতে' : 'Welcome to Dhopa Bari'}</Text>
        <Text style={styles.subtitle}>
          {t('splashTagline')}
        </Text>
        <TouchableOpacity style={styles.primaryButton} onPress={() => router.replace('/(tabs)/home')} activeOpacity={0.85}>
          <Text style={styles.primaryText}>অ্যাপে প্রবেশ করুন</Text>
          <Text style={styles.primaryText}>→</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 24,
  },
  mark: {
    width: 118,
    height: 118,
    borderRadius: 32,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 26,
    shadowColor: Colors.blue,
    shadowOffset: { width: 0, height: 18 },
    shadowOpacity: 0.25,
    shadowRadius: 19,
    elevation: 12,
  },
  checkmark: { color: '#fff', fontSize: 58 },
  title: { fontSize: 29, fontWeight: '900', color: Colors.ink, textAlign: 'center' },
  subtitle: { fontSize: 20, color: Colors.muted, marginTop: 16, textAlign: 'center', lineHeight: 30 },
  primaryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    minHeight: 56,
    borderRadius: 8,
    backgroundColor: Colors.blue,
    width: '100%',
    marginTop: 24,
    shadowColor: '#0874f8',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.2,
    shadowRadius: 10,
    elevation: 8,
  },
  primaryText: { color: '#fff', fontSize: 20, fontWeight: '900' },
});
