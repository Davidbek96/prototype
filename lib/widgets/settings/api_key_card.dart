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
              'api_key_tip'.tr,
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
          'api_key_label'.tr,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Obx(
          () => Chip(
            label: Text(
              settings.apiKeyIsSet.value
                  ? 'api_key_registered'.tr
                  : 'api_key_not_registered'.tr,
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
          tooltip: 'more'.tr,
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
                children: [
                  const Icon(Icons.copy_outlined),
                  const SizedBox(width: 8),
                  Text('copy_api_key'.tr),
                ],
              ),
            ),
            PopupMenuItem<_MenuAction>(
              value: _MenuAction.delete,
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text(
                    'delete_api_key'.tr,
                    style: const TextStyle(color: Colors.redAccent),
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
        controller: settings.apiKeyTextEditCtrl,
        obscureText: !settings.showApiKey.value,
        decoration: InputDecoration(
          hintText: 'api_key_hint'.tr,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => IconButton(
                  tooltip: settings.showApiKey.value ? 'hide'.tr : 'show'.tr,
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
                  tooltip: 'save_api_key'.tr,
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
    final text = settings.apiKeyTextEditCtrl.text.trim().isNotEmpty
        ? settings.apiKeyTextEditCtrl.text.trim()
        : (settings.storedApiKey ?? '');
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
    } else {
      Get.closeAllSnackbars();
      Get.snackbar('settings'.tr, 'no_api_key_to_copy'.tr);
    }
  }

  Future<void> _confirmDeleteApiKey(
    BuildContext context,
    SettingsController settings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('clear_api_key_title'.tr),
        content: Text('clear_api_key_content'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await settings.clearApiKey();
      Get.closeAllSnackbars();
      Get.snackbar('settings'.tr, 'api_key_cleared'.tr);
    }
  }
}

enum _MenuAction { copy, delete }
