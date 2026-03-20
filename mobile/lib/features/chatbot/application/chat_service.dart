import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_service.g.dart';

// Placeholder for API key. Will be replaced with real key upon completion.
const String _apiKey = 'YOUR_API_KEY_HERE';

@riverpod
ChatService chatService(Ref ref) {
  return ChatService();
}

class ChatService {
  late final GenerativeModel _model;
  late ChatSession _chatSession;

  ChatService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system('''
You are the Vitable Health AI Assistant. You manage the entire user journey.
Responsibilities:
1. Handle Login/Registration by asking for email. If new, ask for basic details.
2. Allow users to view and change their health plans (Basic Health Plan or Complete Health Plan).
3. Schedule telemedicine appointments with available doctors (Dr. Sarah, Dr. James).
4. Request free medications (e.g., Ibuprofen 400mg, Amoxicillin 500mg, Omeprazole 20mg).
Always be polite, concise, and professional. 
Never ask for real sensitive health info. Maintain state implicitly through the chat.
'''),
    );
    _chatSession = _model.startChat();
  }

  Future<String> sendMessage(String message) async {
    // If API key is not yet provided, return a mocked response 
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      await Future.delayed(const Duration(seconds: 1)); // simulate network
      return "I received your message: '\$message'. (Note: Replace YOUR_API_KEY_HERE with a real Gemini key to enable AI)";
    }

    try {
      final response = await _chatSession.sendMessage(Content.text(message));
      return response.text ?? "I'm sorry, I couldn't process that.";
    } catch (e) {
      return "Error connecting to AI Assistant: \$e";
    }
  }
}
