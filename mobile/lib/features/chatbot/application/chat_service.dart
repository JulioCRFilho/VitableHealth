import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/api_constants.dart';
import '../../identity/application/auth_notifier.dart';
import '../../identity/domain/auth_state.dart';

part 'chat_service.g.dart';

@Riverpod(keepAlive: true)
ChatService chatService(Ref ref) {
  ref.keepAlive();
  return ChatService(ref);
}

class ChatService {
  final Ref _ref;
  ChatService(this._ref);

  final String _endpoint = '${ApiConstants.baseUrl}/api/chat/';

  Future<String> sendMessage(String message, {String? sessionId}) async {
    try {
      // Use .read() to avoid registering a persistent dependency.
      // If .watch() is used with the ChatNotifier's Ref, any auth change
      // will cause the Entire ChatNotifier to rebuild.
      final token = _ref.read(authProvider).value?.token;

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
          if (sessionId != null) 'session_id': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // If the backend returns a new token (e.g. session update), update auth state
        if (data.containsKey('token')) {
          final newToken = data['token'];
          if (newToken != null) {
            _ref.read(authProvider.notifier).setUser(newToken);
          } else {
            // If token is explicitly null, it means the session was cleared (logout)
            final currentAuth = _ref.read(authProvider).value;
            if (currentAuth?.status == AuthStatus.authenticated) {
              debugPrint('DEBUG: ChatService: Backend signaled logout. Clearing local state.');
              _ref.read(authProvider.notifier).logout();
            }
          }
        }

        return (data['response'] ?? "I'm sorry, I couldn't process that.")
            as String;
      } else if (response.statusCode == 404) {
        return "Connection error: The chat service endpoint was not found (404). Please ensure the backend is deployed.";
      } else {
        return "Error from AI Assistant (Status ${response.statusCode}): ${response.reasonPhrase}";
      }
    } catch (e, stackTrace) {
      debugPrintStack(
        stackTrace: stackTrace,
        label: "Error connecting to AI Assistant: $e",
      );
      return "Error connecting to AI Assistant. Please, check logs.";
    }
  }
}
