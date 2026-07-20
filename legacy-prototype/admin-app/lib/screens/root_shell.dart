import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_page_route.dart';
import 'dashboard_screen.dart';
import 'orders_screen.dart';
import 'customers_screen.dart';
import 'riders_screen.dart';
import 'catalog_screen.dart';
import 'withdrawals_screen.dart';
import 'login_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  static const _titles = ['ড্যাশবোর্ড', 'অর্ডার ব্যবস্থাপনা', 'কাস্টমার ব্যবস্থাপনা', 'রাইডার ব্যবস্থাপনা'];

  final _tabs = const [
    DashboardScreen(),
    OrdersScreen(),
    CustomersScreen(),
    RidersScreen(),
  ];

  void _comingSoon(String label) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label শীঘ্রই আসছে')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('৩টি নতুন নোটিফিকেশন'))),
            ),
          ),
        ],
      ),
      drawer: _AdminDrawer(onComingSoon: _comingSoon),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.blueSoft,
        height: 64,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.blue), label: 'ড্যাশবোর্ড'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.blue), label: 'অর্ডার'),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt_rounded, color: AppColors.blue), label: 'কাস্টমার'),
          NavigationDestination(icon: Icon(Icons.two_wheeler_outlined), selectedIcon: Icon(Icons.two_wheeler_rounded, color: AppColors.blue), label: 'রাইডার'),
        ],
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final void Function(String) onComingSoon;
  const _AdminDrawer({required this.onComingSoon});

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
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
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
                  _sectionLabel('ক্যাটালগ'),
                  _item(context, Icons.category_rounded, 'সার্ভিস, ক্যাটাগরি, আইটেম ও মূল্য', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, AppPageRoute(builder: (_) => const CatalogScreen()));
                  }),
                  _item(context, Icons.account_balance_wallet_rounded, 'রাইডার উত্তোলন অনুরোধ', onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, AppPageRoute(builder: (_) => const WithdrawalsScreen()));
                  }),
                  const Divider(height: 24, indent: 20, endIndent: 20, color: AppColors.line),
                  _sectionLabel('আরও'),
                  _item(context, Icons.admin_panel_settings_outlined, 'অ্যাডমিন ব্যবস্থাপনা ও রোল', onTap: () => onComingSoon('অ্যাডমিন ব্যবস্থাপনা')),
                  _item(context, Icons.campaign_outlined, 'প্রোমোশন ও কুপন', onTap: () => onComingSoon('প্রোমোশন')),
                  _item(context, Icons.notifications_active_outlined, 'নোটিফিকেশন পাঠান', onTap: () => onComingSoon('নোটিফিকেশন')),
                  _item(context, Icons.support_agent_outlined, 'সাপোর্ট সেটিংস', onTap: () => onComingSoon('সাপোর্ট সেটিংস')),
                  _item(context, Icons.language_outlined, 'ওয়েবসাইট সেটিংস', onTap: () => onComingSoon('ওয়েবসাইট সেটিংস')),
                  _item(context, Icons.payment_outlined, 'পেমেন্ট সেটিংস', onTap: () => onComingSoon('পেমেন্ট সেটিংস')),
                  _item(context, Icons.bar_chart_rounded, 'রিপোর্ট (PDF/Excel)', onTap: () => onComingSoon('রিপোর্ট')),
                  _item(context, Icons.settings_outlined, 'সিস্টেম সেটিংস', onTap: () => onComingSoon('সিস্টেম সেটিংস')),
                  _item(context, Icons.fact_check_outlined, 'অডিট লগ', onTap: () => onComingSoon('অডিট লগ')),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            _item(
              context,
              Icons.logout_rounded,
              'লগআউট',
              danger: true,
              onTap: () => Navigator.of(context).pushAndRemoveUntil(AppPageRoute(builder: (_) => const LoginScreen()), (r) => false),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.muted, letterSpacing: 0.6)),
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
