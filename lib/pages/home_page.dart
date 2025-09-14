import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:testapp/bindings/chat_binding.dart';
import 'package:testapp/pages/help_docs_page.dart';
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
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 600;

    final currentLocale = Get.locale?.languageCode ?? 'en';

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
                  // App badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.16,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 28,
                      color: theme.colorScheme.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'webview_chatbot'.tr,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'welcome'.tr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.75,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Language dropdown (flag + short code)
                  DropdownButton<String>(
                    value: currentLocale,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'en',
                        child: Row(
                          children: [
                            Text("🇺🇸", style: TextStyle(fontSize: 18)),
                            SizedBox(width: 4),
                            Text("EN"),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'ko',
                        child: Row(
                          children: [
                            Text("🇰🇷", style: TextStyle(fontSize: 18)),
                            SizedBox(width: 4),
                            Text("KO"),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == 'en') {
                        Get.updateLocale(const Locale('en'));
                      } else if (value == 'ko') {
                        Get.updateLocale(const Locale('ko'));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Action grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: isWide ? 2 : 1,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: isWide ? 3.2 : 3.0,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ActionCard(
                      title: 'webview_demo'.tr,
                      subtitle: 'webview_demo_sub'.tr,
                      icon: Icons.web_outlined,
                      onTap: () => Get.to(() => const WebViewPage()),
                      accentColor: Colors.indigo,
                    ),
                    ActionCard(
                      title: 'chatbot_demo'.tr,
                      subtitle: 'chatbot_demo_sub'.tr,
                      icon: Icons.mic_none,
                      onTap: () => Get.to(
                        () => const ChatPage(),
                        binding: ChatBinding(),
                      ),
                      accentColor: Colors.teal,
                    ),
                    ActionCard(
                      title: 'devices'.tr,
                      subtitle: 'devices_sub'.tr,
                      icon: Icons.devices_other_outlined,
                      onTap: () {
                        Get.closeAllSnackbars();
                        Get.snackbar('coming_soon'.tr, 'coming_soon_msg'.tr);
                      },
                      accentColor: Colors.orange,
                    ),
                    ActionCard(
                      title: 'help_docs'.tr,
                      subtitle: 'help_docs_sub'.tr,
                      icon: Icons.info_outline,
                      onTap: () {
                        Get.to(() => HelpDocsPage());
                      },
                      accentColor: Color.fromARGB(255, 21, 166, 228),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Text('version'.tr, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
