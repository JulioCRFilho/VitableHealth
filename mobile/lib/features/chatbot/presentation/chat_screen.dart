import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../application/chat_service.dart';

part 'chat_screen.g.dart';

@riverpod
class ChatNotifier extends _$ChatNotifier {
  @override
  List<Map<String, dynamic>> build() {
    return [
      {"text": "Welcome to Vitable AI Assistant! Are you a new or returning patient?", "isBot": true}
    ];
  }

  Future<void> addMessage(String text) async {
    state = [...state, {"text": text, "isBot": false}];
    
    final chatService = ref.read(chatServiceProvider);
    final botReply = await chatService.sendMessage(text);
    
    state = [...state, {"text": botReply, "isBot": true}];
  }
}

class ChatScreen extends HookConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatProvider);
    final textController = useTextEditingController();
    final scrollController = useScrollController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitable Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _buildMessageBubble(msg['text'], msg['isBot'], context);
              },
            ),
          ),
          _buildInputArea(context, textController, ref, scrollController),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isBot, BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isBot ? theme.colorScheme.surface : theme.colorScheme.primary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isBot ? const Radius.circular(0) : const Radius.circular(16),
            bottomRight: isBot ? const Radius.circular(16) : const Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isBot ? theme.colorScheme.onSurface : Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, TextEditingController controller, WidgetRef ref, ScrollController scrollController) {
    final theme = Theme.of(context);
    
    void _sendMessage() {
      final val = controller.text;
      if (val.isNotEmpty) {
        ref.read(chatProvider.notifier).addMessage(val);
        controller.clear();
        Future.delayed(const Duration(milliseconds: 100), () {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              radius: 24,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            )
          ],
        ),
      ),
    );
  }
}
