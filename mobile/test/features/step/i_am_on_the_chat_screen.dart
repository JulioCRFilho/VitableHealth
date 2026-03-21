import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/main.dart';

/// Usage: I am on the Chat screen
Future<void> iAmOnTheChatScreen(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: VitableHealthApp()));
  await tester.pumpAndSettle();
}
