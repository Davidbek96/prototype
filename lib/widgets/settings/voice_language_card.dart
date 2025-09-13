import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';

class VoiceLanguageCard extends StatelessWidget {
  const VoiceLanguageCard({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final theme = Theme.of(context);

    Widget sectionTitle(String title) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle('Voice & Language'),
        Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Auto-play TTS
                Obx(() {
                  return SwitchListTile(
                    title: const Text('Auto-play TTS'),
                    subtitle: const Text(
                      'Automatically play model replies aloud',
                    ),
                    value: settings.autoPlayTts.value,
                    onChanged: settings.toggleAutoPlayTts,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                const Divider(),

                // TTS language
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'TTS Language',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 180,
                      child: Obx(() {
                        return DropdownButtonFormField<String>(
                          initialValue: settings.ttsLanguage.value,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: settings.supportedLanguages
                              .map(
                                (lang) => DropdownMenuItem<String>(
                                  value: lang['code'],
                                  child: Text(lang['label']!),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              settings.setTtsLanguage(val);
                              Get.snackbar(
                                'Settings',
                                'TTS language set to $val',
                              );
                            }
                          },
                        );
                      }),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // STT language
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'STT Language',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 180,
                      child: Obx(() {
                        return DropdownButtonFormField<String>(
                          initialValue: settings.sttLanguage.value,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: settings.supportedLanguages
                              .map(
                                (lang) => DropdownMenuItem<String>(
                                  value: lang['code'],
                                  child: Text(lang['label']!),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              settings.setSttLanguage(val);
                              Get.snackbar(
                                'Settings',
                                'STT language set to $val',
                              );
                            }
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
