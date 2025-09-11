// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool isSpeaking = false;

  Future<void> init({
    String lang = 'ko-KR',
    double rate = 0.45,
    double pitch = 1.0,
  }) async {
    try {
      await _tts.setLanguage(lang);
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
    isSpeaking = true;
  }

  Future<void> stop() async {
    await _tts.stop();
    isSpeaking = false;
  }

  void dispose() {
    // nothing to close for FlutterTts, but call stop if needed
    _tts.stop();
  }
}
