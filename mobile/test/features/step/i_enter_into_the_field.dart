import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iEnterIntoTheField(WidgetTester tester, String param1, String param2) async {
  // Use a more robust way to find the field, especially if it's in a dialog
  // Search for TextField decoration since TextFormField doesn't expose it directly as a getter
  
  var finder = find.byWidgetPredicate((widget) => 
    widget is TextField && 
    (widget.decoration?.labelText == param2 || 
     widget.decoration?.hintText == param2),
    skipOffstage: false
  );
  
  if (finder.evaluate().isEmpty) {
    finder = find.widgetWithText(TextFormField, param2, skipOffstage: false);
  }
  
  if (finder.evaluate().isEmpty) {
    // Fallback: Name is the first field, Email is the second
    finder = find.byType(TextField, skipOffstage: false).at(param2 == "Name" ? 0 : 1);
  }

  // Wait for the field to appear (e.g. if a dialog is animating)
  for (int i = 0; i < 20; i++) {
    if (finder.evaluate().isNotEmpty) break;
    await tester.pump();
  }

  try {
    await tester.ensureVisible(finder);
    await tester.pump();
  } catch (e) {}
  
  await tester.enterText(finder, param1);
  await tester.pump();
}
