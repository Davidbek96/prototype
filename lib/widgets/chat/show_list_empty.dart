// lib/widgets/show_list_empty.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShowListEmpty extends StatelessWidget {
  const ShowListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy, size: 92, color: Colors.grey.shade400),
            const SizedBox(height: 18),
            Text(
              'ask_me_anything'.tr,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'start_conversation_hint'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
