import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/input_area.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

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
                  Text(
                    " • tokens: ${''}",
                  ), // token display handled below if desired
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
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: msgs.length,
                itemBuilder: (context, index) {
                  final msg = msgs[index];

                  final isActive =
                      ctrl.isStreaming.value &&
                      index == ctrl.activeModelIndex.value;
                  return ChatBubble(
                    message: msg,
                    isActiveStream: isActive,
                    onReplay: () => ctrl.tts.speak(msg.content),
                    onStopTts: () => ctrl.tts.stop(),
                  );
                },
              );
            }),
          ),
          //const Divider(height: 1),
          // Input area: pass controller's messageController and mic callbacks
          Obx(() {
            return InputArea(
              controller: ctrl.messageController,
              speech: ctrl
                  .speech, // keeps backward compatibility; InputArea will prefer callbacks if provided
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
