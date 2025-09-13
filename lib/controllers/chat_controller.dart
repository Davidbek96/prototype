// lib/controllers/chat_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/chat_model.dart';
//import '../gemini_chat_model.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/permission_service.dart';
import '../services/connectivity_service.dart';
import '../services/gemini_manager.dart';
import '../domain/chat_stream_manager.dart';
import '../domain/transient_message_service.dart';
import 'settings_controller.dart';

class ChatController extends GetxController {
  // collaborators (injected via Binding or constructor)
  late final SpeechService speech;
  late final TtsService tts;
  late final PermissionService permission;
  late final ConnectivityService connectivity;
  late final GeminiManager geminiManager;
  late final ChatStreamManager streamManager;
  late final TransientMessageService transientMsg;

  ChatController({
    SpeechService? speech,
    TtsService? tts,
    PermissionService? permission,
    ConnectivityService? connectivity,
    GeminiManager? geminiManager,
    ChatStreamManager? streamManager,
    TransientMessageService? transientMsg,
  }) {
    // prefer injected values, otherwise resolve from Get
    this.speech = speech ?? Get.find<SpeechService>();
    this.tts = tts ?? Get.find<TtsService>();
    this.permission = permission ?? Get.find<PermissionService>();
    this.connectivity = connectivity ?? Get.find<ConnectivityService>();
    this.geminiManager = geminiManager ?? Get.find<GeminiManager>();
    this.streamManager = streamManager ?? Get.find<ChatStreamManager>();
    this.transientMsg = transientMsg ?? Get.find<TransientMessageService>();
  }
  final _box = GetStorage();

  final messages = <ChatMessage>[].obs;
  final isStreaming = false.obs;
  final tokenCount = 0.obs;
  final activeModelIndex = (-1).obs;
  final isListening = false.obs;
  late final TextEditingController messageController;

  SettingsController get _settings => Get.find<SettingsController>();

