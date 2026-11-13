import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flashcard_quiz_app/main.dart';

void main() {
  testWidgets('App pumps and shows the first flashcard',
      (WidgetTester tester) async {
    // Start with a clean, empty preferences store so the default deck loads.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const FlashcardQuizApp());
    await tester.pumpAndSettle();

    // App bar and first seed card are visible.
    expect(find.text('Flashcard Quiz App'), findsWidgets);
    expect(find.text('What is the capital of France?'), findsOneWidget);
    expect(find.text('Card 1 of 10'), findsOneWidget);
    expect(find.text('Show Answer'), findsOneWidget);

    // Tapping "Show Answer" flips the card to reveal the answer.
    await tester.tap(find.text('Show Answer'));
    await tester.pumpAndSettle();
    expect(find.text('Paris'), findsOneWidget);
    expect(find.text('Hide Answer'), findsOneWidget);

    // Next moves to the second card.
    await tester.tap(find.text('Next →'));
    await tester.pumpAndSettle();
    expect(find.text('Card 2 of 10'), findsOneWidget);
    expect(
      find.text('What planet is known as the Red Planet?'),
      findsOneWidget,
    );
  });
}
