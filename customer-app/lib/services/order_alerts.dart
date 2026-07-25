import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_globals.dart';
import '../data/admin_mock_data.dart';
import '../theme/app_theme.dart';
import 'language.dart';

/// Realtime order alerts for STAFF (admin + rider). While the panel is open,
/// a new order or an order status change plays a chime and pops an in-app
/// banner — so the shop notices instantly without refreshing.
///
/// Requires (one-time SQL): the `orders` table added to the `supabase_realtime`
/// publication with `replica identity full` (see migration 0011) so the old
/// status is available to detect a real status change.
class OrderAlerts {
  OrderAlerts._();

  static RealtimeChannel? _channel;
  static final AudioPlayer _player = AudioPlayer(playerId: 'order-alerts')
    ..setReleaseMode(ReleaseMode.stop);

  /// Staff can silence the chime (banners still show). In-memory, defaults on.
  static final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  /// Subscribes to order inserts/updates. Safe to call more than once.
  static void start() {
    if (_channel != null) return;
    final db = Supabase.instance.client;
    _channel = db.channel('order-alerts')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'orders',
        callback: _onInsert,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'orders',
        callback: _onUpdate,
      )
      ..subscribe();
  }

  /// Tears the subscription down (call on staff logout).
  static Future<void> stop() async {
    final ch = _channel;
    _channel = null;
    if (ch != null) {
      try {
        await Supabase.instance.client.removeChannel(ch);
      } catch (_) {}
    }
  }

  static void _onInsert(PostgresChangePayload payload) {
    final no = (payload.newRecord['order_no'] as String?)?.trim() ?? '';
    _alert(AppLanguage.tr('🔔 নতুন অর্ডার এসেছে'), no, AppColors.blue);
  }

  static void _onUpdate(PostgresChangePayload payload) {
    final oldS = payload.oldRecord['status'] as String?;
    final newS = payload.newRecord['status'] as String?;
    // Only a genuine status change is worth a chime (rider assignment,
    // updated_at bumps, etc. are ignored).
    if (newS == null || oldS == newS) return;
    final no = (payload.newRecord['order_no'] as String?)?.trim() ?? '';
    final label = AdminMockData.orderStatusesBn[newS] ?? newS;
    final color = newS == 'Cancelled' ? AppColors.danger : AppColors.teal;
    _alert('${AppLanguage.tr('🔔 অর্ডার আপডেট')}: $label', no, color);
  }

  static void _alert(String title, String subtitle, Color color) {
    _playChime();
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          subtitle.isEmpty ? title : '$title  •  $subtitle',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static Future<void> _playChime() async {
    if (muted.value) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/ding.wav'));
    } catch (_) {
      // Audio can be blocked (e.g. web autoplay before interaction) — the
      // banner still shows, so a silent failure is fine.
    }
  }
}
