import 'package:flutter/material.dart';
import '../widgets/settings/api_key_card.dart';
import '../widgets/settings/voice_language_card.dart';
import '../widgets/settings/danger_utilities_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // key remains until the user explicitly deletes it.
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
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
