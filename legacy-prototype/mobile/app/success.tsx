import React from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { Colors, Shadows } from '../constants/theme';
import { useLanguage } from '../services/language';

export default function SuccessScreen() {
  const router = useRouter();
  const { t } = useLanguage();

  return (
    <View style={styles.container}>
      {/* Confetti dots */}
      <View style={styles.confetti}>
        {[
          { x: 40, y: 10, color: Colors.blue },
          { x: 120, y: 30, color: Colors.green },
          { x: 220, y: 5, color: '#f6a400' },
          { x: 300, y: 25, color: Colors.blue },
          { x: 80, y: 50, color: '#f6a400' },
          { x: 180, y: 45, color: Colors.green },
          { x: 260, y: 55, color: Colors.blue },
        ].map((dot, i) => (
          <View
            key={i}
            style={[styles.dot, { left: dot.x, top: dot.y, backgroundColor: dot.color, borderRadius: i % 3 === 0 ? 2 : 4, transform: [{ rotate: i % 2 === 0 ? '25deg' : '0deg' }] }]}
          />
        ))}
      </View>

      {/* Check mark */}
      <View style={styles.checkCircle}>
        <Text style={styles.checkMark}>✓</Text>
      </View>

      <Text style={styles.title}>{t('successTitle')} 🎉</Text>
      <Text style={styles.subtitle}>{t('successSubtitle')}</Text>

      <TouchableOpacity style={styles.primaryButton} onPress={() => router.push('/tracking')} activeOpacity={0.85}>
        <Text style={styles.primaryText}>{t('successTrack')}</Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.outlineButton} onPress={() => router.replace('/(tabs)/home')} activeOpacity={0.7}>
        <Text style={styles.outlineText}>{t('successHome')}</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff', justifyContent: 'center', alignItems: 'center', paddingHorizontal: 32 },
  confetti: { height: 70, width: '100%', position: 'relative', marginBottom: -20 },
  dot: { position: 'absolute', width: 8, height: 8 },
  checkCircle: {
    width: 140,
    height: 140,
    borderRadius: 70,
    backgroundColor: Colors.green,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 28,
    shadowColor: Colors.green,
    shadowOffset: { width: 0, height: 14 },
    shadowOpacity: 0.22,
    shadowRadius: 14,
    elevation: 12,
  },
  checkMark: { color: '#fff', fontSize: 82 },
  title: { fontSize: 29, fontWeight: '900', color: Colors.ink, textAlign: 'center', marginBottom: 12 },
  subtitle: { fontSize: 16, color: Colors.muted, textAlign: 'center', lineHeight: 24, marginBottom: 32 },
  primaryButton: {
    minHeight: 56,
    borderRadius: 8,
    backgroundColor: Colors.blue,
    width: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
    ...Shadows.button,
  },
  primaryText: { color: '#fff', fontSize: 20, fontWeight: '900' },
  outlineButton: {
    minHeight: 54,
    borderRadius: 8,
    borderWidth: 1.5,
    borderColor: Colors.blue,
    width: '100%',
    justifyContent: 'center',
    alignItems: 'center',
  },
  outlineText: { color: Colors.blue, fontSize: 18, fontWeight: '900' },
});
