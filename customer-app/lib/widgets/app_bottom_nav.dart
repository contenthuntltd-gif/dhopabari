import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/language.dart';

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
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isEnglish,
      builder: (context, _, _) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.line, width: 1)),
          boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -8))],
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 14),
        child: SafeArea(
          top: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tab(icon: Icons.home_rounded, label: AppLanguage.tr('হোম'), index: 0),
              _tab(icon: Icons.list_alt_rounded, label: AppLanguage.tr('আমার অর্ডার'), index: 1),
              _newOrderTab(),
              _tab(icon: Icons.chat_bubble_rounded, label: AppLanguage.tr('চ্যাট'), index: 3, badge: chatUnread),
              _tab(icon: Icons.person_rounded, label: AppLanguage.tr('প্রোফাইল'), index: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab({required IconData icon, required String label, required int index, int badge = 0}) {
    final active = currentIndex == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: badge > 0 ? '$label, $badge টি নতুন' : label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedScale(
                        scale: active ? 1.08 : 1.0,
                        duration: AppMotion.fast,
                        curve: Curves.easeOut,
                        child: Icon(icon, color: active ? AppColors.blue : AppColors.muted, size: 24),
                      ),
                      if (badge > 0)
                        Positioned(
                          top: -4,
                          right: -8,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: AppMotion.base,
                            curve: Curves.easeOutBack,
                            builder: (context, t, child) => Transform.scale(scale: t, child: child),
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
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: AppMotion.fast,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                      color: active ? AppColors.blue : AppColors.muted,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _newOrderTab() {
    return Expanded(
      child: Semantics(
        button: true,
        label: 'নতুন অর্ডার তৈরি করুন',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onNewOrder,
            borderRadius: BorderRadius.circular(30),
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
                      boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 6))],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: Text(
                    AppLanguage.tr('নতুন অর্ডার'),
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
