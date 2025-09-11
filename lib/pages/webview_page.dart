import 'dart:async';
import 'dart:convert';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibration/vibration.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/webview_bridge.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});
  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  late final WebViewBridge _bridge;

  Timer? _tickTimer;
  int _tick = 0;

  final _battery = Battery();
  StreamSubscription<BatteryState>? _batterySub;

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'JOI',
        onMessageReceived: (msg) => _onJsMessage(msg.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) async {
            setState(() => _isLoading = false);
            await _injectOnMessageFallback();
            _startEventStreams();
          },
        ),
      )
      ..loadFlutterAsset('assets/demo/index.html');

    _bridge = WebViewBridge(_controller);
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
    await _controller.runJavaScript(js);
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
          await _bridge.sendResponse(action, requestId, {"status": "ok"});
          break;

        case 'getDeviceInfo':
          await _bridge.sendResponse(
            action,
            requestId,
            await WebViewBridge.getDeviceInfo(),
          );
          break;

        case 'copyToClipboard':
          final text = payload['text']?.toString() ?? '';
          if (text.isEmpty) {
            await _bridge.sendError(
              action,
              requestId,
              'E_INVALID',
              'No text to copy',
            );
          } else {
            await Clipboard.setData(ClipboardData(text: text));
            await _bridge.sendResponse(action, requestId, {
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
              await _bridge.sendError(
                action,
                requestId,
                'E_CANCELLED',
                'User cancelled',
              );
            } else {
              final dataUri =
                  "data:image/${file.path.split('.').last};base64,${base64Encode(await file.readAsBytes())}";
              await _bridge.sendResponse(action, requestId, {
                'uri': file.path,
                'imageData': dataUri,
              });
            }
          } catch (e) {
            await _bridge.sendError(
              action,
              requestId,
              'E_PICK_FAILED',
              e.toString(),
            );
          }
          break;

        default:
          await _bridge.sendError(
            action,
            requestId,
            'E_UNSUPPORTED',
            'Unknown action: $action',
          );
      }
    } catch (_) {
      await _bridge.sendError('parse', null, 'E_PARSE', 'Invalid JSON from JS');
    }
  }

  /// ========= Native → JS Events =========
  void _startEventStreams() {
    _tickTimer?.cancel();
    _tick = 0;
    _tickTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _bridge.sendEvent('nativeTick', {'tick': ++_tick}),
    );

    _batterySub?.cancel();
    _batterySub = _battery.onBatteryStateChanged.listen((s) {
      const msgs = {
        BatteryState.charging: "Your device is charging",
        BatteryState.discharging: "Your device is running on battery",
        BatteryState.full: "Your battery is fully charged",
        BatteryState.unknown: "Battery status is unknown",
      };
      _bridge.sendEvent('batteryState', {
        'state': msgs[s] ?? "Battery status is unknown",
      });
    });

    _connSub?.cancel();
    _connSub = _connectivity.onConnectivityChanged.listen((results) {
      final status = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      const msgs = {
        ConnectivityResult.wifi: "Connected via Wi-Fi",
        ConnectivityResult.mobile: "Connected via mobile data",
        ConnectivityResult.ethernet: "Connected via Ethernet",
        ConnectivityResult.bluetooth: "Connected via Bluetooth",
        ConnectivityResult.vpn: "Connected via VPN",
        ConnectivityResult.other: "Connected (other network)",
        ConnectivityResult.none: "No internet connection",
      };
      _bridge.sendEvent('connectivity', {'status': msgs[status] ?? "Unknown"});
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
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        SafeArea(child: WebViewWidget(controller: _controller)),
        if (_isLoading)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    ),
  );
}
