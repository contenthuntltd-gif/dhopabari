import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, TextInput } from 'react-native';
import { useRouter } from 'expo-router';
import { Colors, Shadows, toBn, money, ridersData, priceMap } from '../constants/theme';
import { savePriceItem } from '../services/api';
import { useLanguage } from '../services/language';
import { useStore } from '../services/store';

export default function AdminPricingScreen() {
  const router = useRouter();
  const { lang, t } = useLanguage();
  const { priceMap: livePriceMap, priceList, fetchPrices } = useStore();

  const [editingItem, setEditingItem] = useState<any | null>(null);
  const [isNewItem, setIsNewItem] = useState(false);
  const [itemName, setItemName] = useState('');
  const [itemCategory, setItemCategory] = useState('male');
  const [itemWashPrice, setItemWashPrice] = useState('');
  const [itemDryPrice, setItemDryPrice] = useState('');
  const [itemComboPrice, setItemComboPrice] = useState('');
  const [itemIronPrice, setItemIronPrice] = useState('');

  const handleSavePriceItem = async () => {
    if (!itemName.trim()) {
      alert(lang === 'bn' ? 'আইটেম নাম আবশ্যক' : 'Item name is required');
      return;
    }
    const wash = Number(itemWashPrice) || 0;
    const dry = Number(itemDryPrice) || 0;
    const combo = Number(itemComboPrice) || 0;
    const iron = Number(itemIronPrice) || 0;

    const payload = {
      id: isNewItem ? `item_${Date.now()}` : (editingItem?.id || `item_${Date.now()}`),
      name: itemName.trim(),
      category: itemCategory,
      wash,
      dry,
      combo,
      iron,
    };

    try {
      await savePriceItem(payload);
      await fetchPrices(); // reload in store
      setEditingItem(null);
      alert(lang === 'bn' ? 'আইটেম সফলভাবে সংরক্ষিত হয়েছে!' : 'Item saved successfully!');
    } catch (e) {
      alert('Failed to save item');
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
          <Text style={styles.title}>{lang === 'bn' ? 'আইটেমের নাম' : 'Item Name'}</Text>
          <View style={{ width: 36 }} />
        </View>

        {/* Add New Item Button at the top */}
        <TouchableOpacity
          style={styles.adminAddItemPill}
          onPress={() => {
            setIsNewItem(true);
            setItemName('');
            setItemCategory('male');
            setItemWashPrice('');
            setItemDryPrice('');
            setItemComboPrice('');
            setItemIronPrice('');
            setEditingItem({});
          }}
          activeOpacity={0.8}
        >
          <Text style={styles.adminAddItemPillText}>➕ {lang === 'bn' ? 'নতুন আইটেম যোগ করুন' : 'Add New Item'}</Text>
        </TouchableOpacity>

        {/* Price Table */}
        <View style={styles.table}>
          <View style={styles.priceHeaderRow}>
            <Text style={[styles.priceColHeader, { flex: 1.5, textAlign: 'left', paddingLeft: 8 }]}>{lang === 'bn' ? 'আইটেম' : 'Item'}</Text>
            <Text style={styles.priceColHeader}>{lang === 'bn' ? 'ওয়াশ' : 'Wash'}</Text>
            <Text style={styles.priceColHeader}>{lang === 'bn' ? 'ড্রাই' : 'Dry'}</Text>
            <Text style={[styles.priceColHeader, { flex: 0.5 }]}></Text>
          </View>

          {priceList.map((item, i) => (
            <View key={i} style={styles.priceRowItem}>
              <Text style={[styles.priceItemName, { flex: 1.5 }]}>{item.name}</Text>
              <Text style={styles.priceItemVal}>৳{toBn(item.wash)}</Text>
              <Text style={styles.priceItemVal}>৳{toBn(item.dry)}</Text>
              <TouchableOpacity
                style={styles.editPriceItemBtn}
                onPress={() => {
                  setIsNewItem(false);
                  setEditingItem(item);
                  setItemName(item.name);
                  setItemCategory(item.category || 'male');
                  setItemWashPrice(String(item.wash));
                  setItemDryPrice(String(item.dry));
                  setItemComboPrice(String(item.combo || 0));
                  setItemIronPrice(String(item.iron || 0));
                }}
                activeOpacity={0.7}
              >
                <Text style={styles.editPriceItemBtnText}>✏️</Text>
              </TouchableOpacity>
            </View>
          ))}
        </View>
      </ScrollView>

      {/* Edit / Add Item Pricing Overlay */}
      {editingItem !== null && (
        <View style={styles.overlay}>
          <View style={[styles.dialog, { maxHeight: '90%' }]}>
            <View style={styles.dialogHeader}>
              <Text style={styles.dialogTitle}>
                {isNewItem 
                  ? (lang === 'bn' ? 'নতুন আইটেম যোগ করুন' : 'Add New Item')
                  : (lang === 'bn' ? 'আইটেম এডিট করুন' : 'Edit Item Pricing')}
              </Text>
              <TouchableOpacity onPress={() => setEditingItem(null)}>
                <Text style={styles.dialogClose}>✕</Text>
              </TouchableOpacity>
            </View>

            <ScrollView style={{ paddingBottom: 20 }} showsVerticalScrollIndicator={false}>
              {/* Item Name Input */}
              <Text style={styles.adminSectionTitle}>{lang === 'bn' ? 'আইটেমের নাম' : 'Item Name'}</Text>
              <TextInput
                style={styles.input}
                value={itemName}
                onChangeText={setItemName}
                placeholder={lang === 'bn' ? 'যেমন: জিন্স প্যান্ট' : 'e.g., Jeans Pants'}
                placeholderTextColor="#a2abb8"
              />

              {/* Category selector */}
              <Text style={styles.adminSectionTitle}>{lang === 'bn' ? 'ক্যাটাগরি' : 'Category'}</Text>
              <View style={styles.adminRiderSelector}>
                {['male', 'female', 'kids', 'home'].map((catKey) => {
                  const catLabelMap: Record<string, string> = {
                    male: lang === 'bn' ? 'পুরুষ' : 'Male',
                    female: lang === 'bn' ? 'মহিলা' : 'Female',
                    kids: lang === 'bn' ? 'বাচ্চা' : 'Kids',
                    home: lang === 'bn' ? 'বাসা' : 'Home',
                  };
                  return (
                    <TouchableOpacity
                      key={catKey}
                      style={[styles.riderChip, itemCategory === catKey && styles.riderChipActive]}
                      onPress={() => setItemCategory(catKey)}
                    >
                      <Text style={[styles.riderChipText, itemCategory === catKey && styles.riderChipActiveText]}>
                        {catLabelMap[catKey]}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </View>

              {/* Wash Price */}
              <Text style={styles.adminSectionTitle}>{lang === 'bn' ? 'ওয়াশ মূল্য (৳)' : 'Wash Price (৳)'}</Text>
              <TextInput
                style={styles.input}
                value={itemWashPrice}
                onChangeText={setItemWashPrice}
                placeholder="40"
                placeholderTextColor="#a2abb8"
                keyboardType="numeric"
              />

              {/* Dry Clean Price */}
              <Text style={styles.adminSectionTitle}>{lang === 'bn' ? 'ড্রাই ক্লিন মূল্য (৳)' : 'Dry Clean Price (৳)'}</Text>
              <TextInput
                style={styles.input}
                value={itemDryPrice}
                onChangeText={setItemDryPrice}
                placeholder="60"
                placeholderTextColor="#a2abb8"
                keyboardType="numeric"
              />

              {/* Combo Price */}
              <Text style={styles.adminSectionTitle}>{lang === 'bn' ? 'কম্বো মূল্য (৳)' : 'Combo Price (৳)'}</Text>
              <TextInput
                style={styles.input}
                value={itemComboPrice}
                onChangeText={setItemComboPrice}
                placeholder="50"
                placeholderTextColor="#a2abb8"
                keyboardType="numeric"
              />

              {/* Iron Price */}
              <Text style={styles.adminSectionTitle}>{lang === 'bn' ? 'ইস্ত্রি মূল্য (৳)' : 'Iron Price (৳)'}</Text>
              <TextInput
                style={styles.input}
                value={itemIronPrice}
                onChangeText={setItemIronPrice}
                placeholder="8"
                placeholderTextColor="#a2abb8"
                keyboardType="numeric"
              />

              {/* Actions */}
              <View style={styles.adminFormActions}>
                <TouchableOpacity
                  style={styles.adminFormCancel}
                  onPress={() => setEditingItem(null)}
                >
                  <Text style={styles.adminFormCancelText}>{lang === 'bn' ? 'বাতিল' : 'Cancel'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.adminFormSubmit}
                  onPress={handleSavePriceItem}
                >
                  <Text style={styles.adminFormSubmitText}>{lang === 'bn' ? 'সেভ করুন' : 'Save Item'}</Text>
                </TouchableOpacity>
              </View>
            </ScrollView>
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

  adminAddItemPill: {
    backgroundColor: '#eafaf1',
    borderWidth: 1.2,
    borderColor: '#c3ecd0',
    borderRadius: 8,
    height: 44,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  adminAddItemPillText: {
    color: '#15803d',
    fontWeight: '900',
    fontSize: 14,
  },

  table: {
    backgroundColor: '#fff',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    padding: 12,
    ...Shadows.card as any,
  },
  priceHeaderRow: { flexDirection: 'row', paddingVertical: 8, borderBottomWidth: 1.5, borderBottomColor: '#e2e8f0', marginBottom: 6 },
  priceColHeader: { flex: 1, fontWeight: '900', color: Colors.ink, fontSize: 13, textAlign: 'center' },
  priceRowItem: { flexDirection: 'row', alignItems: 'center', paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: '#f1f5f9' },
  priceItemName: { flex: 1, fontSize: 14, color: Colors.ink, fontWeight: '800', textAlign: 'left', paddingLeft: 8 },
  priceItemVal: { flex: 1, fontSize: 14, color: '#334155', fontWeight: '800', textAlign: 'center' },
  editPriceItemBtn: {
    flex: 0.5,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 6,
  },
  editPriceItemBtnText: {
    fontSize: 14,
  },

  // Modal styles
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
  adminSectionTitle: {
    fontSize: 14,
    fontWeight: '900',
    color: '#091632',
    marginTop: 10,
    marginBottom: 6,
  },
  input: {
    height: 44,
    backgroundColor: '#f1f4f9',
    borderRadius: 8,
    paddingHorizontal: 12,
    fontSize: 15,
    color: Colors.ink,
    fontWeight: '700',
    marginVertical: 4,
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
  adminFormActions: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 16,
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
});
