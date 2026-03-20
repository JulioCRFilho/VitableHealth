import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/api_constants.dart';
import '../../identity/application/auth_notifier.dart';

part 'chat_service.g.dart';

@riverpod
ChatService chatService(Ref ref) {
  final token = ref.watch(authProvider).value?.token;
  return ChatService(token: token);
}

class ChatService {
  final String _endpoint = '${ApiConstants.baseUrl}/api/chat/';
  final String? token;

  ChatService({this.token});

  Future<({String response, String? token})> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (
          response:
              (data['response'] ?? "I'm sorry, I couldn't process that.") as String,
          token: data['token'] as String?,
        );
      } else if (response.statusCode == 404) {
        return (
          response:
              "Connection error: The chat service endpoint was not found (404). Please ensure the backend is deployed.",
          token: null,
        );
      } else {
        return (
          response:
              "Error from AI Assistant (Status ${response.statusCode}): ${response.reasonPhrase}",
          token: null,
        );
      }
    } catch (e) {
      return (response: "Error connecting to AI Assistant: $e", token: null);
    }
  }
}
