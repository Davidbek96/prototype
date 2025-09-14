// lib/widgets/input_area.dart
import 'package:flutter/material.dart';
import 'package:testapp/widgets/chat/mic_pulse_btn.dart';
import '../../services/speech_service.dart';
import 'package:get/get.dart';

class InputArea extends StatefulWidget {
  final TextEditingController controller;
  final SpeechService? speech;
  final VoidCallback onSend;
  final bool isListening;
  final void Function(bool listening)? onListeningChanged;
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
      await widget.onMicStart!();
    } else if (widget.speech != null) {
      await widget.speech!.startListening(
        requestPermission: true,
        listenFor: Duration.zero,
      );
    }
  }

  void _handleLongPressEnd() async {
    setState(() => _holding = false);
    widget.onListeningChanged?.call(false);
    if (widget.onMicEnd != null) {
      await widget.onMicEnd!();
    } else if (widget.speech != null) {
      await widget.speech!.stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border(
          top: BorderSide(color: Colors.grey.withAlpha(50), width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
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
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 4,
                          left: 10,
                          top: 10,
                          bottom: 10,
                        ),
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
                            hintText: "message".tr,
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    if (widget.controller.text.trim().isNotEmpty)
                      InkWell(
                        onTap: widget.onSend,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 15.0,
                            horizontal: 6,
                          ),
                          child: Icon(Icons.send, size: 22, color: Colors.blue),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            MicOnButton(
              isActive: widget.isListening || _holding,
              onLongPressStart: (_) => _handleLongPressStart(),
              onLongPressEnd: (_) => _handleLongPressEnd(),
            ),
          ],
        ),
      ),
    );
  }
}
