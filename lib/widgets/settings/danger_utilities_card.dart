import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';

class DangerUtilitiesCard extends StatelessWidget {
  const DangerUtilitiesCard({super.key});

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
        sectionTitle('Danger & Utilities'),
        Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Storage info
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline),
                  title: Text('Storage'),
                  subtitle: Text(
                    'API key and settings are stored locally on this device only.',
                  ),
                ),

                const Divider(),

                // Defaults info
                Row(
                  children: [
                    Icon(Icons.restart_alt, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Defaults', style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Language and auto-play defaults are: '
                            'TTS = en-US, STT = en-US, Auto-play TTS = off.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Clear preferences button
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _confirmClearPreferences(context, settings),
                        icon: const Icon(Icons.delete_forever_outlined),
                        label: const Text('Clear preferences'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(
                            color: Colors.redAccent.withValues(alpha: 0.12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
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

  Future<void> _confirmClearPreferences(
    BuildContext context,
    SettingsController settings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all stored settings?'),
        content: const Text(
          'This removes saved language & auto-play preferences. '
          'API key will remain unless explicitly cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      settings.toggleAutoPlayTts(false);
      settings.setTtsLanguage('en-US');
      settings.setSttLanguage('en-US');
      Get.closeAllSnackbars();
      Get.snackbar('Settings', 'Preferences cleared');
    }
  }
}
