import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:testapp/bindings/chat_binding.dart';
import 'package:testapp/widgets/chat/action_card.dart';

import 'chat_page.dart';
import 'webview_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Theme.of(context).cardColor,
        systemNavigationBarIconBrightness: Brightness.dark, // dark icons
      ),
    );
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 600;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header / greeting
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Prototype',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose a demo to explore the features.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Action grid: responsive (1 column on narrow, 2 on wide)
              Expanded(
                child: GridView.count(
                  crossAxisCount: isWide ? 2 : 1,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  // make narrow tiles a bit taller by lowering the aspect ratio:
                  childAspectRatio: isWide ? 3.2 : 3.0,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ActionCard(
                      title: 'WebView Hook Demo',
                      subtitle: 'Integrate and control web content',
                      icon: Icons.web_outlined,
                      onTap: () => Get.to(() => const WebViewPage()),
                      accentColor: Colors.indigo,
                    ),
                    ActionCard(
                      title: 'Voice Chatbot Demo',
                      subtitle: 'Talk to the assistant & test voice flow',
                      icon: Icons.mic_none,
                      onTap: () => Get.to(
                        () => const ChatPage(),
                        binding: ChatBinding(),
                      ),
                      accentColor: Colors.teal,
                    ),
                    ActionCard(
                      title: 'Connected Devices',
                      subtitle: 'Control everythin using your phone',
                      icon: Icons.devices_other_outlined,
                      onTap: () {
                        Get.closeCurrentSnackbar();
                        Get.snackbar(
                          'Coming Soon',
                          'You will be able to use this feature soon',
                        );
                      },
                      accentColor: Colors.orange,
                    ),
                    ActionCard(
                      title: 'Help & Docs',
                      subtitle: 'Read quickstart and docs',
                      icon: Icons.info_outline,
                      onTap: () {
                        Get.closeCurrentSnackbar();
                        Get.snackbar(
                          'Coming Soon',
                          'You will be able to use this feature soon',
                        );
                      },
                      accentColor: const Color.fromARGB(255, 21, 166, 228),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Text('Prototype v1.0', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
