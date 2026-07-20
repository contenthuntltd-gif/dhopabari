import React, { useEffect, useState, useRef } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, FlatList, KeyboardAvoidingView, Platform, Linking, Alert } from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { Colors, Shadows, ridersData } from '../constants/theme';
import { getMessages, sendMessage, getOrders } from '../services/api';
import { useLanguage } from '../services/language';

export default function ChatScreen() {
  const router = useRouter();
  const params = useLocalSearchParams();
  const orderId = (params.orderId as string) || 'ORD-1234';
  const riderId = (params.riderId as string) || 'rider_karim';

  const rider = ridersData[riderId] || ridersData.rider_karim;
  const { t, lang } = useLanguage();
  const [messages, setMessages] = useState<any[]>([]);
  const [inputText, setInputText] = useState('');
  const [orderStatus, setOrderStatus] = useState(t('workflowPending'));
  const [isTyping, setIsTyping] = useState(false);
  
  const flatListRef = useRef<FlatList>(null);

  // Load chat messages and order status
  const loadData = async () => {
    try {
      const msgs = await getMessages(orderId);
      setMessages(msgs);
      
      const orders = await getOrders();
      const order = orders.find((o: any) => o.id === orderId);
      if (order) {
        setOrderStatus(order.status);
      }
    } catch (e) {
      console.warn('Failed to load chat data');
    }
  };

  useEffect(() => {
    loadData();
    // Poll every 3 seconds to feel real-time
    const interval = setInterval(loadData, 3000);
    return () => clearInterval(interval);
  }, [orderId]);

  const handleCall = () => {
    const tel = `tel:${rider.phone}`;
    Linking.canOpenURL(tel)
      .then((supported) => {
        if (supported) {
          Linking.openURL(tel);
        } else {
          Alert.alert(t('chatCallFail'), `${t('chatRiderNumber')} ${rider.displayPhone}`);
        }
      })
      .catch(() => {
        Alert.alert(t('chatCallFail'), `${t('chatRiderNumber')} ${rider.displayPhone}`);
      });
  };

  // Get simulated context-aware rider response
  const getSimulatedRiderResponse = (userMsg: string, status: string): string => {
    const msg = userMsg.toLowerCase();
    const statusLower = (status || '').toLowerCase();

    if (msg.includes('কখন') || msg.includes('সময়') || msg.includes('kobe') || msg.includes('kokhon')) {
      if (statusLower.includes('পেন্ডিং')) {
        return t('chatRespPending');
      }
      if (statusLower.includes('সংগ্রহ')) {
        return t('chatRespCollect');
      }
      if (statusLower.includes('ধোয়া') || statusLower.includes('ওয়াশ')) {
        return t('chatRespWash');
      }
      if (statusLower.includes('প্রস্তুত') || statusLower.includes('রেডি')) {
        return t('chatRespReady');
      }
      if (statusLower.includes('সম্পন্ন')) {
        return t('chatRespDone');
      }
    }

    if (msg.includes('কোথায়') || msg.includes('kothay') || msg.includes('koe')) {
      if (statusLower.includes('সংগ্রহ')) {
        return t('chatRespLocCollect');
      }
      return t('chatRespLocDefault');
    }

    // Default responses based on status
    if (statusLower.includes('পেন্ডিং')) {
      return t('chatRespDefaultPending');
    }
    if (statusLower.includes('সংগ্রহ')) {
      return t('chatRespDefaultCollect');
    }
    if (statusLower.includes('ধোয়া') || statusLower.includes('ওয়াশ')) {
      return t('chatRespDefaultWash');
    }
    if (statusLower.includes('ডেলিভারি সম্পন্ন') || statusLower.includes('delivered')) {
      return t('chatRespDefaultDone');
    }

    return t('chatRespDefault');
  };

  const handleSend = async () => {
    if (!inputText.trim()) return;
    const textToSend = inputText.trim();
    setInputText('');

    try {
      // 1. Send customer message to server
      const newMsg = await sendMessage(orderId, textToSend, 'customer');
      setMessages((prev) => [...prev, newMsg]);
      
      // Scroll to bottom
      setTimeout(() => flatListRef.current?.scrollToEnd({ animated: true }), 100);

      // 2. Trigger rider typing and automatic response
      setIsTyping(true);
      setTimeout(async () => {
        setIsTyping(false);
        const replyText = getSimulatedRiderResponse(textToSend, orderStatus);
        
        try {
          const replyMsg = await sendMessage(orderId, replyText, 'rider');
          setMessages((prev) => [...prev, replyMsg]);
          setTimeout(() => flatListRef.current?.scrollToEnd({ animated: true }), 100);
        } catch (e) {
          console.warn('Failed to send simulated rider reply');
        }
      }, 1500); // 1.5 seconds typing simulation delay

    } catch (e) {
      Alert.alert(t('chatError'), t('chatSendFail'));
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 0}
    >
      {/* Custom Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.backBtn} onPress={() => router.back()} activeOpacity={0.7}>
          <Text style={styles.backBtnText}>‹</Text>
        </TouchableOpacity>

        <View style={styles.profileArea}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{rider.avatar}</Text>
          </View>
          <View style={styles.profileInfo}>
            <Text style={styles.riderName}>{rider.name}</Text>
            <View style={styles.statusRow}>
              <View style={styles.dot} />
              <Text style={styles.onlineText}>{t('chatOnline')} | {orderId}</Text>
            </View>
          </View>
        </View>

        <TouchableOpacity style={styles.callBtn} onPress={handleCall}>
          <Text style={styles.callIcon}>📞</Text>
        </TouchableOpacity>
      </View>

      {/* Message List */}
      <FlatList
        ref={flatListRef}
        data={messages}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => {
          const isCustomer = item.sender === 'customer';
          return (
            <View style={[styles.msgRow, isCustomer ? styles.msgRight : styles.msgLeft]}>
              <View style={[styles.bubble, isCustomer ? styles.bubbleCustomer : styles.bubbleRider]}>
                <Text style={[styles.msgText, isCustomer ? styles.textCustomer : styles.textRider]}>
                  {item.text}
                </Text>
                <Text style={[styles.timeText, isCustomer ? styles.timeCustomer : styles.timeRider]}>
                  {new Date(item.createdAt).toLocaleTimeString(lang === 'bn' ? 'bn-BD' : 'en-US', { hour: '2-digit', minute: '2-digit' })}
                </Text>
              </View>
            </View>
          );
        }}
        contentContainerStyle={styles.listContent}
        onContentSizeChange={() => flatListRef.current?.scrollToEnd({ animated: true })}
        onLayout={() => flatListRef.current?.scrollToEnd({ animated: true })}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyIcon}>💬</Text>
            <Text style={styles.emptyTitle}>{t('chatEmptyTitle')}</Text>
            <Text style={styles.emptySubtitle}>{t('chatEmptySub')}</Text>
          </View>
        }
      />

      {/* Typing Indicator */}
      {isTyping && (
        <View style={styles.typingBox}>
          <Text style={styles.typingText}>{rider.name} {t('chatTyping')}</Text>
        </View>
      )}

      {/* Input Bar */}
      <View style={styles.inputBar}>
        <TextInput
          style={styles.input}
          value={inputText}
          onChangeText={setInputText}
          placeholder={t('chatPlaceholder')}
          placeholderTextColor="#a2abb8"
          multiline
        />
        <TouchableOpacity style={styles.sendBtn} onPress={handleSend}>
          <Text style={styles.sendText}>{t('chatSend')}</Text>
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#f5f8fc' },
  header: {
    height: 72,
    backgroundColor: '#fff',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#e7edf6',
    ...Shadows.card,
  },
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
    marginRight: 8,
  },
  backBtnText: {
    fontSize: 22,
    fontWeight: '900',
    color: '#334155',
    lineHeight: 24,
    textAlign: 'center',
  },
  profileArea: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: 10 },
  avatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: Colors.blue,
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarText: { color: '#fff', fontSize: 18, fontWeight: '900' },
  profileInfo: { gap: 2 },
  riderName: { fontSize: 17, fontWeight: '900', color: Colors.ink },
  statusRow: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  dot: { width: 8, height: 8, borderRadius: 4, backgroundColor: Colors.green },
  onlineText: { fontSize: 12, color: Colors.muted, fontWeight: '600' },
  callBtn: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#f1f4f9',
    justifyContent: 'center',
    alignItems: 'center',
  },
  callIcon: { fontSize: 18 },
  listContent: { padding: 16, gap: 12, paddingBottom: 24 },
  msgRow: { flexDirection: 'row', width: '100%' },
  msgLeft: { justifyContent: 'flex-start' },
  msgRight: { justifyContent: 'flex-end' },
  bubble: {
    maxWidth: '80%',
    borderRadius: 16,
    paddingHorizontal: 16,
    paddingVertical: 10,
    gap: 4,
    ...Shadows.card,
  },
  bubbleCustomer: {
    backgroundColor: Colors.blue,
    borderTopRightRadius: 2,
  },
  bubbleRider: {
    backgroundColor: '#fff',
    borderTopLeftRadius: 2,
    borderWidth: 1,
    borderColor: '#e2e9f3',
  },
  msgText: { fontSize: 16, lineHeight: 22 },
  textCustomer: { color: '#fff' },
  textRider: { color: Colors.ink },
  timeText: { fontSize: 10, alignSelf: 'flex-end' },
  timeCustomer: { color: 'rgba(255,255,255,0.76)' },
  timeRider: { color: Colors.muted },
  typingBox: { paddingHorizontal: 20, paddingVertical: 6 },
  typingText: { fontSize: 13, color: Colors.muted, fontStyle: 'italic' },
  inputBar: {
    minHeight: 74,
    backgroundColor: '#fff',
    borderTopWidth: 1,
    borderTopColor: '#e7edf6',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
    gap: 12,
  },
  input: {
    flex: 1,
    minHeight: 44,
    maxHeight: 100,
    backgroundColor: '#f1f4f9',
    borderRadius: 22,
    paddingHorizontal: 18,
    paddingVertical: 10,
    fontSize: 16,
    color: Colors.ink,
  },
  sendBtn: {
    backgroundColor: Colors.blue,
    borderRadius: 22,
    paddingHorizontal: 20,
    height: 44,
    justifyContent: 'center',
    alignItems: 'center',
    ...Shadows.button,
  },
  sendText: { color: '#fff', fontSize: 16, fontWeight: '900' },
  emptyContainer: { flex: 1, alignItems: 'center', justifyContent: 'center', marginTop: 100, gap: 8 },
  emptyIcon: { fontSize: 50 },
  emptyTitle: { fontSize: 19, fontWeight: '900', color: Colors.ink },
  emptySubtitle: { fontSize: 14, color: Colors.muted, textAlign: 'center', paddingHorizontal: 40 },
});
