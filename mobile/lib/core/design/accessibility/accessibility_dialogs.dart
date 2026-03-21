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

void showScreenReaderHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.record_voice_over_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Text('Screen Reader Help'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The Vitable app is optimized for VoiceOver (iOS) and TalkBack (Android).',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text('• Messages are announced as "Assistant said" or "You said".'),
          Text('• The typing indicator will automatically notify you when the assistant is responding.'),
          Text('• Action buttons and quick replies are clearly labeled for easy navigation.'),
          SizedBox(height: 12),
          Text('Tip: Use swipe gestures to navigate between messages and focus on the input field at the bottom to reply.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}

void showVoiceControlGuideDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings_voice_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Text('Voice Control Guide'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interact with the chatbot using system voice commands:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text('• "Tap Send" to send your message.'),
          Text('• "Tap [Option name]" to select a quick reply (e.g., "Tap New patient").'),
          Text('• "Scroll down" to see the latest messages.'),
          SizedBox(height: 12),
          Text('You can also dictate your message by focusing the input field and using the keyboard dictation feature.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
