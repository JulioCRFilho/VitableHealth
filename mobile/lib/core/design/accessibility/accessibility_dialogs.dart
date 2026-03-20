import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../typography/text_scale_provider.dart';
import '../colors/app_colors.dart';

void showTextScaleDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final currentScale = ref.watch(textScaleProvider);
          return AlertDialog(
            title: const Text('Text Size'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Adjust the application text size',
                  style: TextStyle(fontSize: 14 * currentScale),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: currentScale,
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  label: '${(currentScale * 100).toInt()}%',
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    ref.read(textScaleProvider.notifier).setScale(value);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Small', style: TextStyle(fontSize: 12)),
                    const Text('Default', style: TextStyle(fontSize: 14)),
                    const Text('Large', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(textScaleProvider.notifier).reset();
                },
                child: const Text('Reset'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    },
  );
}
