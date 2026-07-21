import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/admin_mock_data.dart';
import 'auth_service.dart';

/// Real Supabase-backed data for the admin panel and rider app, replacing
/// the in-memory [AdminMockData] lists.
///
/// What each role may do is enforced by Row Level Security in the database
/// (supabase/migrations/0002_orders_and_staff.sql), not here — the checks in
/// this file only shape the UI. A blocked or non-staff account gets an empty
/// result from the server no matter what the client asks for.
class AdminService {
  static SupabaseClient get _db => Supabase.instance.client;

  static String? get _uid => _db.auth.currentUser?.id;

  // ----- Role -----

  static String? _cachedRole;
  static String? _cachedRoleUid;

  /// The signed-in user's role ('admin' | 'rider' | 'customer'), or null if
  /// signed out. Cached per-user: switching accounts invalidates the cache
  /// automatically, so a customer can never inherit a previous admin
  /// session's cached role (or vice versa).
  static Future<String?> currentRole() async {
    final id = _uid;
    if (id == null) return null;
    if (_cachedRole != null && _cachedRoleUid == id) return _cachedRole;
    final row = await _db.from('profiles').select('role').eq('id', id).maybeSingle();
    _cachedRoleUid = id;
    return _cachedRole = row?['role'] as String?;
  }

  static void clearRoleCache() {
    _cachedRole = null;
    _cachedRoleUid = null;
  }

  static Future<bool> get isStaff async {
    final r = await currentRole();
    return r == 'admin' || r == 'rider';
  }

  static Future<bool> get isAdmin async => await currentRole() == 'admin';

  // ----- Customers -----

  /// Every customer, with order count and lifetime spend, newest first.
  /// [search] matches name or phone.
  static Future<List<AdminCustomer>> customers({String? search}) async {
    var query = _db.from('customer_summary').select().eq('role', 'customer');

    final q = search?.trim() ?? '';
    if (q.isNotEmpty) {
      // Escape PostgREST's or() delimiters so a comma or paren in the search
      // box cannot break out of the filter expression.
      final safe = q.replaceAll(RegExp(r'[,()]'), ' ');
      query = query.or('name.ilike.%$safe%,phone.ilike.%$safe%');
    }

    final rows = await query.order('created_at', ascending: false);
    return (rows as List).map((r) => AdminCustomer.fromRow(r)).toList();
  }

  /// The signed-in user's own summary row (used by the rider dashboard).
  static Future<AdminCustomer?> me() async {
    final id = _uid;
    return id == null ? null : customerById(id);
  }

  static Future<AdminCustomer?> customerById(String id) async {
    final row = await _db.from('customer_summary').select().eq('id', id).maybeSingle();
    return row == null ? null : AdminCustomer.fromRow(row);
  }

  /// Creates a login-capable account (phone + password) for someone else.
  ///
  /// Routed through the `admin-create-user` Edge Function because setting
  /// another user's password needs the service_role key, which must never
  /// ship inside this app. Throws [AdminServiceException] with a
  /// Bengali message suitable for showing to the user.
  static Future<AdminCustomer> createUser({
    required String name,
    required String phone,
    required String password,
    String role = 'customer',
    String? area,
    String? localAddress,
    String? whatsappNumber,
  }) async {
    try {
      final res = await _db.functions.invoke('admin-create-user', body: {
        'name': name,
        'phone': phone,
        'password': password,
        'role': role,
        'area': area ?? '',
        'local_address': localAddress ?? '',
        'whatsapp_number': whatsappNumber ?? '',
      });

      final data = res.data;
      if (data is Map && data['user'] != null) {
        return AdminCustomer.fromRow(Map<String, dynamic>.from(data['user']));
      }
      throw AdminServiceException(_errorFrom(data) ?? 'অ্যাকাউন্ট তৈরি করা যায়নি');
    } on FunctionException catch (e) {
      throw AdminServiceException(
        _errorFrom(e.details) ?? 'অ্যাকাউন্ট তৈরি করা যায়নি (${e.status})',
      );
    }
  }

