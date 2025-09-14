import 'package:get/get.dart';
import 'gemini_adapter.dart';
import '../../settings/settings_page.dart';
import '../../settings/settings_controller.dart';

class GeminiManager {
  GeminiAdapter? _cached;

  GeminiAdapter? get current => _cached;

  /// Returns cached model or creates one from SettingsController's stored API key.
  /// If API key is missing, prompts user to open settings and returns null.
  GeminiAdapter? currentOrPromptSettings() {
    final settings = Get.find<SettingsController>();

    // ONLY check the stored key (do not rely on the TextEditingController)
    final stored = settings.storedApiKey?.toString().trim() ?? '';
    if (stored.isEmpty) {
      Get.defaultDialog(
        title: 'missing_api_key'.tr,
        middleText: 'please_set_api_key'.tr,
        textConfirm: 'open_settings'.tr,
        onConfirm: () {
          Get.back();
          Get.to(() => const SettingsPage());
        },
      );
      return null;
    }

    if (_cached == null || _cached!.apiKey != stored) {
      _cached = GeminiAdapter(apiKey: stored);
    }
    return _cached;
  }

  void clear() => _cached = null;
}
