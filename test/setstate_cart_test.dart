import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cart_four_ways/setstate/cart_page_setstate.dart';

void main() {
  testWidgets('adding Keyboard twice and applying SAVE10 gives total 88.20',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SetStateCartPage()),
    );

    // Tap Keyboard twice (49 * 2 = 98.00)
    final keyboardChip = find.text('Keyboard · 49');
    await tester.tap(keyboardChip);
    await tester.pump();
    await tester.tap(keyboardChip);
    await tester.pump();

    // Enter SAVE10 and tap Apply
    await tester.enterText(find.byType(TextField), 'SAVE10');
    await tester.tap(find.text('Apply'));
    await tester.pump();

    // Verify 98.00 - 10% = 88.20
    expect(find.text('88.20'), findsOneWidget);
  });
}