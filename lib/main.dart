// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'controllers/settings_controller.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Register only truly global controllers (settings is app-wide)
  // ChatController and chat-related services will be registered when the chat route opens.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      // App-level initial binding: register SettingsController at startup
      initialBinding: BindingsBuilder(() {
        Get.put(SettingsController());
      }),
      home: HomePage(),
    );
  }
}
