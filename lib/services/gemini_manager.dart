// lib/services/gemini_manager.dart
import 'package:get/get.dart';
import '../gemini_chat_model.dart';
import '../pages/settings_page.dart';
import '../controllers/settings_controller.dart';

class GeminiManager {
  GeminiChatModel? _cached;

  GeminiChatModel? get current => _cached;

  /// Returns cached model or creates one from SettingsController's stored API key.
  /// If API key is missing, prompts user to open settings and returns null.
  GeminiChatModel? currentOrPromptSettings() {
    final settings = Get.find<SettingsController>();

    // ONLY check the stored key (do not rely on the TextEditingController)
    final stored = settings.storedApiKey?.toString().trim() ?? '';
    if (stored.isEmpty) {
      Get.defaultDialog(
        title: 'Missing API Key',
        middleText: 'Please set your Gemini API key in Settings.',
        textConfirm: 'Open Settings',
        onConfirm: () {
          Get.back();
          Get.to(() => const SettingsPage());
        },
      );
      return null;
    }

    if (_cached == null || _cached!.apiKey != stored) {
      _cached = GeminiChatModel(apiKey: stored);
    }
    return _cached;
  }

  void clear() => _cached = null;
}
