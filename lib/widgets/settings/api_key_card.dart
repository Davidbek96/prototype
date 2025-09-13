import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';

class ApiKeyCard extends StatelessWidget {
  const ApiKeyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final theme = Theme.of(context);

    // We no longer auto-clear the controller on first frame.
    // The controller starts empty (privacy). The stored key remains in storage.

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, settings, theme),
            const SizedBox(height: 8),
            _buildApiKeyField(settings),
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
    );
  }

  Widget _buildHeader(
    BuildContext context,
    SettingsController settings,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Text(
          'API Key',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Obx(
          () => Chip(
            label: Text(
              settings.apiKeyIsSet.value ? 'Registered' : 'Not registered',
            ),
            backgroundColor: settings.apiKeyIsSet.value
                ? Colors.green.shade100
                : Colors.red.shade50,
            avatar: Icon(
              settings.apiKeyIsSet.value
                  ? Icons.check_circle
                  : Icons.error_outline,
              size: 18,
              color: settings.apiKeyIsSet.value ? Colors.green : Colors.red,
            ),
          ),
        ),

        const Spacer(),

        PopupMenuButton<_MenuAction>(
          tooltip: 'More',
          icon: const Icon(Icons.more_vert),
          onSelected: (action) async {
            if (action == _MenuAction.copy) {
              _copyApiKey(context, settings);
            } else if (action == _MenuAction.delete) {
              await _confirmDeleteApiKey(context, settings);
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem<_MenuAction>(
              value: _MenuAction.copy,
              child: Row(
                children: const [
                  Icon(Icons.copy_outlined),
                  SizedBox(width: 8),
                  Text('Copy API key'),
                ],
              ),
            ),
            PopupMenuItem<_MenuAction>(
              value: _MenuAction.delete,
              child: Row(
                children: const [
                  Icon(Icons.delete_outline, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    'Delete API key',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApiKeyField(SettingsController settings) {
    return Obx(
      () => TextField(
        controller: settings.apiKeyController,
        obscureText: !settings.showApiKey.value,
        decoration: InputDecoration(
          hintText: 'Enter Gemini API key',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => IconButton(
                  tooltip: settings.showApiKey.value ? 'Hide' : 'Show',
                  onPressed: settings.toggleShowApiKey,
                  icon: Icon(
                    settings.showApiKey.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
              Obx(() {
                if (settings.isSaving.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return IconButton(
                  tooltip: 'Save API key',
                  onPressed: settings.saveApiKey,
                  icon: const Icon(Icons.save),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _copyApiKey(BuildContext context, SettingsController settings) {
    // Favor visible input when present, otherwise fall back to stored key.
    final text = settings.apiKeyController.text.trim().isNotEmpty
        ? settings.apiKeyController.text.trim()
        : (settings.storedApiKey ?? '');
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
    } else {
      Get.closeAllSnackbars();
      Get.snackbar('Settings', 'No API key to copy');
    }
  }

  Future<void> _confirmDeleteApiKey(
    BuildContext context,
    SettingsController settings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear API key?'),
        content: const Text('This will remove the stored API key.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await settings.clearApiKey();
      Get.closeAllSnackbars();
      Get.snackbar('Settings', 'API key cleared');
    }
  }
}

enum _MenuAction { copy, delete }
