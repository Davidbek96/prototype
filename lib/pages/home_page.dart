import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat_page.dart';
import 'webview_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("JOI Prototype")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("WebView Hook Demo"),
              onPressed: () => Get.to(() => const WebViewPage()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Voice Chatbot Demo"),
              onPressed: () => Get.to(() => const ChatPage()),
            ),
          ],
        ),
      ),
    );
  }
}
