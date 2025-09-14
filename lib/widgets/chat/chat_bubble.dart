import 'package:flutter/material.dart';
import 'package:get/get.dart'; // for .tr
import '../../models/chat_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isActiveStream;
  final VoidCallback? onReplay;
  final VoidCallback? onStopTts;
  final VoidCallback? onRetry;
  final VoidCallback? onCopy;

  const ChatBubble({
    super.key,
    required this.message,
    this.isActiveStream = false,
    this.onReplay,
    this.onStopTts,
    this.onCopy,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: isUser
            ? const EdgeInsets.only(top: 10, bottom: 10, left: 30, right: 10)
            : const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 30),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 700),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (message.content.isEmpty || message.content == '...')
                  ? 'thinking'.tr
                  : message.content,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            if (!isUser &&
                message.content.isNotEmpty &&
                message.content != '...')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'replay_tts'.tr,
                    icon: const Icon(Icons.volume_up, size: 20),
                    onPressed: onReplay,
                  ),
                  IconButton(
                    tooltip: 'stop_speaking'.tr,
                    icon: const Icon(Icons.volume_off, size: 21),
                    onPressed: onStopTts,
                  ),
                  IconButton(
                    tooltip: 'copy_chat'.tr,
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: onCopy,
                  ),
                  IconButton(
                    tooltip: 'retry_message'.tr,
                    icon: const Icon(Icons.refresh, size: 22),
                    onPressed: onRetry,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
