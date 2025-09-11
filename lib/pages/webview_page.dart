import 'dart:async';
import 'dart:convert';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibration/vibration.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  Timer? _tickTimer;
  int _tick = 0;

  final _battery = Battery();
  StreamSubscription<BatteryState>? _batterySub;

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'JOI',
        onMessageReceived: (JavaScriptMessage msg) {
          _onJsMessage(msg.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            await _injectOnMessageFallback();
            _startNativeTick();
            _startBatteryListener();
            _startConnectivityListener();
          },
        ),
      )
      ..loadFlutterAsset('assets/demo/index.html');
  }

  Future<void> _injectOnMessageFallback() async {
    const js = '''
      (function(){
        window.JOI = window.JOI || {};
        if (typeof window.JOI.onMessage !== 'function') {
          window.JOI.onMessage = function(json){
            console.log("Native→JS:", json);
          };
        }
      })();
    ''';
    await _controller.runJavaScript(js);
  }

  Future<void> _onJsMessage(String raw) async {
    Map<String, dynamic> req;
    try {
      req = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return _sendToJs({
        'type': 'error',
        'action': 'parse',
        'error': {'code': 'E_PARSE', 'message': 'Invalid JSON from JS'},
      });
    }

    final String action = req['action'] ?? 'unknown';
    final String? requestId = req['requestId'];
    final payload = req['payload'] ?? {};

    try {
      switch (action) {
        case 'vibrate':
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 500);
          }
          await _sendToJs({
            'type': 'response',
            'action': action,
            'requestId': requestId,
            'payload': {'result': 'ok'},
          });
          break;

        case 'getDeviceInfo':
          final info = await _getDeviceInfo();
          await _sendToJs({
            'type': 'response',
            'action': action,
            'requestId': requestId,
            'payload': {'result': info},
          });
          break;

        case 'copyToClipboard':
          final text = payload['text'] ?? '';
          await Clipboard.setData(ClipboardData(text: text));
          await _sendToJs({
            'type': 'response',
            'action': action,
            'requestId': requestId,
            'payload': {'result': 'copied', 'text': text},
          });
          break;

        case 'pickImage':
          final picker = ImagePicker();
          final XFile? file = await picker.pickImage(
            source: ImageSource.gallery,
          );
          if (file != null) {
            await _sendToJs({
              'type': 'response',
              'action': action,
              'requestId': requestId,
              'payload': {'path': file.path},
            });
          } else {
            await _sendToJs({
              'type': 'error',
              'action': action,
              'requestId': requestId,
              'error': {'code': 'E_CANCELLED', 'message': 'User cancelled'},
            });
          }
          break;

        default:
          await _sendToJs({
            'type': 'error',
            'action': action,
            'requestId': requestId,
            'error': {
              'code': 'E_UNSUPPORTED',
              'message': 'Unknown action: $action',
            },
          });
      }
    } catch (e) {
      await _sendToJs({
        'type': 'error',
        'action': action,
        'requestId': requestId,
        'error': {'code': 'E_NATIVE', 'message': e.toString()},
      });
    }
  }

  Future<void> _sendToJs(Map<String, dynamic> data) async {
    final jsObjectLiteral = jsonEncode(data);
    await _controller.runJavaScript(
      'window.JOI && window.JOI.onMessage($jsObjectLiteral)',
    );
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
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

  void _startNativeTick() {
    _tickTimer?.cancel();
    _tick = 0;
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _tick++;
      _sendToJs({
        'type': 'event',
        'action': 'nativeTick',
        'payload': {'tick': _tick},
      });
    });
  }

  void _startBatteryListener() {
    _batterySub?.cancel();
    _batterySub = _battery.onBatteryStateChanged.listen((BatteryState state) {
      String message;

      switch (state) {
        case BatteryState.charging:
          message = "Your device is charging";
          break;
        case BatteryState.discharging:
          message = "Your device is running on battery";
          break;
        case BatteryState.full:
          message = "Your battery is fully charged";
          break;
        case BatteryState.unknown:
        default:
          message = "Battery status is unknown";
      }

      _sendToJs({
        'type': 'event',
        'action': 'batteryState',
        'payload': {'state': message},
      });
    });
  }

  void _startConnectivityListener() {
    _connSub?.cancel();
    _connSub = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final status = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      String message;

      switch (status) {
        case ConnectivityResult.wifi:
          message = "Connected via Wi-Fi";
          break;
        case ConnectivityResult.mobile:
          message = "Connected via mobile data";
          break;
        case ConnectivityResult.ethernet:
          message = "Connected via Ethernet";
          break;
        case ConnectivityResult.bluetooth:
          message = "Connected via Bluetooth";
          break;
        case ConnectivityResult.vpn:
          message = "Connected via VPN";
          break;
        case ConnectivityResult.other:
          message = "Connected (other network)";
          break;
        case ConnectivityResult.none:
          message = "No internet connection";
      }

      _sendToJs({
        'type': 'event',
        'action': 'connectivity',
        'payload': {'status': message},
      });
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _batterySub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }
}
