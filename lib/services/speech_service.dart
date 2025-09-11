// lib/services/speech_service.dart
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Small wrapper around speech_to_text to centralize initialization and callbacks.
/// - Use [partialStream] to listen to interim transcripts (live updates).
/// - Use [statusStream] to monitor engine status (listening/done/notListening).
/// - Use [errorStream] to receive error maps/strings from the plugin.
class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  final StreamController<String> _partialController =
      StreamController.broadcast();
  final StreamController<String> _statusController =
      StreamController.broadcast();
  final StreamController<dynamic> _errorController =
      StreamController.broadcast();
  final StreamController<double> _soundLevelController =
      StreamController.broadcast();

  Stream<String> get partialStream => _partialController.stream;
  Stream<String> get statusStream => _statusController.stream;
  Stream<dynamic> get errorStream => _errorController.stream;
  Stream<double> get soundLevelStream => _soundLevelController.stream;

  bool get isAvailable => _available;
  bool _available = false;

  Future<void> initialize() async {
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
    }
  }

  /// Start listening. If [requestPermission] is true we will ask for microphone permission.
  Future<bool> startListening({
    bool requestPermission = true,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 4),
    String localeId = 'ko-KR',
  }) async {
    if (requestPermission) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return false;
    }

    if (!_available) {
      await initialize();
      if (!_available) return false;
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

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }

  void dispose() {
    _partialController.close();
    _statusController.close();
    _errorController.close();
    _soundLevelController.close();
  }

  bool get isListening => _speech.isListening;
}
