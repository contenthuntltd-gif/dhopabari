import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../data/admin_mock_data.dart';
import '../data/cart.dart';
import '../data/mock_data.dart';
import '../services/admin_service.dart';
import '../widgets/bn_number.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/fade_slide_in.dart';

import '../widgets/app_page_route.dart';
import '../widgets/app_logo.dart';
import '../services/auth_service.dart';
import '../services/language.dart';
import '../widgets/support_fab.dart';
import 'tracking_screen.dart';
import 'orders_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onStartNewOrder;
  final void Function(String service) onStartNewOrderWithService;
  final void Function(int tabIndex) onSwitchTab;
  const HomeScreen({
    super.key,
    required this.onStartNewOrder,
    required this.onStartNewOrderWithService,
    required this.onSwitchTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;

  /// The signed-in user's real orders (own rows only, via RLS). Signed-out
  /// preview falls back to the demo list.
  List<MockOrder> _orders = const [];

  @override
  void initState() {
    super.initState();
    _load();
    // A successful order clears the cart — that's our cue to refetch so
    // the new order appears as "চলমান" the moment the user lands back here.
    Cart.revision.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    Cart.revision.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted && Cart.isEmpty) _load();
  }

  Future<void> _load() async {
    try {
      if (AuthService.isLoggedIn) {
        final rows = await AdminService.orders(limit: 25);
        _orders = rows.map((o) => o.toMockOrder()).toList();
      } else {
        _orders = MockData.recentOrders;
      }
    } catch (_) {
      // Home must render even offline — keep whatever we had.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refresh() => _load();

  /// The most recent order still in progress, or null → empty-state card.
  MockOrder? get _ongoing {
    for (final o in _orders) {
      if (o.progress < 1 && o.currentStatusLabel != 'অর্ডার বাতিল হয়েছে') return o;
    }
    return null;
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(AppLanguage.tr('মেনু'), style: AppText.h1),
            const SizedBox(height: 10),
            _menuTile(Icons.person_rounded, AppLanguage.tr('প্রোফাইল'), () {
              Navigator.pop(context);
              widget.onSwitchTab(4);
            }),
            _menuTile(Icons.list_alt_rounded, AppLanguage.tr('আমার অর্ডার'), () {
              Navigator.pop(context);
              widget.onSwitchTab(1);
            }),
            _menuTile(Icons.chat_bubble_rounded, AppLanguage.tr('চ্যাট'), () {
              Navigator.pop(context);
              widget.onSwitchTab(3);
            }),
            _menuTile(Icons.support_agent_rounded, AppLanguage.tr('সাপোর্ট (WhatsApp)'), () {
              Navigator.pop(context);
              launchUrl(
                Uri.parse('https://wa.me/8801700000000'),
                mode: LaunchMode.externalApplication,
              );
            }),
            _menuTile(Icons.logout_rounded, AppLanguage.tr('লগআউট'), () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                AppPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            }, danger: true),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: danger ? AppColors.danger : AppColors.muted,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: danger ? AppColors.danger : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('নোটিফিকেশন', style: AppText.h1),
            const SizedBox(height: 14),
            _notifTile(
              '🧺',
              'আপনার অর্ডার ওয়াশ হচ্ছে',
              'অর্ডার #DB123456 এখন ওয়াশ ধাপে আছে',
              '১০ মিনিট আগে',
            ),
            _notifTile(
              '🎁',
              'নতুন অফার!',
              'প্রথম অর্ডারে পান ১০% পর্যন্ত ছাড়',
              '২ ঘন্টা আগে',
            ),
            _notifTile(
              '✅',
              'ডেলিভারি সম্পন্ন',
              'অর্ডার #DB123401 সফলভাবে ডেলিভারি হয়েছে',
              'গতকাল',
            ),
          ],
        ),
      ),
    );
  }

  Widget _notifTile(String emoji, String title, String subtitle, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.blueSoft,
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h3),
                Text(subtitle, style: AppText.caption),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOffers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('চলমান অফার', style: AppText.h1),
            const SizedBox(height: 14),
            _offerTile('🎉', 'FIRST10', 'প্রথম অর্ডারে ১০% পর্যন্ত ছাড়', AppColors.amberSoft, AppColors.amber),
            const SizedBox(height: 10),
            _offerTile('🚚', 'ফ্রি ডেলিভারি', 'সবসময় ফ্রি পিকআপ ও ডেলিভারি', AppColors.tealSoft, AppColors.teal),
          ],
        ),
      ),
    );
  }

  Widget _offerTile(String emoji, String code, String subtitle, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: fg)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ongoing = _ongoing;
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isEnglish,
      builder: (context, _, _) => Stack(
      children: [
      SafeArea(
        child: RefreshIndicator(
        color: AppColors.blue,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpace.sm,
            AppSpace.xs,
            AppSpace.sm,
            AppSpace.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _iconTapTarget(
                    icon: Icons.menu_rounded,
                    tooltip: AppLanguage.tr('মেনু'),
                    onTap: _showMenu,
                  ),
                  const AppLogo(size: 46),
                  Semantics(
                    button: true,
                    label: AppLanguage.tr('নোটিফিকেশন, ৩ টি নতুন'),
                    child: PressableScale(
                      onTap: _showNotifications,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.line),
                              boxShadow: AppShadows.soft,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: AppColors.ink,
                              size: AppIconSize.lg,
                            ),
                          ),
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 17,
                                minHeight: 17,
                              ),
                              child: const Text(
                                '৩',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Text(
                    AppLanguage.tr('স্বাগতম, '),
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      MockData.userName.split(' ').first,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Text(' 👋', style: TextStyle(fontSize: 15)),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.blue,
                    size: AppIconSize.sm,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      MockData.userArea,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              _LoyaltyStrip(
                completedOrders: _orders
                    .where((o) => o.progress >= 1)
                    .length,
              ),
              const SizedBox(height: AppSpace.sm),
              FadeSlideIn(
                child: _HeroBanner(onOrderNow: widget.onStartNewOrder),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(AppLanguage.tr('সার্ভিস বাছাই করে অর্ডার করুন'), style: AppText.h2),
              const SizedBox(height: 2),
              Text(
                AppLanguage.tr('মাত্র ২ ধাপে আপনার কাপড় আমাদের কাছে পৌঁছে দিন'),
                style: AppText.bodyMuted,
              ),
              const SizedBox(height: AppSpace.xs),
              FadeSlideIn(
                delayMs: 60,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ServiceCard(
                          titleBn: AppLanguage.tr('ওয়াশ'),
                          colors: const [AppColors.blue, AppColors.blueDeep],
                          icon: Icons.local_laundry_service_rounded,
                          onTap: () => widget.onStartNewOrderWithService('Wash'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ServiceCard(
                          titleBn: AppLanguage.tr('ড্রাই ক্লিন'),
                          colors: const [AppColors.teal, Color(0xFF0C8B85)],
                          icon: Icons.dry_cleaning_rounded,
                          onTap: () =>
                              widget.onStartNewOrderWithService('Dry Clean'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // The running-order card appears ONLY while an order is
              // actually in progress — no header, no empty placeholder.
              // A quiet home stays compact instead of showing a dead card.
              if (!_loading && ongoing != null) ...[
                const SizedBox(height: AppSpace.sm),
                FadeSlideIn(
                  delayMs: 80,
                  child: _OngoingOrderCard(
                    order: ongoing,
                    onTap: () => Navigator.push(
                      context,
                      AppPageRoute(
                        builder: (_) => TrackingScreen(order: ongoing),
                      ),
                    ),
                  ),
                ),
              ],
              if (_orders.length > 1) ...[
                const SizedBox(height: AppSpace.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLanguage.tr('সাম্প্রতিক অর্ডার'), style: AppText.h2),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        AppPageRoute(builder: (_) => const OrdersScreen()),
                      ),
                      child: Text(
                        AppLanguage.tr('সবগুলো দেখুন →'),
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ..._orders
                    .skip(1)
                    .take(2)
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (entry) => FadeSlideIn(
                        delayMs: 100 + entry.key * 40,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.xs),
                          child: _RecentOrderRow(
                            order: entry.value,
                            onTap: () => Navigator.push(
                              context,
                              AppPageRoute(
                                builder: (_) =>
                                    TrackingScreen(order: entry.value),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: AppSpace.sm),
              Text(AppLanguage.tr('কুইক অ্যাকশন'), style: AppText.h2),
              const SizedBox(height: AppSpace.xs),
              FadeSlideIn(
                delayMs: 100,
                child: _QuickActions(
                  onTrackOrder: () {
                    final ongoing = _ongoing;
                    Navigator.push(
                      context,
                      AppPageRoute(
                        builder: (_) => ongoing != null ? TrackingScreen(order: ongoing) : const OrdersScreen(),
                      ),
                    );
                  },
                  onChatSupport: () => widget.onSwitchTab(3),
                  onOrderHistory: () => Navigator.push(context, AppPageRoute(builder: (_) => const OrdersScreen())),
                  onOffers: _showOffers,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
      const Positioned(bottom: 16, right: 16, child: SupportFab()),
      ],
      ),
    );
  }

  Widget _iconTapTarget({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: AppColors.ink, size: 22),
          ),
        ),
      ),
    );
  }
}

/// Small stat strip under the greeting — total completed orders.
class _LoyaltyStrip extends StatelessWidget {
  final int completedOrders;
  const _LoyaltyStrip({required this.completedOrders});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pill(Icons.local_laundry_service_rounded, '${toBn(completedOrders)} ${AppLanguage.tr('সম্পন্ন অর্ডার')}', AppColors.blue, AppColors.blueSoft),
      ],
    );
  }

  Widget _pill(IconData icon, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

/// Row of 4 shortcut tiles to the most common next actions — spares the
/// user a trip through the bottom nav / hamburger menu for the things
/// they reach for most right after opening the app.
class _QuickActions extends StatelessWidget {
  final VoidCallback onTrackOrder;
  final VoidCallback onChatSupport;
  final VoidCallback onOrderHistory;
  final VoidCallback onOffers;
  const _QuickActions({
    required this.onTrackOrder,
    required this.onChatSupport,
    required this.onOrderHistory,
    required this.onOffers,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _tile(Icons.location_searching_rounded, AppLanguage.tr('ট্র্যাক অর্ডার'), AppColors.blue, onTrackOrder)),
        const SizedBox(width: 10),
        Expanded(child: _tile(Icons.support_agent_rounded, AppLanguage.tr('চ্যাট সাপোর্ট'), AppColors.teal, onChatSupport)),
        const SizedBox(width: 10),
        Expanded(child: _tile(Icons.history_rounded, AppLanguage.tr('অর্ডার ইতিহাস'), AppColors.blue, onOrderHistory)),
        const SizedBox(width: 10),
        Expanded(child: _tile(Icons.local_offer_rounded, AppLanguage.tr('অফার'), AppColors.amber, onOffers)),
      ],
    );
  }

  Widget _tile(IconData icon, String label, Color color, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.line),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home hero — leads with the brand (logo + tagline) then showcases the
/// two perks every order already gets: free pickup and free delivery.
/// Replaces the old "আজই আপনার কাপড় দিন" promo card.
class _HeroBanner extends StatefulWidget {
  final VoidCallback onOrderNow;
  const _HeroBanner({required this.onOrderNow});

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue, AppColors.blueDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -22,
            top: -22,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const AppLogo(size: 40),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLanguage.tr('ধোপা বাড়ি'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'কাপড়ের যত্নে আপনার বিশ্বস্ত পার্টনার',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _perkTile(
                      icon: Icons.inventory_2_rounded,
                      label: AppLanguage.tr('ফ্রি পিকআপ'),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white.withValues(alpha: 0.2),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  Expanded(
                    child: _perkTile(
                      icon: Icons.local_shipping_rounded,
                      label: AppLanguage.tr('ফ্রি ডেলিভারি'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedBuilder(
                animation: _glow,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(
                            alpha: 0.25 + _glow.value * 0.2,
                          ),
                          blurRadius: 18 + _glow.value * 10,
                          spreadRadius: _glow.value * 1.5,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapCancel: () => setState(() => _pressed = false),
                  onTapUp: (_) => setState(() => _pressed = false),
                  child: AnimatedScale(
                    scale: _pressed ? 0.97 : 1.0,
                    duration: AppMotion.fast,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF2F6FF)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: widget.onOrderNow,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_circle_rounded, size: 20, color: AppColors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  AppLanguage.tr('এখনই অর্ডার করুন'),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.blue),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _perkTile({required IconData icon, required String label}) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String titleBn;
  final List<Color> colors;
  final IconData icon;
  final VoidCallback onTap;
  const _ServiceCard({
    required this.titleBn,
    required this.colors,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$titleBn সার্ভিস',
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors[0].withValues(alpha: 0.08),
                colors[0].withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: colors[0].withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 23),
              ),
              const SizedBox(height: 12),
              Text(
                titleBn,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: colors[0],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: colors[0],
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLanguage.tr('অর্ডার করুন'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OngoingOrderCard extends StatelessWidget {
  final MockOrder order;
  final VoidCallback onTap;
  const _OngoingOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'চলমান অর্ডার ${order.id}, অবস্থা: ${order.currentStatusLabel}',
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'অর্ডার ${order.id}',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blueSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.currentStatusLabel,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.blue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                order.date,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${order.service} • ${toBn(order.pieces)} পিস',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.blue,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      order.area,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (order.riderName != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: Row(
                    children: [
                      const Icon(Icons.two_wheeler_rounded, size: 14, color: AppColors.teal),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          order.riderName!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (order.etaLabel != null) ...[
                        const Icon(Icons.schedule_rounded, size: 12, color: AppColors.teal),
                        const SizedBox(width: 3),
                        Text(order.etaLabel!, style: const TextStyle(fontSize: 10.5, color: AppColors.teal, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: order.progress),
                  duration: const Duration(milliseconds: 700),
                  curve: AppMotion.curve,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: AppColors.line,
                    valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Compact single-line summary for a past order, used in the Home screen's
/// "সাম্প্রতিক অর্ডার" preview (full history lives on the Orders screen).
class _RecentOrderRow extends StatelessWidget {
  final MockOrder order;
  final VoidCallback onTap;
  const _RecentOrderRow({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final delivered = order.progress >= 1.0;
    return Semantics(
      button: true,
      label: 'অর্ডার ${order.id}, ${order.currentStatusLabel}',
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpace.xs),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: delivered ? AppColors.tealSoft : AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  delivered
                      ? Icons.check_circle_rounded
                      : Icons.local_laundry_service_rounded,
                  color: delivered ? AppColors.teal : AppColors.blue,
                  size: AppIconSize.md,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.service} • ${toBn(order.pieces)} পিস',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.date,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                money(order.total),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: AppIconSize.md,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Replaces the old referral/10%-off card — the business no longer runs
/// that promo, so instead this spotlights the one perk every order
/// already gets: free pickup and delivery.
