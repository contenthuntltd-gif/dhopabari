import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../data/admin_mock_data.dart';
import '../data/cart.dart';
import '../data/catalog.dart';
import '../data/mock_data.dart';
import '../widgets/laundry_icons.dart';
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
        // Guest: no orders to show yet (no demo data).
        _orders = const [];
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
            // Guests see "লগইন" (optional); signed-in users see "লগআউট".
            if (AuthService.isLoggedIn)
              _menuTile(Icons.logout_rounded, AppLanguage.tr('লগআউট'), () async {
                Navigator.pop(context);
                await AuthService.logout();
                if (!mounted) return;
                setState(() {}); // back to guest home
              }, danger: true)
            else
              _menuTile(Icons.login_rounded, AppLanguage.tr('লগইন / অ্যাডমিন'), () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  AppPageRoute(builder: (_) => const LoginScreen()),
                );
              }),
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
                  Semantics(
                    button: true,
                    label: AppLanguage.tr('নোটিফিকেশন'),
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
              const FadeSlideIn(child: _HeroBanner()),
              const SizedBox(height: AppSpace.sm),
              // Inline quick-order: pick Wash / Dry Clean, browse the items
              // for that service and add them straight to the cart. Checkout
              // (address + confirm) happens on the New Order screen.
              FadeSlideIn(
                delayMs: 60,
                child: _QuickOrderSection(onCheckout: widget.onStartNewOrder),
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

/// Inline quick-order for the home page: pick Wash / Dry Clean, browse that
/// service's items by category, and tap "যোগ" to drop them straight into the
/// cart. The cart is shared with the New Order screen, so "অর্ডার করুন" just
/// hands off to that screen for address + confirmation.
class _QuickOrderSection extends StatefulWidget {
  final VoidCallback onCheckout;
  const _QuickOrderSection({required this.onCheckout});

  @override
  State<_QuickOrderSection> createState() => _QuickOrderSectionState();
}

class _QuickOrderSectionState extends State<_QuickOrderSection> {
  String _service = 'Wash';
  String _category = MockData.categories.first;

  @override
  void initState() {
    super.initState();
    Cart.revision.addListener(_onCart);
  }

  @override
  void dispose() {
    Cart.revision.removeListener(_onCart);
    super.dispose();
  }

  void _onCart() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = Catalog.forCategory(_category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _serviceTabs(),
        const SizedBox(height: 12),
        _categoryChips(),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) _itemRow(items[i], last: i == items.length - 1),
            ],
          ),
        ),
        if (!Cart.isEmpty) ...[
          const SizedBox(height: 12),
          _checkoutBar(),
        ],
      ],
    );
  }

  Widget _serviceTabs() {
    Widget tab(String label, String service, IconData icon) {
      final active = _service == service;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _service = service),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? AppColors.blue : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: active ? AppColors.blue : AppColors.line),
              boxShadow: active ? AppShadows.soft : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: active ? Colors.white : AppColors.muted),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: active ? Colors.white : AppColors.ink)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(AppLanguage.tr('ওয়াশ'), 'Wash', Icons.local_laundry_service_rounded),
        const SizedBox(width: 10),
        tab(AppLanguage.tr('ড্রাই ক্লিন'), 'Dry Clean', Icons.dry_cleaning_rounded),
      ],
    );
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: MockData.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = MockData.categories[i];
          final active = c == _category;
          return GestureDetector(
            onTap: () => setState(() => _category = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.blueSoft : Colors.white,
                border: Border.all(color: active ? AppColors.blue : AppColors.line),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(MockData.categoriesBn[c] ?? c, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: active ? AppColors.blue : AppColors.ink)),
            ),
          );
        },
      ),
    );
  }

  Widget _itemRow(PriceItem item, {required bool last}) {
    final price = _service == 'Wash' ? item.washPrice : item.dryPrice;
    final qty = Cart.qtyOf(item.id, _service);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: last ? Colors.transparent : AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.blueSoft.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: LaundryIcon(item.id, size: 24, color: AppColors.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nameBn, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text('৳$price', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.blue)),
              ],
            ),
          ),
          if (qty == 0)
            _addButton(() => Cart.setQty(item.id, _service, 1))
          else
            _stepper(qty, () => Cart.setQty(item.id, _service, qty - 1), () => Cart.setQty(item.id, _service, qty + 1)),
        ],
      ),
    );
  }

  Widget _addButton(VoidCallback onTap) {
    return Material(
      color: AppColors.blue,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(AppLanguage.tr('যোগ'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepper(int qty, VoidCallback onMinus, VoidCallback onPlus) {
    return Container(
      decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(Icons.remove_rounded, onMinus),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(toBn(qty), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.blue)),
          ),
          _stepBtn(Icons.add_rounded, onPlus),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 18, color: AppColors.blue)),
      ),
    );
  }

  Widget _checkoutBar() {
    return Material(
      color: AppColors.blue,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: widget.onCheckout,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text('${toBn(Cart.totalPieces)} পিস • ৳${Cart.subtotal}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
              const Spacer(),
              Text(AppLanguage.tr('অর্ডার করুন'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
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
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

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
