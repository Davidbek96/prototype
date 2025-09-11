import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:testapp/widgets/show_list_empty.dart';

import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/input_area.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  ChatController get _ctrl => Get.find<ChatController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Ensure TTS is stopped and clean up
    try {
      _ctrl.tts.stop();
    } catch (_) {}
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // Called when the widget is removed from the widget tree or covered by another route.
    // Stop any ongoing TTS so it doesn't keep playing when the user navigates away.
    try {
      _ctrl.tts.stop();
    } catch (_) {}
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the app loses focus/paused, stop TTS to avoid background playback
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      try {
        _ctrl.tts.stop();
      } catch (_) {}
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ChatController ctrl = Get.find<ChatController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gemini Chatbot"),
        actions: [
          Obx(() {
            if (!ctrl.isStreaming.value) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => Text(" • tokens: ${ctrl.tokenCount.value}")),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Stop reply',
                    icon: const Icon(Icons.stop_circle),
                    onPressed: ctrl.stopStreaming,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final msgs = ctrl.messages;

              // If there are no messages show a friendly robot placeholder
              if (msgs.isEmpty) {
                return ShowListEmpty();
              }

              // Auto-scroll whenever messages change
              _scrollToBottom();

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: msgs.length,
                itemBuilder: (context, index) {
                  final msg = msgs[index];

                  final isActive =
                      ctrl.isStreaming.value &&
                      index == ctrl.activeModelIndex.value;

                  // Determine the preceding user message index (for retry)
                  int userIndex = -1;
                  if (msg.role == 'model' &&
                      index - 1 >= 0 &&
                      msgs[index - 1].role == 'user') {
                    userIndex = index - 1;
                  }

                  return ChatBubble(
                    message: msg,
                    isActiveStream: isActive,
                    onReplay: () => ctrl.tts.speak(msg.content),
                    onStopTts: () {
                      try {
                        ctrl.tts.stop();
                      } catch (_) {}
                    },
                    onRetry: userIndex >= 0
                        ? () => ctrl.retryMessage(userIndex)
                        : null,
                  );
                },
              );
            }),
          ),
          Obx(() {
            return InputArea(
              controller: ctrl.messageController,
              speech: ctrl.speech,
              isListening: ctrl.isListening.value,
              onListeningChanged: (listening) =>
                  ctrl.isListening.value = listening,
              onSend: ctrl.sendMessage,
              onMicStart: ctrl.startListening,
              onMicEnd: () => ctrl.stopListening(submit: false),
            );
          }),
        ],
      ),
    );
  }
}
