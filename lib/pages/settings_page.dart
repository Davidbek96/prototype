import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // register controller if missing
    final SettingsController settings = Get.isRegistered<SettingsController>()
        ? Get.find<SettingsController>()
        : Get.put(SettingsController());

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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: ListView(
          children: [
            // ===== API Key card =====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'API Key',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Obx(() {
                          final set = settings.apiKeyIsSet.value;
                          return Chip(
                            label: Text(set ? 'Registered' : 'Not registered'),
                            backgroundColor: set
                                ? Colors.green.shade100
                                : Colors.red.shade50,
                            avatar: Icon(
                              set ? Icons.check_circle : Icons.error_outline,
                              size: 18,
                              color: set ? Colors.green : Colors.red,
                            ),
                          );
                        }),
                        IconButton(
                          tooltip: 'Copy to clipboard',
                          onPressed: () {
                            final text = settings.apiKeyController.text.trim();
                            if (text.isNotEmpty) {
                              Clipboard.setData(ClipboardData(text: text));
                              Get.snackbar(
                                'Settings',
                                'API key copied to clipboard',
                              );
                            } else {
                              Get.snackbar('Settings', 'No API key to copy');
                            }
                          },
                          icon: const Icon(Icons.copy_outlined, size: 20),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Delete API key',
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Clear API key?'),
                                content: const Text(
                                  'This will remove the stored API key.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await settings.clearApiKey();
                              Get.snackbar('Settings', 'API key cleared');
                            }
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: settings.apiKeyController,
                      obscureText: !settings.showApiKey.value,
                      decoration: InputDecoration(
                        hintText: 'Enter API key',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Obx(
                              () => IconButton(
                                tooltip: settings.showApiKey.value
                                    ? 'Hide'
                                    : 'Show',
                                onPressed: settings.toggleShowApiKey,
                                icon: Icon(
                                  settings.showApiKey.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Save API key',
                              onPressed: () async {
                                await settings.saveApiKey();
                              },
                              icon: const Icon(Icons.save),
                            ),
                          ],
                        ),
                        // ensure suffixIcon spacing doesn't overflow
                        // (we used Row inside suffixIcon; it's ok on modern Flutter)
                      ),
                      onChanged: (_) {
                        // nothing automatic - user should press Save
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tip: keep your API key secret. Do not share screenshots containing the full key.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== Voice & Language card =====
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

            const SizedBox(height: 18),

            // ===== Danger / Utilities =====
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Storage'),
                      subtitle: const Text(
                        'API key and settings are stored locally on this device only.',
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.restart_alt),
                      title: const Text('Reset to defaults'),
                      subtitle: const Text(
                        'Resets language and toggles, but will not delete API key automatically.',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          settings.toggleAutoPlayTts(false);
                          settings.setTtsLanguage('en-US');
                          settings.setSttLanguage('en-US');
                          Get.snackbar('Settings', 'Reset applied (defaults)');
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Clear all stored settings?'),
                            content: const Text(
                              'This removes saved language & auto-play preferences. API key will remain unless explicitly cleared.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Clear',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          // remove stored non-key settings
                          settings.toggleAutoPlayTts(false);
                          settings.setTtsLanguage('en-US');
                          settings.setSttLanguage('en-US');
                          Get.snackbar('Settings', 'Preferences cleared');
                        }
                      },
                      icon: const Icon(
                        Icons.delete_forever_outlined,
                        color: Colors.redAccent,
                      ),
                      label: const Text('Clear preferences'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
