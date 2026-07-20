import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ScrollView, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import Svg, { Path, Rect, Circle } from 'react-native-svg';
import { Colors, areaOptions } from '../constants/theme';
import { useStore } from '../services/store';
import * as apiService from '../services/api';

export default function DetailsScreen() {
  const router = useRouter();
  const { user, setUser } = useStore();
  const [name, setName] = useState(user.name || '');
  const [area, setArea] = useState(user.area || '');
  const [address, setAddress] = useState('');
  const [showAreas, setShowAreas] = useState(false);

  const localAreas = areaOptions;

  const handleSave = async () => {
    if (!name.trim()) return Alert.alert('', 'আপনার পূর্ণ নাম লিখুন।');
    if (!area) return Alert.alert('', 'এলাকা নির্বাচন করুন।');
    if (!address.trim()) return Alert.alert('', 'বাসা নম্বর, রোড, এলাকা লিখুন।');

    const updatedUser = {
      ...user,
      name: name.trim(),
      area,
      address: `${address.trim()}, ${area}`,
    };
    setUser(updatedUser);

    try {
      await apiService.saveCustomer(updatedUser);
    } catch (e) {
      console.warn('Customer saved locally only');
    }
    router.push('/welcome');
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
      {/* Top Header Row */}
      <View style={styles.topHeader}>
        <TouchableOpacity style={styles.back} onPress={() => router.back()} activeOpacity={0.7}>
          <Text style={styles.backText}>‹</Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={() => router.push('/welcome')}>
          <Text style={styles.skipText}>পরে দিব</Text>
        </TouchableOpacity>
      </View>

      {/* Step Progress Bar */}
      <View style={styles.stepBar}>
        <View style={styles.stepFill} />
      </View>

      <Text style={styles.stepLabel}>ধাপ ১ এর ১</Text>
      <Text style={styles.title}>আপনার তথ্য দিন</Text>
      <Text style={styles.subtitle}>অর্ডার ও ডেলিভারির জন্য এই তথ্য প্রয়োজন</Text>

      {/* Name Input */}
      <View style={styles.field}>
        <Svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="#727b8e" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
          <Path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
          <Circle cx={12} cy={7} r={4} />
        </Svg>
        <TextInput
          style={styles.input}
          value={name}
          onChangeText={setName}
          placeholder="আপনার নাম"
          placeholderTextColor="#a2abb8"
        />
      </View>

      {/* Area Picker */}
      <TouchableOpacity style={styles.field} onPress={() => setShowAreas(!showAreas)} activeOpacity={0.9}>
        <Svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="#727b8e" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
          <Path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
          <Circle cx={12} cy={10} r={3} />
        </Svg>
        <Text style={[styles.inputTextValue, !area && { color: '#a2abb8' }]}>
          {area || 'এলাকা নির্বাচন করুন'}
        </Text>
        <Text style={styles.dropdownArrow}>⌄</Text>
      </TouchableOpacity>

      {/* Custom Area Selection Card matching Screenshot 4 */}
      {showAreas && (
        <View style={styles.areaList}>
          {localAreas.map((opt) => (
            <TouchableOpacity
              key={opt}
              style={[styles.areaOption, area === opt && styles.areaOptionActive]}
              onPress={() => {
                setArea(opt);
                setShowAreas(false);
              }}
            >
              <Text style={[styles.areaText, area === opt && styles.areaTextActive]}>
                {opt}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      )}

      {/* Full Address Input */}
      <View style={[styles.field, styles.textareaField]}>
        <View style={styles.textareaIcon}>
          <Svg width={20} height={20} viewBox="0 0 24 24" fill="none" stroke="#727b8e" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
            <Path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
            <Path d="M9 22V12h6v10" />
          </Svg>
        </View>
        <TextInput
          style={styles.textarea}
          value={address}
          onChangeText={setAddress}
          placeholder="পূর্ণ ঠিকানা (বাসা নম্বর, রোড, এলাকা)"
          placeholderTextColor="#a2abb8"
          multiline
        />
      </View>

      {/* Save Button */}
      <TouchableOpacity style={styles.primaryButton} onPress={handleSave} activeOpacity={0.85}>
        <Text style={styles.primaryText}>সেভ করুন ✓</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { paddingHorizontal: 28, paddingTop: 16, paddingBottom: 40 },
  topHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    minHeight: 44,
  },
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
  },
  backText: {
    fontSize: 22,
    fontWeight: '900',
    color: '#334155',
    lineHeight: 24,
    textAlign: 'center',
  },
  skipText: { fontSize: 16, fontWeight: '800', color: '#0874f8' },
  stepBar: {
    height: 5,
    backgroundColor: '#eaf2ff',
    borderRadius: 6,
    marginTop: 14,
    marginBottom: 16,
    overflow: 'hidden',
  },
  stepFill: { width: '50%', height: '100%', backgroundColor: '#0874f8', borderRadius: 6 },
  stepLabel: { fontSize: 14, color: '#727b8e', textAlign: 'center', fontWeight: '600' },
  title: { fontSize: 27, fontWeight: '900', color: '#091632', textAlign: 'center', marginTop: 6 },
  subtitle: { fontSize: 14.5, color: '#727b8e', textAlign: 'center', marginTop: 4, lineHeight: 22, fontWeight: '500' },
  field: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1.2,
    borderColor: '#e2e7ee',
    borderRadius: 12,
    minHeight: 58,
    paddingHorizontal: 16,
    gap: 12,
    marginTop: 18,
    backgroundColor: '#fff',
  },
  input: { flex: 1, fontSize: 17, color: '#091632', fontWeight: '700' },
  inputTextValue: { flex: 1, fontSize: 17, color: '#091632', fontWeight: '700' },
  dropdownArrow: { fontSize: 20, color: '#727b8e', fontWeight: '800' },
  textareaField: {
    minHeight: 110,
    alignItems: 'flex-start',
    paddingVertical: 14,
  },
  textareaIcon: {
    marginTop: 4,
  },
  textarea: {
    flex: 1,
    fontSize: 17,
    color: '#091632',
    fontWeight: '700',
    minHeight: 80,
    textAlignVertical: 'top',
    paddingTop: 0,
  },
  areaList: {
    borderWidth: 1.2,
    borderColor: '#e2e7ee',
    borderRadius: 12,
    padding: 12,
    marginTop: 6,
    backgroundColor: '#fff',
    gap: 8,
  },
  areaOption: {
    minHeight: 46,
    borderRadius: 8,
    backgroundColor: '#f6f8fa',
    justifyContent: 'center',
    paddingHorizontal: 14,
  },
  areaOptionActive: {
    backgroundColor: '#0874f8',
  },
  areaText: { fontWeight: '800', color: '#495260', fontSize: 16 },
  areaTextActive: { color: '#fff' },
  primaryButton: {
    minHeight: 52,
    borderRadius: 10,
    backgroundColor: '#0874f8',
    marginTop: 24,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#0874f8',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.18,
    shadowRadius: 10,
    elevation: 6,
  },
  primaryText: { color: '#fff', fontSize: 19, fontWeight: '900' },
});
