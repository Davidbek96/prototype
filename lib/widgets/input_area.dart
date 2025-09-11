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
        await widget.speech!.startListening(
          requestPermission: true,
          listenFor: Duration.zero,
        );
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
    bool hasText = widget.controller.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,

        borderRadius: BorderRadius.circular(15),
        border: Border(
          top: BorderSide(color: Colors.grey.withAlpha(50), width: 2),
        ),
      ),
      //color: Theme.of(context).cardColor, // light grey background
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Text field
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        minLines: 1,
                        maxLines: 5,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "Message",
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),

                    // 📤 Send button (only when text exists)
                    if (hasText)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: GestureDetector(
                          onTap: widget.onSend,
                          child: const Icon(
                            Icons.send,
                            color: Colors.blue, // iOS blue
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // 🎤 Microphone with glowing wave (always visible)
            AvatarGlow(
              animate: widget.isListening || _holding,
              glowColor: Colors.blue.withValues(alpha: 0.6),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              repeat: true,
              child: GestureDetector(
                onLongPressStart: (_) => _handleLongPressStart(),
                onLongPressEnd: (_) => _handleLongPressEnd(),
                child: CircleAvatar(
                  backgroundColor: (widget.isListening || _holding)
                      ? Colors.blue
                      : Theme.of(context).cardColor,
                  radius: 26,
                  child: (widget.isListening || _holding)
                      ? Icon(Icons.mic_sharp, color: Colors.white, size: 30)
                      : Icon(
                          Icons.mic_none,
                          color: Colors.grey.shade600,
                          size: 30,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
