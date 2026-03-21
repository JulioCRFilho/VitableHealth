import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usage: I enter {"   "} into the message input
Future<void> iEnterIntoTheMessageInput(
    WidgetTester tester, String param1) async {
  final textField = find.byType(TextField);
  await tester.enterText(textField, param1);
  await tester.pumpAndSettle();
}
