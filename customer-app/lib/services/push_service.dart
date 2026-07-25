import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Firebase background message handler — must be a top-level function.
/// For notification-type messages Android renders the tray notification on
/// its own while the app is backgrounded/terminated, so there is nothing to
/// do here.
@pragma('vm:entry-point')
Future<void> _firebaseBgHandler(RemoteMessage message) async {}

/// Push notifications for the phone (FCM) — Android only. The web build never
/// touches Firebase. Registers this device's token against the signed-in user
/// so the server (`send-push` Edge Function) can target them when their order
/// status changes; shows a tray notification for foreground messages.
class PushService {
  PushService._();

  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'dhopabari_orders',
    'অর্ডার নোটিফিকেশন',
    description: 'নতুন অর্ডার ও স্ট্যাটাস আপডেট',
    importance: Importance.high,
  );

  static bool get _supported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /// One-time setup: Firebase, the notification channel, permission, listeners
  /// and the initial token registration. Safe to call when signed out (the
  /// token binds once the user logs in via [onLogin]).
  static Future<void> init() async {
    if (!_supported || _inited) return;
    _inited = true;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseBgHandler);

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _local.initialize(const InitializationSettings(android: androidInit));
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      await FirebaseMessaging.instance.requestPermission();
      FirebaseMessaging.onMessage.listen(_showForeground);

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await registerToken(token);
      FirebaseMessaging.instance.onTokenRefresh.listen(registerToken);
    } catch (e) {
      debugPrint('Push init failed: $e');
    }
  }

  static void _showForeground(RemoteMessage m) {
    final n = m.notification;
    final title = n?.title ?? (m.data['title'] as String?) ?? 'ধোপা বাড়ি';
    final body = n?.body ?? (m.data['body'] as String?) ?? '';
    _local.show(
      m.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Saves this device's token against the signed-in user. No-op when signed
  /// out or on an unsupported platform.
  static Future<void> registerToken(String token) async {
    if (!_supported) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await Supabase.instance.client.from('device_tokens').upsert(
        {'user_id': uid, 'token': token, 'platform': 'android'},
        onConflict: 'token',
      );
    } catch (e) {
      debugPrint('token register failed: $e');
    }
  }

  /// Re-bind this device's token to whoever just logged in.
  static Future<void> onLogin() async {
    if (!_supported) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await registerToken(token);
    } catch (_) {}
  }

  /// Drop this device's token on logout so a signed-out phone stops getting
  /// that user's pushes.
  static Future<void> onLogout() async {
    if (!_supported) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await Supabase.instance.client.from('device_tokens').delete().eq('token', token);
      }
    } catch (_) {}
  }
}
