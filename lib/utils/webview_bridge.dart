import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Helper functions for JOI WebView bridge
class WebViewBridge {
  final WebViewController controller;
  WebViewBridge(this.controller);

  Future<void> sendResponse(
    String action,
    String? requestId,
    Map<String, dynamic> payload,
  ) => _send({
    'type': 'response',
    'action': action,
    'requestId': requestId,
    'payload': payload,
  });

  Future<void> sendError(
    String action,
    String? requestId,
    String code,
    String message,
  ) => _send({
    'type': 'error',
    'action': action,
    'requestId': requestId,
    'error': {'code': code, 'message': message},
  });

  Future<void> sendEvent(String action, Map<String, dynamic> payload) =>
      _send({'type': 'event', 'action': action, 'payload': payload});

  Future<void> _send(Map<String, dynamic> data) async {
    final js = 'window.JOI.onMessage(${jsonEncode(data)})';
    await controller.runJavaScript(js);
  }

  /// Device info utility
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final plugin = DeviceInfoPlugin();
    try {
      final android = await plugin.androidInfo;
      return {
        'platform': 'android',
        'brand': android.brand,
        'model': android.model,
        'version': android.version.release,
        'sdkInt': android.version.sdkInt,
        'isPhysicalDevice': android.isPhysicalDevice,
      };
    } catch (_) {
      final ios = await plugin.iosInfo;
      return {
        'platform': 'ios',
        'name': ios.name,
        'systemName': ios.systemName,
        'systemVersion': ios.systemVersion,
        'model': ios.utsname.machine,
        'isPhysicalDevice': ios.isPhysicalDevice,
      };
    }
  }
}
