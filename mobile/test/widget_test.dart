import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VitableHealthApp()));
    
    // Wait for animations to settle
    await tester.pumpAndSettle();
    
    // We expect the ChatScreen to be the first screen, which has this title
    expect(find.text('Vitable Assistant'), findsOneWidget);
  });
}
