import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingsController extends GetxController {
  final GetStorage _box = GetStorage();

  late TextEditingController apiKeyController;
  final RxBool apiKeyIsSet = false.obs;
  final autoPlayTts = false.obs;

  // Separate languages for TTS and STT
  final ttsLanguage = 'en-US'.obs;
  final sttLanguage = 'en-US'.obs;

  final List<Map<String, String>> supportedLanguages = [
    {'code': 'en-US', 'label': 'English (US)'},
    {'code': 'en-GB', 'label': 'English (UK)'},
    {'code': 'ko-KR', 'label': 'Korean'},
    {'code': 'ja-JP', 'label': 'Japanese'},
    {'code': 'fr-FR', 'label': 'French'},
    {'code': 'de-DE', 'label': 'German'},
    {'code': 'es-ES', 'label': 'Spanish'},
    {'code': 'hi-IN', 'label': 'Hindi'},
    // add more if needed
  ];

  // UI state
  final showApiKey = false.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    apiKeyController = TextEditingController(text: _box.read('apiKey') ?? '');
    apiKeyIsSet.value = (apiKeyController.text.trim().isNotEmpty);
    autoPlayTts.value = _box.read('autoPlayTts') ?? false;
    ttsLanguage.value =
        _box.read('ttsLanguage') ?? (_box.read('language') ?? 'en-US');
    sttLanguage.value =
        _box.read('sttLanguage') ?? (_box.read('language') ?? 'en-US');
  }

  /// Save API key to storage (explicit Save button)
  Future<void> saveApiKey() async {
    final key = apiKeyController.text.trim();
    isSaving.value = true;
    try {
      if (key.isEmpty) {
        apiKeyIsSet.value = false;
        _box.remove('apiKey');
        Get.snackbar('Setting', 'API key not saved');
      } else {
        _box.write('apiKey', key);
        apiKeyIsSet.value = true;
        Get.snackbar('Settings', 'API key saved');
      }
    } finally {
      isSaving.value = false;
    }
  }

  /// Clear API key (with confirm from UI)
  Future<void> clearApiKey() async {
    apiKeyController.clear();
    _box.remove('apiKey');
    apiKeyIsSet.value = false;
  }

  /// Toggle auto-play TTS setting
  void toggleAutoPlayTts(bool value) {
    autoPlayTts.value = value;
    _box.write('autoPlayTts', value);
  }

  /// Set TTS language and persist
  void setTtsLanguage(String code) {
    ttsLanguage.value = code;
    _box.write('ttsLanguage', code);
  }

  /// Set STT language and persist
  void setSttLanguage(String code) {
    sttLanguage.value = code;
    _box.write('sttLanguage', code);
  }

  /// Toggle visibility of API key input
  void toggleShowApiKey() => showApiKey.value = !showApiKey.value;

  /// Convenience: return stored API key (if any)
  String? get storedApiKey => _box.read('apiKey');

  @override
  void onClose() {
    apiKeyController.dispose();
    super.onClose();
  }
}
