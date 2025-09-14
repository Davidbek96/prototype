// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:testapp/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await GetStorage.init();

  runApp(const MyApp());
}
