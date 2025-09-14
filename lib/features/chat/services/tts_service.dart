// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool isSpeaking = false;

  /// Initialize TTS engine and set default parameters and handlers.
  Future<void> init({
    String? lang,
    double rate = 0.45,
    double pitch = 1.0,
    double volume = 1.0,
  }) async {
    try {
      // Apply language if provided
      if (lang != null && lang.isNotEmpty) {
        await _tts.setLanguage(lang);
      }

      // Apply voice parameters
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
      try {
        await _tts.setVolume(volume);
      } catch (_) {
        // some platforms may not support volume control; ignore
      }

      // Handlers to keep isSpeaking in sync
      try {
        _tts.setStartHandler(() {
          isSpeaking = true;
        });
      } catch (_) {}
      try {
        _tts.setCompletionHandler(() {
          isSpeaking = false;
        });
      } catch (_) {}
      try {
        _tts.setCancelHandler(() {
          isSpeaking = false;
        });
      } catch (_) {}
      try {
        _tts.setErrorHandler((msg) {
          isSpeaking = false;
        });
      } catch (_) {}

      // Wait for completion where supported
      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (_) {}
    } catch (e) {
      // initialization failed — ignore here, caller can retry or log
    }
  }

  /// Speak text. If locale is provided, set language before speaking.
  Future<void> speak(String text, {String? locale}) async {
    if (text.trim().isEmpty) return;
    try {
      await _tts.stop(); // stop any existing speech
      if (locale != null && locale.isNotEmpty) {
        await _tts.setLanguage(locale);
      }
      // Speak the provided text
      await _tts.speak(text);
    } catch (e) {
      // swallow but log in caller if needed
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    isSpeaking = false;
  }

  void dispose() {
    try {
      _tts.stop();
    } catch (_) {}
  }
}
