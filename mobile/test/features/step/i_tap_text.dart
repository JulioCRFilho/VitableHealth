import 'package:flutter_test/flutter_test.dart';

/// Example: When I tap {'some'} text
Future<void> iTapText(
  WidgetTester tester,
  String text,
) async {
  final finder = find.text(text);
  try {
    await tester.ensureVisible(finder);
  } catch (_) {}

  await tester.tap(finder);
  
  if (text == 'Confirm Appointment') {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  } else {
    await tester.pumpAndSettle();
  }
}
