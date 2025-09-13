import 'package:get/get.dart';
import 'package:flutter/widgets.dart';

/// Small service for showing short-lived user-visible system messages.
/// By default it uses Get.snackbar. You can extend this to also insert
/// messages into the in-chat message list by providing a callback.
class TransientMessageService {
  /// Optional callback to insert/remove an in-chat system message.
  /// Example signature: (String text, {Duration duration})
  void Function(String text, {Duration duration})? inChatCallback;

  /// Show a short user-visible transient message.
  /// - `text`: message text
  /// - `duration`: how long the snackbar should be visible (default 4s)
  void show(String text, {Duration duration = const Duration(seconds: 4)}) {
    // First: notify via snack bar for immediate feedback
    Get.snackbar(
      'Info',
      text,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    // Optionally also notify the in-chat UI (if caller wired the callback)
    try {
      inChatCallback?.call(text, duration: duration);
    } catch (e) {
      // Swallow errors from the optional callback to avoid crashing callers.
      debugPrint('TransientMessageService.inChatCallback error: $e');
    }
  }
}
