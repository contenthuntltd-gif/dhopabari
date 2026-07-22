import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/cart.dart';
import '../data/mock_data.dart';
import '../data/business_info.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../widgets/laundry_icons.dart';
import '../widgets/bn_number.dart';
import '../widgets/app_page_route.dart';
import 'order_success_screen.dart';

class NewOrderScreen extends StatefulWidget {
  final String initialService;

  /// Set when an admin or rider is placing this order on a customer's
  /// behalf from that customer's profile. Null for a customer ordering for
  /// themselves. Either way the order is stored against the customer, so
  /// their history is the same regardless of who typed it in.
  final String? forCustomerId;
  final String? forCustomerName;
  final String? forCustomerAddress;

  /// True when the customer already picked their items on the home page:
  /// the flow then has only two steps — "তথ্য" and "নিশ্চিত করুন" — and the
  /// items step is skipped entirely.
  final bool quickCheckout;

  const NewOrderScreen({
    super.key,
    this.initialService = 'Wash',
    this.forCustomerId,
    this.forCustomerName,
    this.forCustomerAddress,
    this.quickCheckout = false,
  });

  bool get isStaffOrder => forCustomerId != null;

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  int _step = 0; // 0 service/items, 1 address+time, 2 summary
  // The service tab being BROWSED right now. Adding an item puts it in the
  // cart under this service — the cart itself can hold Wash and Dry Clean
  // lines side by side, each at its own price.
  late String _service;
  String _category = 'Men';
  int _addressIndex = 0;
  DeliveryType _deliveryType = DeliveryType.free; // free is the default
  bool _confirming = false;

  // Guest checkout fields — used only when the customer is not logged in
  // (and this is not a staff order). On placing the order the phone becomes
  // their auto-created account.
  final _guestName = TextEditingController();
  final _guestPhone = TextEditingController();
  final _guestAddress = TextEditingController();
  String? _guestError;

  /// A not-logged-in customer ordering for themselves.
  bool get _isGuest => !AuthService.isLoggedIn && !widget.isStaffOrder;

  /// Quick checkout (items already picked on home) shows just two steps;
  /// the full flow keeps the items step for staff/other entry points.
  List<String> get _stepLabels =>
      widget.quickCheckout ? const ['তথ্য', 'নিশ্চিত করুন'] : const ['সার্ভিস', 'তথ্য', 'নিশ্চিত করুন'];

  /// Header index for the current internal step (internal steps are always
  /// 0=items, 1=info, 2=summary; quick mode starts at 1 and shows 2 labels).
  int get _displayStep => widget.quickCheckout ? _step - 1 : _step;

