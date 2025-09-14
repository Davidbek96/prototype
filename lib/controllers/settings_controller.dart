// lib/controllers/settings_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SettingsController extends GetxController {
  final GetStorage _box = GetStorage();

  late TextEditingController apiKeyTextEditCtrl;
  final RxBool apiKeyIsSet = false.obs;
  final autoPlayTts = false.obs;

  // Separate languages for TTS and STT
  final ttsLanguage = 'en-US'.obs;
  final sttLanguage = 'en-US'.obs;

  final List<Map<String, String>> supportedLanguages = [
    {'code': 'en-US', 'label': 'lang_english_us'.tr},
    {'code': 'en-GB', 'label': 'lang_english_uk'.tr},
    {'code': 'ko-KR', 'label': 'lang_korean'.tr},
    {'code': 'ja-JP', 'label': 'lang_japanese'.tr},
    {'code': 'fr-FR', 'label': 'lang_french'.tr},
    {'code': 'de-DE', 'label': 'lang_german'.tr},
    {'code': 'es-ES', 'label': 'lang_spanish'.tr},
    {'code': 'hi-IN', 'label': 'lang_hindi'.tr},
  ];

  // UI state
  final showApiKey = false.obs;
  final isSaving = false.obs;

  @override
  @override
  void onInit() {
    super.onInit();

    apiKeyTextEditCtrl = TextEditingController(text: '');

    final stored = (_box.read('apiKey') ?? '').toString().trim();
    final firstRun = _box.read('firstRun') ?? true;

    if (stored.isNotEmpty) {
      // User already saved a key before
      apiKeyIsSet.value = true;
    } else if (firstRun) {
      // First install only → fallback to .env
      final envKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      if (envKey.isNotEmpty) {
        _box.write('apiKey', envKey);
        apiKeyIsSet.value = true;
      }
      // Mark app as initialized so we don’t load .env again
      _box.write('firstRun', false);
    } else {
      // No key and not first run
      apiKeyIsSet.value = false;
    }

    autoPlayTts.value = _box.read('autoPlayTts') ?? false;
    ttsLanguage.value =
        _box.read('ttsLanguage') ?? (_box.read('language') ?? 'ko-KR');
    sttLanguage.value =
        _box.read('sttLanguage') ?? (_box.read('language') ?? 'ko-KR');
  }

  /// Validate API key by calling a lightweight endpoint and then persist.
  Future<void> saveApiKey() async {
    Get.closeAllSnackbars();
    final candidate = apiKeyTextEditCtrl.text.trim();
    if (candidate.isEmpty) {
      Get.snackbar('settings_title'.tr, 'settings_no_api_key'.tr);
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
        await _box.write('apiKey', candidate);
        apiKeyIsSet.value = true;
        FocusManager.instance.primaryFocus?.unfocus();
        apiKeyTextEditCtrl.clear();
        Get.snackbar('settings_title'.tr, 'settings_api_key_saved'.tr);
      } else {
        final msg = (resp.statusCode == 401 || resp.statusCode == 403)
            ? 'settings_invalid_api_key'.tr
            : 'settings_invalid_api_key_http'.trParams({
                'code': resp.statusCode.toString(),
              });
        Get.snackbar(
          'settings_title'.tr,
          msg,
          backgroundColor: Colors.red.shade100,
        );
      }
    } on TimeoutException {
      Get.snackbar(
        'settings_title'.tr,
        'settings_timeout'.tr,
        backgroundColor: Colors.orange.shade100,
      );
    } catch (e) {
      Get.snackbar(
        'settings_title'.tr,
        'settings_failed_validation'.trParams({'error': e.toString()}),
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> clearApiKey() async {
    apiKeyTextEditCtrl.clear();
    await _box.remove('apiKey');
    apiKeyIsSet.value = false;
  }

  void toggleAutoPlayTts(bool value) {
    autoPlayTts.value = value;
    _box.write('autoPlayTts', value);
  }

  void setTtsLanguage(String code) {
    ttsLanguage.value = code;
    _box.write('ttsLanguage', code);
  }

  void setSttLanguage(String code) {
    sttLanguage.value = code;
    _box.write('sttLanguage', code);
  }

  void toggleShowApiKey() => showApiKey.value = !showApiKey.value;

  String? get storedApiKey => _box.read('apiKey');

  @override
  void onClose() {
    apiKeyTextEditCtrl.dispose();
    super.onClose();
  }
}
