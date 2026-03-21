import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/features/chatbot/presentation/chat_screen.dart';
import 'package:flutter/rendering.dart';

void main() {
  testWidgets('ChatScreen shows correct semantics for bot greeting', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );

    // Wait for animations and initial message
    await tester.pumpAndSettle();

    // Verify bot greeting semantics
    // The greeting is: 'Hello! 👋 I am your **Vitable Assistant**. How can I help you today?\n\nAre you a new or returning patient?'
    // (Note: The exact text depends on auth state, but we are unauthenticated here)
    
    // We expect a MergeSemantics containing the bot message
    expect(
      find.bySemanticsLabel(RegExp(r'Assistant said: Hello!.*')),
      findsOneWidget,
    );
  });

  testWidgets('Input area has correct semantics', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify text field semantics
    expect(find.bySemanticsLabel('Message input field'), findsOneWidget);

    // Verify send button semantics and hint
    final sendButton = find.bySemanticsLabel('Send message');
    expect(sendButton, findsOneWidget);
    
    // Check if it matches semantics with the hint
    // Note: matchesSemantics is more thorough but bySemanticsLabel is a good start.
  });

  testWidgets('Quick replies have correct semantics', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChatScreen(),
        ),
      ),
    );
    // Initial pump
    await tester.pump();
    // Wait for initial message AND the 400ms delay for quick replies
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // Scroll down to ensure quick replies are in view if needed
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    // Verify the widget is built and visible
    expect(find.text('New patient'), findsOneWidget);

    // Verify individual quick reply semantics directly
    expect(find.byType(Wrap), findsAtLeastNWidgets(1));

    // Verify individual quick reply semantics directly
    // Using find.bySemanticsLabel to ensure they are interpreted as buttons/accessible nodes
    expect(find.bySemanticsLabel('Quick reply: New patient'), findsOneWidget);
    expect(find.bySemanticsLabel('Quick reply: Returning patient'), findsOneWidget);
  });
}
