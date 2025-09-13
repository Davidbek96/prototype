// lib/widgets/mic_pulse_btn.dart
import 'dart:async';
import 'package:flutter/material.dart';

class MicOnButton extends StatefulWidget {
  final bool isActive; // true when system is listening or holding
  final double volumeLevel; // raw dB value from SpeechService (e.g. -50..0)
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressEndCallback? onLongPressEnd;

  const MicOnButton({
    super.key,
    required this.isActive,
    this.volumeLevel = 0.0,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  State<MicOnButton> createState() => _MicOnButtonState();
}

class _MicOnButtonState extends State<MicOnButton>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late final AnimationController _animController;
  double _smoothedLevel = 0.0;

  // local subscription option (not required — we accept volumeLevel prop)
  StreamSubscription<double>? _directSub;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _animController.value = 0.0; // idle until overlay starts
  }

  @override
  void didUpdateWidget(covariant MicOnButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Smooth incoming raw volume (simple low-pass)
    final newNorm = _normalizeLevel(widget.volumeLevel);
    _smoothedLevel = _smoothedLevel * 0.7 + newNorm * 0.3;

    // Show/hide overlay based on isActive
    if (!oldWidget.isActive && widget.isActive) {
      _showOverlay();
    } else if (oldWidget.isActive && !widget.isActive) {
      _hideOverlay();
    } else {
      if (_overlayEntry != null) {
        // Defer rebuild until after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _overlayEntry?.markNeedsBuild();
        });
      }
    }
  }

  double _normalizeLevel(double raw) {
    // speech_to_text typically emits around -50..0 (platform dependent)
    // map -50 -> 0.0, 0 -> 1.0. clamp extras.
    final norm = ((raw + 50.0) / 50.0).clamp(0.0, 1.0);
    return norm;
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !mounted) return;

    final btnOffset = renderBox.localToGlobal(Offset.zero);
    final btnSize = renderBox.size;

    const overlaySide = 180.0;

    // Place overlay exactly centered on mic button
    final left = btnOffset.dx + (btnSize.width / 2) - (overlaySide / 2);
    final top = btnOffset.dy + (btnSize.height / 2) - (overlaySide / 2);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: left,
          top: top,
          width: overlaySide,
          height: overlaySide,
          child: IgnorePointer(
            ignoring: true,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final t = _animController.value; // 0..1
                final loudness = 0.8 + (_smoothedLevel * 1.6);

                Widget ring(
                  double phase,
                  double base,
                  double stroke,
                  double alpha,
                ) {
                  final phaseValue = (t + phase) % 1.0;
                  final scale = 0.6 + phaseValue * 1.6;
                  final opacity = ((1.0 - phaseValue) * alpha).clamp(0.0, 1.0);
                  return Center(
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: base * scale * loudness,
                        height: base * scale * loudness,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: opacity * 0.9),
                            width: stroke,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                const base = 64.0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // soft glow background
                    Container(
                      width: base * 1.8 * loudness,
                      height: base * 1.8 * loudness,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(
                              alpha: 0.08 + _smoothedLevel * 0.12,
                            ),
                            blurRadius: 28 + _smoothedLevel * 32,
                            spreadRadius: 6 + _smoothedLevel * 12,
                          ),
                        ],
                      ),
                    ),

                    ring(0.0, base, 4.0, 0.55),
                    ring(0.33, base, 3.0, 0.38),
                    ring(0.66, base, 2.0, 0.28),

                    // central blue disc with mic icon
                    Container(
                      width: 86.0 * (0.9 + _smoothedLevel * 0.45),
                      height: 86.0 * (0.9 + _smoothedLevel * 0.45),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(
                              alpha: 0.28 + _smoothedLevel * 0.18,
                            ),
                            blurRadius: 18 + _smoothedLevel * 18,
                            spreadRadius: 3 + _smoothedLevel * 8,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.mic, color: Colors.white, size: 34),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    _animController.repeat();
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _animController.stop();
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _animController.dispose();
    _directSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        widget.onLongPressStart?.call(details);
        _showOverlay();
      },
      onLongPressEnd: (details) {
        widget.onLongPressEnd?.call(details);
        _hideOverlay();
      },
      child: CircleAvatar(
        backgroundColor: widget.isActive ? Colors.blue : Colors.grey.shade200,
        radius: 28,
        child: Icon(
          widget.isActive ? Icons.mic : Icons.mic_none,
          color: widget.isActive ? Colors.white : Colors.grey.shade700,
          size: 30,
        ),
      ),
    );
  }
}
