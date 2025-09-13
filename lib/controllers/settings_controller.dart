import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

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
  ];

  // UI state
  final showApiKey = false.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();

    // For privacy, start the TextField empty. The actual "is set" state is
    // determined from storage (so clearing the text field does NOT remove the stored value).
    apiKeyController = TextEditingController(text: '');

    apiKeyIsSet.value = (_box.read('apiKey') ?? '')
        .toString()
        .trim()
        .isNotEmpty;

    autoPlayTts.value = _box.read('autoPlayTts') ?? false;
    ttsLanguage.value =
        _box.read('ttsLanguage') ?? (_box.read('language') ?? 'en-US');
    sttLanguage.value =
        _box.read('sttLanguage') ?? (_box.read('language') ?? 'en-US');
  }

  /// Validate API key by calling a lightweight endpoint and then persist.
  Future<void> saveApiKey() async {
    Get.closeAllSnackbars();
    final candidate = apiKeyController.text.trim();
    if (candidate.isEmpty) {
      // treat empty as "remove stored key" — this is an explicit user intent.
      await _box.remove('apiKey');
      apiKeyIsSet.value = false;
      Get.snackbar('Settings', 'No API key provided (storage cleared)');
      return;
    }

    isSaving.value = true;
    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models',
      );
      final resp = await http
          .get(uri, headers: {'X-Goog-Api-Key': candidate})
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        // key is valid — persist it
        await _box.write('apiKey', candidate);
        apiKeyIsSet.value = true;

        // Dismiss keyboard and clear the input for privacy
        FocusManager.instance.primaryFocus?.unfocus();
        apiKeyController.clear();

        Get.snackbar('Settings', 'API key saved');
      } else {
        final msg = (resp.statusCode == 401 || resp.statusCode == 403)
            ? 'Invalid API key (unauthorized)'
            : 'Invalid API key (HTTP ${resp.statusCode})';
        Get.snackbar('Settings', msg, backgroundColor: Colors.red.shade100);
      }
    } on TimeoutException {
      Get.snackbar(
        'Settings',
        'Validation timed out — check network or try again.',
        backgroundColor: Colors.orange.shade100,
      );
    } catch (e) {
      Get.snackbar(
        'Settings',
        'Failed to validate API key: $e',
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// Clear API key (with confirm from UI)
  Future<void> clearApiKey() async {
    // Clear UI and storage explicitly when user confirms deletion
    apiKeyController.clear();
    await _box.remove('apiKey');
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
