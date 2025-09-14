import 'dart:async';
import 'dart:convert';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibration/vibration.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/webview_bridge.dart';

class WebViewControllerX extends GetxController {
  late final WebViewController webViewController;
  late final WebViewBridge bridge;

  final battery = Battery();
  StreamSubscription<BatteryState>? _batterySub;

  final connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  Timer? _tickTimer;
  int _tick = 0;

  /// Observables
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'JOI',
        onMessageReceived: (msg) => _onJsMessage(msg.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => isLoading.value = true,
          onPageFinished: (_) async {
            isLoading.value = false;
            await _injectOnMessageFallback();
            _startEventStreams();
          },
        ),
      )
      ..loadFlutterAsset('assets/demo/index.html');

    bridge = WebViewBridge(webViewController);
  }

  Future<void> _injectOnMessageFallback() async {
    const js = '''
      (function(){
        window.JOI = window.JOI || {};
        if (typeof window.JOI.onMessage !== 'function') {
          window.JOI.onMessage = function(json){ console.log("Native→JS:", json); };
        }
      })();
    ''';
    await webViewController.runJavaScript(js);
  }

  /// ========= Handle JS → Native =========
  Future<void> _onJsMessage(String raw) async {
    try {
      final req = jsonDecode(raw) as Map<String, dynamic>;
      final action = req['action'] ?? 'unknown';
      final requestId = req['requestId'] as String?;
      final payload = (req['payload'] ?? {}) as Map<String, dynamic>;

      switch (action) {
        case 'vibrate':
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 500);
          }
          await bridge.sendResponse(action, requestId, {"status": "ok"});
          break;

        case 'getDeviceInfo':
          await bridge.sendResponse(
            action,
            requestId,
            await WebViewBridge.getDeviceInfo(),
          );
          break;

        case 'copyToClipboard':
          final text = payload['text']?.toString() ?? '';
          if (text.isEmpty) {
            await bridge.sendError(
              action,
              requestId,
              'E_INVALID',
              'webview_no_text'.tr,
            );
          } else {
            await Clipboard.setData(ClipboardData(text: text));
            await bridge.sendResponse(action, requestId, {
              "copied": true,
              "text": text,
            });
          }
          break;

        case 'pickImage':
          try {
            final file = await ImagePicker().pickImage(
              source: ImageSource.gallery,
            );
            if (file == null) {
              await bridge.sendError(
                action,
                requestId,
                'E_CANCELLED',
                'webview_user_cancelled'.tr,
              );
            } else {
              final dataUri =
                  "data:image/${file.path.split('.').last};base64,${base64Encode(await file.readAsBytes())}";
              await bridge.sendResponse(action, requestId, {
                'uri': file.path,
                'imageData': dataUri,
              });
            }
          } catch (e) {
            await bridge.sendError(
              action,
              requestId,
              'E_PICK_FAILED',
              e.toString(),
            );
          }
          break;

        default:
          await bridge.sendError(
            action,
            requestId,
            'E_UNSUPPORTED',
            'webview_unknown_action'.trParams({'action': action}),
          );
      }
    } catch (_) {
      await bridge.sendError(
        'parse',
        null,
        'E_PARSE',
        'webview_invalid_json'.tr,
      );
    }
  }

  /// ========= Native → JS Events =========
  void _startEventStreams() {
    _tickTimer?.cancel();
    _tick = 0;
    _tickTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => bridge.sendEvent('nativeTick', {'tick': ++_tick}),
    );

    _batterySub?.cancel();
    _batterySub = battery.onBatteryStateChanged.listen((s) {
      final msgs = {
        BatteryState.charging: 'webview_battery_charging'.tr,
        BatteryState.discharging: 'webview_battery_discharging'.tr,
        BatteryState.full: 'webview_battery_full'.tr,
        BatteryState.unknown: 'webview_battery_unknown'.tr,
      };
      bridge.sendEvent('batteryState', {
        'state': msgs[s] ?? 'webview_battery_unknown'.tr,
      });
    });

    _connSub?.cancel();
    _connSub = connectivity.onConnectivityChanged.listen((results) {
      final status = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      final msgs = {
        ConnectivityResult.wifi: 'webview_connected_wifi'.tr,
        ConnectivityResult.mobile: 'webview_connected_mobile'.tr,
        ConnectivityResult.ethernet: 'webview_connected_ethernet'.tr,
        ConnectivityResult.bluetooth: 'webview_connected_bluetooth'.tr,
        ConnectivityResult.vpn: 'webview_connected_vpn'.tr,
        ConnectivityResult.other: 'webview_connected_other'.tr,
        ConnectivityResult.none: 'webview_no_internet'.tr,
      };
      bridge.sendEvent('connectivity', {
        'status': msgs[status] ?? 'webview_unknown'.tr,
      });
    });
  }

  @override
  void onClose() {
    _tickTimer?.cancel();
    _batterySub?.cancel();
    _connSub?.cancel();
    super.onClose();
  }
}
