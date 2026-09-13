import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artesian/main.dart';

void main() {
  test(
    'product photo url uses the backend uploader path when photo_path exists',
    () {
      final product = {'photo_path': '/uploads/demo.jpg'};

      expect(productPhotoUrl(product), '$backendUrl/uploads/demo.jpg');
    },
  );

  testWidgets('pricing assistant MVP screen renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PricingAssistantPage()));

    expect(find.text('Pricing Assistant'), findsNWidgets(2));
    expect(find.text('Suggested price'), findsOneWidget);
    expect(find.text('Breakdown'), findsOneWidget);
  });
}
