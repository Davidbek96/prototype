import 'dart:async';
import '../models/gemini_chat_model.dart';
import '../models/chat_model.dart';

typedef ChunkCallback = void Function(ChatChunk chunk);
typedef DoneCallback = void Function();
typedef ErrorCallback = void Function(Object error);

class ChatStreamManager {
  StreamSubscription<ChatChunk>? _sub;

  ChunkCallback? onChunk;
  DoneCallback? onDone;
  ErrorCallback? onError;

  /// Start a new streaming session from the provided Gemini model.
  /// Cancels any previous stream before starting.
  void startStream(GeminiChatModel gemini, List<ChatMessage> history) {
    stop();
    _sub = gemini
        .streamReply(messages: history)
        .listen(
          (chunk) => onChunk?.call(chunk),
          onError: (e) => onError?.call(e),
          onDone: () => onDone?.call(),
          cancelOnError: true,
        );
  }

  /// Stop the current stream (if any).
  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void dispose() => stop();
}
