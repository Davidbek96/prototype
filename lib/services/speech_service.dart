// lib/services/speech_service.dart
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wrapper around speech_to_text for STT.
/// - Emits partial transcripts
/// - Emits status, error, and sound level events
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  final StreamController<String> _partialController =
      StreamController<String>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  final StreamController<dynamic> _errorController =
      StreamController<dynamic>.broadcast();
  final StreamController<double> _soundLevelController =
      StreamController<double>.broadcast();

  Stream<String> get partialStream => _partialController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<dynamic> get errorStream => _errorController.stream;
  Stream<double> get soundLevelStream => _soundLevelController.stream;

  bool get isAvailable => _available;
  bool _available = false;

  bool get isListening => _speech.isListening;

  /// Initialize the underlying plugin. Safe to call multiple times.
  Future<bool> initialize() async {
    try {
      _available = await _speech.initialize(
        onStatus: (status) {
          _statusController.add(status);
        },
        onError: (err) {
          _errorController.add(err);
        },
      );
    } catch (e) {
      _available = false;
      _errorController.add(e);
    }
    return _available;
  }

  /// Optional helper to set a locale for next listen call.
  void setLocale(String localeId) {
    // noop here (kept for parity). Caller should pass localeId into startListening.
  }

  /// Start listening with long session (dictation mode).
  Future<bool> startListening({
    bool requestPermission = true,
    Duration listenFor = const Duration(minutes: 5),
    Duration pauseFor = const Duration(seconds: 10),
    String? localeId,
  }) async {
    if (requestPermission) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _errorController.add('microphone_permission_denied');
        return false;
      }
    }

    if (!_available) {
      final ok = await initialize();
      if (!ok) {
        _errorController.add('stt_not_available');
        return false;
      }
    }

    try {
      await _speech.listen(
        onResult: (result) {
          _partialController.add(result.recognizedWords);
        },
        listenFor: listenFor,
        pauseFor: pauseFor,
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
        ),
        onSoundLevelChange: (level) {
          _soundLevelController.add(level.toDouble());
        },
      );
      return true;
    } catch (e) {
      _errorController.add(e);
      return false;
    }
  }

  /// Stop listening (graceful)
  Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      _errorController.add(e);
    }
  }

  void dispose() {
    try {
      _partialController.close();
      _statusController.close();
      _errorController.close();
      _soundLevelController.close();
    } catch (_) {}
  }
}
