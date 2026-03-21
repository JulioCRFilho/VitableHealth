import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldSeeInTheChatList(WidgetTester tester, String param1) async {
  // Use find.textContaining to be safe with Markdown rendering
  expect(find.textContaining(param1), findsAtLeastNWidgets(1));
}
