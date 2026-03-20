import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/design/typography/text_scale_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/colors/app_colors.dart';
import '../application/chat_service.dart';
import '../../identity/application/auth_notifier.dart';
import '../../identity/domain/auth_state.dart';
import '../../profile/application/profile_provider.dart';

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
// Chat state (messages + typing + quick replies for current session)
// --------------------------------------------------------------------------
class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final List<String> quickReplies;

  const ChatState({
    required this.messages,
    required this.isTyping,
    required this.quickReplies,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    List<String>? quickReplies,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isTyping: isTyping ?? this.isTyping,
        quickReplies: quickReplies ?? this.quickReplies,
      );
}

// --------------------------------------------------------------------------
// Notifier
// --------------------------------------------------------------------------
@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  Future<ChatState> build() async {
    // Resolve auth state; don't crash if it errors – treat as unauthenticated.
    final authState = await ref.watch(authProvider.future).catchError(
          (_) => const AuthState(status: AuthStatus.unauthenticated),
        );

    final isLoggedIn = authState.status == AuthStatus.authenticated;

    // Try to fetch the user's first name when authenticated.
    String? firstName;
    if (isLoggedIn) {
      try {
        final profile = await ref.watch(profileProvider.future);
        if (profile.name.trim().isNotEmpty) {
          firstName = profile.name.trim().split(' ').first;
        }
      } catch (_) {
        // Ignore errors, greet without name
      }
    }

    final greeting = isLoggedIn
        ? 'Hello${firstName != null ? ', $firstName' : ''}! 👋 Welcome back to **Vitable Assistant**.\n\nHow can I help you today?'
        : 'Hello! 👋 I am your **Vitable Assistant**. How can I help you today?\n\nAre you a new or returning patient?';

    final quickReplies = isLoggedIn
        ? const ['My appointments', 'Update profile', 'See services', 'Talk to a human']
        : const ['New patient', 'Returning patient', 'See services', 'Talk to a human'];

    return ChatState(
      messages: [ChatMessage(text: greeting, isBot: true)],
      isTyping: false,
      quickReplies: quickReplies,
    );
  }

  Future<void> addMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final current = state.value;
    if (current == null) return;

    // Add user message + show typing
    state = AsyncValue.data(
      current.copyWith(
        messages: [...current.messages, ChatMessage(text: trimmed, isBot: false)],
        isTyping: true,
      ),
    );

    final chatService = ref.read(chatServiceProvider);
    final result = await chatService.sendMessage(trimmed);

    // If a token was returned (e.g. after login), persist it and rebuild
    // so the greeting updates to the authenticated version.
    if (result.token != null) {
      await ref.read(authProvider.notifier).login(result.token!);
      ref.invalidateSelf();
      return;
    }

    final updated = state.value;
    if (updated == null) return;
    state = AsyncValue.data(
      updated.copyWith(
        messages: [
          ...updated.messages,
          ChatMessage(text: result.response, isBot: true),
        ],
        isTyping: false,
      ),
    );
  }
}

// Quick replies are now stored in ChatState and set dynamically based on
// auth status. See ChatNotifier.build() for the two variants.

// --------------------------------------------------------------------------
// Main screen
// --------------------------------------------------------------------------
class ChatScreen extends HookConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatAsync = ref.watch(chatProvider);
    final chatState = chatAsync.value;
    final messages = chatState?.messages ?? const [];
    final isTyping = chatState?.isTyping ?? false;
    final quickReplies = chatState?.quickReplies ?? const [];

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
              child: chatAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 130, 16, 12),
                      itemCount: messages.length +
                          (isTyping ? 1 : 0) +
                          (messages.length == 1 && quickReplies.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show quick replies after the first bot greeting
                        if (messages.length == 1 &&
                            quickReplies.isNotEmpty &&
                            index == 1 &&
                            !isTyping) {
                          return _QuickReplies(
                            replies: quickReplies,
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
class _GlassAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool isDark;

  const _GlassAppBar({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: preferredSize.height,
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.05),
            border: Border(
              bottom: BorderSide(
                color: (isDark ? Colors.white : AppColors.primary)
                    .withValues(alpha: 0.08),
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
                          color: AppColors.primary.withValues(alpha: 0.35),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
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
                  // Profile Button
                  IconButton(
                    icon: Hero(
                      tag: 'profile-photo',
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.secondary,
                          child: Icon(Icons.person_rounded,
                              size: 18, color: AppColors.primary),
                        ),
                      ),
                    ),
                    onPressed: () => context.push('/profile'),
                  ),
                  // Accessibility menu
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.accessibility_new_rounded,
                      color: isDark ? Colors.white70 : AppColors.primary,
                      size: 24,
                    ),
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'font_size',
                        child: Row(
                          children: [
                            Icon(Icons.format_size_rounded,
                                size: 20,
                                color: isDark ? Colors.white70 : AppColors.primary),
                            const SizedBox(width: 12),
                            const Text('Text Scale Setting'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'screen_reader',
                        child: Row(
                          children: [
                            Icon(Icons.record_voice_over_rounded,
                                size: 20,
                                color: isDark ? Colors.white70 : AppColors.primary),
                            const SizedBox(width: 12),
                            const Text('Screen Reader Help'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'voice_control',
                        child: Row(
                          children: [
                            Icon(Icons.settings_voice_rounded,
                                size: 20,
                                color: isDark ? Colors.white70 : AppColors.primary),
                            const SizedBox(width: 12),
                            const Text('Voice Control Guide'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'contrast',
                        child: Row(
                          children: [
                            Icon(Icons.contrast_rounded,
                                size: 20,
                                color: isDark ? Colors.white70 : AppColors.primary),
                            const SizedBox(width: 12),
                            const Text('High Contrast'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'font_size') {
                        _showTextScaleDialog(context, ref);
                      } else {
                        // Logic for other accessibility menu options
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Accessibility feature: $value coming soon!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTextScaleDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final scale = ref.watch(textScaleProvider);
            return AlertDialog(
              title: const Text('Adjust Text Size'),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Sample Text',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(scale * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Slider(
                    value: scale,
                    min: 0.8,
                    max: 2.0,
                    divisions: 12,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      ref.read(textScaleProvider.notifier).setScale(value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(textScaleProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
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
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
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
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
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
                  color: AppColors.primary.withValues(alpha: 0.6),
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
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    r,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
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
                (isDark ? Colors.black : Colors.white).withValues(alpha: 0.05),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : AppColors.primary)
                    .withValues(alpha: 0.08),
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
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                            color: AppColors.primary.withValues(alpha: 0.40),
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
