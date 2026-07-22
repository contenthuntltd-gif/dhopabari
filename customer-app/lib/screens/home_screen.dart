import 'package:flutter/material.dart';
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
import 'tracking_screen.dart';
import 'orders_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Opens the (2-step) checkout for whatever is already in the cart.
  final VoidCallback onStartNewOrder;
  final void Function(int tabIndex) onSwitchTab;
  const HomeScreen({
    super.key,
    required this.onStartNewOrder,
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
    if (!mounted) return;
    // Rebuild so the pinned checkout bar tracks the cart; a cart that just
    // emptied means an order was placed → refetch the order list too.
    setState(() {});
    if (Cart.isEmpty) _load();
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


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isEnglish,
      builder: (context, _, _) => SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.blue,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.sm,
                    AppSpace.sm,
                    AppSpace.sm,
                    AppSpace.md,
                  ),
                  child: FadeSlideIn(
                    // Hero (with Wash/Dry Clean tabs inside) + mini order
                    // cards + category chips + item list, all in one flow.
                    child: _QuickOrderSection(
                      belowHero: _miniOrders(),
                    ),
                  ),
                ),
              ),
            ),
            // Sticky checkout bar — always visible above the bottom nav the
            // moment anything is in the cart, no scrolling needed.
            if (!Cart.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.sm, 6, AppSpace.sm, 8),
                child: _checkoutBar(),
              ),
          ],
        ),
      ),
    );
  }

  /// Small horizontal order cards shown right under the blue hero card —
  /// enough to see status at a glance, tap for full tracking.
  Widget? _miniOrders() {
    if (_loading || _orders.isEmpty) return null;
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _orders.length > 5 ? 6 : _orders.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          // 6th tile is a "see all" shortcut.
          if (_orders.length > 5 && i == 5) {
            return _miniSeeAll();
          }
          final o = _orders[i];
          final isDone = o.progress >= 1;
          final accent = isDone ? AppColors.green : AppColors.blue;
          return PressableScale(
            onTap: () => Navigator.push(
              context,
              AppPageRoute(builder: (_) => TrackingScreen(order: o)),
            ),
            child: Container(
              width: 168,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.line),
                boxShadow: AppShadows.soft,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(o.id, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.ink)),
                      ),
                      Text(money(o.total), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: accent)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    o.currentStatusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent),
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: o.progress,
                      minHeight: 4,
                      backgroundColor: AppColors.line,
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _miniSeeAll() {
    return PressableScale(
      onTap: () => Navigator.push(context, AppPageRoute(builder: (_) => const OrdersScreen())),
      child: Container(
        width: 92,
        decoration: BoxDecoration(
          color: AppColors.blueSoft.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_forward_rounded, color: AppColors.blue, size: 20),
            const SizedBox(height: 4),
            Text(AppLanguage.tr('সব দেখুন'), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.blue)),
          ],
        ),
      ),
    );
  }

  /// The pinned "অর্ডার করুন" bar above the bottom nav.
  Widget _checkoutBar() {
    return Material(
      color: AppColors.blue,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: widget.onStartNewOrder,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Text('${toBn(Cart.totalPieces)} পিস • ৳${Cart.subtotal}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
              const Spacer(),
              Text(AppLanguage.tr('অর্ডার করুন'), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline quick-order for the home page. The blue hero card carries the
/// brand, the free-pickup/delivery perks AND the Wash / Dry Clean tabs;
/// below it come the (optional) mini order cards, category chips and the
/// item list. Items add straight to the shared cart; the pinned bar on the
/// home screen hands off to the order screen.
class _QuickOrderSection extends StatefulWidget {
  /// Slotted in right under the hero card (mini order cards).
  final Widget? belowHero;
  const _QuickOrderSection({this.belowHero});

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
        _heroCard(),
        if (widget.belowHero != null) ...[
          const SizedBox(height: 10),
          widget.belowHero!,
        ],
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
      ],
    );
  }

  /// The blue brand card with the two service tabs living inside it.
  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue, AppColors.blueDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: AppColors.blue.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const AppLogo(size: 34),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLanguage.tr('ধোপা বাড়ি'), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                    const Text('কাপড়ের যত্নে আপনার বিশ্বস্ত পার্টনার', style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _perk(Icons.inventory_2_rounded, AppLanguage.tr('ফ্রি পিকআপ')),
              const SizedBox(width: 12),
              _perk(Icons.local_shipping_rounded, AppLanguage.tr('ফ্রি ডেলিভারি')),
            ],
          ),
          const SizedBox(height: 12),
          // Wash / Dry Clean — inside the blue card, controlling the list.
          Row(
            children: [
              _serviceTab(AppLanguage.tr('ওয়াশ'), 'Wash', Icons.local_laundry_service_rounded),
              const SizedBox(width: 8),
              _serviceTab(AppLanguage.tr('ড্রাই ক্লিন'), 'Dry Clean', Icons.dry_cleaning_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _perk(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _serviceTab(String label, String service, IconData icon) {
    final active = _service == service;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _service = service),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: active ? AppColors.blue : Colors.white),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: active ? AppColors.blue : Colors.white)),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: last ? Colors.transparent : AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: AppColors.blueSoft.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: LaundryIcon(item.id, size: 20, color: AppColors.blue),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Row(
              children: [
                Flexible(child: Text(item.nameBn, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink))),
                const SizedBox(width: 6),
                Text('৳$price', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.blue)),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 3),
              Text(AppLanguage.tr('যোগ'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepper(int qty, VoidCallback onMinus, VoidCallback onPlus) {
    return Container(
      decoration: BoxDecoration(color: AppColors.blueSoft, borderRadius: BorderRadius.circular(9)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(Icons.remove_rounded, onMinus),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(toBn(qty), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.blue)),
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
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(5), child: Icon(icon, size: 16, color: AppColors.blue)),
      ),
    );
  }

}

