import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> iTapTheButton(WidgetTester tester, String param1) async {
  var finder = find.text(param1, skipOffstage: false);
  
  if (finder.evaluate().isEmpty) {
     finder = find.bySemanticsLabel(RegExp('.*$param1.*', caseSensitive: false), skipOffstage: false);
  }
  
  if (finder.evaluate().isEmpty) {
     finder = find.widgetWithText(Widget, param1, skipOffstage: false);
  }

  try {
    await tester.ensureVisible(finder);
    await tester.pump();
  } catch (e) {}
  
  await tester.tap(finder, warnIfMissed: false);
  
  // Just a simple pump and give it time to work through the frame
  await tester.pump();
}
