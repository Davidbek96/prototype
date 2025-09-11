
// lib/controllers/chat_controller.dart
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
      // Wire partial transcript -> update text field without auto-sending
      _partialSub = speech.partialStream.listen((partial) {
        // Keep the live transcript in the text field; don't submit automatically
        // Do not trim or drop previous content because most engines send the
        // full interim transcript each time. We trust the service to supply cumulative text.
        messageController.text = partial;
        messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: messageController.text.length),
        );
      });

      _statusSub = speech.statusStream.listen((status) {
        // reflect listening status in UI
        isListening.value = status == 'listening';
      });
    });

    // Init TTS
    tts.init();

    // ensure we start with a greeting or empty list as desired
    // messages.add(ChatMessage(role: 'model', content: '안녕하세요!')); // optional
  }

  /// Start listening (user presses mic)
  Future<void> startListening() async {
    // Don't re-start if already listening
    if (speech.isListening) return;
    try {
      await speech.startListening(requestPermission: true, listenFor: Duration.zero);
      // isListening will be updated via statusStream
    } catch (e) {
      debugPrint("ChatController.startListening error: $e");
    }
  }

  /// Stop listening (user releases mic). We do NOT auto-submit — sendButton controls submission.
  Future<void> stopListening({bool submit = false}) async {
    try {
      await speech.stopListening();
    } catch (e) {
      debugPrint("ChatController.stopListening error: $e");
    }
    // Do NOT auto-send when submit=false
    if (submit) {
      sendMessage();
    }
  }

  /// Send message (from send button)
  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    // Clear input for UX (keep a local copy)
    messageController.clear();
    // Add user message and a placeholder for model reply
    messages.add(ChatMessage(role: 'user', content: text));
    messages.add(ChatMessage(role: 'model', content: '...'));
    final modelIndex = messages.length - 1;
    activeModelIndex.value = modelIndex;
    isStreaming.value = true;
    tokenCount.value = 0;

    // Build history without placeholder
    final history = List<ChatMessage>.from(messages)..removeAt(modelIndex);

    // Start Gemini streaming
    _streamingSub = gemini.streamReply(messages: history).listen(
      (chunk) {
        debugPrint("ChatController got chunk: delta='${chunk.delta}' isFinal=${chunk.isFinal}");
        if (chunk.delta != null && chunk.delta!.isNotEmpty) {
          final old = messages[modelIndex];
          final newText = (old.content == '...') ? chunk.delta! : (old.content + chunk.delta!);
          messages[modelIndex] = ChatMessage(role: old.role, content: newText);
          tokenCount.value++;
        }
        if (chunk.isFinal) {
          isStreaming.value = false;
          activeModelIndex.value = -1;
          // optionally autoplay TTS for the final model response
          if (messages[modelIndex].content.trim().isNotEmpty) {
            // uncomment if you want auto-play
            // tts.speak(messages[modelIndex].content);
          }
        }
      },
      onError: (e) {
        debugPrint("Gemini error: $e");
        isStreaming.value = false;
        activeModelIndex.value = -1;
        messages[modelIndex] = ChatMessage(role: 'model', content: "⚠️ Error: ${e.toString()}");
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

