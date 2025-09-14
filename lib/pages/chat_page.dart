import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:testapp/widgets/chat/show_list_empty.dart';

import '../controllers/chat_controller.dart';
import '../widgets/chat/chat_bubble.dart';
import '../widgets/chat/input_area.dart';
import 'settings_page.dart'; // <--- import the settings page

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
    _ctrl.stopTtsSafe();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // Stop any ongoing TTS when widget is removed or covered
    _ctrl.stopTtsSafe();
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the app loses focus/paused, stop TTS
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _ctrl.stopTtsSafe();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ChatController ctrl = Get.find<ChatController>();

    return Scaffold(
      appBar: AppBar(
        title: Text("gemini_chatbot".tr),
        actions: [
          Obx(() {
            if (!ctrl.isStreaming.value) {
              return IconButton(
                tooltip: 'settings'.tr,
                icon: const Icon(Icons.settings),
                onPressed: () {
                  ctrl.stopTtsSafe(); // stop TTS before navigating
                  Get.to(() => const SettingsPage());
                },
              );
            }
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
                  Obx(() => Text("• ${"tokens".tr}:${ctrl.tokenCount.value}")),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'stop_reply'.tr,
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

              // Use a reversed ListView so the bottom (latest message) is visible on open.
              // We still present messages in chronological order by reading from the end.
              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: EdgeInsets.only(
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                itemCount: msgs.length,
                itemBuilder: (context, reverseIndex) {
                  // Map reversed index to normal chronological index:
                  final index = msgs.length - 1 - reverseIndex;
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
                    onReplay: () {
                      ctrl.tts.speak(msg.content);
                    },
                    onStopTts: ctrl.stopTtsSafe,
                    onCopy: () => ctrl.copyChat(context, msg.content),
                    onRetry: userIndex >= 0
                        ? () {
                            ctrl.retryMessage(userIndex);
                          }
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
              onSend: () {
                ctrl.sendMessage();
              },
              onMicStart: ctrl.startListening,
              onMicEnd: () => ctrl.stopListening(submit: false),
            );
          }),
        ],
      ),
    );
  }
}
