import 'package:flutter_test/flutter_test.dart';

/// Usage: I tap the Send button
Future<void> iTapTheSendButton(WidgetTester tester) async {
  final sendButton = find.bySemanticsLabel('Send message');
  await tester.tap(sendButton);
  await tester.pumpAndSettle();
}
