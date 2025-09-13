// lib/bindings/chat_binding.dart
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/permission_service.dart';
import '../services/connectivity_service.dart';
import '../services/gemini_manager.dart';
import '../domain/chat_stream_manager.dart';
import '../domain/transient_message_service.dart';

/// Bindings to register chat-related dependencies for GetX.
/// Uses lazyPut so instances are created on first use.
class ChatBinding extends Bindings {
  @override
  void dependencies() {
    // Core services - created lazily when first requested.
    Get.lazyPut<SpeechService>(() => SpeechService());
    Get.lazyPut<TtsService>(() => TtsService());
    Get.lazyPut<PermissionService>(() => PermissionService());
    Get.lazyPut<ConnectivityService>(() => ConnectivityService());
    Get.lazyPut<GeminiManager>(() => GeminiManager());
    Get.lazyPut<ChatStreamManager>(() => ChatStreamManager());
    Get.lazyPut<TransientMessageService>(() => TransientMessageService());

    // ChatController - lazy, with fenix: true so it's recreated if removed.
    // Remove fenix if you want the controller to be destroyed and not recreated.
    Get.lazyPut<ChatController>(() => ChatController(), fenix: true);
  }
}
