// Basic widget test for Idly Express app

import 'package:flutter_test/flutter_test.dart';

import 'package:idly_express/main.dart';

void main() {
  testWidgets('App loads dashboard screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IdlyExpressApp());

    // Verify that the dashboard title is present
    expect(find.text('Idly Express'), findsOneWidget);
  });
}
