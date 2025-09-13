// lib/controllers/chat_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/chat_model.dart';
import '../gemini_chat_model.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../pages/settings_page.dart'; // used to navigate to settings when missing API key
import 'settings_controller.dart';

class ChatController extends GetxController {
  // Services (long-lived)
  final SpeechService speech = SpeechService();
  final TtsService tts = TtsService();

  // Cached Gemini model (recreated when API key is saved/cleared)
  GeminiChatModel? _gemini;

  // UI / reactive state
  final messages = <ChatMessage>[].obs;
  final isStreaming = false.obs;
  final tokenCount = 0.obs;
  final activeModelIndex = (-1).obs;
  final isListening = false.obs;

  // text editing controller for the input box
  late final TextEditingController messageController;

  StreamSubscription<String>? _partialSub;
  StreamSubscription<String>? _statusSub;
  StreamSubscription<ChatChunk>? _streamingSub;

  // Helper to access settings controller (ensure registered)
  SettingsController get _settings {
    if (Get.isRegistered<SettingsController>()) {
      return Get.find<SettingsController>();
    } else {
      return Get.put(SettingsController());
    }
  }

  @override
  void onInit() {
    super.onInit();
    messageController = TextEditingController();

    // Initialize speech and subscribe to partial transcripts
    speech.initialize().then((ok) {
      _partialSub = speech.partialStream.listen((partial) {
        // Update input with partial transcript
        messageController.text = partial;
        messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: messageController.text.length),
        );
      });

      _statusSub = speech.statusStream.listen((status) {
        isListening.value = status == 'listening';
      });
    });

    // Init TTS with saved language and re-init when language changes
    tts.init(lang: _settings.ttsLanguage.value);
    ever<String>(_settings.ttsLanguage, (newLang) {
      try {
        tts.init(lang: newLang);
      } catch (e) {
        debugPrint('Failed to re-init TTS for language $newLang: $e');
      }
    });

    // Create or clear cached Gemini model based on current saved API key state.
    // Note: this reacts to explicit Save/Clear actions in SettingsController
    _createOrUpdateModel();
    ever<bool>(_settings.apiKeyIsSet, (isSet) {
      if (isSet == true) {
        _createOrUpdateModel();
      } else {
        _gemini = null;
        debugPrint('Gemini model cleared (API key removed)');
      }
    });
  }

  /// Create or update the cached Gemini model based on stored API key.
  /// Called only when the user explicitly saves/clears the key in Settings.
  void _createOrUpdateModel() {
    final key = _settings.apiKeyController.text.trim();
    if (key.isEmpty) {
      _gemini = null;
      debugPrint('No API key found; cached Gemini model cleared.');
    } else {
      if (_gemini == null || _gemini!.apiKey != key) {
        _gemini = GeminiChatModel(apiKey: key);
        debugPrint('Gemini model created/updated with new API key');
      }
    }
  }

  /// Show a short-lived system message in the chat (transient).
  /// This inserts a message with role 'system' and removes it after [duration].
  void _showTransientSystemMessage(
    String text, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final sys = ChatMessage(role: 'system', content: text);
    messages.add(sys);
    Future.delayed(duration, () {
      try {
        messages.remove(sys);
      } catch (_) {}
    });
  }

  Future<void> startListening() async {
    if (speech.isListening) return;

    try {
      // Check current microphone permission state first
      final micStatus = await Permission.microphone.status;

      if (micStatus.isPermanentlyDenied) {
        // Permanently denied -> tell user how to open settings
        Get.defaultDialog(
          title: 'Microphone Access Required',
          contentPadding: const EdgeInsets.only(
            bottom: 20,
            left: 16,
            right: 16,
          ),
          titlePadding: const EdgeInsets.only(top: 16),
          middleText:
              'Microphone permission is permanently denied. '
              'To use voice input, please enable the microphone permission in your device settings.',
          textCancel: 'Cancel',
          textConfirm: 'Open Settings',
          confirmTextColor: Colors.white,
          onConfirm: () async {
            Get.back(); // close dialog
            await openAppSettings();
          },
        );
        return;
      }

      // If not granted, request permission
      if (!micStatus.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          Get.snackbar(
            'Permission denied',
            'Microphone permission is required to use voice input.',
          );
          return;
        }
      }

      // Permission is granted — start listening.
      final locale = _settings.sttLanguage.value;
      final started = await speech.startListening(
        requestPermission: false,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 10),
        localeId: locale,
      );
      isListening.value = started;
    } catch (e) {
      debugPrint("ChatController.startListening error: $e");
      Get.snackbar(
        'Error',
        'Failed to start listening: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Stop listening (user releases mic). Do not auto-submit by default.
  Future<void> stopListening({bool submit = false}) async {
    try {
      await speech.stopListening();
    } catch (e) {
      debugPrint("ChatController.stopListening error: $e");
    }
    if (submit) {
      await sendMessage();
    }
  }

  /// Send message (from send button) — performs an async connectivity check first.
  Future<void> sendMessage() async {
    try {
      // perform connectivity check first
      final dynamic rawConn = await Connectivity().checkConnectivity();

      final bool isOffline = (rawConn is ConnectivityResult)
          ? rawConn == ConnectivityResult.none
          : (rawConn is List<ConnectivityResult>)
          ? rawConn.isEmpty ||
                rawConn.every((c) => c == ConnectivityResult.none)
          : false; // unknown type -> assume online

      if (isOffline) {
        Get.snackbar(
          'No internet',
          'Please check your connection and try again.',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      final text = messageController.text.trim();
      if (text.isEmpty) return;

      if (_gemini == null) {
        Get.defaultDialog(
          contentPadding: const EdgeInsets.only(
            bottom: 30,
            left: 20,
            right: 20,
          ),
          title: "Missing API Key",
          middleText:
              "Please set your Gemini API key in Settings before sending messages.",
          textCancel: "Cancel",
          textConfirm: "Go to Settings",
          confirmTextColor: Colors.white,
          onConfirm: () {
            Get.back(); // close dialog
            Get.to(
              () => const SettingsPage(),
              transition: Transition.rightToLeft,
              duration: const Duration(milliseconds: 250),
            );
          },
        );
        return;
      }

      final gemini = _gemini!;

      // UI: add user + model placeholder
      messageController.clear();
      messages.add(ChatMessage(role: 'user', content: text));
      messages.add(ChatMessage(role: 'model', content: '...'));

      final modelIndex = messages.length - 1;
      activeModelIndex.value = modelIndex;
      isStreaming.value = true;
      tokenCount.value = 0;

      final history = List<ChatMessage>.from(messages)..removeAt(modelIndex);

      // Cancel any existing stream and wait for it to finish cancelling
      if (_streamingSub != null) {
        try {
          await _streamingSub!.cancel();
        } catch (e) {
          debugPrint('Error cancelling previous stream: $e');
        }
        _streamingSub = null;
      }

      _streamingSub = gemini
          .streamReply(messages: history)
          .listen(
            (chunk) async {
              if (modelIndex < 0 || modelIndex >= messages.length) return;

              final delta = chunk.delta;
              if (delta.isNotEmpty) {
                final old = messages[modelIndex];
                final newText = (old.content == '...')
                    ? delta
                    : (old.content + delta);
                messages[modelIndex] = ChatMessage(
                  role: old.role,
                  content: newText,
                );
              }

              // token/meta handling
              if (chunk.meta != null) {
                final meta = chunk.meta!;
                if (meta['tokenCount'] != null) {
                  final tc = meta['tokenCount'];
                  if (tc is int) {
                    tokenCount.value = tc;
                  } else if (tc is num) {
                    tokenCount.value = tc.toInt();
                  } else {
                    tokenCount.value =
                        int.tryParse(tc.toString()) ??
                        (delta.isNotEmpty
                            ? tokenCount.value + 1
                            : tokenCount.value);
                  }
                } else if (delta.isNotEmpty) {
                  tokenCount.value++;
                }

                if (meta['event'] == 'retry') {
                  final reason = meta['reason'] ?? 'retrying';
                  final attempt = meta['attempt'] ?? '';
                  _showTransientSystemMessage(
                    'Retrying: $reason (attempt $attempt)',
                  );
                } else if (meta['event'] == 'gap_retry') {
                  final attempt = meta['attempt'] ?? '';
                  _showTransientSystemMessage(
                    'Connection gap detected — retrying (attempt $attempt)',
                  );
                }

                if (meta['error'] != null) {
                  final err = meta['error'].toString();
                  if (modelIndex >= 0 && modelIndex < messages.length) {
                    messages[modelIndex] = ChatMessage(
                      role: 'model',
                      content: '⚠️ Error: $err',
                    );
                  }
                  isStreaming.value = false;
                  activeModelIndex.value = -1;
                  try {
                    await _streamingSub?.cancel();
                  } catch (_) {}
                  _streamingSub = null;
                  return;
                }
              } else {
                if (delta.isNotEmpty) tokenCount.value++;
              }

              if (chunk.isFinal) {
                isStreaming.value = false;
                activeModelIndex.value = -1;

                final reply = (modelIndex >= 0 && modelIndex < messages.length)
                    ? messages[modelIndex].content
                    : '';
                if (reply.isNotEmpty && _settings.autoPlayTts.value) {
                  _playTts(reply);
                }

                try {
                  await _streamingSub?.cancel();
                } catch (_) {}
                _streamingSub = null;
              }
            },
            onError: (e) async {
              debugPrint("Gemini error: $e");
              isStreaming.value = false;
              activeModelIndex.value = -1;
              if (modelIndex >= 0 && modelIndex < messages.length) {
                messages[modelIndex] = ChatMessage(
                  role: 'model',
                  content: "⚠️ Error: ${e.toString()}",
                );
              }
              try {
                await _streamingSub?.cancel();
              } catch (_) {}
              _streamingSub = null;
            },
            onDone: () {
              isStreaming.value = false;
              activeModelIndex.value = -1;
              _streamingSub = null;
            },
            cancelOnError: true,
          );
    } catch (err) {
      Get.snackbar(
        'Network error',
        'Could not verify network: $err',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Retry an earlier user message (by index).
  void retryMessage(int userIndex) {
    if (userIndex < 0 || userIndex >= messages.length) return;
    final userMsg = messages[userIndex];
    if (userMsg.role != 'user') return;

    // Validate API key / cached model
    if (_gemini == null) {
      Get.snackbar(
        'Missing API Key',
        'Please set your Gemini API key in Settings before retrying.',
      );
      Get.to(() => const SettingsPage());
      return;
    }
    final gemini = _gemini!;

    // Cancel existing stream
    try {
      _streamingSub?.cancel();
    } catch (_) {}
    _streamingSub = null;

    // Remove everything after the user message
    if (userIndex + 1 < messages.length) {
      messages.removeRange(userIndex + 1, messages.length);
    }

    // Insert model placeholder
    messages.insert(userIndex + 1, ChatMessage(role: 'model', content: '...'));

    final modelIndex = userIndex + 1;
    activeModelIndex.value = modelIndex;
    isStreaming.value = true;
    tokenCount.value = 0;

    // Build history up to user message (inclusive)
    final history = messages.sublist(0, userIndex + 1);

    _streamingSub = gemini
        .streamReply(messages: history)
        .listen(
          (chunk) async {
            if (chunk.delta.isNotEmpty) {
              final old = messages[modelIndex];
              final newText = (old.content == '...')
                  ? chunk.delta
                  : (old.content + chunk.delta);
              messages[modelIndex] = ChatMessage(
                role: old.role,
                content: newText,
              );

              if (chunk.meta != null && chunk.meta!['tokenCount'] != null) {
                try {
                  tokenCount.value = chunk.meta!['tokenCount'] as int;
                } catch (_) {
                  tokenCount.value++;
                }
              } else {
                tokenCount.value++;
              }
            }

            // meta -> transient system messages
            if (chunk.meta != null) {
              final meta = chunk.meta!;
              if (meta['event'] == 'retry') {
                final reason = meta['reason'] ?? 'retrying';
                final attempt = meta['attempt'] ?? '';
                _showTransientSystemMessage(
                  'Retrying: $reason (attempt $attempt)',
                );
              } else if (meta['event'] == 'gap_retry') {
                final attempt = meta['attempt'] ?? '';
                _showTransientSystemMessage(
                  'Connection gap detected — retrying (attempt $attempt)',
                );
              } else if (meta['error'] != null) {
                final err = meta['error'].toString();
                messages[modelIndex] = ChatMessage(
                  role: 'model',
                  content: '⚠️ Error: $err',
                );
                isStreaming.value = false;
                activeModelIndex.value = -1;
              }
            }

            if (chunk.isFinal) {
              isStreaming.value = false;
              activeModelIndex.value = -1;
              final reply = messages[modelIndex].content;
              if (reply.isNotEmpty && _settings.autoPlayTts.value) {
                _playTts(reply);
              }
            }
          },
          onError: (e) {
            debugPrint("Gemini retry error: $e");
            isStreaming.value = false;
            activeModelIndex.value = -1;
            messages[modelIndex] = ChatMessage(
              role: 'model',
              content: "⚠️ Error: ${e.toString()}",
            );
          },
          onDone: () {
            isStreaming.value = false;
            activeModelIndex.value = -1;
          },
          cancelOnError: true,
        );
  }

  /// Stop current streaming (if any)
  void stopStreaming() {
    try {
      _streamingSub?.cancel();
    } catch (_) {}
    _streamingSub = null;
    isStreaming.value = false;
    activeModelIndex.value = -1;
  }

  /// Play TTS (non-blocking from caller). Errors are caught and printed.
  Future<void> _playTts(String text) async {
    try {
      await tts.speak(text, locale: _settings.ttsLanguage.value);
    } catch (e) {
      debugPrint('TTS play error: $e');
    }
  }

  @override
  void onClose() {
    _partialSub?.cancel();
    _statusSub?.cancel();
    _streamingSub?.cancel();
    messageController.dispose();
    speech.dispose();
    tts.dispose();
    super.onClose();
  }
}