  static String? _errorFrom(dynamic details) {
    if (details is Map && details['error'] is String) return details['error'] as String;
    if (details is String && details.isNotEmpty) return details;
    return null;
  }

  /// Sets a new password for [userId]. There is no self-service reset: the
  /// accounts use a pseudo-email that receives no mail, so the shop sets the
  /// password and tells the customer.
  static Future<void> setPassword(String userId, String password) async {
    await _manage({'action': 'set_password', 'user_id': userId, 'password': password});
  }

  /// Deletes the auth account; the profile and its orders cascade with it.
  static Future<void> deleteUser(String userId) async {
    await _manage({'action': 'delete', 'user_id': userId});
  }

  static Future<void> _manage(Map<String, dynamic> body) async {
    try {
      final res = await _db.functions.invoke('admin-manage-user', body: body);
      final data = res.data;
      if (data is Map && data['ok'] == true) return;
      throw AdminServiceException(_errorFrom(data) ?? 'কাজটি সম্পন্ন করা যায়নি');
    } on FunctionException catch (e) {
      throw AdminServiceException(
        _errorFrom(e.details) ?? 'কাজটি সম্পন্ন করা যায়নি (${e.status})',
      );
    }
  }

  static Future<void> setBlocked(String customerId, bool blocked) async {
    await _db.from('profiles').update({'blocked': blocked}).eq('id', customerId);
  }

  static Future<void> updateCustomer({
    required String id,
    String? name,
    String? area,
    String? localAddress,
    String? whatsappNumber,
  }) async {
    await _db.from('profiles').update({
      if (name != null) 'name': name,
      if (area != null) 'area': area,
      if (localAddress != null) 'local_address': localAddress,
      if (whatsappNumber != null) 'whatsapp_number': whatsappNumber,
    }).eq('id', id);
  }

  // ----- Riders -----

  static Future<List<AdminRider>> riders() async {
    final rows = await _db
        .from('customer_summary')
        .select()
        .eq('role', 'rider')
        .order('created_at', ascending: false);
    return (rows as List).map((r) => AdminRider.fromRow(r)).toList();
  }

  // ----- Orders -----

  /// Orders, newest first. Filter by [customerId] for one user's history or
  /// [riderId] for a rider's workload. Staff see all; a customer's RLS
  /// silently narrows this to their own rows.
  static Future<List<AdminOrder>> orders({
    String? customerId,
    String? riderId,
    String? status,
    int limit = 200,
  }) async {
    var query = _db.from('orders').select(
      '*, customer:customer_id(name, phone), rider:rider_id(name, phone)',
    );

    if (customerId != null) query = query.eq('customer_id', customerId);
    if (riderId != null) query = query.eq('rider_id', riderId);
    if (status != null) query = query.eq('status', status);

    try {
      final rows = await query.order('created_at', ascending: false).limit(limit);
      return (rows as List).map((r) => AdminOrder.fromRow(r)).toList();
    } on PostgrestException catch (e) {
      // 42P01: the orders table hasn't been created yet (migration 0002
      // not applied). To a customer that is simply "no orders yet" — an
      // error screen would punish them for a pending server setup step.
      if (e.code == '42P01') return const [];
      rethrow;
    }
  }

  /// Places an order. Omit [customerId] for a customer ordering for
  /// themselves; pass it when staff order on someone's behalf — either way
  /// `placed_by` records who actually entered it, so the order lands in that
  /// customer's history.
  static Future<AdminOrder> createOrder({
    String? customerId,
    required String service,
    String? category,
    required List<Map<String, dynamic>> items,
    required int pieces,
    required int total,
    String? address,
    String? area,
    String paymentMethod = 'Cash on Delivery',
    String? note,
  }) async {
    final me = _uid;
    if (me == null) throw AdminServiceException('আপনি লগইন করা নেই');

    final row = await _db
        .from('orders')
        .insert({
          'customer_id': customerId ?? me,
          'placed_by': me,
          'service': service,
          if (category != null) 'category': category,
          'items': items,
          'pieces': pieces,
          'total': total,
          if (address != null) 'address': address,
          if (area != null) 'area': area,
          'payment_method': paymentMethod,
          if (note != null && note.isNotEmpty) 'note': note,
        })
        .select('*, customer:customer_id(name, phone), rider:rider_id(name, phone)')
        .single();

    return AdminOrder.fromRow(row);
  }

