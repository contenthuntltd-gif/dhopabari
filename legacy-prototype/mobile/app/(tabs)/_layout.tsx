import { Tabs } from 'expo-router';
import { Text, StyleSheet } from 'react-native';
import { Colors } from '../../constants/theme';
import { useLanguage } from '../../services/language';

export default function TabsLayout() {
  const { t } = useLanguage();
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarStyle: styles.tabBar,
        tabBarActiveTintColor: Colors.blue,
        tabBarInactiveTintColor: '#687284',
        tabBarLabelStyle: styles.tabLabel,
      }}
    >
      <Tabs.Screen
        name="home"
        options={{
          title: t('tabHome'),
          tabBarIcon: ({ color }) => <Text style={[styles.tabIcon, { color }]}>⌂</Text>,
        }}
      />
      <Tabs.Screen
        name="orders"
        options={{
          title: t('tabOrders'),
          tabBarIcon: ({ color }) => <Text style={[styles.tabIcon, { color }]}>▣</Text>,
        }}
      />
      <Tabs.Screen
        name="messages"
        options={{
          title: t('tabMessages'),
          tabBarIcon: ({ color }) => <Text style={[styles.tabIcon, { color }]}>💬</Text>,
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: t('tabProfile'),
          tabBarIcon: ({ color }) => <Text style={[styles.tabIcon, { color }]}>♙</Text>,
        }}
      />
    </Tabs>
  );
}

const styles = StyleSheet.create({
  tabBar: {
    height: 62,
    backgroundColor: 'rgba(255,255,255,0.98)',
    borderTopWidth: 1,
    borderTopColor: Colors.line,
    paddingTop: 4,
    paddingBottom: 6,
  },
  tabIcon: { fontSize: 24, lineHeight: 28 },
  tabLabel: { fontSize: 12, fontWeight: '800' },
});