  @override
  void onInit() {
    super.onInit();
    messageController = TextEditingController();
    // Load saved messages on startup
    final stored = _box.read<List>('messages');
    if (stored != null) {
      messages.assignAll(
        stored.map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m))),
      );
    }

    // Save messages whenever they change
    ever(messages, (_) {
      _box.write('messages', messages.map((m) => m.toJson()).toList());
    });

    // wire speech partial + status
    speech.initialize().then((_) {
      speech.partialStream.listen((partial) {
        messageController.text = partial;
        messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: messageController.text.length),
        );
      });

      speech.statusStream.listen((status) {
        isListening.value = status == 'listening';
      });
    });

    // keep tts language in sync with settings
    tts.init(lang: _settings.ttsLanguage.value);
    ever<String>(_settings.ttsLanguage, (newLang) {
      try {
        tts.init(lang: newLang);
      } catch (e) {
        debugPrint('Failed to re-init TTS for language $newLang: $e');
      }
    });

    // wire stream manager callbacks
    streamManager.onChunk = _onChunk;
    streamManager.onDone = _onStreamDone;
    streamManager.onError = _onStreamError;
  }

  void copyChat(BuildContext context, String text) {
    // Favor visible input when present, otherwise fall back to stored key.
    final trimmedText = text.trim();

    if (trimmedText.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
    }
  }

  //used to stop tts when new action started
  void stopTtsSafe() {
    try {
      tts.stop();
    } catch (_) {}
  }

  Future<void> startListening() async {
    final havePermission = await permission.ensureMicPermissionOrPrompt();
    if (!havePermission) return;
    if (!await connectivity.hasNetwork()) {
      Get.closeAllSnackbars();
      Get.snackbar('No internet', 'Please check your connection.');
      return;
    }

    final started = await speech.startListening(
      requestPermission: false,
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 10),
      localeId: _settings.sttLanguage.value,
    );
    isListening.value = started;
  }

  Future<void> stopListening({bool submit = false}) async {
    try {
      await speech.stopListening();
      isListening.value = false;
    } catch (e) {
      debugPrint('stopListening error: $e');
    }
    if (submit) await sendMessage();
  }

  Future<void> sendMessage() async {
    //if tts working stop
    stopTtsSafe();
    // connectivity check
    if (!await connectivity.hasNetwork()) {
      Get.closeAllSnackbars();
      Get.snackbar('No internet', 'Please check your connection.');
      return;
    }

    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final gemini = geminiManager.currentOrPromptSettings();
    if (gemini == null) return; // user prompted to settings

    // UI placeholders
    messageController.clear();
    messages.add(ChatMessage(role: 'user', content: text));
    messages.add(ChatMessage(role: 'model', content: '...'));
    final modelIndex = messages.length - 1;
    activeModelIndex.value = modelIndex;
    isStreaming.value = true;
    tokenCount.value = 0;

    final history = List<ChatMessage>.from(messages)..removeAt(modelIndex);

    // start streaming
    streamManager.startStream(gemini, history);
  }

  /// Retry an earlier user message by index.
  /// This mirrors the original behavior: cancels any current stream,
  /// removes messages after the user message, inserts a model placeholder,
  /// and restarts streaming using the history up to the user message.
  void retryMessage(int userIndex) {
    //if tts working stop
    stopTtsSafe();

    if (userIndex < 0 || userIndex >= messages.length) return;
    final userMsg = messages[userIndex];
    if (userMsg.role != 'user') return;

    final gemini = geminiManager.currentOrPromptSettings();
    if (gemini == null) {
      // user prompted to settings (or cancelled)
      return;
    }

    // Cancel any existing stream (via streamManager)
    try {
      streamManager.stop();
    } catch (_) {}

    // Remove all messages after the user message
    if (userIndex + 1 < messages.length) {
      messages.removeRange(userIndex + 1, messages.length);
    }

    // Insert model placeholder and update state
    messages.insert(userIndex + 1, ChatMessage(role: 'model', content: '...'));
    final modelIndex = userIndex + 1;
    activeModelIndex.value = modelIndex;
    isStreaming.value = true;
    tokenCount.value = 0;

    // Build history up to user message (inclusive)
    final history = messages.sublist(0, userIndex + 1);

    // Start streaming again
    streamManager.startStream(gemini, history);
  }

  void _onChunk(ChatChunk chunk) {
    final modelIndex = activeModelIndex.value;
    if (modelIndex < 0 || modelIndex >= messages.length) return;

    final old = messages[modelIndex];
    final newText = (old.content == '...')
        ? chunk.delta
        : (old.content + chunk.delta);
    messages[modelIndex] = ChatMessage(role: old.role, content: newText);

    if (chunk.meta != null && chunk.meta!['tokenCount'] != null) {
      try {
        tokenCount.value = (chunk.meta!['tokenCount'] as num).toInt();
      } catch (_) {
        tokenCount.value++;
      }
    } else if (chunk.delta.isNotEmpty) {
      tokenCount.value++;
    }

    final meta = chunk.meta ?? {};
    if (meta['event'] == 'retry') {
      transientMsg.show('Retrying: ${meta['reason'] ?? ''}');
    }
    if (meta['event'] == 'gap_retry') {
      transientMsg.show('Connection gap — retrying');
    }

    if (meta['error'] != null) {
      messages[modelIndex] = ChatMessage(
        role: 'model',
        content: '⚠️ Error: ${meta['error']}',
      );
      stopStreaming();
    }
  }

  void _onStreamDone() async {
    isStreaming.value = false;
    activeModelIndex.value = -1;
    final reply = (messages.isNotEmpty ? messages.last.content : '');
    if (reply.isNotEmpty && _settings.autoPlayTts.value) {
      try {
        await tts.speak(reply, locale: _settings.ttsLanguage.value);
      } catch (e) {
        debugPrint('TTS play error: $e');
      }
    }
  }

  void _onStreamError(Object e) {
    isStreaming.value = false;
    activeModelIndex.value = -1;
    transientMsg.show('Stream error: $e');
  }

  void stopStreaming() {
    streamManager.stop();
    isStreaming.value = false;
    activeModelIndex.value = -1;
  }

  @override
  void onClose() {
    messageController.dispose();
    speech.dispose();
    tts.dispose();
    streamManager.dispose();
    super.onClose();
  }
}
