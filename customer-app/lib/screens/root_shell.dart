import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_page_route.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';
import 'new_order_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  void _goToNewOrder({String service = 'Wash', bool quick = false}) {
    Navigator.push(context, AppPageRoute(builder: (_) => NewOrderScreen(initialService: service, quickCheckout: quick)));
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(
        // The home checkout bar means "I've picked my items" → jump straight
        // to the 2-step তথ্য / নিশ্চিত করুন flow.
        onStartNewOrder: () => _goToNewOrder(quick: true),
        onSwitchTab: (i) => setState(() => _index = i),
      ),
      const OrdersScreen(),
      const SizedBox.shrink(), // index 2 is the FAB, never actually shown
      const ChatListScreen(),
      ProfileScreen(onSwitchTab: (i) => setState(() => _index = i)),
    ];

    return Scaffold(
      // IndexedStack (not a rebuild-on-switch widget) so each tab keeps its
      // scroll position / in-progress state (e.g. a half-typed chat message)
      // when the user switches away and back.
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        onNewOrder: () => _goToNewOrder(),
        chatUnread: 1,
      ),
    );
  }
}
