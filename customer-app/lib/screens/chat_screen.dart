import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/mock_data.dart';

enum MessageStatus { sent, delivered, read }

class ChatMessage {
  final String text;
  final bool fromMe;
  final String time;
  final bool isImage;
  final MessageStatus status;
  const ChatMessage({
    required this.text,
    required this.fromMe,
    required this.time,
    this.isImage = false,
    this.status = MessageStatus.read,
  });
}

class ChatScreen extends StatefulWidget {
  final ChatPreview chat;
  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late List<ChatMessage> _messages;
  bool _typing = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _messages = [
      ChatMessage(
        text: widget.chat.isRider
            ? 'হ্যালো, আমি আপনার অর্ডার নিয়ে আসছি।'
            : 'আপনাকে স্বাগতম! কীভাবে সাহায্য করতে পারি?',
        fromMe: false,
        time: '১০:৩০ AM',
      ),
      ChatMessage(
        text: widget.chat.isRider
            ? 'প্রায় ১৫ মিনিটের মধ্যে পৌঁছে যাব।'
            : 'আপনার অর্ডার নিয়ে কোনো প্রশ্ন আছে?',
        fromMe: false,
        time: '১০:৩১ AM',
      ),
      const ChatMessage(
        text: 'ধন্যবাদ, অপেক্ষা করছি।',
        fromMe: true,
        time: '১০:৩৫ AM',
        status: MessageStatus.read,
      ),
      ChatMessage(
        text: widget.chat.lastMessage,
        fromMe: false,
        time: '১০:৪২ AM',
      ),
    ];
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppMotion.base,
        curve: AppMotion.curve,
      );
    });
  }

  void _send({bool asImage = false}) {
    final text = asImage ? '📷 ছবি' : _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          fromMe: true,
          time: 'এখন',
          isImage: asImage,
          status: MessageStatus.sent,
        ),
      );
      _controller.clear();
      _typing = true;
    });
    _scrollToBottom();

    // Simulate delivered → read receipt progression on the just-sent message.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _updateLastStatus(MessageStatus.delivered));
    });

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _updateLastStatus(MessageStatus.read);
        _typing = false;
        _messages.add(
          const ChatMessage(
            text: 'ঠিক আছে, ধন্যবাদ!',
            fromMe: false,
            time: 'এখন',
          ),
        );
      });
      _scrollToBottom();
    });
  }

  void _updateLastStatus(MessageStatus status) {
    final idx = _messages.lastIndexWhere((m) => m.fromMe);
    if (idx == -1) return;
    final m = _messages[idx];
    _messages[idx] = ChatMessage(
      text: m.text,
      fromMe: m.fromMe,
      time: m.time,
      isImage: m.isImage,
      status: status,
    );
  }

  void _notImplemented(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label শীঘ্রই আসছে')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: widget.chat.isRider
                      ? AppColors.tealSoft
                      : AppColors.blueSoft,
                  child: Icon(
                    widget.chat.isRider
                        ? Icons.two_wheeler_rounded
                        : Icons.support_agent_rounded,
                    color: widget.chat.isRider
                        ? AppColors.teal
                        : AppColors.blue,
                    size: 18,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.chat.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const Text(
                  'অনলাইন আছে',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount:
                    _messages.length +
                    (_typing ? 1 : 0) +
                    1, // +1 for the day divider
                itemBuilder: (context, i) {
                  if (i == 0) return const _DayDivider(label: 'আজ');
                  final msgIndex = i - 1;
                  if (msgIndex == _messages.length) {
                    return const _TypingBubble();
                  }

                  final message = _messages[msgIndex];
                  final prev = msgIndex > 0 ? _messages[msgIndex - 1] : null;
                  final next = msgIndex < _messages.length - 1
                      ? _messages[msgIndex + 1]
                      : null;
                  final groupedWithPrev =
                      prev != null && prev.fromMe == message.fromMe;
                  final groupedWithNext =
                      next != null && next.fromMe == message.fromMe;

                  return _AnimatedBubble(
                    key: ValueKey('${message.time}_$msgIndex'),
                    message: message,
                    showTail: !groupedWithNext,
                    topSpacing: groupedWithPrev ? 2 : 10,
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Tooltip(
                      message: 'ছবি পাঠান',
                      child: IconButton(
                        onPressed: () => _send(asImage: true),
                        icon: const Icon(
                          Icons.image_outlined,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'ইমোজি',
                      child: IconButton(
                        onPressed: () => _notImplemented('ইমোজি'),
                        icon: const Icon(
                          Icons.emoji_emotions_outlined,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        decoration: const InputDecoration(
                          hintText: 'বার্তা লিখুন...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Semantics(
                      button: true,
                      label: 'বার্তা পাঠান',
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        decoration: BoxDecoration(
                          color: _hasText ? AppColors.blue : AppColors.line,
                          shape: BoxShape.circle,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _hasText ? () => _send() : null,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                Icons.send_rounded,
                                color: _hasText
                                    ? Colors.white
                                    : AppColors.muted,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  final String label;
  const _DayDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.line),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showTail;
  final double topSpacing;
  const _AnimatedBubble({
    super.key,
    required this.message,
    required this.showTail,
    required this.topSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.base,
      curve: AppMotion.entrance,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: child,
        ),
      ),
      child: Align(
        alignment: message.fromMe
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Semantics(
          label: '${message.fromMe ? "আপনি" : "প্রেরক"}: ${message.text}',
          child: Container(
            margin: EdgeInsets.only(top: topSpacing, bottom: 2),
            padding: message.isImage
                ? const EdgeInsets.all(6)
                : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            decoration: BoxDecoration(
              color: message.fromMe ? AppColors.blue : Colors.white,
              border: message.fromMe ? null : Border.all(color: AppColors.line),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(
                  message.fromMe ? 16 : (showTail ? 3 : 16),
                ),
                bottomRight: Radius.circular(
                  message.fromMe ? (showTail ? 3 : 16) : 16,
                ),
              ),
              boxShadow: message.fromMe ? null : AppShadows.soft,
            ),
            child: message.isImage ? _imageBubble(context) : _textBubble(),
          ),
        ),
      ),
    );
  }

  Widget _textBubble() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.text,
          style: TextStyle(
            color: message.fromMe ? Colors.white : AppColors.ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (message.time.isNotEmpty) _timeRow(),
      ],
    );
  }

  Widget _imageBubble(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 180,
            height: 130,
            color: message.fromMe
                ? Colors.white.withValues(alpha: 0.15)
                : AppColors.paper,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_rounded,
              size: 36,
              color: message.fromMe ? Colors.white70 : AppColors.muted,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
          child: _timeRow(),
        ),
      ],
    );
  }

  Widget _timeRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.time,
            style: TextStyle(
              color: message.fromMe ? Colors.white70 : AppColors.muted,
              fontSize: 9.5,
            ),
          ),
          if (message.fromMe) ...[
            const SizedBox(width: 4),
            Icon(
              message.status == MessageStatus.sent
                  ? Icons.check_rounded
                  : Icons.done_all_rounded,
              size: 13,
              color: message.status == MessageStatus.read
                  ? const Color(0xFF7ED6FF)
                  : Colors.white70,
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        label: 'টাইপ করছে',
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.line),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(3),
            ),
            boxShadow: AppShadows.soft,
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final t = (_controller.value + i * 0.2) % 1.0;
                  final dy = -4 * (0.5 - (t - 0.5).abs()) * 2;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Transform.translate(
                      offset: Offset(0, dy),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.muted,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
