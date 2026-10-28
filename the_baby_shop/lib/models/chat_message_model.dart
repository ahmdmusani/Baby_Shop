class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  // Convert model message to Gemini payload format
  Map<String, dynamic> toGeminiPart() {
    return {
      'text': text,
    };
  }

  // Helper to get role string for Gemini payload
  String get role => isUser ? 'user' : 'model';
}