  @override
  void initState() {
    super.initState();
    _service = widget.initialService;
    if (widget.quickCheckout) _step = 1; // items already in the cart

    // Pre-fill guest fields if a previous session left contact details.
    _guestName.text = MockData.userName;
    _guestPhone.text = MockData.userPhone;
    // Staff ordering on a customer's behalf always starts from an empty
    // cart — otherwise items left over from customer A's (or the staff
    // member's own) session would silently land in customer B's order.
    // A customer's own flow keeps the persistent cart untouched.
    if (widget.isStaffOrder) Cart.clear();
    // The cart is global and persistent — reopening this screen shows
    // whatever was left in it. Rebuild on any cart change.
    Cart.revision.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    Cart.revision.removeListener(_onCartChanged);
    _guestName.dispose();
    _guestPhone.dispose();
    _guestAddress.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  int get _totalPieces => Cart.totalPieces;

  int get _itemsSubtotal => Cart.subtotal;

  int get _expressCharge => _deliveryType == DeliveryType.express ? DeliveryOptions.express.charge : 0;

  int get _totalPrice => _itemsSubtotal + _expressCharge;

  /// The pickup address as a {line, area} map, resolved for whichever kind
  /// of order this is (guest / staff-on-behalf / logged-in-with-saved).
  Map<String, String> get _resolvedAddress {
    if (_isGuest) {
      return {'line': _guestAddress.text.trim(), 'area': ''};
    }
    final forCustomer = widget.forCustomerAddress?.trim() ?? '';
    if (forCustomer.isNotEmpty) {
      return {'line': forCustomer, 'area': MockData.userArea};
    }
    if (MockData.savedAddresses.isEmpty) return {'line': '', 'area': ''};
    return MockData.savedAddresses[_addressIndex];
  }

  String get _orderAddress => _resolvedAddress['line'] ?? '';

  /// Validates the guest name/phone/address before leaving the info step.
  bool _validateGuest() {
    final name = _guestName.text.trim();
    final phone = _guestPhone.text.trim().replaceAll(RegExp(r'\D'), '');
    final address = _guestAddress.text.trim();
    String? err;
    if (name.isEmpty) {
      err = 'আপনার নাম দিন';
    } else if (phone.length < 10) {
      err = 'সঠিক মোবাইল নম্বর দিন';
    } else if (address.isEmpty) {
      err = 'পিকআপ ঠিকানা দিন';
    }
    setState(() => _guestError = err);
    return err == null;
  }

  Future<void> _next() async {
    if (_confirming) return;
    if (_step < 2) {
      // A guest must fill in name/phone/address before reaching the summary.
      if (_step == 1 && _isGuest && !_validateGuest()) return;
      setState(() => _step++);
      return;
    }

    setState(() => _confirming = true);

    try {
      if (_isGuest) {
        // No login: the phone becomes the customer's auto-created account.
        await AdminService.guestOrder(
          name: _guestName.text.trim(),
          phone: _guestPhone.text.trim(),
          address: _guestAddress.text.trim(),
          service: Cart.serviceLabel,
          items: Cart.toOrderItems(),
          pieces: _totalPieces,
          total: _totalPrice,
          paymentMethod: 'Cash on Delivery',
          note: _deliveryType == DeliveryType.express ? 'Express delivery' : null,
        );
      } else {
        await AdminService.createOrder(
          customerId: widget.forCustomerId,
          // 'Wash', 'Dry Clean', or 'Wash + Dry Clean' for a mixed order —
          // each line in items carries its own service and unit price.
          service: Cart.serviceLabel,
          items: Cart.toOrderItems(),
          pieces: _totalPieces,
          total: _totalPrice,
          address: _orderAddress,
          area: MockData.userArea,
          paymentMethod: 'Cash on Delivery',
          note: _deliveryType == DeliveryType.express ? 'Express delivery' : null,
        );
      }

      // Order is done — THIS is the one moment the cart resets. Leaving
      // the screen mid-flow never clears it.
      await Cart.clear();

      if (!mounted) return;

      // Staff came here from a customer's profile — hand the result back so
      // that screen can refresh, instead of showing the customer-facing
      // success screen.
      if (widget.isStaffOrder) {
        Navigator.pop(context, true);
        return;
      }

      Navigator.pushReplacement(
        context,
        AppPageRoute(builder: (_) => OrderSuccessScreen(placedOffHours: !BusinessHours.isOpenNow)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AdminService.messageFor(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  /// The first visible step of this flow (quick mode never goes back to
  /// the items step — that lives on the home page).
  int get _firstStep => widget.quickCheckout ? 1 : 0;

  void _back() {
    if (_step > _firstStep) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _firstStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Column(
            children: [
              _Header(step: _displayStep, steps: _stepLabels, onBack: _back),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppMotion.base,
                  switchInCurve: AppMotion.entrance,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: _buildStep(),
                ),
              ),
              _BottomBar(
                step: _step,
                totalPieces: _totalPieces,
                totalPrice: _totalPrice,
                enabled: _step == 0 ? _totalPieces > 0 : true,
                loading: _confirming,
                onNext: _next,
                onSeeAll: _step == 0 && _totalPieces > 0 ? () => _showCartSheet(context) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _ServiceItemsStep(
          key: const ValueKey(0),
          service: _service,
          category: _category,
          onServiceChanged: (s) => setState(() => _service = s),
          onCategoryChanged: (c) => setState(() => _category = c),
        );
      case 1:
        // Guests type their name/phone/address here; logged-in customers
        // pick from their saved address instead.
        if (_isGuest) {
          return _GuestInfoStep(
            key: const ValueKey(1),
            nameCtrl: _guestName,
            phoneCtrl: _guestPhone,
            addressCtrl: _guestAddress,
            error: _guestError,
            deliveryType: _deliveryType,
            onDeliveryTypeChanged: (t) => setState(() => _deliveryType = t),
          );
        }
        return _AddressTimeStep(
          key: const ValueKey(1),
          addressIndex: _addressIndex,
          onAddressChanged: (i) => setState(() => _addressIndex = i),
          deliveryType: _deliveryType,
          onDeliveryTypeChanged: (t) => setState(() => _deliveryType = t),
        );
      default:
        return _SummaryStep(
          key: const ValueKey(2),
          totalPieces: _totalPieces,
          itemsSubtotal: _itemsSubtotal,
          expressCharge: _expressCharge,
          totalPrice: _totalPrice,
          deliveryType: _deliveryType,
          address: _resolvedAddress,
          onEditStep: (s) => setState(() => _step = s),
        );
    }
  }

  /// "সব দেখুন" — the full cart: every selected line with its own service
  /// and price, editable in place.
  void _showCartSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _CartSheet(),
    );
  }
}

class _Header extends StatelessWidget {
  final int step;
  final List<String> steps;
  final VoidCallback onBack;
  const _Header({
    required this.step,
    required this.steps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Tooltip(
                message: 'পেছনে যান',
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'নতুন অর্ডার',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'ধাপ ${toBn(step + 1)}/৩',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 34),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(steps.length, (i) {
              final active = i <= step;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: AppMotion.base,
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active ? AppColors.blue : AppColors.line,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedDefaultTextStyle(
                            duration: AppMotion.base,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: active ? AppColors.blue : AppColors.muted,
                            ),
                            child: Text(steps[i]),
                          ),
                        ],
                      ),
                    ),
                    if (i != steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 18),
                          child: AnimatedContainer(
                            duration: AppMotion.base,
                            color: i < step ? AppColors.blue : AppColors.line,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ServiceItemsStep extends StatelessWidget {
  final String service;
  final String category;
  final ValueChanged<String> onServiceChanged;
  final ValueChanged<String> onCategoryChanged;

  const _ServiceItemsStep({
    super.key,
    required this.service,
    required this.category,
    required this.onServiceChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = MockData.itemsForCategory(category);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        const Text('সার্ভিস নির্বাচন করুন', style: AppText.h3),
        const SizedBox(height: 10),
        _ServiceOption(
          title: 'WASH',
          subtitle: 'সাধারণ ও বিশেষ যত্নে কাপড় ও লন্ড্রি পরিষেবা',
          icon: Icons.local_laundry_service_rounded,
          selected: service == 'Wash',
          badgeCount: Cart.linesFor('Wash').fold(0, (s, l) => s + l.qty),
          onTap: () => onServiceChanged('Wash'),
        ),
        const SizedBox(height: 10),
        _ServiceOption(
          title: 'DRY CLEAN',
          subtitle: 'প্রিমিয়াম ড্রাই ক্লিন, সুরক্ষিত ও নির্ভরযোগ্য পরিষেবা',
          icon: Icons.dry_cleaning_rounded,
          selected: service == 'Dry Clean',
          badgeCount: Cart.linesFor('Dry Clean').fold(0, (s, l) => s + l.qty),
          onTap: () => onServiceChanged('Dry Clean'),
        ),
        const SizedBox(height: 8),
        // Mixed orders are the point: pick some items in Wash, switch the
        // tab, pick others in Dry Clean — everything lands in one cart.
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.blueSoft.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: const [
              Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'একই অর্ডারে কিছু কাপড় ওয়াশ, কিছু ড্রাই ক্লিন নিতে পারবেন — সার্ভিস বদলে আইটেম যোগ করুন, দাম আলাদাভাবে হিসাব হবে।',
                  style: TextStyle(fontSize: 10.5, color: AppColors.ink, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        const Text('কাপড়ের ধরন নির্বাচন করুন', style: AppText.h3),
        const SizedBox(height: AppSpace.xs),
        Row(
          children: MockData.categories.map((c) {
            final active = c == category;
            // Badge counts pieces across BOTH services.
            final countInCategory = MockData.itemsForCategory(
              c,
            ).fold<int>(0, (sum, item) => sum + Cart.piecesOfItem(item.id));
            return Expanded(
              child: Semantics(
                button: true,
                selected: active,
                label:
                    '${MockData.categoriesBn[c]}${countInCategory > 0 ? ', ${toBn(countInCategory)} পিস নির্বাচিত' : ''}',
                child: GestureDetector(
                  onTap: () => onCategoryChanged(c),
                  child: AnimatedContainer(
                    duration: AppMotion.base,
                    curve: AppMotion.curve,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? AppColors.blueSoft : Colors.white,
                      border: Border.all(
                        color: active ? AppColors.blue : AppColors.line,
                        width: active ? 1.6 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColors.blue.withValues(alpha: 0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          children: [
                            Icon(
                              _categoryIcon(c),
                              size: AppIconSize.md,
                              color: active ? AppColors.blue : AppColors.muted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              MockData.categoriesBn[c]!,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? AppColors.blue
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        if (countInCategory > 0)
                          Positioned(
                            top: -6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.teal,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              constraints: const BoxConstraints(minWidth: 16),
                              child: Text(
                                toBn(countInCategory),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpace.md),
        const Text('আইটেম যোগ করুন', style: AppText.h3),
        const SizedBox(height: AppSpace.xs),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: items.map((item) {
              // Qty under the service tab being browsed; the same item may
              // also sit in the cart under the other service.
              final q = Cart.qtyOf(item.id, service);
              final otherService = service == 'Wash' ? 'Dry Clean' : 'Wash';
              final otherQty = Cart.qtyOf(item.id, otherService);
              final price = service == 'Wash' ? item.washPrice : item.dryPrice;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: q > 0
                      ? AppColors.blueSoft.withValues(alpha: 0.25)
                      : null,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.line,
                      width: item == items.last ? 0 : 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Dedicated per-item icon, matching the official Dhopa
                    // Bari price list (never a generic category glyph).
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: q > 0 ? AppColors.blue : AppColors.blueSoft.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: LaundryIcon(
                        item.id,
                        size: 24,
                        color: q > 0 ? Colors.white : AppColors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nameBn,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Prices in English numerals, per the official list.
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '৳$price',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.blue,
                            ),
                          ),
                          Text(
                            otherQty > 0
                                ? (service == 'Wash' ? 'ড্রাই-তে $otherQty পিস' : 'ওয়াশে $otherQty পিস')
                                : (service == 'Wash' ? 'ড্রাই ৳${item.dryPrice}' : 'ওয়াশ ৳${item.washPrice}'),
                            style: TextStyle(
                              fontSize: 9.5,
                              color: otherQty > 0 ? AppColors.teal : AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _QtyStepper(
                      itemName: item.nameBn,
                      qty: q,
                      onChanged: (v) => Cart.setQty(item.id, service, v),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        if (Cart.isEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amberSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.info_outline_rounded,
                  size: AppIconSize.md,
                  color: AppColors.amber,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'চালিয়ে যেতে অন্তত ১টি আইটেম নির্বাচন করুন',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  IconData _categoryIcon(String c) {
    switch (c) {
      case 'Men':
        return Icons.man_rounded;
      case 'Women':
        return Icons.woman_rounded;
      case 'Kids':
        return Icons.child_care_rounded;
      default:
        return Icons.home_rounded;
    }
  }
}

class _ServiceOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  /// Pieces already in the cart under this service — visible even when the
  /// other tab is active, so a mixed order stays legible.
  final int badgeCount;

  const _ServiceOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title সার্ভিস',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.base,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.blueSoft.withValues(alpha: 0.4)
                  : Colors.white,
              border: Border.all(
                color: selected ? AppColors.blue : AppColors.line,
                width: selected ? 1.6 : 1,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.16),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          if (badgeCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.blue,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$badgeCount পিস',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _SelectDot(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple selected/unselected circle indicator — avoids the deprecated
/// `Radio.groupValue`/`onChanged` API (Flutter now wants a `RadioGroup`
/// ancestor for that) for something this simple.
class _SelectDot extends StatelessWidget {
  final bool selected;
  const _SelectDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.blue : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.blue : AppColors.line,
          width: 1.6,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : null,
    );
  }
}

class _QtyStepper extends StatefulWidget {
  final String itemName;
  final int qty;
  final ValueChanged<int> onChanged;
  const _QtyStepper({
    required this.itemName,
    required this.qty,
    required this.onChanged,
  });

  @override
  State<_QtyStepper> createState() => _QtyStepperState();
}

class _QtyStepperState extends State<_QtyStepper> {
  Timer? _repeatTimer;

  void _startRepeating(int direction) {
    _bump(direction);
    _repeatTimer?.cancel();
    _repeatTimer = Timer(const Duration(milliseconds: 400), () {
      _repeatTimer = Timer.periodic(
        const Duration(milliseconds: 110),
        (_) => _bump(direction),
      );
    });
  }

  void _bump(int direction) {
    final next = widget.qty + direction;
    if (next < 0) return;
    widget.onChanged(next);
  }

  void _stopRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  Future<void> _openQuickPicker() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text('${widget.itemName} — সংখ্যা বাছাই করুন', style: AppText.h3),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(13, (i) {
                final selected = i == widget.qty;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, i),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.blue : AppColors.paper,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      toBn(i),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: selected ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.itemName}, ${toBn(widget.qty)} পিস নির্বাচিত',
      child: Row(
        children: [
          _roundBtn(
            Icons.remove_rounded,
            widget.qty > 0 ? () => _bump(-1) : null,
            'কমান',
            -1,
          ),
          GestureDetector(
            onTap: _openQuickPicker,
            child: SizedBox(
              width: 32,
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  toBn(widget.qty),
                  key: ValueKey(widget.qty),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          _roundBtn(Icons.add_rounded, () => _bump(1), 'বাড়ান', 1),
        ],
      ),
    );
  }

  Widget _roundBtn(
    IconData icon,
    VoidCallback? onTap,
    String label,
    int direction,
  ) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onLongPressStart: onTap == null
            ? null
            : (_) => _startRepeating(direction),
        onLongPressEnd: (_) => _stopRepeating(),
        child: Material(
          color: onTap == null ? AppColors.paper : AppColors.blueSoft,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Icon(
                icon,
                size: 19,
                color: onTap == null ? AppColors.muted : AppColors.blue,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Step 1 for a not-logged-in customer: collect name, phone and pickup
/// address. On placing the order the phone becomes their auto-created
/// account — no password to choose.
class _GuestInfoStep extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController addressCtrl;
  final String? error;
  final DeliveryType deliveryType;
  final ValueChanged<DeliveryType> onDeliveryTypeChanged;

  const _GuestInfoStep({
    super.key,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.error,
    required this.deliveryType,
    required this.onDeliveryTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        const Text('আপনার তথ্য দিন', style: AppText.h3),
        const SizedBox(height: 4),
        const Text(
          'লগইন ছাড়াই অর্ডার করুন — এই নম্বর দিয়েই আপনার অ্যাকাউন্ট তৈরি হয়ে যাবে।',
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'আপনার নাম', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: 'মোবাইল নম্বর (যেমন 01712345678)', prefixIcon: Icon(Icons.phone_outlined, size: 20)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: addressCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'পিকআপ ঠিকানা (বাসা, রোড, এলাকা)', prefixIcon: Icon(Icons.location_on_outlined, size: 20)),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
              const SizedBox(width: 6),
              Text(error!, style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
        const SizedBox(height: AppSpace.md),
        const Text('ডেলিভারি অপশন', style: AppText.h3),
        const SizedBox(height: 10),
        _DeliveryOptionTile(
          option: DeliveryOptions.free,
          selected: deliveryType == DeliveryType.free,
          onTap: () => onDeliveryTypeChanged(DeliveryType.free),
        ),
        const SizedBox(height: 10),
        _DeliveryOptionTile(
          option: DeliveryOptions.express,
          selected: deliveryType == DeliveryType.express,
          onTap: () => onDeliveryTypeChanged(DeliveryType.express),
        ),
      ],
    );
  }
}

class _AddressTimeStep extends StatefulWidget {
  final int addressIndex;
  final ValueChanged<int> onAddressChanged;
  final DeliveryType deliveryType;
  final ValueChanged<DeliveryType> onDeliveryTypeChanged;

  const _AddressTimeStep({
    super.key,
    required this.addressIndex,
    required this.onAddressChanged,
    required this.deliveryType,
    required this.onDeliveryTypeChanged,
  });

  @override
  State<_AddressTimeStep> createState() => _AddressTimeStepState();
}

class _AddressTimeStepState extends State<_AddressTimeStep> {
  Future<void> _editAddress(int index) async {
    final a = MockData.savedAddresses[index];
    final labelCtrl = TextEditingController(text: a['labelBn']);
    final lineCtrl = TextEditingController(text: a['line']);
    final areaCtrl = TextEditingController(text: a['area']);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('ঠিকানা সম্পাদনা করুন', style: AppText.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelCtrl, decoration: const InputDecoration(hintText: 'লেবেল (যেমন: বাসা, অফিস)')),
            const SizedBox(height: 10),
            TextField(controller: lineCtrl, decoration: const InputDecoration(hintText: 'বাসা/রোড')),
            const SizedBox(height: 10),
            TextField(controller: areaCtrl, decoration: const InputDecoration(hintText: 'এলাকা')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('বাতিল')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('সংরক্ষণ করুন')),
        ],
      ),
    );
    if (saved == true && lineCtrl.text.trim().isNotEmpty) {
      setState(() {
        MockData.savedAddresses[index] = {
          ...a,
          'labelBn': labelCtrl.text.trim().isEmpty ? a['labelBn']! : labelCtrl.text.trim(),
          'line': lineCtrl.text.trim(),
          'area': areaCtrl.text.trim(),
        };
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ঠিকানা আপডেট করা হয়েছে')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        const Text('পিকআপ ঠিকানা নির্বাচন করুন', style: AppText.h3),
        const SizedBox(height: 10),
        ...List.generate(MockData.savedAddresses.length, (i) {
          final a = MockData.savedAddresses[i];
          final selected = i == widget.addressIndex;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Semantics(
              button: true,
              selected: selected,
              label: '${a['labelBn']}, ${a['line']}',
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => widget.onAddressChanged(i),
                  child: AnimatedContainer(
                    duration: AppMotion.base,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.blueSoft.withValues(alpha: 0.4)
                          : Colors.white,
                      border: Border.all(
                        color: selected ? AppColors.blue : AppColors.line,
                        width: selected ? 1.6 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.blue.withValues(alpha: 0.16),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: selected ? AppColors.blue : AppColors.muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a['labelBn']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                '${a['line']}, ${a['area']}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tooltip(
                          message: 'সম্পাদনা করুন',
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _editAddress(i),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(Icons.edit_outlined, size: 17, color: selected ? AppColors.blue : AppColors.muted),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _SelectDot(selected: selected),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.blueSoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.blue.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                child: const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'পিকআপের সময়',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'আমাদের টিম অফিস সময়ে (${BusinessHours.label}) আপনার সাথে যোগাযোগ করে পিকআপ নিশ্চিত করবে।',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        const Text('ডেলিভারি অপশন', style: AppText.h3),
        const SizedBox(height: 10),
        _DeliveryOptionTile(
          option: DeliveryOptions.free,
          selected: widget.deliveryType == DeliveryType.free,
          onTap: () => widget.onDeliveryTypeChanged(DeliveryType.free),
        ),
        const SizedBox(height: 10),
        _DeliveryOptionTile(
          option: DeliveryOptions.express,
          selected: widget.deliveryType == DeliveryType.express,
          onTap: () => widget.onDeliveryTypeChanged(DeliveryType.express),
        ),
      ],
    );
  }
}

class _DeliveryOptionTile extends StatelessWidget {
  final DeliveryOption option;
  final bool selected;
  final VoidCallback onTap;
  const _DeliveryOptionTile({required this.option, required this.selected, required this.onTap});

  bool get _isExpress => option.type == DeliveryType.express;

  @override
  Widget build(BuildContext context) {
    final accent = _isExpress ? AppColors.amber : AppColors.teal;
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.label}, ${option.charge == 0 ? "ফ্রি" : "৳${option.charge}"}, ${option.eta}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.base,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.08) : Colors.white,
            border: Border.all(color: selected ? accent : AppColors.line, width: selected ? 1.6 : 1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? [BoxShadow(color: accent.withValues(alpha: 0.16), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Row(
            children: [
              Icon(_isExpress ? Icons.bolt_rounded : Icons.local_shipping_outlined, size: 22, color: selected ? accent : AppColors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(option.label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: selected ? accent : AppColors.ink)),
                        if (_isExpress) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(999)),
                            child: const Text('⚡ Express Delivery', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('আনুমানিক সম্পন্ন: ${option.eta}', style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Text(
                option.charge == 0 ? 'ফ্রি' : '+${money(option.charge)}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: selected ? accent : AppColors.ink),
              ),
              const SizedBox(width: 8),
              _SelectDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStep extends StatelessWidget {
  final int totalPieces;
  final int itemsSubtotal;
  final int expressCharge;
  final int totalPrice;
  final DeliveryType deliveryType;
  final Map<String, String> address;
  final ValueChanged<int> onEditStep;

  const _SummaryStep({
    super.key,
    required this.totalPieces,
    required this.itemsSubtotal,
    required this.expressCharge,
    required this.totalPrice,
    required this.deliveryType,
    required this.address,
    required this.onEditStep,
  });

  @override
  Widget build(BuildContext context) {
    final lines = Cart.lines;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _summaryCard(
          title: 'আইটেমসমূহ (${toBn(lines.length)})',
          onEdit: () => onEditStep(0),
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    LaundryIcon(line.item.id, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.item.nameBn,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          // Per-line service + unit price — a mixed order
                          // shows exactly what each line costs and why.
                          Text(
                            '${line.service == 'Wash' ? 'ওয়াশ' : 'ড্রাই ক্লিন'} • ৳${line.unitPrice} × ${line.qty} = ৳${line.lineTotal}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: line.service == 'Wash' ? AppColors.blue : AppColors.teal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _QtyStepper(
                      itemName: line.item.nameBn,
                      qty: line.qty,
                      onChanged: (v) => Cart.setQty(line.item.id, line.service, v),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _summaryCard(
          title: 'পিকআপ',
          onEdit: () => onEditStep(1),
          children: [
            _row('ঠিকানা', '${address['line']}, ${address['area']}'),
            _row('পিকআপের সময়', BusinessHours.label),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ডেলিভারি', style: TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  if (deliveryType == DeliveryType.express)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(999)),
                      child: const Text('⚡ Express Delivery', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                    )
                  else
                    const Text('ফ্রি ডেলিভারি', style: TextStyle(fontSize: 12.5, color: AppColors.teal, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.blue, AppColors.blueDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'মূল্য বিবরণ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              _priceRow('মোট আইটেম', '${toBn(totalPieces)} পিস'),
              _priceRow('সাবটোটাল', money(itemsSubtotal)),
              _priceRow('ডেলিভারি ফি', 'ফ্রি', highlight: true),
              if (expressCharge > 0) _priceRow('এক্সপ্রেস চার্জ', '+${money(expressCharge)}'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'সর্বমোট',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    money(totalPrice),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              color: highlight ? AppColors.tealSoft : Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required List<Widget> children,
    VoidCallback? onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 13, color: AppColors.blue),
                      SizedBox(width: 3),
                      Text(
                        'সম্পাদনা',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 12.5,
              color: bold ? AppColors.ink : AppColors.muted,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: bold ? 15 : 12.5,
                color: bold ? AppColors.blue : AppColors.ink,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int step;
  final int totalPieces;
  final int totalPrice;
  final bool enabled;
  final bool loading;
  final VoidCallback onNext;

  /// Opens the full-cart sheet; null hides the link (empty cart / later steps).
  final VoidCallback? onSeeAll;

  const _BottomBar({
    required this.step,
    required this.totalPieces,
    required this.totalPrice,
    required this.enabled,
    required this.loading,
    required this.onNext,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (step == 0)
              Expanded(
                child: GestureDetector(
                  onTap: onSeeAll,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${toBn(totalPieces)} পিস',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            money(totalPrice),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: AppColors.blue,
                            ),
                          ),
                          if (onSeeAll != null) ...[
                            const SizedBox(width: 8),
                            const Text(
                              'সব দেখুন',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.teal,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_up_rounded, size: 15, color: AppColors.teal),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              flex: step == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: enabled && !loading ? onNext : null,
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: loading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          step == 2 ? 'অর্ডার নিশ্চিত করুন   ✓' : 'পরবর্তী   →',
                          key: const ValueKey('label'),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "সব দেখুন" — the whole cart in one sheet, grouped by service. Lines are
/// editable in place (qty steppers write straight to [Cart]), and the sheet
/// live-updates via [Cart.revision].
class _CartSheet extends StatelessWidget {
  const _CartSheet();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Cart.revision,
      builder: (context, _, _) {
        final washLines = Cart.linesFor('Wash');
        final dryLines = Cart.linesFor('Dry Clean');
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 20),
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
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(child: Text('নির্বাচিত আইটেম', style: AppText.h2)),
                  Text(
                    '${toBn(Cart.totalPieces)} পিস',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (Cart.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('কার্ট খালি — আইটেম যোগ করুন', style: AppText.bodyMuted),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (washLines.isNotEmpty) ...[
                        _serviceHeader('ওয়াশ', AppColors.blue, washLines.fold(0, (s, l) => s + l.lineTotal)),
                        for (final line in washLines) _lineRow(line),
                        const SizedBox(height: 8),
                      ],
                      if (dryLines.isNotEmpty) ...[
                        _serviceHeader('ড্রাই ক্লিন', AppColors.teal, dryLines.fold(0, (s, l) => s + l.lineTotal)),
                        for (final line in dryLines) _lineRow(line),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('সাবটোটাল', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    Text(
                      '৳${Cart.subtotal}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _serviceHeader(String label, Color color, int sectionTotal) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ),
          const Spacer(),
          Text('৳$sectionTotal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _lineRow(CartLine line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.blueSoft.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: LaundryIcon(line.item.id, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.item.nameBn, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text(
                  '৳${line.unitPrice} × ${line.qty} = ৳${line.lineTotal}',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          _QtyStepper(
            itemName: line.item.nameBn,
            qty: line.qty,
            onChanged: (v) => Cart.setQty(line.item.id, line.service, v),
          ),
        ],
      ),
    );
  }
}
