import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:testapp/bindings/translations/translations.dart';
import 'package:testapp/controllers/settings_controller.dart';
import 'package:testapp/pages/home_page.dart';

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
