import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/skeleton.dart';
import '../widgets/state_views.dart';
import '../widgets/app_page_route.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chats = MockData.chats;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('চ্যাট', style: AppText.h1),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.base,
              child: _loading
                  ? ListView.separated(
                      key: const ValueKey('skeleton'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: 3,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, i) => Row(
                        children: const [
                          SkeletonBox(
                            width: 44,
                            height: 44,
                            borderRadius: BorderRadius.all(Radius.circular(22)),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonBox(width: 120, height: 13),
                                SizedBox(height: 6),
                                SkeletonBox(width: 180, height: 11),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : chats.isEmpty
                  ? EmptyState(
                      key: const ValueKey('empty'),
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'কোনো কথোপকথন নেই',
                      subtitle:
                          'অর্ডার করলে সাপোর্ট ও রাইডারের সাথে চ্যাট এখানে দেখা যাবে।',
                    )
                  : ListView.separated(
                      key: const ValueKey('content'),
                      padding: const EdgeInsets.all(20),
                      itemCount: chats.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final chat = chats[i];
                        final unread = chat.unread > 0;
                        return FadeSlideIn(
                          delayMs: i * 50,
                          child: PressableScale(
                            onTap: () => Navigator.push(
                              context,
                              AppPageRoute(
                                builder: (_) => ChatScreen(chat: chat),
                              ),
                            ),
                            child: Semantics(
                              button: true,
                              label:
                                  '${chat.name}, ${chat.lastMessage}${unread ? ', ${chat.unread} টি অপঠিত' : ''}',
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  border: Border.all(
                                    color: unread
                                        ? AppColors.blue.withValues(alpha: 0.25)
                                        : AppColors.line,
                                  ),
                                  color: unread
                                      ? AppColors.blueSoft.withValues(
                                          alpha: 0.3,
                                        )
                                      : Colors.white,
                                  boxShadow: AppShadows.soft,
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: chat.isRider
                                              ? AppColors.tealSoft
                                              : AppColors.blueSoft,
                                          child: Icon(
                                            chat.isRider
                                                ? Icons.two_wheeler_rounded
                                                : Icons.support_agent_rounded,
                                            color: chat.isRider
                                                ? AppColors.teal
                                                : AppColors.blue,
                                            size: 22,
                                          ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: AppColors.green,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  chat.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                    color: AppColors.ink,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                chat.time,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  color: unread
                                                      ? AppColors.blue
                                                      : AppColors.muted,
                                                  fontWeight: unread
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              if (chat.isRider)
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                    right: 4,
                                                  ),
                                                  child: Icon(
                                                    Icons.two_wheeler_rounded,
                                                    size: 12,
                                                    color: AppColors.muted,
                                                  ),
                                                ),
                                              Expanded(
                                                child: Text(
                                                  chat.lastMessage,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    color: unread
                                                        ? AppColors.ink
                                                        : AppColors.muted,
                                                    fontWeight: unread
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (unread) ...[
                                                const SizedBox(width: 8),
                                                TweenAnimationBuilder<double>(
                                                  tween: Tween(
                                                    begin: 0,
                                                    end: 1,
                                                  ),
                                                  duration: AppMotion.base,
                                                  curve: Curves.easeOutBack,
                                                  builder:
                                                      (context, t, child) =>
                                                          Transform.scale(
                                                            scale: t,
                                                            child: child,
                                                          ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(5),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color:
                                                              AppColors.danger,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    constraints:
                                                        const BoxConstraints(
                                                          minWidth: 18,
                                                          minHeight: 18,
                                                        ),
                                                    child: Text(
                                                      '${chat.unread}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
