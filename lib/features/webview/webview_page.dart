import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'bridge/webview_controller.dart';

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
          // Loader
          Obx(
            () => controller.isLoading.value
                ? Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink(),
          ),
          // Back button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Get.back(); // exit page if no history
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
