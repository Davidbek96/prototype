import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../controllers/webview_controller.dart';

class WebViewPage extends StatelessWidget {
  const WebViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WebViewControllerX());

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: WebViewWidget(controller: controller.webViewController),
          ),
          Obx(
            () => controller.isLoading.value
                ? Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
