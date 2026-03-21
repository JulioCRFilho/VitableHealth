import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/api_constants.dart';
import '../../identity/application/auth_notifier.dart';

part 'chat_service.g.dart';

@riverpod
ChatService chatService(Ref ref) => ChatService();

class ChatService {
  final String _endpoint = '${ApiConstants.baseUrl}/api/chat/';

  Future<String> sendMessage(Ref ref, String message) async {
    try {
      final token = ref.watch(authProvider).value?.token;

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['token'] != null) {
          ref.read(authProvider.notifier).setUser(data['token']);
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
