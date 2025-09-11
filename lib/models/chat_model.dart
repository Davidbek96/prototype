class ChatMessage {
  final String role; // "user" or "model"
  final String content;

  ChatMessage({required this.role, required this.content});
}

class ChatChunk {
  final String? delta; // new token from Gemini
  final bool isFinal;
  final Map<String, dynamic>? meta;

  ChatChunk({this.delta, this.isFinal = false, this.meta});
}

abstract class ChatModel {
  Stream<ChatChunk> streamReply({
    required List<ChatMessage> messages,
    double? temperature,
    Map<String, dynamic>? options,
  });
}