  /// Places an order for a customer who is NOT logged in. Collects their
  /// name/phone/address, and via the `guest-order` Edge Function creates (or
  /// reuses) an account for that phone and saves the order — no password the
  /// customer has to choose. The device is then silently signed in as that
  /// account, so they immediately have a session and can see their order.
  static Future<AdminOrder> guestOrder({
    required String name,
    required String phone,
    required String address,
    String? area,
    required String service,
    String? category,
    required List<Map<String, dynamic>> items,
    required int pieces,
    required int total,
    String paymentMethod = 'Cash on Delivery',
    String? note,
  }) async {
    try {
      final res = await _db.functions.invoke('guest-order', body: {
        'name': name,
        'phone': phone,
        'address': address,
        'area': area ?? '',
        'service': service,
        'category': category ?? '',
        'items': items,
        'pieces': pieces,
        'total': total,
        'payment_method': paymentMethod,
        'note': note ?? '',
      });

      final data = res.data;
      if (data is Map && data['order'] != null) {
        final ph = data['phone'] as String?;
        final pw = data['password'] as String?;
        if (ph != null && pw != null) {
          // Best-effort silent sign-in; the order is already saved even if
          // this fails, so never let it break the success flow.
          try {
            await AuthService.signInWithPassword(phone: ph, password: pw);
          } catch (_) {}
        }
        clearRoleCache();
        return AdminOrder.fromRow(Map<String, dynamic>.from(data['order']));
      }
      throw AdminServiceException(_errorFrom(data) ?? 'অর্ডার করা যায়নি');
    } on FunctionException catch (e) {
      throw AdminServiceException(
        _errorFrom(e.details) ?? 'অর্ডার করা যায়নি (${e.status})',
      );
    }
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.from('orders').update({'status': status}).eq('id', orderId);
  }

  static Future<void> assignRider(String orderId, String? riderId) async {
    await _db.from('orders').update({'rider_id': riderId}).eq('id', orderId);
  }

  // ----- Dashboard -----

  /// Loads every order's timestamp/total/status plus the customer & rider
  /// head-counts. All period aggregation (today / week / month / year /
  /// custom) is then done client-side from [DashboardStats.entries], so the
  /// period selector never triggers another round trip.
  static Future<DashboardStats> dashboardStats() async {
    final rows = await _db.from('orders').select('status, total, created_at');
    final list = (rows as List).cast<Map<String, dynamic>>();

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final entries = <OrderEntry>[];
    // Revenue for each of the last 7 days, oldest first — index 6 is today.
    final weekly = List<int>.filled(7, 0);
    final weekLabels = <String>[];
    for (var i = 6; i >= 0; i--) {
      weekLabels.add(_weekdayBn(startOfDay.subtract(Duration(days: i)).weekday));
    }

    for (final o in list) {
      final status = o['status'] as String? ?? 'Confirmed';
      final created = DateTime.tryParse(o['created_at'] as String? ?? '')?.toLocal();
      final total = (o['total'] as num?)?.toInt() ?? 0;
      if (created == null) continue;
      entries.add(OrderEntry(at: created, total: total, status: status));

      if (status == 'Cancelled') continue;
      final daysAgo = startOfDay.difference(DateTime(created.year, created.month, created.day)).inDays;
      if (daysAgo >= 0 && daysAgo < 7) weekly[6 - daysAgo] += total;
    }

    final customerCount = await _count('customer');
    final riderCount = await _count('rider');

    return DashboardStats(
      entries: entries,
      totalCustomers: customerCount,
      totalRiders: riderCount,
      revenueSeries: weekly,
      revenueLabels: weekLabels,
    );
  }

  static String _weekdayBn(int weekday) {
    const names = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'];
    return names[weekday - 1];
  }

