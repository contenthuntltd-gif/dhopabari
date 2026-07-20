import React, { useEffect, useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Linking } from 'react-native';
import { useRouter } from 'expo-router';
import { Colors, Shadows, ridersData } from '../../constants/theme';
import { getOrders, getMessages } from '../../services/api';
import { useStore } from '../../services/store';
import { useLanguage } from '../../services/language';

const WHATSAPP_NUMBER = '8801973615217';

export default function MessagesScreen() {
  const router = useRouter();
  const { user } = useStore();
  const { t, lang } = useLanguage();
  const [chats, setChats] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const loadChats = async () => {
    try {
      const orders = await getOrders();
      const userOrders = orders.filter(
        (o: any) => o.phone === user.phone || o.customerName === user.name
      );

      const chatsList: any[] = [];
      for (const order of userOrders) {
        // Skip cancelled orders
        const s = (order.status || '').toLowerCase();
        if (s.includes('বাতিল') || s.includes('cancelled')) continue;

        const rId = order.riderId || 'rider_karim';
        const rider = ridersData[rId] || ridersData.rider_karim;
        let lastMsg = t('messagesTapToChat');
        try {
          const msgs = await getMessages(order.id);
          if (msgs && msgs.length > 0) lastMsg = msgs[msgs.length - 1].text;
        } catch (e) {}
        chatsList.push({ rider, order, lastMsg });
      }

      chatsList.sort((a, b) =>
        new Date(b.order.createdAt).getTime() - new Date(a.order.createdAt).getTime()
      );

      setChats(chatsList);
    } catch (e) {
      setChats([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadChats(); }, [user.phone, user.name]);

  const openWhatsApp = () => {
    const msg = lang === 'bn'
      ? 'আসসালামু আলাইকুম, আমি ধোপা বাড়ি অ্যাপ থেকে যোগাযোগ করছি।'
      : 'Hi, I am contacting from Dopa Bari app.';
    const url = `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(msg)}`;
    Linking.openURL(url);
  };

  return (
    <View style={styles.root}>
      {/* ── Header ── */}
      <View style={styles.header}>
        <View>
          <Text style={styles.title}>{t('messagesTitle')}</Text>
          <Text style={styles.subtitle}>{t('messagesSubtitle')}</Text>
        </View>
        <TouchableOpacity style={styles.refreshBtn} onPress={loadChats}>
          <Text style={styles.refreshBtnText}>{t('messagesUpdate')}</Text>
        </TouchableOpacity>
      </View>

      {/* ── WhatsApp Support Card ── */}
      <TouchableOpacity style={styles.waCard} onPress={openWhatsApp} activeOpacity={0.8}>
        <View style={styles.waLeft}>
          <View style={styles.waIconWrap}>
            <Text style={styles.waIcon}>💬</Text>
          </View>
          <View style={{ flex: 1 }}>
            <Text style={styles.waTitle}>
              {lang === 'bn' ? 'সাপোর্টে যোগাযোগ করুন' : 'Contact Support'}
            </Text>
            <Text style={styles.waSub}>
              {lang === 'bn' ? 'WhatsApp-এ সরাসরি হেড অফিসে কথা বলুন' : 'Chat directly with head office on WhatsApp'}
            </Text>
          </View>
        </View>
        <View style={styles.waBadge}>
          <Text style={styles.waBadgeText}>WhatsApp</Text>
        </View>
      </TouchableOpacity>

      {/* ── Chat List ── */}
      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.listContent}>
        {chats.length > 0 ? (
          chats.map(({ rider, order, lastMsg }) => (
            <TouchableOpacity
              key={order.id}
              style={styles.chatCard}
              onPress={() => router.push({
                pathname: '/chat',
                params: { orderId: order.id, riderId: rider.id }
              })}
              activeOpacity={0.8}
            >
              <View style={styles.avatarWrap}>
                <View style={styles.avatar}>
                  <Text style={styles.avatarText}>{rider.avatar}</Text>
                </View>
                <View style={styles.onlineDot} />
              </View>

              <View style={styles.chatBody}>
                <View style={styles.chatTop}>
                  <Text style={styles.riderName}>{rider.name}</Text>
                  <Text style={styles.orderTag}>#{order.id}</Text>
                </View>
                <Text style={styles.lastMsg} numberOfLines={1}>{lastMsg}</Text>
                <Text style={styles.statusRow}>
                  {t('messagesStatus')}
                  <Text style={styles.statusVal}> {order.status || t('ordersPending')}</Text>
                </Text>
              </View>

              <Text style={styles.arrow}>›</Text>
            </TouchableOpacity>
          ))
        ) : (
          <View style={styles.emptyCard}>
            <Text style={styles.emptyIcon}>💬</Text>
            <Text style={styles.emptyTitle}>
              {lang === 'bn' ? 'কোনো চলমান চ্যাট নেই' : 'No active chats'}
            </Text>
            <Text style={styles.emptySub}>
              {lang === 'bn' ? 'অর্ডার দিলে এখানে ডেলিভারি ম্যানের সাথে চ্যাট দেখাবে' : 'Order something to start chatting with the rider'}
            </Text>
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#f5f8fc' },

  // Header
  header: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-end',
    paddingHorizontal: 16, paddingTop: 16, paddingBottom: 10,
  },
  title: { fontSize: 22, fontWeight: '900', color: Colors.ink },
  subtitle: { fontSize: 12, color: Colors.muted, marginTop: 2 },
  refreshBtn: {
    paddingVertical: 6, paddingHorizontal: 14, borderRadius: 16,
    backgroundColor: '#fff', borderWidth: 1, borderColor: '#e5e9f0',
  },
  refreshBtnText: { color: Colors.muted, fontWeight: '700', fontSize: 12 },

  // WhatsApp support card
  waCard: {
    marginHorizontal: 16, marginBottom: 12,
    backgroundColor: '#dcfce7', borderRadius: 14, padding: 14,
    borderWidth: 1, borderColor: '#bbf7d0',
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    ...Shadows.card,
  },
  waLeft: { flexDirection: 'row', alignItems: 'center', gap: 10, flex: 1 },
  waIconWrap: {
    width: 42, height: 42, borderRadius: 21,
    backgroundColor: '#22c55e',
    justifyContent: 'center', alignItems: 'center',
  },
  waIcon: { fontSize: 20, color: '#fff' },
  waTitle: { fontSize: 14, fontWeight: '900', color: '#15803d', lineHeight: 18 },
  waSub: { fontSize: 11, color: '#166534', marginTop: 2, lineHeight: 15 },
  waBadge: {
    backgroundColor: '#22c55e', borderRadius: 8,
    paddingHorizontal: 8, paddingVertical: 4, marginLeft: 8,
  },
  waBadgeText: { color: '#fff', fontWeight: '900', fontSize: 10 },

  // List
  listContent: { paddingHorizontal: 16, paddingBottom: 90, gap: 10 },

  // Chat card
  chatCard: {
    backgroundColor: '#fff', borderRadius: 12, padding: 12,
    flexDirection: 'row', alignItems: 'center', gap: 12,
    borderWidth: 1, borderColor: '#e7edf6', ...Shadows.card,
  },

  // Avatar
  avatarWrap: { position: 'relative' },
  avatar: {
    width: 44, height: 44, borderRadius: 22,
    backgroundColor: Colors.blue, justifyContent: 'center', alignItems: 'center',
  },
  avatarText: { color: '#fff', fontSize: 18, fontWeight: '900' },
  onlineDot: {
    position: 'absolute', bottom: 0, right: 0,
    width: 12, height: 12, borderRadius: 6,
    backgroundColor: Colors.green, borderWidth: 2, borderColor: '#fff',
  },

  // Chat body
  chatBody: { flex: 1, gap: 2 },
  chatTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  riderName: { fontSize: 14, fontWeight: '900', color: Colors.ink },
  orderTag: {
    fontSize: 11, fontWeight: '700', color: Colors.blue,
    backgroundColor: '#eaf4ff', paddingHorizontal: 5, paddingVertical: 2, borderRadius: 5,
  },
  lastMsg: { fontSize: 12, color: Colors.muted },
  statusRow: { fontSize: 11, color: Colors.muted, marginTop: 1 },
  statusVal: { color: Colors.blue, fontWeight: '800' },
  arrow: { fontSize: 22, color: Colors.blue, fontWeight: '700' },

  // Empty
  emptyCard: {
    backgroundColor: '#fff', borderRadius: 14, borderWidth: 1,
    borderColor: '#e8edf5', padding: 28, alignItems: 'center', marginTop: 10,
  },
  emptyIcon: { fontSize: 36, marginBottom: 10 },
  emptyTitle: { fontSize: 16, fontWeight: '900', color: Colors.ink },
  emptySub: { fontSize: 12, color: Colors.muted, marginTop: 4, textAlign: 'center', lineHeight: 18 },
});
