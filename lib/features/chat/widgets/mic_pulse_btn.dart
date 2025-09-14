// lib/widgets/mic_pulse_btn.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/utils.dart';
import 'package:permission_handler/permission_handler.dart';

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

  bool _hasMicPermission = false;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _animController.value = 0.0;

    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (mounted) {
      setState(() => _hasMicPermission = status.isGranted);
    }
  }

  Future<bool> _requestPermissionIfNeeded() async {
    if (_hasMicPermission) return true; // already granted

    if (_isRequestingPermission) return false; // another request in progress

    _isRequestingPermission = true;
    final prevGranted = _hasMicPermission;

    final status = await Permission.microphone.request();
    final granted = status.isGranted;

    if (mounted) {
      setState(() => _hasMicPermission = granted);
    }

    _isRequestingPermission = false;

    if (!granted) {
      // still denied -> explain / open settings
      _showPermissionDialog();
      return false;
    }

    // If permission was just granted right now, return false so the user must press again
    // to actually start listening / show overlay. This avoids unexpected actions immediately
    // after the OS permission dialog.
    if (!prevGranted && granted) return false;

    return granted;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("mic_permission_title".tr),
        content: Text("mic_permission_content".tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("cancel".tr),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: Text("open_settings".tr),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant MicOnButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newNorm = _normalizeLevel(widget.volumeLevel);
    _smoothedLevel = _smoothedLevel * 0.7 + newNorm * 0.3;

    if (_hasMicPermission) {
      if (!oldWidget.isActive && widget.isActive) {
        _showOverlay();
      } else if (oldWidget.isActive && !widget.isActive) {
        _hideOverlay();
      } else {
        if (_overlayEntry != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _overlayEntry?.markNeedsBuild();
          });
        }
      }
    } else {
      _hideOverlay();
    }
  }

  double _normalizeLevel(double raw) {
    final norm = ((raw + 50.0) / 50.0).clamp(0.0, 1.0);
    return norm;
  }

  void _showOverlay() {
    if (_overlayEntry != null || !_hasMicPermission) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !mounted) return;

    final btnOffset = renderBox.localToGlobal(Offset.zero);
    final btnSize = renderBox.size;

    const overlaySide = 180.0;
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
                final t = _animController.value;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _hasMicPermission && widget.isActive;

    return GestureDetector(
      onTap: () async {
        if (!await _requestPermissionIfNeeded()) {
          return;
        }
        Get.closeAllSnackbars();
        Get.snackbar("mic_hold_title".tr, "mic_hold_message".tr);
      },
      onLongPressStart: (details) async {
        if (await _requestPermissionIfNeeded()) {
          widget.onLongPressStart?.call(details);
          _showOverlay();
        }
      },
      onLongPressEnd: (details) {
        if (_hasMicPermission) {
          widget.onLongPressEnd?.call(details);
          _hideOverlay();
        }
      },
      child: CircleAvatar(
        backgroundColor: active ? Colors.blue : Colors.grey.shade200,
        radius: 28,
        child: Icon(
          active ? Icons.mic : Icons.mic_none,
          color: active ? Colors.white : Colors.grey.shade700,
          size: 30,
        ),
      ),
    );
  }
}