  /// Turns any thrown error into something worth showing a shop owner.
  /// Postgres/PostgREST messages are English and reference table names, so
  /// they are mapped rather than surfaced raw.
  static String messageFor(Object error) {
    if (error is AdminServiceException) return error.message;
    if (error is PostgrestException) {
      final code = error.code ?? '';
      if (code == '42501' || code == 'PGRST301') {
        return 'এই তথ্য দেখার অনুমতি নেই — আবার লগইন করুন';
      }
      if (code == '23505') return 'এই তথ্য ইতিমধ্যে সংরক্ষিত আছে';
      if (code == '42P01') {
        // A required table/view doesn't exist yet — server setup pending.
        return 'ডাটাবেস সেটআপ এখনো সম্পন্ন হয়নি — supabase ফোল্ডারের মাইগ্রেশনগুলো (0002–0004) SQL Editor-এ চালান';
      }
      return 'সার্ভার থেকে তথ্য আনা যায়নি';
    }
    if (error is AuthException) return 'সেশন শেষ হয়ে গেছে — আবার লগইন করুন';
    return 'তথ্য লোড করা যায়নি — ইন্টারনেট সংযোগ দেখুন';
  }

  static Future<int> _count(String role) async {
    final res = await _db.from('profiles').select('id').eq('role', role).count();
    return res.count;
  }
}

/// One order reduced to the fields the dashboard aggregates over.
class OrderEntry {
  final DateTime at;
  final int total;
  final String status;
  const OrderEntry({required this.at, required this.total, required this.status});
}

/// The date window a dashboard is showing.
enum DashPeriod { today, week, month, year, custom }

/// Aggregated numbers for one period.
class PeriodStats {
  final int revenue;
  final int orders;
  final Map<String, int> byStatus;
  const PeriodStats({required this.revenue, required this.orders, required this.byStatus});

  int status(String s) => byStatus[s] ?? 0;
  int get avgOrderValue => orders == 0 ? 0 : (revenue / orders).round();
}

class DashboardStats {
  /// Every order (any status) as a light entry, for client-side period math.
  final List<OrderEntry> entries;
  final int totalCustomers;
  final int totalRiders;

  /// Revenue for the last 7 days, oldest first, with matching day labels.
  final List<int> revenueSeries;
  final List<String> revenueLabels;

  const DashboardStats({
    required this.entries,
    required this.totalCustomers,
    required this.totalRiders,
    required this.revenueSeries,
    required this.revenueLabels,
  });

  /// The [start, end) window for a preset period, relative to now.
  /// `custom` returns the caller-supplied [customStart]/[customEnd].
  ({DateTime start, DateTime? end}) rangeFor(
    DashPeriod period, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    switch (period) {
      case DashPeriod.today:
        return (start: startOfDay, end: null);
      case DashPeriod.week:
        return (start: startOfDay.subtract(const Duration(days: 6)), end: null);
      case DashPeriod.month:
        return (start: DateTime(now.year, now.month), end: null);
      case DashPeriod.year:
        return (start: DateTime(now.year), end: null);
      case DashPeriod.custom:
        return (
          start: customStart ?? startOfDay,
          // Include the whole end day.
          end: customEnd == null ? null : DateTime(customEnd.year, customEnd.month, customEnd.day).add(const Duration(days: 1)),
        );
    }
  }

  /// Revenue, order count and per-status counts within [start, end).
  /// Cancelled orders are counted in [byStatus] but excluded from revenue
  /// and the order count.
  PeriodStats forRange(DateTime start, DateTime? end) {
    var revenue = 0, orders = 0;
    final byStatus = <String, int>{};
    for (final e in entries) {
      if (e.at.isBefore(start)) continue;
      if (end != null && !e.at.isBefore(end)) continue;
      byStatus[e.status] = (byStatus[e.status] ?? 0) + 1;
      if (e.status == 'Cancelled') continue;
      revenue += e.total;
      orders++;
    }
    return PeriodStats(revenue: revenue, orders: orders, byStatus: byStatus);
  }
}

/// An error with a message already written for the user, in Bengali.
class AdminServiceException implements Exception {
  final String message;
  const AdminServiceException(this.message);
  @override
  String toString() => message;
}
