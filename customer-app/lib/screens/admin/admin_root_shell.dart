import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_page_route.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/phone_frame.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../data/mock_data.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'customers_screen.dart';
import 'riders_screen.dart';
import 'catalog_screen.dart';
import 'withdrawals_screen.dart';
import 'memo_center_screen.dart';
import 'support_settings_screen.dart';
import '../login_screen.dart';
import '../../data/business_info.dart';

/// A destination in the admin panel. Some render inside the shell's content
/// area (the everyday screens); the rest are secondary tools.
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

/// Everyday screens embedded in the shell content area (kept alive across
/// switches). Each renders without its own app bar.
const _primaryNav = <_NavItem>[
  _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'ড্যাশবোর্ড'),
  _NavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'অর্ডার'),
  _NavItem(Icons.people_alt_outlined, Icons.people_alt_rounded, 'কাস্টমার'),
  _NavItem(Icons.two_wheeler_outlined, Icons.two_wheeler_rounded, 'রাইডার'),
];

/// Secondary tools opened as full pages (they bring their own app bar and
/// back button, so they are pushed rather than embedded).
const _toolNav = <_NavItem>[
  _NavItem(Icons.sell_outlined, Icons.sell_rounded, 'মূল্য তালিকা'),
  _NavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'উত্তোলন'),
  _NavItem(Icons.description_outlined, Icons.description_rounded, 'মেমো সেন্টার'),
  _NavItem(Icons.support_agent_outlined, Icons.support_agent_rounded, 'সাপোর্ট সেটিংস'),
];

/// The admin panel shell. On a wide window (desktop) it renders a fixed
/// left sidebar + top bar + content area — a real admin dashboard. On a
/// narrow window (phone) it falls back to bottom-tab navigation, so the
/// same panel is still usable on a mobile browser.
class AdminRootShell extends StatefulWidget {
  const AdminRootShell({super.key});
  @override
  State<AdminRootShell> createState() => _AdminRootShellState();
}

class _AdminRootShellState extends State<AdminRootShell> {
  /// Below this width we drop to the mobile layout.
  static const double _desktopBreakpoint = 900;

  int _index = 0;

  @override
  void initState() {
    super.initState();
    // The admin panel is a desktop product — break out of the phone frame
    // while it is on screen.
    PhoneFrame.fullScreen.value = true;
  }

  @override
  void dispose() {
    PhoneFrame.fullScreen.value = false;
    super.dispose();
  }

  /// The embedded screen for a primary index (0–3).
  Widget _screenFor(int i) {
    switch (i) {
      case 0:
        return DashboardScreen(onOpenOrders: () => setState(() => _index = 1));
      case 1:
        return const OrdersScreen();
      case 2:
        return const CustomersScreen();
      case 3:
        return const RidersScreen();
      default:
        return DashboardScreen(onOpenOrders: () => setState(() => _index = 1));
    }
  }

  /// Opens a secondary tool as a full page.
  void _openTool(int toolIndex) {
    final page = switch (toolIndex) {
      0 => const CatalogScreen(),
      1 => const WithdrawalsScreen(),
      2 => const MemoCenterScreen(),
      _ => const SupportSettingsScreen(),
    };
    Navigator.push(context, AppPageRoute(builder: (_) => page));
  }

  String get _title => _primaryNav[_index].label;

