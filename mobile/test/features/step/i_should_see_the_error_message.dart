import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldSeeTheErrorMessage(WidgetTester tester, String param1) async {
  expect(find.text(param1), findsOneWidget);
}
