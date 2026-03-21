import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design/colors/app_colors.dart';
import '../application/chat_service.dart';
import '../../identity/application/auth_notifier.dart';
import '../../identity/domain/auth_state.dart';
import '../../../core/design/theme/high_contrast_provider.dart';
import '../../../core/design/accessibility/accessibility_dialogs.dart';

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
  }) => ChatState(
    messages: messages ?? this.messages,
    isTyping: isTyping ?? this.isTyping,
    quickReplies: quickReplies ?? this.quickReplies,
  );
}

// --------------------------------------------------------------------------
// Notifier
// --------------------------------------------------------------------------
@Riverpod(keepAlive: true)
class ChatNotifier extends _$ChatNotifier {
  @override
  ChatState build() {
    // 1. Listen for auth changes to handle greeting updates or resets
    ref.listen(authProvider, (previous, next) {
      _handleAuthChange(previous, next);
    });

    // 2. Initial state based on current auth
    final authState = ref.read(authProvider);
    return _createInitialState(authState.value);
  }

  ChatState _createInitialState(AuthState? auth) {
    final firstName = auth?.firstName;
    final isPt = auth?.language == 'pt';

    final greeting = isPt
        ? (firstName != null
            ? 'Olá $firstName! 👋 Bem-vindo de volta ao **Assistente Vitable**.\n\nComo posso ajudar hoje?'
            : 'Olá! 👋 Eu sou seu **Assistente Vitable**. Como posso ajudar hoje?\n\nVocê é um paciente novo ou já nos conhece?')
        : (firstName != null
            ? 'Hello $firstName! 👋 Welcome back to **Vitable Assistant**.\n\nHow can I help you today?'
            : 'Hello! 👋 I am your **Vitable Assistant**. How can I help you today?\n\nAre you a new or returning patient?');

    final quickReplies = _getQuickReplies(auth);

    return ChatState(
      messages: [ChatMessage(text: greeting, isBot: true)],
      isTyping: false,
      quickReplies: quickReplies,
    );
  }

  List<String> _getQuickReplies(AuthState? auth) {
    final firstName = auth?.firstName;
    final isPt = auth?.language == 'pt';

    if (isPt) {
      return firstName != null
          ? const [
              'Minhas consultas',
              'Atualizar perfil',
              'Ver serviços',
              'Falar com um humano',
            ]
          : const [
              'Novo paciente',
              'Paciente antigo',
              'Ver serviços',
              'Falar com um humano',
            ];
    }

    return firstName != null
        ? const [
            'My appointments',
            'Update profile',
            'See services',
            'Talk to a human',
          ]
        : const [
            'New patient',
            'Returning patient',
            'See services',
            'Talk to a human',
          ];
  }

  void _handleAuthChange(AsyncValue<AuthState>? previous, AsyncValue<AuthState> next) {
    final prevAuth = previous?.value;
    final nextAuth = next.value;

    if (nextAuth == null) return;

    // Detected Logout
    if (prevAuth?.status == AuthStatus.authenticated && 
        nextAuth.status == AuthStatus.unauthenticated) {
      debugPrint('DEBUG: ChatNotifier: Logout detected. Resetting to guest greeting.');
      state = _createInitialState(nextAuth);
      return;
    }

    // Detected Login or Name Update
    if (nextAuth.status == AuthStatus.authenticated) {
      final wasGuest = prevAuth == null || prevAuth.status == AuthStatus.unauthenticated;
      final isNewConversation = state.messages.length <= 1;

      if (wasGuest && isNewConversation) {
        debugPrint('DEBUG: ChatNotifier: New Login detected. Personalizing greeting.');
        state = _createInitialState(nextAuth);
      } else if (isNewConversation && prevAuth?.firstName != nextAuth.firstName) {
        // Name changed/appeared while we only have the greeting
        debugPrint('DEBUG: ChatNotifier: Name update detected. Updating greeting.');
        state = _createInitialState(nextAuth);
      } else {
        // Mid-conversation or stable session: just update quick replies
        debugPrint('DEBUG: ChatNotifier: Auth change ignored for reset (messages: ${state.messages.length}). Updating quick replies.');
        state = state.copyWith(
          quickReplies: _getQuickReplies(nextAuth),
        );
      }
    }
  }


