import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../settings_controller.dart';
import '../../chat/chat_controller.dart';

class DangerUtilitiesCard extends StatelessWidget {
  const DangerUtilitiesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final theme = Theme.of(context);

    Widget sectionTitle(String title) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title.tr,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle('danger_utilities'.tr),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: Text('storage'.tr),
                  subtitle: Text('storage_info'.tr),
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
                          Text('defaults'.tr, style: theme.textTheme.bodyLarge),
                          const SizedBox(height: 4),
                          Text(
                            'defaults_info'.tr,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Clear preferences + Clear messages buttons (side-by-side)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _confirmClearPreferences(context, settings),
                        icon: const Icon(Icons.settings_backup_restore),
                        label: Text('clear_preferences'.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(
                            color: theme.colorScheme.error.withAlpha(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmClearMessages(context),
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: Text('clear_messages'.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(
                            color: theme.colorScheme.error.withAlpha(30),
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
        title: Text('clear_all_settings_title'.tr),
        content: Text('clear_all_settings_content'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('clear'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      settings.toggleAutoPlayTts(false);
      settings.setTtsLanguage('ko-KR');
      settings.setSttLanguage('ko-KR');
      Get.closeAllSnackbars();
      Get.snackbar('settings'.tr, 'preferences_cleared'.tr);
    }
  }

  Future<void> _confirmClearMessages(BuildContext context) async {
    final chatCtrl = Get.find<ChatController>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('clear_messages_title'.tr),
        content: Text('clear_messages_content'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('clear'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await chatCtrl.clearMessages();
        Get.closeAllSnackbars();
        Get.snackbar('messages'.tr, 'messages_cleared'.tr);
      } catch (e) {
        Get.closeAllSnackbars();
        Get.snackbar('error'.tr, 'failed_to_clear_messages'.tr);
      }
    }
  }
}