  Future<void> _logout() async {
    await AuthService.logout();
    AdminService.clearRoleCache();
    PhoneFrame.fullScreen.value = false;
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      AppPageRoute(builder: (_) => const LoginScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _desktopBreakpoint;
        return isDesktop ? _buildDesktop(context) : _buildMobile(context);
      },
    );
  }

  // ── Desktop: sidebar + top bar + content ──────────────────

  Widget _buildDesktop(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Sidebar(
            selectedIndex: _index,
            onSelect: (i) => setState(() => _index = i),
            onOpenTool: _openTool,
            onLogout: _logout,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: _title),
                Expanded(
                  // Screens keep their own state across tab switches.
                  child: IndexedStack(
                    index: _index,
                    children: List.generate(_primaryNav.length, _screenFor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile: bottom nav + drawer (unchanged behaviour) ─────

  Widget _buildMobile(BuildContext context) {
    // Mobile bottom-nav only exposes the four everyday screens; the rest
    // live in the drawer.
    final mobileIndex = _index < 4 ? _index : 0;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 52,
        leading: const Padding(padding: EdgeInsets.all(6), child: AppLogo(size: 40)),
        title: Text(_primaryNav[mobileIndex].label),
        centerTitle: false,
      ),
      drawer: _MobileDrawer(
        onSelectPrimary: (i) => setState(() => _index = i),
        onOpenTool: _openTool,
        onLogout: _logout,
      ),
      body: IndexedStack(index: mobileIndex, children: List.generate(4, _screenFor)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: mobileIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.blueSoft,
        height: 64,
        destinations: [
          for (int i = 0; i < 4; i++)
            NavigationDestination(
              icon: Icon(_primaryNav[i].icon),
              selectedIcon: Icon(_primaryNav[i].activeIcon, color: AppColors.blue),
              label: _primaryNav[i].label,
            ),
        ],
      ),
    );
  }
}

// ── Sidebar (desktop) ───────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onOpenTool;
  final VoidCallback onLogout;
  const _Sidebar({required this.selectedIndex, required this.onSelect, required this.onOpenTool, required this.onLogout});

  static const _navy = Color(0xFF0B1F3A);
  static const _navyLight = Color(0xFF13294D);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      color: _navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                const AppLogo(size: 42, padding: EdgeInsets.all(5), rounded: true),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('ধোপা বাড়ি', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                    Text('অ্যাডমিন প্যানেল', style: TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _label('প্রধান'),
                for (int i = 0; i < _primaryNav.length; i++)
                  _navTile(i, _primaryNav[i], active: i == selectedIndex, onTap: () => onSelect(i)),
                const SizedBox(height: 14),
                _label('টুলস'),
                for (int i = 0; i < _toolNav.length; i++)
                  _navTile(i, _toolNav[i], active: false, onTap: () => onOpenTool(i)),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          // Admin identity + logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _navyLight, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 18, backgroundColor: AppColors.blue, child: Icon(Icons.person_rounded, color: Colors.white, size: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              MockData.userName.isNotEmpty ? MockData.userName : 'অ্যাডমিন',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5),
                            ),
                            const Text('Super Admin', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'লগআউট',
                        icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
                        onPressed: onLogout,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 11, color: Colors.white38),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        BusinessHours.labelWithDays,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 9.5, color: Colors.white38, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white38, letterSpacing: 0.8)),
    );
  }

  Widget _navTile(int index, _NavItem item, {required bool active, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? AppColors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(active ? item.activeIcon : item.icon, size: 19, color: active ? Colors.white : Colors.white70),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: active ? Colors.white : Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top bar (desktop) ───────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(
                  BusinessHours.isOpenNow ? 'এখন খোলা' : 'এখন বন্ধ',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          IconButton(
            tooltip: 'নোটিফিকেশন',
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.muted),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('কোনো নতুন নোটিফিকেশন নেই')),
            ),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.blueSoft,
            child: Text(
              (MockData.userName.isNotEmpty ? MockData.userName.characters.first : 'অ'),
              style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile drawer (all destinations) ───────────────────────

class _MobileDrawer extends StatelessWidget {
  final ValueChanged<int> onSelectPrimary;
  final ValueChanged<int> onOpenTool;
  final VoidCallback onLogout;
  const _MobileDrawer({required this.onSelectPrimary, required this.onOpenTool, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.blue, AppColors.blueDeep], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Row(
                children: const [
                  AppLogo(size: 46, padding: EdgeInsets.all(6), rounded: true),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('অ্যাডমিন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                        Text('Super Admin', style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (int i = 0; i < _primaryNav.length; i++)
                    _item(context, _primaryNav[i].icon, _primaryNav[i].label, onTap: () {
                      Navigator.pop(context);
                      onSelectPrimary(i);
                    }),
                  const Divider(height: 24, indent: 20, endIndent: 20, color: AppColors.line),
                  for (int i = 0; i < _toolNav.length; i++)
                    _item(context, _toolNav[i].icon, _toolNav[i].label, onTap: () {
                      Navigator.pop(context);
                      onOpenTool(i);
                    }),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            _item(context, Icons.logout_rounded, 'লগআউট', danger: true, onTap: () {
              Navigator.pop(context);
              onLogout();
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, {required VoidCallback onTap, bool danger = false}) {
    return ListTile(
      leading: Icon(icon, color: danger ? AppColors.danger : AppColors.ink, size: 22),
      title: Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: danger ? AppColors.danger : AppColors.ink)),
      onTap: onTap,
      dense: true,
    );
  }
}
