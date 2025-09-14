import 'package:flutter/material.dart';
import 'widgets/api_key_card.dart';
import 'widgets/voice_language_card.dart';
import 'widgets/danger_utilities_card.dart';
import 'package:get/get.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // key remains until the user explicitly deletes it.
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: ListView(
          children: const [
            ApiKeyCard(),
            SizedBox(height: 16),
            VoiceLanguageCard(),
            SizedBox(height: 18),
            DangerUtilitiesCard(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
