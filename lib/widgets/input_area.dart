
// lib/widgets/input_area.dart
import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../services/speech_service.dart';
import 'dart:async';

class InputArea extends StatefulWidget {
  final TextEditingController controller;
  final SpeechService? speech;
  final VoidCallback onSend;
  final bool isListening;
  final void Function(bool listening)? onListeningChanged;

  // New optional callbacks - prefer these when provided (allows GetX controller to manage STT)
  final Future<void> Function()? onMicStart;
  final Future<void> Function()? onMicEnd;

  const InputArea({
    super.key,
    required this.controller,
    required this.onSend,
    this.speech,
    this.isListening = false,
    this.onListeningChanged,
    this.onMicStart,
    this.onMicEnd,
  });

  @override
  State<InputArea> createState() => _InputAreaState();
}

class _InputAreaState extends State<InputArea> {
  bool _holding = false;

  void _handleLongPressStart() async {
    setState(() => _holding = true);
    widget.onListeningChanged?.call(true);
    if (widget.onMicStart != null) {
      try {
        await widget.onMicStart!();
      } catch (e) {
        debugPrint("InputArea.onMicStart error: $e");
      }
    } else if (widget.speech != null) {
      try {
        await widget.speech!.startListening(requestPermission: true, listenFor: Duration.zero);
      } catch (e) {
        debugPrint("InputArea.startListening error: $e");
      }
    }
  }

  void _handleLongPressEnd() async {
    setState(() => _holding = false);
    widget.onListeningChanged?.call(false);
    if (widget.onMicEnd != null) {
      try {
        await widget.onMicEnd!();
      } catch (e) {
        debugPrint("InputArea.onMicEnd error: $e");
      }
    } else if (widget.speech != null) {
      try {
        await widget.speech!.stopListening();
      } catch (e) {
        debugPrint("InputArea.stopListening error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
      child: Row(
        children: [
          // 🎤 Microphone with glowing wave
          AvatarGlow(
            animate: widget.isListening || _holding,
            glowColor: const Color.fromARGB(255, 46, 46, 46),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            repeat: true,
            child: GestureDetector(
              onLongPressStart: (_) => _handleLongPressStart(),
              onLongPressEnd: (_) => _handleLongPressEnd(),
              child: CircleAvatar(
                backgroundColor: (widget.isListening || _holding)
                    ? Colors.red
                    : const Color.fromARGB(255, 46, 46, 46),
                radius: 25,
                child: Icon(
                  (widget.isListening || _holding) ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ⌨️ Growable text input (shows live transcript while speaking)
          Expanded(
            child: TextField(
              controller: widget.controller,
              minLines: 1,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Type or speak your message...",
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.all(10),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: widget.onSend),
        ],
      ),
    );
  }
}
