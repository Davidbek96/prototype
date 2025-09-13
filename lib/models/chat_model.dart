abstract class ChatModel {
  /// Takes prompt + context and streams partial responses.
  Stream<ChatChunk> streamReply({
    required List<ChatMessage> messages,
    double? temperature,
    Map<String, dynamic>? options,
  });
}

class ChatMessage {
  final String role; // "user" or "model"
  final String content;

  ChatMessage({required this.role, required this.content});
}

class ChatChunk {
  final String delta; // newly added token
  final bool isFinal; // end-of-stream flag
  final Map<String, dynamic>? meta; // token count, model name, etc.

  ChatChunk({required this.delta, this.isFinal = false, this.meta});
}
