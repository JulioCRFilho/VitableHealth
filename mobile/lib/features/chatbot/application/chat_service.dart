import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/api_constants.dart';
import '../../identity/application/auth_notifier.dart';

part 'chat_service.g.dart';

@riverpod
ChatService chatService(Ref ref) {
  final authState = ref.watch(authProvider).asData?.value;
  return ChatService(token: authState?.token);
}

class ChatService {
  final String _endpoint = '${ApiConstants.baseUrl}/api/chat/';
  final String? token;

  ChatService({this.token});

  Future<String> sendMessage(String message) async {
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
        return data['response'] ?? "I'm sorry, I couldn't process that.";
      } else if (response.statusCode == 404) {
        return "Connection error: The chat service endpoint was not found (404). Please ensure the backend is deployed.";
      } else {
        return "Error from AI Assistant (Status ${response.statusCode}): ${response.reasonPhrase}";
      }
    } catch (e) {
      return "Error connecting to AI Assistant: $e";
    }
  }
}
