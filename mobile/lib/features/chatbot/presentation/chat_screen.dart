import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/design/colors/app_colors.dart';
import '../application/chat_service.dart';

part 'chat_screen.g.dart';

// --------------------------------------------------------------------------
// State model
// --------------------------------------------------------------------------
class ChatMessage {
  final String text;
  final bool isBot;

  const ChatMessage({required this.text, required this.isBot});
}

// --------------------------------------------------------------------------
// Notifier
// --------------------------------------------------------------------------
@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  ({List<ChatMessage> messages, bool isTyping}) build() {
    return (
      messages: [
        const ChatMessage(
          text:
              'Hello! 👋 I am your **Vitable Assistant**. How can I help you today?\n\n'
              'Are you a new or returning patient?',
          isBot: true,
        ),
      ],
      isTyping: false,
    );
  }

  Future<void> addMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Add user message + show typing
    state = (
      messages: [...state.messages, ChatMessage(text: trimmed, isBot: false)],
      isTyping: true,
    );

    final chatService = ref.read(chatServiceProvider);
    final botReply = await chatService.sendMessage(trimmed);

    state = (
      messages: [
        ...state.messages,
        ChatMessage(text: botReply, isBot: true),
      ],
      isTyping: false,
    );
  }
}

// --------------------------------------------------------------------------
// Quick reply suggestions (shown only after the first bot greeting)
// --------------------------------------------------------------------------
const _quickReplies = [
  'New patient',
  'Returning patient',
  'See services',
  'Talk to a human',
];

// --------------------------------------------------------------------------
// Main screen
// --------------------------------------------------------------------------
class ChatScreen extends HookConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;
    final isTyping = chatState.isTyping;

    final textController = useTextEditingController();
    final scrollController = useScrollController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Auto-scroll when new messages or typing changes
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      });
      return null;
    }, [messages.length, isTyping]);

    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1A2D2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFF0FAF8), Color(0xFFE9F5F2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _GlassAppBar(isDark: isDark),
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: Column(
          children: [
            // ----------------------------------------------------------
            // Message list
            // ----------------------------------------------------------
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 130, 16, 12),
                itemCount: messages.length +
                    (isTyping ? 1 : 0) +
                    (messages.length == 1 ? 1 : 0), // quick replies
                itemBuilder: (context, index) {
                  // Show quick replies after the first bot greeting
                  if (messages.length == 1 && index == 1 && !isTyping) {
                    return _QuickReplies(
                      replies: _quickReplies,
                      onTap: (reply) {
                        textController.text = reply;
                        _sendMessage(ref, textController, scrollController);
                      },
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3);
                  }

                  // Typing indicator bubble
                  if (isTyping && index == messages.length) {
                    return _TypingIndicatorBubble(isDark: isDark)
                        .animate()
                        .fadeIn()
                        .slideX(begin: -0.2);
                  }

                  final msg = messages[index];
                  return _MessageBubble(
                    message: msg,
                    isDark: isDark,
                    animationDelay: (index * 50).ms,
                  );
                },
              ),
            ),

            // ----------------------------------------------------------
            // Input area
            // ----------------------------------------------------------
            _InputArea(
              controller: textController,
              isDark: isDark,
              onSend: () => _sendMessage(ref, textController, scrollController),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(
    WidgetRef ref,
    TextEditingController controller,
    ScrollController scrollController,
  ) {
    final text = controller.text;
    if (text.trim().isEmpty) return;
    ref.read(chatProvider.notifier).addMessage(text);
    controller.clear();
  }
}

// --------------------------------------------------------------------------
// Glass AppBar
// --------------------------------------------------------------------------
class _GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;

  const _GlassAppBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: preferredSize.height,
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: (isDark ? Colors.white : AppColors.primary)
                    .withOpacity(0.08),
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Bot avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF14B8A6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vitable Assistant',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              'Online',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
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
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(110);
}

// --------------------------------------------------------------------------
// Message bubble
// --------------------------------------------------------------------------
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  final Duration animationDelay;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    final isBot = message.isBot;

    Widget bubble;
    if (isBot) {
      bubble = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Small bot avatar
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 16),
          ),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12, right: 48),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A37)
                    : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  strong: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.secondary : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      bubble = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12, left: 48),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0D8073)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return bubble
        .animate(delay: animationDelay)
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.15, duration: 300.ms, curve: Curves.easeOut);
  }
}

// --------------------------------------------------------------------------
// Typing indicator
// --------------------------------------------------------------------------
class _TypingIndicatorBubble extends StatelessWidget {
  final bool isDark;

  const _TypingIndicatorBubble({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(right: 8, bottom: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.health_and_safety_rounded,
              color: Colors.white, size: 16),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E3A37) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scaleXY(
                    begin: 0.5,
                    end: 1.0,
                    duration: 600.ms,
                    delay: (i * 200).ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scaleXY(
                    begin: 1.0,
                    end: 0.5,
                    duration: 600.ms,
                    curve: Curves.easeInOut,
                  );
            }),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------------------
// Quick reply chips
// --------------------------------------------------------------------------
class _QuickReplies extends StatelessWidget {
  final List<String> replies;
  final void Function(String) onTap;

  const _QuickReplies({required this.replies, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 46),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: replies
            .map(
              (r) => GestureDetector(
                onTap: () => onTap(r),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    r,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn()
                    .scale(begin: const Offset(0.9, 0.9)),
              ),
            )
            .toList(),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Input area
// --------------------------------------------------------------------------
class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onSend;

  const _InputArea({
    required this.controller,
    required this.isDark,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color:
                (isDark ? Colors.black : Colors.white).withOpacity(0.05),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : AppColors.primary)
                    .withOpacity(0.08),
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: 4,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: GestureDetector(
                    onTap: onSend,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF14B8A6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.40),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    )
                        .animate(target: 1)
                        .scaleXY(begin: 1, end: 0.92, duration: 100.ms),
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
