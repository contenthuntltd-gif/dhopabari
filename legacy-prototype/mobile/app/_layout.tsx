import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { StoreProvider } from '../services/store';
import { LanguageProvider } from '../services/language';
import { View, Platform, StyleSheet } from 'react-native';
// import './global.css'; // temporarily disabled: lightningcss native binary fails to load on this machine (missing VC++ runtime), blocking web bundling

const PHONE_WIDTH = 430;

export default function RootLayout() {
  const isWeb = Platform.OS === 'web';
  return (
    <LanguageProvider>
      <StoreProvider>
        <StatusBar style="auto" />
        {isWeb ? (
          <View style={styles.webOuter}>
            <View style={styles.webInner}>
              <Stack
                screenOptions={{
                  headerShown: false,
                  animation: 'none',
                  contentStyle: { backgroundColor: '#ffffff' },
                }}
              >
                {/* ── Core user flow ── */}
                <Stack.Screen name="index" />
                <Stack.Screen name="login" />
                <Stack.Screen name="register" />
                <Stack.Screen name="forgot-password" />
                <Stack.Screen name="otp" />
                <Stack.Screen name="admin-login" />
                <Stack.Screen name="rider-login" />
                <Stack.Screen name="details" />
                <Stack.Screen name="welcome" />
                <Stack.Screen name="(tabs)" options={{ animation: 'fade' }} />
                <Stack.Screen name="order" />
                <Stack.Screen name="summary" />
                <Stack.Screen name="success" />
                <Stack.Screen name="tracking" />
                <Stack.Screen name="price-list" />
                <Stack.Screen name="chat" />

                {/* ── Admin panel ── */}
                <Stack.Screen name="admin-dashboard" />
                <Stack.Screen name="admin-customers" />
                <Stack.Screen name="admin-customer-profile" />
                <Stack.Screen name="admin-riders" />
                <Stack.Screen name="admin-rider-profile" />
                <Stack.Screen name="admin-pricing" />
                <Stack.Screen name="admin-reports" />

                {/* ── Rider panel ── */}
                <Stack.Screen name="rider-dashboard" />
              </Stack>
            </View>
          </View>
        ) : (
          <Stack
            screenOptions={{
              headerShown: false,
              animation: 'slide_from_right',
              contentStyle: { backgroundColor: '#ffffff' },
            }}
          >
            {/* ── Core user flow ── */}
            <Stack.Screen name="index" />
            <Stack.Screen name="login" />
            <Stack.Screen name="register" />
            <Stack.Screen name="forgot-password" />
            <Stack.Screen name="otp" />
            <Stack.Screen name="admin-login" />
            <Stack.Screen name="rider-login" />
            <Stack.Screen name="details" />
            <Stack.Screen name="welcome" />
            <Stack.Screen name="(tabs)" options={{ animation: 'fade' }} />
            <Stack.Screen name="order" />
            <Stack.Screen name="summary" />
            <Stack.Screen name="success" />
            <Stack.Screen name="tracking" />
            <Stack.Screen name="price-list" />
            <Stack.Screen name="chat" />

            {/* ── Admin panel ── */}
            <Stack.Screen name="admin-dashboard" />
            <Stack.Screen name="admin-customers" />
            <Stack.Screen name="admin-customer-profile" />
            <Stack.Screen name="admin-riders" />
            <Stack.Screen name="admin-rider-profile" />
            <Stack.Screen name="admin-pricing" />
            <Stack.Screen name="admin-reports" />

            {/* ── Rider panel ── */}
            <Stack.Screen name="rider-dashboard" />
          </Stack>
        )}
      </StoreProvider>
    </LanguageProvider>
  );
}

const styles = StyleSheet.create({
  webOuter: {
    flex: 1,
    backgroundColor: '#1a1a2e',
    alignItems: 'center',
    minHeight: '100vh' as any,
  },
  webInner: {
    width: '100%' as any,
    maxWidth: PHONE_WIDTH,
    flex: 1,
    backgroundColor: '#ffffff',
    overflow: 'hidden' as any,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.4,
    shadowRadius: 40,
  },
});
