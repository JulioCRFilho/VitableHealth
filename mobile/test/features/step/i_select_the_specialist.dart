import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
/// Usage: I select the specialist {"Dr. Sarah Smith"}
Future<void> iSelectTheSpecialist(WidgetTester tester, String param1) async {
  await tester.tap(find.byKey(const Key('doctor_dropdown')));
  await tester.pumpAndSettle();

  await tester.tap(find.textContaining(param1).last);
  await tester.pumpAndSettle();
}
