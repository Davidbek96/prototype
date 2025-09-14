// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:testapp/bindings/translations/translations.dart';
import 'controllers/settings_controller.dart';
import 'pages/home_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await GetStorage.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: BindingsBuilder(() {
        Get.put(SettingsController());
      }),
      title: 'Prototype',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko', 'KR'),
      fallbackLocale: const Locale('en', 'US'),
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      translations: AppTranslations(),
      home: HomePage(),
    );
  }
}
