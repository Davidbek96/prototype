// lib/widgets/chat_bubble.dart
import 'package:flutter/material.dart';
import '../models/chat_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isActiveStream;
  final VoidCallback? onReplay;
  final VoidCallback? onStopTts;

  const ChatBubble({
    super.key,
    required this.message,
    this.isActiveStream = false,
    this.onReplay,
    this.onStopTts,
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
          color: isUser ? Colors.blue : Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // if (!isUser && isActiveStream)
            //   Padding(
            //     padding: const EdgeInsets.only(bottom: 6.0),
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: const [
            //         SizedBox(
            //           width: 12,
            //           height: 12,
            //           child: CircularProgressIndicator(strokeWidth: 2),
            //         ),
            //         SizedBox(width: 8),
            //         Text("Typing...", style: TextStyle(fontSize: 12)),
            //       ],
            //     ),
            //   ),
            Text(
              (message.content.isEmpty || message.content == '...')
                  ? '...'
                  : message.content,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            if (!isUser)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Replay (TTS)',
                    icon: const Icon(Icons.volume_up, size: 20),
                    onPressed: onReplay,
                  ),
                  IconButton(
                    tooltip: 'Stop Speaking',
                    icon: const Icon(Icons.stop, size: 20),
                    onPressed: onStopTts,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