  Future<void> addMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final current = state;
    // Add user message + show typing
    state = current.copyWith(
      messages: [
        ...current.messages,
        ChatMessage(text: trimmed, isBot: false),
      ],
      isTyping: true,
    );

    final chatService = ref.read(chatServiceProvider);

    final result = await chatService.sendMessage(trimmed);

    final updated = state;
    state = updated.copyWith(
      messages: [
        ...updated.messages,
        ChatMessage(text: result, isBot: true),
      ],
      isTyping: false,
    );
  }
}

// Quick replies are now stored in ChatState and set dynamically based on
// auth status. See ChatNotifier.build() for the two variants.

// --------------------------------------------------------------------------
// Main screen
// --------------------------------------------------------------------------
class ChatScreen extends HookConsumerWidget {
  final String? initialMessage;
  const ChatScreen({super.key, this.initialMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;
    final isTyping = chatState.isTyping;
    final quickReplies = chatState.quickReplies;

    final textController = useTextEditingController();
    final scrollController = useScrollController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHighContrast = ref.watch(highContrastProvider);

    // Trigger initial message if provided
    useEffect(() {
      if (initialMessage != null && initialMessage!.isNotEmpty) {
        // Wait a bit for the UI to settle
        Future.microtask(() {
          ref.read(chatProvider.notifier).addMessage(initialMessage!);
        });
      }
      return null;
    }, [initialMessage]);

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
        decoration: BoxDecoration(
          gradient: isHighContrast ? null : bgGradient,
          color: isHighContrast ? theme.scaffoldBackgroundColor : null,
        ),
        child: Column(
          children: [
            // ----------------------------------------------------------
            // Message list
            // ----------------------------------------------------------
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 130, 16, 12),
                addSemanticIndexes: true,
                itemCount:
                    messages.length +
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
                    return _TypingIndicatorBubble(
                      isDark: isDark,
                    ).animate().fadeIn().slideX(begin: -0.2);
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
    final isHighContrast = ref.watch(highContrastProvider);
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: preferredSize.height,
          decoration: BoxDecoration(
            color: isHighContrast
                ? theme.scaffoldBackgroundColor
                : (isDark ? Colors.black : Colors.white).withValues(
                    alpha: 0.05,
                  ),
            border: Border(
              bottom: BorderSide(
                color: isHighContrast
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white : AppColors.primary).withValues(
                        alpha: 0.08,
                      ),
                width: isHighContrast ? 2.0 : 1.0,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Bot avatar
                  Tooltip(
                    message: 'Vitable Assistant Avatar',
                    child: Container(
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
                        semanticLabel: 'Assistant Icon',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      label: 'Vitable Assistant, Online',
                      child: ExcludeSemantics(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
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
                                  color: isHighContrast
                                      ? (isDark ? Colors.white : Colors.black)
                                      : (isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight),
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
                                      color: isHighContrast
                                          ? (isDark
                                                ? Colors.white70
                                                : Colors.black87)
                                          : (isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Profile Button
                  IconButton(
                    tooltip: 'Account Profile',
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
                          child: Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    onPressed: () => context.push('/profile'),
                  ),
                  // Accessibility menu
                  PopupMenuButton<String>(
                    tooltip: 'Accessibility Settings',
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
                            Icon(
                              Icons.format_size_rounded,
                              size: 20,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('Text Scale Setting')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'screen_reader',
                        child: Row(
                          children: [
                            Icon(
                              Icons.record_voice_over_rounded,
                              size: 20,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('Screen Reader Help')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'voice_control',
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings_voice_rounded,
                              size: 20,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('Voice Control Guide')),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'contrast',
                        child: Row(
                          children: [
                            Icon(
                              Icons.contrast_rounded,
                              size: 20,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('High Contrast')),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'font_size') {
                        showTextScaleDialog(context, ref);
                      } else if (value == 'contrast') {
                        ref.read(highContrastProvider.notifier).toggle();
                        final isHighContrast = ref.read(highContrastProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isHighContrast
                                  ? 'High contrast mode enabled'
                                  : 'High contrast mode disabled',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      } else if (value == 'screen_reader') {
                        showScreenReaderHelpDialog(context);
                      } else if (value == 'voice_control') {
                        showVoiceControlGuideDialog(context);
                      } else {
                        // Logic for other accessibility menu options
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Accessibility feature: $value coming soon!',
                            ),
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

  // Accessibility dialog moved to core/design/accessibility/accessibility_dialogs.dart

  @override
  Size get preferredSize => const Size.fromHeight(110);
}

// --------------------------------------------------------------------------
// Message bubble
// --------------------------------------------------------------------------
class _MessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isDark;
  final Duration animationDelay;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBot = message.isBot;
    final isHighContrast = ref.watch(highContrastProvider);

    Widget bubble;
    if (isBot) {
      bubble = MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Small bot avatar
            ExcludeSemantics(
              child: Container(
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
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            Flexible(
              child: Semantics(
                label: 'Assistant said: ${message.text}',
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12, right: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isHighContrast
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? const Color(0xFF1E3A37) : Colors.white),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                    border: isHighContrast
                        ? Border.all(
                            color: isDark ? Colors.white : Colors.black,
                            width: 2,
                          )
                        : null,
                    boxShadow: isHighContrast
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.25 : 0.06,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: ExcludeSemantics(
                    child: MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          color: isHighContrast
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                        ),
                        strong: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isHighContrast
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? AppColors.secondary : AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      bubble = MergeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Semantics(
                label: 'You said: ${message.text}',
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12, left: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isHighContrast
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF0D8073)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isHighContrast
                        ? (isDark ? Colors.white : Colors.black)
                        : null,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                    border: isHighContrast
                        ? Border.all(
                            color: isDark ? Colors.black : Colors.white,
                            width: 2,
                          )
                        : null,
                    boxShadow: isHighContrast
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.30),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      message.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isHighContrast
                            ? (isDark ? Colors.black : Colors.white)
                            : Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
class _TypingIndicatorBubble extends ConsumerWidget {
  final bool isDark;

  const _TypingIndicatorBubble({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighContrast = ref.watch(highContrastProvider);
    return Semantics(
      label: 'Assistant is typing...',
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ExcludeSemantics(
            child: Container(
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
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: isHighContrast
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? const Color(0xFF1E3A37) : Colors.white),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              border: isHighContrast
                  ? Border.all(
                      color: isDark ? Colors.white : Colors.black,
                      width: 2,
                    )
                  : null,
              boxShadow: isHighContrast
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.25 : 0.06,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Container(
                        width: 8,
                        height: 8,
                        margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
                        decoration: BoxDecoration(
                          color: isHighContrast
                              ? (isDark ? Colors.white : Colors.black)
                              : AppColors.primary.withValues(alpha: 0.6),
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
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Quick reply chips
// --------------------------------------------------------------------------
class _QuickReplies extends ConsumerWidget {
  final List<String> replies;
  final void Function(String) onTap;

  const _QuickReplies({required this.replies, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighContrast = ref.watch(highContrastProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: 'Quick reply suggestions',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 46),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: replies
              .map(
                (r) => GestureDetector(
                  onTap: () => onTap(r),
                  child: Semantics(
                    label: 'Quick reply: $r',
                    button: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isHighContrast
                            ? (isDark ? Colors.black : Colors.white)
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isHighContrast
                              ? (isDark ? Colors.white : Colors.black)
                              : AppColors.primary.withValues(alpha: 0.35),
                          width: isHighContrast ? 2 : 1,
                        ),
                      ),
                      child: ExcludeSemantics(
                        child: Text(
                          r,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: isHighContrast
                                    ? (isDark ? Colors.white : Colors.black)
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Input area
// --------------------------------------------------------------------------
class _InputArea extends ConsumerWidget {
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onSend;

  const _InputArea({
    required this.controller,
    required this.isDark,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighContrast = ref.watch(highContrastProvider);
    final theme = Theme.of(context);
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isHighContrast
                ? theme.scaffoldBackgroundColor
                : (isDark ? Colors.black : Colors.white).withValues(
                    alpha: 0.05,
                  ),
            border: Border(
              top: BorderSide(
                color: isHighContrast
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white : AppColors.primary).withValues(
                        alpha: 0.08,
                      ),
                width: isHighContrast ? 2.0 : 1.0,
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
                  child: Semantics(
                    textField: true,
                    label: 'Message input field',
                    child: TextField(
                      controller: controller,
                      maxLines: 4,
                      minLines: 1,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Semantics(
                    label: 'Send message',
                    button: true,
                    hint: 'Sends the text in the input field to the assistant',
                    child: GestureDetector(
                      onTap: onSend,
                      child:
                          Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      Color(0xFF14B8A6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.40,
                                      ),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
