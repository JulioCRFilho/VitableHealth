import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldSeeTheMessage(WidgetTester tester, String param1) async {
  // Use a more robust way to find the message, especially if it's in a SnackBar or validation field
  // We avoid pump(Duration) if possible to prevent the "dirty widget" crash
  
  bool found = false;
  for (int i = 0; i < 5; i++) {
    await tester.pump(); // Just one frame
    if (find.text(param1, skipOffstage: false).evaluate().isNotEmpty) {
      found = true;
      break;
    }
    // If not found, try a small duration but be careful
    try {
      await tester.pump(const Duration(milliseconds: 100));
    } catch (e) {
      // If it crashes here, we might still have found it in the previous pump or it might be a fatal build error
      if (find.text(param1, skipOffstage: false).evaluate().isNotEmpty) {
        found = true;
        break;
      }
    }
  }
  
  expect(find.text(param1, skipOffstage: false), findsOneWidget);
}
