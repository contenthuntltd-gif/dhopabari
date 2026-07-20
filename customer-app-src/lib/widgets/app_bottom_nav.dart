import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex; // 0 home, 1 orders, 2 (new order fab), 3 chat, 4 profile
  final ValueChanged<int> onTap;
  final VoidCallback onNewOrder;
  final int chatUnread;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onNewOrder,
    this.chatUnread = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line, width: 1)),
        boxShadow: [BoxShadow(color: AppColors.ink.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -8))],
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tab(icon: Icons.home_rounded, label: 'হোম', index: 0),
            _tab(icon: Icons.list_alt_rounded, label: 'আমার অর্ডার', index: 1),
            _newOrderTab(),
            _tab(icon: Icons.chat_bubble_rounded, label: 'চ্যাট', index: 3, badge: chatUnread),
            _tab(icon: Icons.person_rounded, label: 'প্রোফাইল', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _tab({required IconData icon, required String label, required int index, int badge = 0}) {
    final active = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: active ? AppColors.blue : AppColors.muted, size: 24),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.blue : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newOrderTab() {
    return Expanded(
      child: InkWell(
        onTap: onNewOrder,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -18),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDeep]),
                  boxShadow: [BoxShadow(color: AppColors.blue.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 6))],
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -10),
              child: const Text(
                'নতুন অর্ডার',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
