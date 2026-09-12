import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artesian/main.dart';

void main() {
  testWidgets('pricing assistant MVP screen renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PricingAssistantPage()));

    expect(find.text('Pricing Assistant'), findsNWidgets(2));
    expect(find.text('Suggested price'), findsOneWidget);
    expect(find.text('Breakdown'), findsOneWidget);
  });
}
