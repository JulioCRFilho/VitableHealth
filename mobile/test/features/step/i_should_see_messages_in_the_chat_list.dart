import 'package:flutter_test/flutter_test.dart';

Future<void> iShouldSeeMessagesInTheChatList(
    WidgetTester tester, int param1) async {
  final bubbles = find.bySemanticsLabel(RegExp(r'(Assistant|You) said: .*'));
  expect(bubbles, findsNWidgets(param1));
}
