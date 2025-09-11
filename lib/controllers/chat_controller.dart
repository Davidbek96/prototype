import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/chat_model.dart';
import '../gemini_chat_model.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../consts.dart';

class ChatController extends GetxController {
  // Services / model
  final GeminiChatModel gemini = GeminiChatModel(apiKey: geminiKey);
  final SpeechService speech = SpeechService();
  final TtsService tts = TtsService();

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
  StreamSubscription? _streamingSub;

  @override
  void onInit() {
    super.onInit();
    messageController = TextEditingController();

    // Initialize speech and subscribe to partial transcripts
    speech.initialize().then((ok) {
      _partialSub = speech.partialStream.listen((partial) {
        // Replace text with cumulative transcript (not resetting to empty)
        messageController.text = partial;
        messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: messageController.text.length),
        );
      });

      _statusSub = speech.statusStream.listen((status) {
        isListening.value = status == 'listening';
      });
    });

    // Init TTS
    tts.init();
  }

  /// Start listening (user presses mic)
  Future<void> startListening() async {
    if (speech.isListening) return;
    try {
      await speech.startListening(
        requestPermission: true,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint("ChatController.startListening error: $e");
    }
  }

  /// Stop listening (user releases mic). Do not auto-submit.
  Future<void> stopListening({bool submit = false}) async {
    try {
      await speech.stopListening();
    } catch (e) {
      debugPrint("ChatController.stopListening error: $e");
    }
    if (submit) {
      sendMessage();
    }
  }

  /// Send message (from send button)
  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messageController.clear();
    messages.add(ChatMessage(role: 'user', content: text));
    messages.add(ChatMessage(role: 'model', content: '...'));
    final modelIndex = messages.length - 1;
    activeModelIndex.value = modelIndex;
    isStreaming.value = true;
    tokenCount.value = 0;

    final history = List<ChatMessage>.from(messages)..removeAt(modelIndex);

    _streamingSub = gemini
        .streamReply(messages: history)
        .listen(
          (chunk) {
            if (chunk.delta != null && chunk.delta!.isNotEmpty) {
              final old = messages[modelIndex];
              final newText = (old.content == '...')
                  ? chunk.delta!
                  : (old.content + chunk.delta!);
              messages[modelIndex] = ChatMessage(
                role: old.role,
                content: newText,
              );
              tokenCount.value++;
            }
            if (chunk.isFinal) {
              isStreaming.value = false;
              activeModelIndex.value = -1;
            }
          },
          onError: (e) {
            debugPrint("Gemini error: $e");
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

  void stopStreaming() {
    _streamingSub?.cancel();
    _streamingSub = null;
    isStreaming.value = false;
    activeModelIndex.value = -1;
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
