import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Ensures microphone permission is granted, prompting the user if needed.
  /// Returns true if permission is available, false otherwise.
  Future<bool> ensureMicPermissionOrPrompt() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      // Show a dialog that returns the user's choice (true = open settings)
      final bool? choose = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Microphone required'),
          content: const Text(
            'Microphone permission is permanently denied. Open app settings to enable it?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (choose == true) {
        await openAppSettings();
      }
      return false;
    }

    // Request permission if not permanently denied
    final result = await Permission.microphone.request();
    return result.isGranted;
  }
}
