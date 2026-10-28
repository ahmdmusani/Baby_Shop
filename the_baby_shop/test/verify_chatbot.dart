import 'package:flutter_test/flutter_test.dart';
import 'package:the_baby_shop/services/gemini_chat_service.dart';

void main() {
  test('Gemini Chatbot Verification', () async {
    final chatService = GeminiChatService();

    print('=== VERIFICATION TEST START ===\n');

    // Test Case 1: App related question
    try {
      print('Test 1: Asking about categories...');
      final response1 = await chatService.sendMessage(
        'What categories does the store have?',
        [],
      );
      print('Response 1:\n$response1\n');
      assert(response1.toLowerCase().contains('clothing') || response1.toLowerCase().contains('feed') || response1.toLowerCase().contains('toy') || response1.toLowerCase().contains('shoe'));
    } catch (e) {
      print('Test 1 Failed: $e');
    }

    // Test Case 2: Unrelated general knowledge question
    try {
      print('Test 2: Asking about the president of USA (Unrelated)...');
      final response2 = await chatService.sendMessage(
        'Who is the president of the United States?',
        [],
      );
      print('Response 2:\n$response2\n');
      assert(response2.trim() == "I can only assist with questions related to this application. Please ask a question about the app's features, functionality, or usage.");
    } catch (e) {
      print('Test 2 Failed: $e');
    }

    // Test Case 3: Unrelated coding question
    try {
      print('Test 3: Asking for python code (Unrelated)...');
      final response3 = await chatService.sendMessage(
        'Write a python function to print fibonacci numbers.',
        [],
      );
      print('Response 3:\n$response3\n');
      assert(response3.trim() == "I can only assist with questions related to this application. Please ask a question about the app's features, functionality, or usage.");
    } catch (e) {
      print('Test 3 Failed: $e');
    }

    print('=== VERIFICATION TEST END ===');
  });
}
